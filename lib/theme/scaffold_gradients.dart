import 'package:flutter/material.dart';

/// Material 3 theme extension holding the gradients drawn by frontend_scaffold
/// widgets. Every gradient is null by default, which keeps flat fills and
/// existing fades as they are. Register on [ThemeData.extensions] to restyle
/// them; without one, `context.gradients` falls back to [defaultGradients].
class ScaffoldGradients extends ThemeExtension<ScaffoldGradients> {
  /// Fade ramp for `ScaffoldOverflowFade`, read from the faded edge (stop 0)
  /// toward the content (stop 1). Only its color alphas and stops are used; the
  /// widget keeps its own direction, extent and color. Null keeps the built-in
  /// fade.
  final LinearGradient? edgeFade;

  /// Fill of raised cards and surfaces that use the default surface color, top
  /// to bottom. Null keeps the flat fill.
  final LinearGradient? surfaceSheen;

  const ScaffoldGradients({
    // GENERATED from design_tokens.json scaffold.gradients. Do not edit.
    this.edgeFade,
    this.surfaceSheen,
    // END GENERATED scaffold.gradients
  });

  /// Default gradients: none set. Rendered from `design_tokens.json`.
  static const ScaffoldGradients defaultGradients = ScaffoldGradients();

  /// Returns a copy of these gradients with the given fields replaced.
  @override
  ScaffoldGradients copyWith({
    LinearGradient? edgeFade,
    LinearGradient? surfaceSheen,
  }) {
    return ScaffoldGradients(
      edgeFade: edgeFade ?? this.edgeFade,
      surfaceSheen: surfaceSheen ?? this.surfaceSheen,
    );
  }

  @override
  ScaffoldGradients lerp(ThemeExtension<ScaffoldGradients>? other, double t) {
    if (other is! ScaffoldGradients) {
      return this;
    }
    return ScaffoldGradients(
      edgeFade: LinearGradient.lerp(edgeFade, other.edgeFade, t),
      surfaceSheen: LinearGradient.lerp(surfaceSheen, other.surfaceSheen, t),
    );
  }
}
