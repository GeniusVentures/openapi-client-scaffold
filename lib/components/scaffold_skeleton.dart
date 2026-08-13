import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Animated loading placeholder.
///
/// Renders a rounded-rect [Container] filled with `palette.skeletonBaseColor`
/// at `dimens.skeletonCornerRadius`. When motion is enabled, a
/// [LinearGradient] shimmer (sweeping `palette.skeletonShimmerColor` between
/// two `palette.skeletonBaseColor` edges) slides across the box at
/// [ScaffoldMotionDurations.medium]. When [ScaffoldMotion.reducedMotion] is
/// true, the sweep is replaced by a static opacity pulse (0.6 -> 1.0) — no
/// horizontal motion.
///
/// Width, height, and corner radius override the dimension defaults when
/// provided. The animation is excluded from semantics via [ExcludeSemantics].
class ScaffoldSkeleton extends StatefulWidget {
  const ScaffoldSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  /// Box width; null lets parent constraints (or [child]) size the box.
  final double? width;

  /// Box height; null lets parent constraints (or [child]) size the box.
  final double? height;

  /// Corner radius; defaults to `dimens.skeletonCornerRadius`.
  final double? borderRadius;

  /// Optional content rendered inside the skeleton box.
  final Widget? child;

  @override
  State<ScaffoldSkeleton> createState() => _ScaffoldSkeletonState();
}

class _ScaffoldSkeletonState extends State<ScaffoldSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ScaffoldMotionDurations.medium,
    )..repeat(reverse: true);
    _pulseOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;
    final double radius = widget.borderRadius ?? dimens.skeletonCornerRadius;

    final Widget base = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: palette.skeletonBaseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: widget.child,
    );

    final Widget content;
    if (reducedMotion) {
      content = FadeTransition(opacity: _pulseOpacity, child: base);
    } else {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedBuilder(
          animation: _controller,
          child: base,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              children: <Widget>[
                child!,
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _shimmerGradient(palette),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return ExcludeSemantics(child: content);
  }

  LinearGradient _shimmerGradient(ScaffoldPalette palette) {
    final double shift = _controller.value * 2.0 - 1.0;
    return LinearGradient(
      begin: Alignment(-1.0 - shift, 0.0),
      end: Alignment(1.0 - shift, 0.0),
      colors: <Color>[
        palette.skeletonBaseColor,
        palette.skeletonShimmerColor,
        palette.skeletonBaseColor,
      ],
      stops: const <double>[0.0, 0.5, 1.0],
    );
  }
}
