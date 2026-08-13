// ScaffoldAnimatedDisplayRotate — rotate animated display.
//
// Generated from animated_display.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/animated_display.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';

/// Animates [child] with a rotate effect.
///
/// When [ScaffoldMotion.reducedMotion] is true, the motion is replaced by a
/// zero-duration fade (child renders fully opaque with no movement). The
/// animation plays on mount when [trigger] is null; otherwise it replays
/// whenever [trigger] changes. Content is excluded from semantics while
/// animating.
class ScaffoldAnimatedDisplayRotate extends StatefulWidget {
  /// Creates a [ScaffoldAnimatedDisplayRotate].
  const ScaffoldAnimatedDisplayRotate({
    super.key,
    required this.child,
    this.trigger,
    this.duration,
    this.curve,
    this.intensity,
  });

  /// Content rendered underneath the animation.
  final Widget child;

  /// When non-null, the animation replays whenever this value changes.
  final int? trigger;

  /// Overrides the default animation duration.
  final Duration? duration;

  /// Overrides the default animation curve.
  final Curve? curve;

  /// Animation strength (slide offset, turns, oscillation amplitude).
  final double? intensity;

  @override
  State<ScaffoldAnimatedDisplayRotate> createState() => _ScaffoldAnimatedDisplayRotateState();
}

class _ScaffoldAnimatedDisplayRotateState extends State<ScaffoldAnimatedDisplayRotate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _rotationAnimation;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? ScaffoldMotionDurations.medium,
    );
    _configureAnimation();
    _start();
  }

  void _configureAnimation() {

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.intensity ?? 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? ScaffoldMotionCurves.standard,
      ),
    );

  }

  void _start() {

    if (widget.trigger == null) {
      _controller.forward();
    }

  }

  void _replay() {

    _controller
      ..reset()
      ..forward();

  }

  @override
  void didUpdateWidget(ScaffoldAnimatedDisplayRotate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration ?? ScaffoldMotionDurations.medium;
    }
    if (widget.trigger != oldWidget.trigger) {
      _replay();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;
    if (reducedMotion) {
      return ExcludeSemantics(
        child: FadeTransition(
          opacity: const AlwaysStoppedAnimation<double>(1.0),
          child: widget.child,
        ),
      );
    }

    return ExcludeSemantics(child: _buildMotion());
  }

  Widget _buildMotion() {

    return RotationTransition(turns: _rotationAnimation, child: widget.child);

  }
}
