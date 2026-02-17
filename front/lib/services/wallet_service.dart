import 'dart:async';

enum WalletDeployStatus {
  notStarted,
  pending,
  deployed,
  failed,
}

enum WalletDllrStatus {
  none,
  allocated,
  locked,
  available,
}

class WalletState {
  const WalletState({
    required this.address,
    required this.deployStatus,
    required this.dllrStatus,
    required this.allocated,
    required this.locked,
    required this.available,
    required this.restored,
  });

  final String address;
  final WalletDeployStatus deployStatus;
  final WalletDllrStatus dllrStatus;
  final String allocated;
  final String locked;
  final String available;
  final bool restored;
}

abstract class WalletService {
  Future<WalletState> loadOrCreateWallet();
  Future<WalletState> restoreWallet({required String encryptedBlob});
  Future<WalletState> deployWallet({required String address});
  Stream<WalletState> watchStatus({required String address});
}

// Front-first option: keys + wallet lifecycle handled on device.
class LocalWalletService implements WalletService {
  @override
  Future<WalletState> loadOrCreateWallet() {
    throw UnimplementedError('Local wallet flow not wired yet.');
  }

  @override
  Future<WalletState> restoreWallet({required String encryptedBlob}) {
    throw UnimplementedError('Local wallet restore not wired yet.');
  }

  @override
  Future<WalletState> deployWallet({required String address}) {
    throw UnimplementedError('Local deploy flow not wired yet.');
  }

  @override
  Stream<WalletState> watchStatus({required String address}) {
    throw UnimplementedError('Local status stream not wired yet.');
  }
}

// Optional provider: backend-driven wallet lifecycle.
class BackendWalletService implements WalletService {
  @override
  Future<WalletState> loadOrCreateWallet() {
    throw UnimplementedError('Backend wallet flow not wired yet.');
  }

  @override
  Future<WalletState> restoreWallet({required String encryptedBlob}) {
    throw UnimplementedError('Backend wallet restore not wired yet.');
  }

  @override
  Future<WalletState> deployWallet({required String address}) {
    throw UnimplementedError('Backend deploy flow not wired yet.');
  }

  @override
  Stream<WalletState> watchStatus({required String address}) {
    throw UnimplementedError('Backend status stream not wired yet.');
  }
}

class MockWalletService implements WalletService {
  static const WalletState _mock = WalletState(
    address: 'EQC8fT2u...pRk91A',
    deployStatus: WalletDeployStatus.pending,
    dllrStatus: WalletDllrStatus.allocated,
    allocated: '10.00',
    locked: '2.00',
    available: '8.00',
    restored: false,
  );

  @override
  Future<WalletState> loadOrCreateWallet() async => _mock;

  @override
  Future<WalletState> restoreWallet({required String encryptedBlob}) async {
    return const WalletState(
      address: 'EQC8fT2u...pRk91A',
      deployStatus: WalletDeployStatus.deployed,
      dllrStatus: WalletDllrStatus.available,
      allocated: '10.00',
      locked: '0.00',
      available: '10.00',
      restored: true,
    );
  }

  @override
  Future<WalletState> deployWallet({required String address}) async => _mock;

  @override
  Stream<WalletState> watchStatus({required String address}) async* {
    yield _mock;
  }
}
