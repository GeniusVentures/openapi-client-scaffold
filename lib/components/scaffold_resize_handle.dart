import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// The orientation a [ScaffoldResizeHandle] resizes.
enum ResizeDirection { horizontal, vertical, both }

/// Resize grip: directional stripe or corner in a 48px touch target.
///
/// Renders a 2px line (`palette.textSecondary` at 60% opacity) — horizontal
/// stripe, vertical stripe, or an L-shaped corner — wrapped in a
/// [ScaffoldTouchTarget] for the 48px hit area. Registers the
/// "Drag to resize" label for screen readers.
class ScaffoldResizeHandle extends StatelessWidget {
  /// Creates a [ScaffoldResizeHandle].
  const ScaffoldResizeHandle({
    super.key,
    this.direction = ResizeDirection.both,
    this.color,
    this.size,
  });

  /// Which edge/corner this handle resizes.
  final ResizeDirection direction;

  /// Grip line color; defaults to `palette.textSecondary` at 60% opacity.
  final Color? color;

  /// Grip length; defaults to `dimens.dragHandleSize`.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final double handleSize = size ?? dimens.dragHandleSize;
    final Color lineColor =
        (color ?? palette.textSecondary).withValues(alpha: 0.6);

    final Widget grip = switch (direction) {
      ResizeDirection.horizontal =>
        Container(width: handleSize, height: 2, color: lineColor),
      ResizeDirection.vertical =>
        Container(width: 2, height: handleSize, color: lineColor),
      ResizeDirection.both => CustomPaint(
        size: Size.square(handleSize),
        painter: ScaffoldResizeCornerPainter(color: lineColor),
      ),
    };

    return Semantics(
      label: 'Drag to resize',
      child: ScaffoldTouchTarget(child: grip),
    );
  }
}

/// Paints an L-shaped corner grip (two perpendicular 2px lines).
class ScaffoldResizeCornerPainter extends CustomPainter {
  /// Creates a corner-grip painter with the given line [color].
  const ScaffoldResizeCornerPainter({required this.color});

  /// Line color.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Vertical segment along the left edge.
    canvas.drawLine(Offset(1, 0), Offset(1, size.height), paint);
    // Horizontal segment along the bottom edge.
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScaffoldResizeCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
