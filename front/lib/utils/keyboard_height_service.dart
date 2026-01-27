import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service that provides keyboard height notifier
/// Height is detected by isolated MediaQuery widget (works on all platforms)
/// This avoids rebuilds in Stack by isolating MediaQuery to a separate widget
class KeyboardHeightService {
  static final KeyboardHeightService _instance = KeyboardHeightService._internal();
  factory KeyboardHeightService() => _instance;
  KeyboardHeightService._internal();

  /// Notifier for keyboard height (0 when closed, detected height when open)
  /// Updated by isolated MediaQuery detection widget
  final ValueNotifier<double> heightNotifier = ValueNotifier<double>(0.0);

  bool _isInitialized = false;
  Timer? _debounceTimer;
  double _pendingHeight = 0.0;
  double _lastNotifiedHeight = 0.0;
  DateTime? _lastUpdateTime;

  /// Initialize the service
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    print('[KeyboardHeightService] Initialized - waiting for MediaQuery detection');
  }

  /// Update keyboard height with debouncing to prevent rapid rebuilds
  /// This helps prevent visual "slide" effects when keyboard is animating
  void updateHeight(double height) {
    final now = DateTime.now();
    final timeSinceLastUpdate = _lastUpdateTime != null 
        ? now.difference(_lastUpdateTime!).inMilliseconds 
        : 1000;
    
    // CRITICAL: If height hasn't changed significantly (less than 2px), skip update
    // This prevents the final "slide" when keyboard reaches its highest point
    // The threshold of 2px accounts for minor measurement variations
    if ((_lastNotifiedHeight - height).abs() < 2.0) {
      return;
    }
    
    _pendingHeight = height;
    _debounceTimer?.cancel();
    
    // CRITICAL: Longer debounce delay to prevent final slide when keyboard settles
    // When keyboard is animating, wait 300ms to ensure animation fully completes
    // This prevents the Stack layout recalculation that causes the page slide
    // If it's been a while since last update, update quickly (keyboard just opened/closed)
    final debounceDelay = timeSinceLastUpdate > 500 
        ? const Duration(milliseconds: 100)  // Quick update if keyboard just opened/closed
        : const Duration(milliseconds: 300); // Longer delay during animation to prevent final slide
    
    _debounceTimer = Timer(debounceDelay, () {
      // Double-check that height still changed significantly before updating
      // This prevents updates from stale pending values
      if ((heightNotifier.value - _pendingHeight).abs() >= 2.0) {
        _lastNotifiedHeight = _pendingHeight;
        _lastUpdateTime = DateTime.now();
        heightNotifier.value = _pendingHeight;
      }
    });
  }

  /// Dispose the service
  void dispose() {
    if (!_isInitialized) return;
    _debounceTimer?.cancel();
    heightNotifier.dispose();
    _isInitialized = false;
  }
}
