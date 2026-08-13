import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Renders a dashed rounded-rect border around [child].
///
/// Flutter's [BoxDecoration] has no native dashed border; this widget paints
/// one via [CustomPaint] so drop zones and file-input surfaces can express the
/// "dashed" idle border from the UI-SPEC without a third-party package.
class ScaffoldDashedBorder extends StatelessWidget {
  const ScaffoldDashedBorder({
    super.key,
    required this.child,
    required this.color,
    this.strokeWidth = 1.0,
    this.borderRadius,
    this.dashLength = 6.0,
    this.gapLength = 4.0,
  });

  /// Content drawn underneath the dashed border.
  final Widget child;

  /// Dash color.
  final Color color;

  /// Dash stroke width.
  final double strokeWidth;

  /// Corner radius; defaults to square corners when null.
  final BorderRadiusGeometry? borderRadius;

  /// Length of each dash.
  final double dashLength;

  /// Gap between dashes.
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    final BorderRadius resolved = (borderRadius ?? BorderRadius.zero).resolve(
      Directionality.of(context),
    );
    return CustomPaint(
      foregroundPainter: ScaffoldDashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        borderRadius: resolved,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: child,
    );
  }
}

/// Paints a dashed rounded-rect border (public so tests can assert tokens).
class ScaffoldDashedBorderPainter extends CustomPainter {
  const ScaffoldDashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Rect rect = Offset.zero & size;
    final RRect rrect = borderRadius.toRRect(rect.deflate(strokeWidth / 2));
    final Path path = Path()..addRRect(rrect);

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = (distance + dashLength)
            .clamp(0.0, metric.length)
            .toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(ScaffoldDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
