import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class WalletKeys {
  final String algorithm;
  final String publicKeyBase64;
  final String privateKeyBase64;
  final int createdAtMs;

  const WalletKeys({
    required this.algorithm,
    required this.publicKeyBase64,
    required this.privateKeyBase64,
    required this.createdAtMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'public_key': publicKeyBase64,
      'private_key': privateKeyBase64,
      'created_at_ms': createdAtMs,
    };
  }

  factory WalletKeys.fromJson(Map<String, dynamic> json) {
    return WalletKeys(
      algorithm: (json['algorithm'] ?? 'ed25519').toString(),
      publicKeyBase64: (json['public_key'] ?? '').toString(),
      privateKeyBase64: (json['private_key'] ?? '').toString(),
      createdAtMs: (json['created_at_ms'] is int)
          ? json['created_at_ms'] as int
          : int.tryParse((json['created_at_ms'] ?? '').toString()) ??
              DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class WalletKeyBundle {
  final int version;
  final String algorithm;
  final String publicKeyBase64;
  final String encryptedPrivateKeyBase64;
  final int createdAtMs;
  final String encryption;

  const WalletKeyBundle({
    required this.version,
    required this.algorithm,
    required this.publicKeyBase64,
    required this.encryptedPrivateKeyBase64,
    required this.createdAtMs,
    required this.encryption,
  });

  Map<String, dynamic> toJson() {
    return {
      'v': version,
      'algorithm': algorithm,
      'public_key': publicKeyBase64,
      'private_key_enc': encryptedPrivateKeyBase64,
      'created_at_ms': createdAtMs,
      'enc': encryption,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory WalletKeyBundle.fromJson(Map<String, dynamic> json) {
    return WalletKeyBundle(
      version: (json['v'] is int) ? json['v'] as int : 1,
      algorithm: (json['algorithm'] ?? 'ed25519').toString(),
      publicKeyBase64: (json['public_key'] ?? '').toString(),
      encryptedPrivateKeyBase64: (json['private_key_enc'] ?? '').toString(),
      createdAtMs: (json['created_at_ms'] is int)
          ? json['created_at_ms'] as int
          : int.tryParse((json['created_at_ms'] ?? '').toString()) ??
              DateTime.now().millisecondsSinceEpoch,
      encryption: (json['enc'] ?? 'xor-sha256-v1').toString(),
    );
  }

  static WalletKeyBundle? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return WalletKeyBundle.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}

class WalletKeyGenerator {
  static final Ed25519 _ed25519 = Ed25519();
  static final Sha256 _sha256 = Sha256();

  static Future<WalletKeys> generateEd25519() async {
    final keyPair = await _ed25519.newKeyPair();
    final keyData = await keyPair.extract();

    return WalletKeys(
      algorithm: 'ed25519',
      publicKeyBase64: base64Encode(keyData.publicKey.bytes),
      privateKeyBase64: base64Encode(keyData.privateKeyBytes),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<WalletKeyBundle> encryptBundle({
    required WalletKeys keys,
    required String scope,
  }) async {
    final maskSeed = utf8.encode('$scope|${keys.publicKeyBase64}|hype-links');
    final digest = await _sha256.hash(maskSeed);
    final mask = digest.bytes;

    final privateBytes = base64Decode(keys.privateKeyBase64);
    final encrypted = Uint8List(privateBytes.length);
    for (var i = 0; i < privateBytes.length; i++) {
      encrypted[i] = privateBytes[i] ^ mask[i % mask.length];
    }

    return WalletKeyBundle(
      version: 1,
      algorithm: keys.algorithm,
      publicKeyBase64: keys.publicKeyBase64,
      encryptedPrivateKeyBase64: base64Encode(encrypted),
      createdAtMs: keys.createdAtMs,
      encryption: 'xor-sha256-v1',
    );
  }

  static Future<WalletKeys?> decryptBundle({
    required WalletKeyBundle bundle,
    required String scope,
  }) async {
    if (bundle.algorithm != 'ed25519') return null;
    if (bundle.encryptedPrivateKeyBase64.isEmpty ||
        bundle.publicKeyBase64.isEmpty) {
      return null;
    }
    final maskSeed = utf8.encode('$scope|${bundle.publicKeyBase64}|hype-links');
    final digest = await _sha256.hash(maskSeed);
    final mask = digest.bytes;

    try {
      final encrypted = base64Decode(bundle.encryptedPrivateKeyBase64);
      final privateBytes = Uint8List(encrypted.length);
      for (var i = 0; i < encrypted.length; i++) {
        privateBytes[i] = encrypted[i] ^ mask[i % mask.length];
      }
      final privateKeyBase64 = base64Encode(privateBytes);
      final valid = await _isValidEd25519Pair(
        privateKeyBase64: privateKeyBase64,
        publicKeyBase64: bundle.publicKeyBase64,
      );
      if (!valid) return null;

      return WalletKeys(
        algorithm: 'ed25519',
        publicKeyBase64: bundle.publicKeyBase64,
        privateKeyBase64: privateKeyBase64,
        createdAtMs: bundle.createdAtMs,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _isValidEd25519Pair({
    required String privateKeyBase64,
    required String publicKeyBase64,
  }) async {
    try {
      final privateBytes = base64Decode(privateKeyBase64);
      final expectedPublic = base64Decode(publicKeyBase64);
      final keyPair = SimpleKeyPairData(
        privateBytes,
        type: KeyPairType.ed25519,
        publicKey: SimplePublicKey(expectedPublic, type: KeyPairType.ed25519),
      );

      final challenge = _randomBytes(32);
      final signature = await _ed25519.sign(challenge, keyPair: keyPair);
      return _ed25519.verify(challenge, signature: signature);
    } catch (_) {
      return false;
    }
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
