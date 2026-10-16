// ScaffoldAnimatedDisplayFade — fade animated display.
//
// Generated from animated_display.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/animated_display.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Animates [child] with a fade effect.
///
/// When [ScaffoldMotion.reducedMotion] is true, the motion is replaced by a
/// zero-duration fade (child renders fully opaque with no movement). The
/// animation plays on mount when [trigger] is null; otherwise it replays
/// whenever [trigger] changes. Content is excluded from semantics while
/// animating.
///
/// The default duration and curve come from the `ScaffoldMotionTheme` in the
/// ambient theme (`medium` duration, `standard` curve); [duration] and [curve]
/// override them.
class ScaffoldAnimatedDisplayFade extends StatefulWidget {
  /// Creates a [ScaffoldAnimatedDisplayFade].
  const ScaffoldAnimatedDisplayFade({
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

  /// Overrides the theme's default animation duration.
  final Duration? duration;

  /// Overrides the theme's default animation curve.
  final Curve? curve;

  /// Animation strength (slide offset, turns, oscillation amplitude).
  final double? intensity;

  @override
  State<ScaffoldAnimatedDisplayFade> createState() => _ScaffoldAnimatedDisplayFadeState();
}

class _ScaffoldAnimatedDisplayFadeState extends State<ScaffoldAnimatedDisplayFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _configured = false;

  late final Animation<double> _animation;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  Duration get _defaultDuration =>
      widget.duration ?? context.motion.medium;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = _defaultDuration;
    if (!_configured) {
      _configured = true;
      _configureAnimation();
      _start();
    }
  }

  void _configureAnimation() {

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? context.motion.standard,
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
  void didUpdateWidget(ScaffoldAnimatedDisplayFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = _defaultDuration;
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

    return FadeTransition(opacity: _animation, child: widget.child);

  }
}
