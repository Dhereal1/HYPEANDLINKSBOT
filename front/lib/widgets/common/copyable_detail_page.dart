import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart' as tma;
import '../../app/theme/app_theme.dart';
import '../../widgets/global/global_logo_bar.dart';
import '../../widgets/common/edge_swipe_back.dart';
import '../../widgets/common/pointer_region.dart';
import '../../app/app.dart';
import '../../telegram_safe_area.dart';
import '../../utils/app_haptic.dart';

/// Reusable full-page layout: header row, centered content. Tap/click copies [copyText] (newlines stripped) or clears; "Copied" below. No selection — just tap to copy.
class CopyableDetailPage extends StatefulWidget {
  /// Raw text to copy (newlines removed when copying).
  final String copyText;

  /// Center content (plain text). Whole area is tappable for copy/clear.
  final Widget Function() centerChildBuilder;

  /// Left header label (e.g. '..xk5str4e').
  final String titleLeft;

  /// Right header label (e.g. 'Sendal Rodriges').
  final String titleRight;

  const CopyableDetailPage({
    super.key,
    required this.copyText,
    required this.centerChildBuilder,
    this.titleLeft = '..xk5str4e',
    this.titleRight = 'Sendal Rodriges',
  });

  @override
  State<CopyableDetailPage> createState() => _CopyableDetailPageState();
}

class _CopyableDetailPageState extends State<CopyableDetailPage>
    with RouteAware {
  StreamSubscription<tma.BackButton>? _backButtonSubscription;
  bool _showCopiedIndicator = false;
  bool _routeObserverSubscribed = false;
  /// When true, clipboard read was denied or failed; use only set_state from tap (no read).
  bool _clipboardReadUnavailable = false;

  static double _getAdaptiveBottomPadding() {
    final service = TelegramSafeAreaService();
    final safeAreaInset = service.getSafeAreaInset();
    return safeAreaInset.bottom + 30;
  }

  static double _getGlobalBottomBarHeight() {
    return 10.0 + 30.0 + 15.0;
  }

  String get _oneLine => widget.copyText.replaceAll('\n', '');

  Future<void> _checkClipboardAndUpdateIndicator() async {
    if (_clipboardReadUnavailable) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final clip = data?.text?.trim() ?? '';
      if (!mounted) return;
      final matches = clip == _oneLine;
      if (matches != _showCopiedIndicator) {
        setState(() => _showCopiedIndicator = matches);
      }
    } catch (_) {
      if (mounted) setState(() => _clipboardReadUnavailable = true);
    }
  }

  Future<void> _onTap() async {
    if (_showCopiedIndicator) {
      await Clipboard.setData(const ClipboardData(text: ''));
      AppHaptic.heavy();
      if (mounted) setState(() => _showCopiedIndicator = false);
      return;
    }
    await Clipboard.setData(ClipboardData(text: _oneLine));
    AppHaptic.heavy();
    if (mounted) setState(() => _showCopiedIndicator = true);
  }

  void _handleBackButton() {
    AppHaptic.heavy();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_clipboardReadUnavailable) _checkClipboardAndUpdateIndicator();
      try {
        final webApp = tma.WebApp();
        final eventHandler = webApp.eventHandler;
        _backButtonSubscription =
            eventHandler.backButtonClicked.listen((_) => _handleBackButton());
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) tma.WebApp().backButton.show();
        });
      } catch (_) {}
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeObserverSubscribed) return;
    final route = ModalRoute.of(context);
    if (route != null && route is PageRoute) {
      MyApp.routeObserver.subscribe(this, route);
      _routeObserverSubscribed = true;
    }
  }

  @override
  void didPopNext() {
    if (!_clipboardReadUnavailable) _checkClipboardAndUpdateIndicator();
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      MyApp.routeObserver.unsubscribe(this);
    }
    _backButtonSubscription?.cancel();
    try {
      tma.WebApp().backButton.hide();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = GlobalLogoBar.getContentTopPadding();
    final bottomBarHeight = _getGlobalBottomBarHeight();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: EdgeSwipeBack(
        onBack: _handleBackButton,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: topPadding,
                left: 15,
                right: 15,
                bottom: _getAdaptiveBottomPadding() + bottomBarHeight,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 570),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.titleLeft,
                              style: const TextStyle(
                                fontFamily: 'Aeroport Mono',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF818181),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.titleRight,
                                  style: const TextStyle(
                                    fontFamily: 'Aeroport',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF818181),
                                    height: 1.0,
                                  ),
                                  textHeightBehavior:
                                      const TextHeightBehavior(
                                    applyHeightToFirstAscent: false,
                                    applyHeightToLastDescent: false,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                SvgPicture.asset(
                                  'assets/icons/select.svg',
                                  width: 5,
                                  height: 10,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _onTap,
                                child: widget.centerChildBuilder(),
                              ).pointer,
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: _onTap,
                                child: SizedBox(
                                  height: 15,
                                  child: _showCopiedIndicator
                                      ? Center(
                                          child: Text(
                                            'Copied',
                                            key: const Key('copy_text'),
                                            style: TextStyle(
                                              fontSize: 15,
                                              height: 15 / 15,
                                              fontWeight: FontWeight.w400,
                                              color: AppTheme.textColor,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ).pointer,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
