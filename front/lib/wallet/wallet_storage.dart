import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import '../telegram_webapp.dart';
import 'wallet_keys.dart';

enum WalletKeySource {
  browserLocalStorage,
  telegramDeviceStorage,
  telegramCloudStorage,
  generatedBrowser,
  generatedTelegram,
  generatedTelegramCloudMiss,
}

class WalletKeyResult {
  final WalletKeys keys;
  final WalletKeySource source;

  const WalletKeyResult({
    required this.keys,
    required this.source,
  });
}

class WalletKeyManager {
  static const String _walletBlobKey = 'wallet.bundle.v1';
  static const String _telegramDeviceKey = 'wallet_bundle_v1';
  static const String _telegramCloudKey = 'wallet_bundle_v1';

  final TelegramWebApp _telegram;

  WalletKeyManager({TelegramWebApp? telegramWebApp})
      : _telegram = telegramWebApp ?? TelegramWebApp();

  Future<WalletKeyResult> getOrCreateWalletKeys({
    Future<bool> Function()? hasWalletRemoteCheck,
  }) async {
    if (!_telegram.isActuallyInTelegram) {
      return _getOrCreateBrowserKeys();
    }
    return _getOrCreateTelegramKeys(
      hasWalletRemoteCheck: hasWalletRemoteCheck,
    );
  }

  Future<WalletKeyResult> _getOrCreateBrowserKeys() async {
    final scope = _scopeForBrowser();
    final cached = await _readLocalBundle(scope: scope);
    if (cached != null) {
      return WalletKeyResult(
        keys: cached,
        source: WalletKeySource.browserLocalStorage,
      );
    }

    final created = await _createBundle();
    await _writeLocalBundle(scope: scope, keys: created);
    return WalletKeyResult(
      keys: created,
      source: WalletKeySource.generatedBrowser,
    );
  }

  Future<WalletKeyResult> _getOrCreateTelegramKeys({
    Future<bool> Function()? hasWalletRemoteCheck,
  }) async {
    final scope = _scopeForTelegram();

    final fromDevice = await _readTelegramDeviceBundle(scope: scope);
    if (fromDevice != null) {
      return WalletKeyResult(
        keys: fromDevice,
        source: WalletKeySource.telegramDeviceStorage,
      );
    }

    bool hasWallet = false;
    if (hasWalletRemoteCheck != null) {
      try {
        hasWallet = await hasWalletRemoteCheck();
      } catch (_) {
        hasWallet = false;
      }
    }

    if (hasWallet) {
      final fromCloud = await _readTelegramCloudBundle(scope: scope);
      if (fromCloud != null) {
        await _writeTelegramDeviceBundle(scope: scope, keys: fromCloud);
        await _writeLocalBundle(scope: scope, keys: fromCloud);
        return WalletKeyResult(
          keys: fromCloud,
          source: WalletKeySource.telegramCloudStorage,
        );
      }
    }

    final created = await _createBundle();
    await _writeTelegramDeviceBundle(scope: scope, keys: created);
    await _writeLocalBundle(scope: scope, keys: created);
    await _writeTelegramCloudBundle(scope: scope, keys: created);
    return WalletKeyResult(
      keys: created,
      source: hasWallet
          ? WalletKeySource.generatedTelegramCloudMiss
          : WalletKeySource.generatedTelegram,
    );
  }

  Future<WalletKeys> _createBundle() async {
    final keys = await WalletKeyGenerator.generateEd25519();
    return keys;
  }

  Future<WalletKeys?> _readLocalBundle({required String scope}) async {
    final raw = html.window.localStorage[_walletBlobKey];
    final bundle = WalletKeyBundle.tryParse(raw);
    if (bundle == null) return null;
    return WalletKeyGenerator.decryptBundle(bundle: bundle, scope: scope);
  }

  Future<void> _writeLocalBundle({
    required String scope,
    required WalletKeys keys,
  }) async {
    final bundle = await WalletKeyGenerator.encryptBundle(
      keys: keys,
      scope: scope,
    );
    html.window.localStorage[_walletBlobKey] = bundle.toJsonString();
  }

