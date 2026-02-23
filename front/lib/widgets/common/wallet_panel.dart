import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'pointer_region.dart';

enum WalletPanelState {
  noWallet,
  generating,
  deploying,
  ready,
  restored,
}

class WalletPanel extends StatelessWidget {
  const WalletPanel({
    super.key,
    required this.state,
    required this.mockState,
    this.onCreateWallet,
    this.onRestoreWallet,
  });

  final WalletPanelState state;
  final Map<String, dynamic> mockState;

  /// Called when user taps "Create Wallet". When null, button is non-interactive (demo).
  final VoidCallback? onCreateWallet;

  /// Called when user taps "Restore Wallet". When null, button is non-interactive (demo).
  final VoidCallback? onRestoreWallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.isLightTheme ? const Color(0xFFF3F3F3) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.isLightTheme ? const Color(0xFFE0E0E0) : const Color(0xFF2A2A2A),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (state) {
      case WalletPanelState.noWallet:
        return _buildNoWallet();
      case WalletPanelState.generating:
        return _buildGenerating();
      case WalletPanelState.deploying:
        return _buildDeploying();
      case WalletPanelState.ready:
        return _buildReadyOrRestored(isRestored: false);
      case WalletPanelState.restored:
        return _buildReadyOrRestored(isRestored: true);
    }
  }

  Widget _buildNoWallet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Wallet v1'),
        const SizedBox(height: 8),
        _muted('No wallet found on this device.'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ghostButton('Create Wallet', onTap: onCreateWallet),
            _ghostButton('Restore Wallet', onTap: onRestoreWallet),
          ],
        ),
      ],
    );
  }

  Widget _buildGenerating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Wallet v1'),
        const SizedBox(height: 10),
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(width: 10),
            _muted('Creating wallet...'),
          ],
        ),
      ],
    );
  }

  Widget _buildDeploying() {
    final address = (mockState['address'] as String?) ?? 'EQC...123';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Wallet v1'),
        const SizedBox(height: 8),
        _addressRow(address),
        const SizedBox(height: 12),
        Row(
          children: [
            _badge('Deploying', const Color(0xFFE39A1F)),
            const SizedBox(width: 8),
            _muted('Polling deployment status...'),
          ],
        ),
      ],
    );
  }

  Widget _buildReadyOrRestored({required bool isRestored}) {
    final address = (mockState['address'] as String?) ?? 'EQC...123';
    final dllr = (mockState['balances'] as Map<String, dynamic>?)?['dllr'] as Map<String, dynamic>?;
    final allocated = (dllr?['allocated'] as String?) ?? '0.00';
    final locked = (dllr?['locked'] as String?) ?? '0.00';
    final available = (dllr?['available'] as String?) ?? '0.00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _title('Wallet v1'),
            const SizedBox(width: 8),
            _badge(isRestored ? 'Restored' : 'Ready', const Color(0xFF1CA761)),
          ],
        ),
        const SizedBox(height: 8),
        _addressRow(address),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metricBadge('Allocated', allocated, const Color(0xFF3B82F6)),
            _metricBadge('Locked', locked, const Color(0xFFE39A1F)),
            _metricBadge('Available', available, const Color(0xFF1CA761)),
          ],
        ),
      ],
    );
  }

  Widget _addressRow(String address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.isLightTheme ? Colors.white : const Color(0xFF151515),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              address,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Aeroport Mono',
                fontSize: 13,
                color: AppTheme.textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ghostButton('Copy'),
          const SizedBox(width: 6),
          _ghostButton('QR'),
        ],
      ),
    );
  }

  Widget _ghostButton(String label, {VoidCallback? onTap}) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.isLightTheme ? const Color(0xFFCDCDCD) : const Color(0xFF3B3B3B),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Aeroport',
          fontSize: 12,
          color: AppTheme.textColor,
        ),
      ),
    );
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ).pointer;
    }
    return child;
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Aeroport',
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _metricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Aeroport'),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.isLightTheme ? const Color(0xFF666666) : const Color(0xFFBBBBBB),
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Aeroport',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppTheme.textColor,
      ),
    );
  }

  Widget _muted(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Aeroport',
        fontSize: 13,
        color: Color(0xFF818181),
      ),
    );
  }
}
