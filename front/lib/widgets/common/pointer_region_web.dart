import 'dart:html' as html;

/// Sets the cursor on the element under the pointer (canvas) so the pointer shows on web.
/// Body cursor is ignored when the mouse is over the canvas, so we must set canvas.style.cursor.
void setAppCursor(String cursor) {
  final canvas = html.document.querySelector('canvas');
  if (canvas != null) {
    canvas.style.cursor = cursor;
  }
  html.document.body?.style.cursor = cursor;
}
