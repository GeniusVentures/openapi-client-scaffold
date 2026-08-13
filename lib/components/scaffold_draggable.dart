import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_drag_handle.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Drag wrapper with feedback / preview.
///
/// Wraps [child] in a Flutter [LongPressDraggable] inside a
/// [ScaffoldPressable] (48px touch target, hover state layer, focus ring — its
/// long-press handler is left null so the long-press gesture reaches the
/// [LongPressDraggable]). The default feedback is the child scaled to 1.05x
/// with `palette.dragFeedbackBackground` and a card shadow; the original fades
/// to 40% opacity while dragging. An optional [dragHandle] prepends a
/// [ScaffoldDragHandle] (or the supplied widget) above the child.
class ScaffoldDraggable extends StatelessWidget {
  const ScaffoldDraggable({
    super.key,
    this.child,
    this.data,
    this.feedback,
    this.childWhenDragging,
    this.dragHandle,
    this.onDragStarted,
    this.onDragEnd,
    this.onDraggableCanceled,
  });

  /// Content rendered as the drag source.
  final Widget? child;

  /// Data delivered to accepting [DragTarget]s.
  final dynamic data;

  /// Widget shown under the pointer while dragging. Defaults to a 1.05x-scaled
  /// copy of [child] on `palette.dragFeedbackBackground` with a card shadow.
  final Widget? feedback;

  /// Widget shown in place of [child] while dragging. Defaults to [child] at
  /// 40% opacity.
  final Widget? childWhenDragging;

  /// When `true`, prepends a [ScaffoldDragHandle] above [child]; when a
  /// [Widget], renders that widget instead.
  final dynamic dragHandle;

  /// Called when the drag starts.
  final VoidCallback? onDragStarted;

  /// Called when the drag ends (dropped).
  final VoidCallback? onDragEnd;

  /// Called when the drag ends without being accepted.
  final VoidCallback? onDraggableCanceled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Widget resolvedChild = child ?? const SizedBox.shrink();

    Widget dragSource = LongPressDraggable<Object>(
      data: data,
      feedback: feedback ?? _defaultFeedback(palette, resolvedChild),
      childWhenDragging:
          childWhenDragging ?? Opacity(opacity: 0.4, child: resolvedChild),
      onDragStarted: onDragStarted,
      onDragEnd: onDragEnd == null ? null : (_) => onDragEnd!(),
      onDraggableCanceled: onDraggableCanceled == null
          ? null
          : (_, __) => onDraggableCanceled!(),
      child: resolvedChild,
    );

    final Widget? handle = _resolveHandle();
    if (handle != null) {
      dragSource = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[handle, dragSource],
      );
    }

    return ScaffoldPressable(onLongPress: null, child: dragSource);
  }

  Widget? _resolveHandle() {
    if (dragHandle == true) {
      return const ScaffoldDragHandle();
    }
    if (dragHandle is Widget) {
      return dragHandle as Widget;
    }
    return null;
  }

  Widget _defaultFeedback(ScaffoldPalette palette, Widget child) {
    return Transform.scale(
      scale: 1.05,
      child: Material(
        elevation: 4,
        shadowColor: Colors.black38,
        color: palette.dragFeedbackBackground,
        child: child,
      ),
    );
  }
}
