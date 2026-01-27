# TMA Keyboard-Induced Page Reload Behavior

## Overview
This document explains the Flutter-side issue where opening the keyboard causes page rebuilds/reloads. **Note: Keyboard appearing does NOT cause a Telegram-native reload** - the problem is in Flutter code that reads MediaQuery during build, causing unnecessary rebuilds.

## The Sequence of Events

### 1. Keyboard Opens
- User focuses on an input field (e.g., `GlobalBottomBar` TextField)
- Keyboard slides up from the bottom
- Flutter detects keyboard via `MediaQuery.viewInsets.bottom` in `_KeyboardHeightDetector`
- `KeyboardHeightService().heightNotifier` is updated

### 2. Layout Shifts
- `ValueListenableBuilder` widgets listening to `heightNotifier` rebuild
- `AiSearchOverlay` and `GlobalBottomBar` reposition themselves
- Layout starts shifting to accommodate keyboard

### 3. Page Rebuilds (THE PROBLEM)
**Root Cause**: Pages that read `MediaQuery.of(context)` during `build()` will rebuild when keyboard opens because MediaQuery changes.

**Example**: `SendPage` was reading `MediaQuery.of(context).viewInsets.bottom` directly in `build()`, causing the entire page to rebuild when keyboard opens/closes.

### 4. Visual Effect - Page Slide When Keyboard Reaches Highest Point
**Current Issue**: Even after fixing rebuilds, when keyboard reaches its highest point, the page still slides up.

**Root Cause**: When `ValueListenableBuilder` rebuilds `Positioned` widgets (AiSearchOverlay and GlobalBottomBar), the Stack recalculates its layout. This layout recalculation can cause a visual "slide" effect even though the page content itself doesn't rebuild.

**Why it happens at highest point**: The keyboard height updates multiple times during animation. The final update when keyboard reaches maximum height triggers the last layout recalculation, causing the visible slide.

## Code Evidence

### Disabled Viewport Listener
In `front/lib/widgets/global/global_logo_bar.dart` (lines 149-171):
```dart
void _setupViewportListener() {
  // DISABLED: Viewport listener was causing logo to hide when keyboard opens
  // because Telegram reports isFullscreen=false when viewport shrinks (keyboard opening).
  // This is NOT the same as user pulling down the mini app to exit fullscreen.
  //
  // With the new overlay architecture (Stack + Positioned), we don't need to
  // react to viewport changes. Logo visibility is determined once at init based
  // on initial fullscreen state, and stays fixed during keyboard operations.
}
```

### Active Viewport Listener
In `front/lib/telegram_safe_area.dart` (lines 937-946):
```dart
onEvent.apply([
  'viewportChanged',
  js.allowInterop((dynamic data) {
    Future.delayed(const Duration(milliseconds: 100), () {
      final newSafeArea = getSafeAreaInset();
      _updateSafeAreaIfValid(newSafeArea, 'viewportChanged event');
    });
  })
]);
```

### Keyboard Detection
In `front/lib/app/app.dart` (lines 244-279):
- `_KeyboardHeightDetector` widget isolates MediaQuery reads
- Updates `KeyboardHeightService.heightNotifier` when keyboard opens/closes
- This widget rebuilds, but is isolated from the main Stack

## Current Mitigations

### 1. `resizeToAvoidBottomInset: false`
In `app.dart` line 70:
```dart
resizeToAvoidBottomInset: false, // CRITICAL: Prevents page reload on keyboard
```
This prevents Scaffold from resizing when keyboard opens, stopping page content from rebuilding.

### 2. Isolated Keyboard Detection
The `_KeyboardHeightDetector` widget rebuilds independently, preventing the main Stack and page content from rebuilding.

### 3. Static Padding Calculations
Pages use static helper methods like `_getAdaptiveBottomPadding()` to avoid MediaQuery rebuilds during keyboard operations.

### 4. Disabled Viewport Listener for Logo
The viewport listener in `GlobalLogoBar` is disabled to prevent logo from hiding when keyboard opens.

## Root Cause

The reload happens because:

1. **SafeArea Widget Reads MediaQuery**: All pages were using `SafeArea` widget, which internally reads `MediaQuery.of(context)` to calculate safe area insets. When keyboard opens, MediaQuery changes, causing `SafeArea` to rebuild, which rebuilds the entire page widget tree.

2. **MediaQuery Reads in Build**: Pages reading `MediaQuery.of(context)` directly (like `SendPage` was doing) also cause rebuilds.

3. **Solution**: 
   - Remove `SafeArea` widgets from pages (they were already disabled with `top: false, bottom: false` anyway)
   - Use `KeyboardHeightService().heightNotifier` instead of MediaQuery
   - Wrap only widgets that need keyboard height in `ValueListenableBuilder`

