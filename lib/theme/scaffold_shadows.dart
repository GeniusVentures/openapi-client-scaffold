import 'package:flutter/material.dart';

/// Material 3 theme extension holding the shadows drawn by frontend_scaffold
/// widgets. Register on [ThemeData.extensions] to let a host app restyle them;
/// without one, `context.shadows` falls back to [defaultShadows] (dark) or
/// [lightShadows] (light). Both defaults equal `ScaffoldElevation.card`.
class ScaffoldShadows extends ThemeExtension<ScaffoldShadows> {
  /// Shadow under toasts and other transient elevated surfaces.
  final List<BoxShadow> card;

  const ScaffoldShadows({
    // GENERATED from design_tokens.json scaffold.shadows.dark. Do not edit.
    this.card = const [BoxShadow(color: Color(0x59000000), blurRadius: 16.0, offset: Offset(0.0, 4.0))],
    // END GENERATED scaffold.shadows.dark
  });

  /// Dark-mode defaults. Rendered from `design_tokens.json`.
  static const ScaffoldShadows defaultShadows = ScaffoldShadows();

  /// Light-mode defaults. Rendered from `design_tokens.json`.
  static const ScaffoldShadows lightShadows = ScaffoldShadows(
    // GENERATED from design_tokens.json scaffold.shadows.light. Do not edit.
    card: [BoxShadow(color: Color(0x59000000), blurRadius: 16.0, offset: Offset(0.0, 4.0))],
    // END GENERATED scaffold.shadows.light
  );

  /// Returns a copy of these shadows with the given fields replaced.
  @override
  ScaffoldShadows copyWith({List<BoxShadow>? card}) {
    return ScaffoldShadows(card: card ?? this.card);
  }

  @override
  ScaffoldShadows lerp(ThemeExtension<ScaffoldShadows>? other, double t) {
    if (other is! ScaffoldShadows) {
      return this;
    }
    return ScaffoldShadows(
      card: BoxShadow.lerpList(card, other.card, t) ?? const <BoxShadow>[],
    );
  }
}