  Future<WalletKeys?> _readTelegramDeviceBundle({
    required String scope,
  }) async {
    final raw = await _telegramGetFromDeviceStorage(_telegramDeviceKey);
    final bundle = WalletKeyBundle.tryParse(raw);
    if (bundle == null) return null;
    return WalletKeyGenerator.decryptBundle(bundle: bundle, scope: scope);
  }

  Future<void> _writeTelegramDeviceBundle({
    required String scope,
    required WalletKeys keys,
  }) async {
    final bundle = await WalletKeyGenerator.encryptBundle(
      keys: keys,
      scope: scope,
    );
    await _telegramSetToDeviceStorage(_telegramDeviceKey, bundle.toJsonString());
  }

  Future<WalletKeys?> _readTelegramCloudBundle({
    required String scope,
  }) async {
    final raw = await _telegramCloudGet(_telegramCloudKey);
    final bundle = WalletKeyBundle.tryParse(raw);
    if (bundle == null) return null;
    return WalletKeyGenerator.decryptBundle(bundle: bundle, scope: scope);
  }

  Future<void> _writeTelegramCloudBundle({
    required String scope,
    required WalletKeys keys,
  }) async {
    final bundle = await WalletKeyGenerator.encryptBundle(
      keys: keys,
      scope: scope,
    );
    await _telegramCloudSet(_telegramCloudKey, bundle.toJsonString());
  }

  String _scopeForBrowser() {
    return 'browser:${html.window.location.host}';
  }

  String _scopeForTelegram() {
    final user = _telegram.user;
    final userId = (user?['id'] ?? 'unknown').toString();
    return 'telegram:$userId';
  }

  Future<String?> _telegramGetFromDeviceStorage(String key) async {
    final app = _telegram.webApp;
    if (app == null) return null;

    // Preferred modern API shape.
    for (final objectName in ['DeviceStorage', 'deviceStorage']) {
      final obj = app[objectName];
      if (obj is js.JsObject) {
        final value = await _jsGetItem(obj, key);
        if (value != null) return value;
      }
    }

    // Fallback: local storage mirror for non-supporting clients.
    return html.window.localStorage['tg.device.$key'];
  }

  Future<void> _telegramSetToDeviceStorage(String key, String value) async {
    final app = _telegram.webApp;
    if (app == null) return;

    for (final objectName in ['DeviceStorage', 'deviceStorage']) {
      final obj = app[objectName];
      if (obj is js.JsObject) {
        final ok = await _jsSetItem(obj, key, value);
        if (ok) return;
      }
    }

    html.window.localStorage['tg.device.$key'] = value;
  }

  Future<String?> _telegramCloudGet(String key) async {
    final app = _telegram.webApp;
    if (app == null) return null;

    final cloud = app['CloudStorage'];
    if (cloud is! js.JsObject) return null;
    return _jsGetItem(cloud, key);
  }

  Future<void> _telegramCloudSet(String key, String value) async {
    final app = _telegram.webApp;
    if (app == null) return;

    final cloud = app['CloudStorage'];
    if (cloud is! js.JsObject) return;
    await _jsSetItem(cloud, key, value);
  }

  Future<String?> _jsGetItem(js.JsObject object, String key) async {
    final completer = Completer<String?>();
    try {
      final getItem = object['getItem'];
      if (getItem is js.JsFunction) {
        getItem.apply([
          key,
          (dynamic error, dynamic value) {
            if (completer.isCompleted) return;
            if (error != null) {
              completer.complete(null);
              return;
            }
            completer.complete(value?.toString());
          }
        ]);
      } else {
        completer.complete(null);
      }
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future.timeout(const Duration(seconds: 2), onTimeout: () => null);
  }

  Future<bool> _jsSetItem(js.JsObject object, String key, String value) async {
    final completer = Completer<bool>();
    try {
      final setItem = object['setItem'];
      if (setItem is js.JsFunction) {
        setItem.apply([
          key,
          value,
          (dynamic error, [dynamic _]) {
            if (completer.isCompleted) return;
            completer.complete(error == null);
          }
        ]);
      } else {
        completer.complete(false);
      }
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future.timeout(const Duration(seconds: 2), onTimeout: () => false);
  }
}
