import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Direction in which a [ScaffoldOverflowFade] applies its edge fade.
enum FadeDirection {
  /// Fade the left and right edges.
  horizontal,

  /// Fade the top and bottom edges.
  vertical,

  /// Fade all four edges.
  both,

  /// Fade only the left edge.
  left,

  /// Fade only the right edge.
  right,

  /// Fade only the top edge.
  top,

  /// Fade only the bottom edge.
  bottom,
}

/// Edge-fade gradient overlay.
///
/// Wraps [child] in a [ShaderMask] that fades content from opaque in the
/// center to transparent at the configured edges, so overflowing content
/// visually dissolves into the background instead of clipping hard. The fade
/// color defaults to `palette.deepBlueCardColor`; pass [backgroundColor] to
/// match the surface behind the content.
class ScaffoldOverflowFade extends StatelessWidget {
  const ScaffoldOverflowFade({
    super.key,
    this.child,
    this.fadeDirection = FadeDirection.horizontal,
    this.fadeExtent = 24.0,
    this.backgroundColor,
  });

  final Widget? child;

  /// Which edges fade out. Defaults to [FadeDirection.horizontal].
  final FadeDirection fadeDirection;

  /// Width of the fade zone in logical pixels. Defaults to 24.0.
  final double fadeExtent;

  /// Color the content fades toward; defaults to `palette.deepBlueCardColor`.
  final Color? backgroundColor;

  /// Builds the edge-fade gradient for the given bounds.
  ///
  /// Exposed for testing: it computes normalized gradient stops from
  /// [extent] and the bounds size. With [BlendMode.dstOut], the shader's
  /// alpha hides the destination where it is opaque — so the gradient is
  /// opaque at the faded edges and transparent in the center.
  @visibleForTesting
  static Gradient gradientFor({
    required FadeDirection direction,
    required double extent,
    required Rect bounds,
    required Color color,
  }) {
    final Color transparent = color.withValues(alpha: 0.0);
    final Color opaque = color.withValues(alpha: 1.0);

    switch (direction) {
      case FadeDirection.horizontal:
        final double startStop = _edgeStop(extent, bounds.width);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[opaque, transparent, transparent, opaque],
          stops: <double>[0.0, startStop, 1.0 - startStop, 1.0],
        );
      case FadeDirection.vertical:
        final double startStop = _edgeStop(extent, bounds.height);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[opaque, transparent, transparent, opaque],
          stops: <double>[0.0, startStop, 1.0 - startStop, 1.0],
        );
      case FadeDirection.both:
        final double shortest = bounds.shortestSide;
        final double stop = _edgeStop(extent, shortest / 2);
        return RadialGradient(
          colors: <Color>[transparent, opaque],
          stops: <double>[1.0 - stop, 1.0],
        );
      case FadeDirection.left:
        final double startStop = _edgeStop(extent, bounds.width);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[opaque, transparent],
          stops: <double>[0.0, startStop],
        );
      case FadeDirection.right:
        final double startStop = _edgeStop(extent, bounds.width);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[transparent, opaque],
          stops: <double>[1.0 - startStop, 1.0],
        );
      case FadeDirection.top:
        final double startStop = _edgeStop(extent, bounds.height);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[opaque, transparent],
          stops: <double>[0.0, startStop],
        );
      case FadeDirection.bottom:
        final double startStop = _edgeStop(extent, bounds.height);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[transparent, opaque],
          stops: <double>[1.0 - startStop, 1.0],
        );
    }
  }

  /// Normalized stop position for a fade of [extent] px within [length] px,
  /// clamped so the fade never exceeds half the available dimension.
  static double _edgeStop(double extent, double length) {
    if (length <= 0) {
      return 0.5;
    }
    return (extent / length).clamp(0.0, 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color resolvedColor = backgroundColor ?? palette.deepBlueCardColor;

    return ShaderMask(
      blendMode: BlendMode.dstOut,
      shaderCallback: (Rect bounds) {
        return ScaffoldOverflowFade.gradientFor(
          direction: fadeDirection,
          extent: fadeExtent,
          bounds: bounds,
          color: resolvedColor,
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
