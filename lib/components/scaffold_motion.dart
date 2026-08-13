import 'package:flutter/material.dart';

/// Static animation duration tokens consumed by frontend_scaffold atoms.
///
/// Every animated atom reads from [ScaffoldMotionDurations] rather than
/// hard-coding a duration, so a change here propagates across the library.
class ScaffoldMotionDurations {
  ScaffoldMotionDurations._();

  /// Short transition (150ms) — hover, press, focus-fade.
  static const Duration short = Duration(milliseconds: 150);

  /// Medium transition (300ms) — press release, drop-zone exit.
  static const Duration medium = Duration(milliseconds: 300);

  /// Long transition (500ms) — large reveals, screen transitions.
  static const Duration long = Duration(milliseconds: 500);
}

/// Static animation curve tokens consumed by frontend_scaffold atoms.
class ScaffoldMotionCurves {
  ScaffoldMotionCurves._();

  /// Standard ease-in-out curve.
  static const Curve standard = Curves.easeInOut;

  /// Decelerate curve (fast start, gentle settle).
  static const Curve decelerate = Curves.easeOut;

  /// Emphasized decelerate curve with a slight overshoot — the final control
  /// point's y is 1.2 (> 1.0), so [Curve.transform] exceeds 1.0 near t -> 1.0.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.2);
}

/// InheritedWidget exposing the reduced-motion accessibility preference.
///
/// Widgets read [ScaffoldMotion.of] and substitute zero-duration transitions
/// or fades when `reducedMotion` is true. Place one near the root of the app;
/// it propagates to every atom below it.
class ScaffoldMotion extends InheritedWidget {
  /// Creates a [ScaffoldMotion] ancestor for the subtree below [child].
  const ScaffoldMotion({
    super.key,
    required this.reducedMotion,
    required super.child,
  });

  /// When true, atoms substitute non-motion alternatives for animations.
  final bool reducedMotion;

  /// Returns the nearest [ScaffoldMotion] ancestor.
  ///
  /// Throws a [FlutterError] when no [ScaffoldMotion] ancestor is present, so
  /// a missing ancestor fails loudly rather than silently disabling motion.
  static ScaffoldMotion of(BuildContext context) {
    final ScaffoldMotion? motion =
        context.dependOnInheritedWidgetOfExactType<ScaffoldMotion>();
    if (motion == null) {
      throw FlutterError(
        'No ScaffoldMotion found in context. Wrap the app (or the consuming '
        'subtree) in a ScaffoldMotion(reducedMotion: ..., child: ...).',
      );
    }
    return motion;
  }

  @override
  bool updateShouldNotify(ScaffoldMotion oldWidget) =>
      oldWidget.reducedMotion != reducedMotion;
}
