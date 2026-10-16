import 'package:flutter/material.dart';

/// Material 3 theme extension holding the motion durations and curves used by
/// frontend_scaffold widgets. Register on [ThemeData.extensions] to let a host
/// app retime them; without one, `context.motion` falls back to
/// [defaultMotion].
///
/// Reduced motion stays on the `ScaffoldMotion` InheritedWidget.
class ScaffoldMotionTheme extends ThemeExtension<ScaffoldMotionTheme> {
  /// Short transition (150ms) - hover, press, focus-fade.
  final Duration short;

  /// Medium transition (300ms) - press release, drop-zone exit.
  final Duration medium;

  /// Long transition (500ms) - large reveals, screen transitions.
  final Duration long;

  /// Standard ease-in-out curve.
  final Curve standard;

  /// Decelerate curve (fast start, gentle settle).
  final Curve decelerate;

  /// Emphasized decelerate curve with a slight overshoot.
  final Curve emphasized;

  const ScaffoldMotionTheme({
    // GENERATED from design_tokens.json scaffold.motion.durations. Do not edit.
    this.short = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 300),
    this.long = const Duration(milliseconds: 500),
    // END GENERATED scaffold.motion.durations
    // GENERATED from design_tokens.json scaffold.motion.curves. Do not edit.
    this.standard = Curves.easeInOut,
    this.decelerate = Curves.easeOut,
    this.emphasized = const Cubic(0.2, 0.0, 0.0, 1.2),
    // END GENERATED scaffold.motion.curves
  });

  /// Default motion. Rendered from `design_tokens.json`.
  static const ScaffoldMotionTheme defaultMotion = ScaffoldMotionTheme();

  /// Returns a copy of this theme with the given fields replaced.
  @override
  ScaffoldMotionTheme copyWith({
    Duration? short,
    Duration? medium,
    Duration? long,
    Curve? standard,
    Curve? decelerate,
    Curve? emphasized,
  }) {
    return ScaffoldMotionTheme(
      short: short ?? this.short,
      medium: medium ?? this.medium,
      long: long ?? this.long,
      standard: standard ?? this.standard,
      decelerate: decelerate ?? this.decelerate,
      emphasized: emphasized ?? this.emphasized,
    );
  }

  /// Durations interpolate; curves cannot, so they switch at `t == 0.5`.
  @override
  ScaffoldMotionTheme lerp(ThemeExtension<ScaffoldMotionTheme>? other, double t) {
    if (other is! ScaffoldMotionTheme) {
      return this;
    }
    return ScaffoldMotionTheme(
      short: _lerpDuration(short, other.short, t),
      medium: _lerpDuration(medium, other.medium, t),
      long: _lerpDuration(long, other.long, t),
      standard: t < 0.5 ? standard : other.standard,
      decelerate: t < 0.5 ? decelerate : other.decelerate,
      emphasized: t < 0.5 ? emphasized : other.emphasized,
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    return Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );
  }
}
