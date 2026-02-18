import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';
import '../telegram_safe_area.dart';
import '../utils/app_haptic.dart';
import '../widgets/common/edge_swipe_back.dart';
import '../widgets/global/global_logo_bar.dart';

/// Example page with logo bar, bottom bar, back, and scrolling (same pattern as trade page).
class APageExample extends StatelessWidget {
  const APageExample({super.key});

  double _getAdaptiveBottomPadding() {
    final safeAreaInset = TelegramSafeAreaService().getSafeAreaInset();
    return safeAreaInset.bottom + 30;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = GlobalLogoBar.getContentTopPadding();
    final bottomPadding = _getAdaptiveBottomPadding();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: EdgeSwipeBack(
        onBack: () {
          AppHaptic.heavy();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 15,
                    bottom: 15,
                    left: 15,
                    right: 15,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A Page Example',
                        style: TextStyle(
                          fontFamily: 'Aeroport',
                          fontSize: 30,
                          height: 1.0,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'This page has logo bar, bottom bar, back, and scrolling '
                        'functionality like the trade page.',
                        style: TextStyle(
                          fontFamily: 'Aeroport',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(64, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Scrollable line ${i + 1}. Content to demonstrate scrolling.',
                            style: const TextStyle(
                              fontFamily: 'Aeroport',
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF818181),
                              height: 1.2,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
