import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'pointer_region_stub.dart'
    if (dart.library.html) 'pointer_region_web.dart' as cursor_impl;

/// On web, wraps [child] in [MouseRegion] with pointer cursor and sets
/// document.body.style.cursor so the pointer shows (canvas cursor sometimes doesn't update).
/// On non-web, returns [child] unchanged.
///
/// **Easy reuse:** wrap any active (clickable) widget, or use the [pointer] extension:
/// ```dart
/// GestureDetector(
///   onTap: () => ...,
///   child: Icon(Icons.key),
/// ).pointer
/// ```
class PointerRegion extends StatelessWidget {
  const PointerRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => cursor_impl.setAppCursor('pointer'),
        onExit: (_) => cursor_impl.setAppCursor('default'),
        child: child,
      );
    }
    return child;
  }
}

/// Extension to wrap any widget with [PointerRegion] for pointer cursor on web.
/// Use on active (clickable) elements only. Example: `GestureDetector(...).pointer`
extension PointerRegionExtension on Widget {
  Widget get pointer => PointerRegion(child: this);
}
