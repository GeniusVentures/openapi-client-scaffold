// ScaffoldAnimatedDisplayBounce — bounce animated display.
//
// Generated from animated_display.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/animated_display.dart.jinja2
// Generator version: 0.4.0
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';

/// Animates [child] with a bounce effect.
///
/// When [ScaffoldMotion.reducedMotion] is true, the motion is replaced by a
/// zero-duration fade (child renders fully opaque with no movement). The
/// animation plays on mount when [trigger] is null; otherwise it replays
/// whenever [trigger] changes. Content is excluded from semantics while
/// animating.
class ScaffoldAnimatedDisplayBounce extends StatefulWidget {
  /// Creates a [ScaffoldAnimatedDisplayBounce].
  const ScaffoldAnimatedDisplayBounce({
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
  State<ScaffoldAnimatedDisplayBounce> createState() => _ScaffoldAnimatedDisplayBounceState();
}

class _ScaffoldAnimatedDisplayBounceState extends State<ScaffoldAnimatedDisplayBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;


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

    // Oscillation reads the controller value directly; no curve is applied.

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
  void didUpdateWidget(ScaffoldAnimatedDisplayBounce oldWidget) {
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

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double amplitude = widget.intensity ?? 8.0;
        final double decay = 1.0 - _controller.value;
        final double dy =
            -math.sin(_controller.value * math.pi * 3) * amplitude * decay;
        return Transform.translate(offset: Offset(0.0, dy), child: child);
      },
    );

  }
}