## Fix Applied

### Problem 1: All Pages Using `SafeArea` Widget
**Before** (causes rebuild on all pages):
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(  // ❌ SafeArea reads MediaQuery internally, causes rebuild
      bottom: false,
      top: false,
      child: Builder(...),
    ),
  );
}
```

**After** (no rebuild):
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Builder(...),  // ✅ No SafeArea - we handle padding manually
  );
}
```

### Problem 2: `SendPage` Reading MediaQuery Directly
**Before** (causes rebuild):
```dart
@override
Widget build(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final keyboardHeight = mediaQuery.viewInsets.bottom; // ❌ Causes rebuild
  // ...
}
```

**After** (no rebuild):
```dart
@override
Widget build(BuildContext context) {
  // Don't read MediaQuery here - use KeyboardHeightService instead
  final bottomBarHeight = GlobalBottomBar.getBottomBarHeight(context);
  // ...
  
  // Wrap only widgets that need keyboard height in ValueListenableBuilder
  ValueListenableBuilder<double>(
    valueListenable: KeyboardHeightService().heightNotifier,
    builder: (context, keyboardHeight, child) {
      return Positioned(
        bottom: keyboardHeight + bottomBarHeight,
        // ...
      );
    },
  ),
}
```

### Pages & Widgets Fixed
- ✅ `MainPage` - Removed SafeArea
- ✅ `SwapPage` - Removed SafeArea  
- ✅ `TradePage` - Removed SafeArea
- ✅ `WalletsPage` - Removed SafeArea
- ✅ `SendPage` - Removed SafeArea + Fixed MediaQuery read
- ✅ `GlobalLogoBar` - Removed SafeArea (was using it with `top: false, bottom: false`)
- ✅ `GlobalBottomBar` - Removed SafeArea (was using it with `top: false`)

**Note**: Safe area calculations for logo positioning are handled via `TelegramSafeAreaService.getSafeAreaInset()` and `TelegramSafeAreaService.getContentSafeAreaInset()`, which don't cause rebuilds when keyboard opens. The `SafeArea` widget was only used as a wrapper but still read MediaQuery internally, causing unnecessary rebuilds.

## Additional Fix: Preventing Page Slide When Keyboard Reaches Highest Point

### Problem: Stack Layout Recalculation
When `ValueListenableBuilder` rebuilds `Positioned` widgets, the Stack recalculates layout, causing a visual "slide" even though page content doesn't rebuild.

### Solution Applied

1. **Debounced Keyboard Height Updates** (`keyboard_height_service.dart`):
   - Added `updateHeight()` method with 50ms debounce
   - Prevents rapid rebuilds during keyboard animation
   - Only updates when keyboard animation settles

2. **RepaintBoundary + Positioned.fill Isolation** (`app.dart`):
   - Wrapped page content in `RepaintBoundary` for repaint isolation
   - Wrapped in `Positioned.fill` to ensure page always fills Stack bounds
   - Prevents page content from shifting when other Positioned widgets change constraints
   - Ensures page position is independent of overlay widget changes

3. **Stack clipBehavior**:
   - Set to `Clip.none` to allow overlays to extend beyond bounds
   - Prevents clipping issues during layout changes

4. **Cached Safe Area Values** (`global_logo_bar.dart`):
   - Logo top padding and block height are cached during initialization
   - Prevents recalculation when keyboard opens and viewport changes
   - Safe area values remain stable during keyboard operations

5. **ViewportChanged Event Filtering** (`telegram_safe_area.dart`):
   - `viewportChanged` events are filtered to ignore keyboard-related changes
   - Only significant changes (orientation changes) trigger safe area updates
   - Prevents safe area recalculation during keyboard animation

### Key Principles
1. **Never read MediaQuery in page `build()` methods** - use `KeyboardHeightService` instead
2. **Wrap only widgets that need keyboard height** in `ValueListenableBuilder` - don't rebuild entire pages
3. **Use static calculations** for values that don't change with keyboard (like `bottomBarHeight`)

## Related Files

- `front/lib/app/app.dart` - Main app structure with keyboard handling
- `front/lib/widgets/global/global_logo_bar.dart` - Logo bar with disabled viewport listener
- `front/lib/telegram_safe_area.dart` - Safe area service with active viewport listener
- `front/lib/utils/keyboard_height_service.dart` - Keyboard height detection
- `front/lib/widgets/global/global_bottom_bar.dart` - Input field that triggers keyboard
- `front/web/index.html` - JavaScript viewport change handlers

## References

- Telegram Mini Apps Documentation: https://docs.telegram-mini-apps.com/platform/viewport
- TMA.js SDK Viewport: https://docs.telegram-mini-apps.com/packages/tma-js-sdk/features/viewport
