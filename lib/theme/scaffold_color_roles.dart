import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_colors.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

/// Material 3 theme extension holding the role colors frontend_scaffold
/// widgets use beyond [ScaffoldPalette]. Register on [ThemeData.extensions]
/// like the palette to restyle them. Without one, `context.colorRoles` derives
/// them with [fallbackFor], so existing apps draw the same colors as before.
class ScaffoldColorRoles extends ThemeExtension<ScaffoldColorRoles> {
  /// Accent fill.
  final Color accent;

  /// Accent used as a foreground on surfaces: text, outlines, focused borders.
  final Color accentOnSurface;

  /// Enabled border of input controls.
  final Color borderControl;

  /// Text typed into `TextEntryFieldWidget`.
  final Color inputForeground;

  /// Title and close icon of `BottomDrawer`.
  final Color sheetForeground;

  /// Divider under the `BottomDrawer` header.
  final Color sheetDivider;

  const ScaffoldColorRoles({
    // GENERATED from design_tokens.json scaffold.colorRoles.dark. Do not edit.
    this.accent = ScaffoldColors.lightGreenPrimary,
    this.accentOnSurface = ScaffoldColors.lightGreenPrimary,
    this.borderControl = const Color(0x5CFFFFFF),
    this.inputForeground = const Color(0xFFFFFFFF),
    this.sheetForeground = const Color(0xFFFFFFFF),
    this.sheetDivider = const Color(0x1FFFFFFF),
    // END GENERATED scaffold.colorRoles.dark
  });

  /// Dark-mode defaults. Rendered from `design_tokens.json`.
  static const ScaffoldColorRoles defaultColorRoles = ScaffoldColorRoles();

  /// Light-mode defaults. Rendered from `design_tokens.json`.
  static const ScaffoldColorRoles lightColorRoles = ScaffoldColorRoles(
    // GENERATED from design_tokens.json scaffold.colorRoles.light. Do not edit.
    accent: ScaffoldColors.lightGreenPrimary,
    accentOnSurface: ScaffoldColors.lightGreenPrimary,
    borderControl: Color(0x73000000),
    inputForeground: Color(0xFF17191E),
    sheetForeground: Color(0xFF17191E),
    sheetDivider: Color(0x1F000000),
    // END GENERATED scaffold.colorRoles.light
  );

  /// Roles for an app that registered no [ScaffoldColorRoles]. [accent],
  /// [accentOnSurface] and [borderControl] come from [palette], which is what
  /// the widgets read before these roles existed; the other roles come from
  /// [lightColorRoles] or [defaultColorRoles] by [brightness].
  static ScaffoldColorRoles fallbackFor(
    ScaffoldPalette palette,
    Brightness brightness,
  ) {
    final base = brightness == Brightness.light ? lightColorRoles : defaultColorRoles;
    return base.copyWith(
      accent: palette.lightGreenPrimary,
      accentOnSurface: palette.lightGreenPrimary,
      borderControl: palette.borderGrey,
    );
  }

  /// Like [fallbackFor], but picks the foreground tokens from the surfaces of
  /// [palette] instead of a [Brightness]. Input text follows the luminance of
  /// [ScaffoldPalette.grayPrimary] and the drawer foregrounds follow
  /// [ScaffoldPalette.deepBlueTertiary], so a light theme with no registered
  /// palette (dark default surfaces) still gets readable text.
  static ScaffoldColorRoles fallbackForPalette(ScaffoldPalette palette) {
    final onInput =
        _isLightSurface(palette.grayPrimary) ? lightColorRoles : defaultColorRoles;
    final onSheet = _isLightSurface(palette.deepBlueTertiary)
        ? Brightness.light
        : Brightness.dark;
    return fallbackFor(palette, onSheet)
        .copyWith(inputForeground: onInput.inputForeground);
  }

  static bool _isLightSurface(Color surface) =>
      ThemeData.estimateBrightnessForColor(surface) == Brightness.light;

  /// Returns a copy of these roles with the given fields replaced.
  @override
  ScaffoldColorRoles copyWith({
    Color? accent,
    Color? accentOnSurface,
    Color? borderControl,
    Color? inputForeground,
    Color? sheetForeground,
    Color? sheetDivider,
  }) {
    return ScaffoldColorRoles(
      accent: accent ?? this.accent,
      accentOnSurface: accentOnSurface ?? this.accentOnSurface,
      borderControl: borderControl ?? this.borderControl,
      inputForeground: inputForeground ?? this.inputForeground,
      sheetForeground: sheetForeground ?? this.sheetForeground,
      sheetDivider: sheetDivider ?? this.sheetDivider,
    );
  }

  @override
  ScaffoldColorRoles lerp(ThemeExtension<ScaffoldColorRoles>? other, double t) {
    if (other is! ScaffoldColorRoles) {
      return this;
    }
    return ScaffoldColorRoles(
      accent: Color.lerp(accent, other.accent, t)!,
      accentOnSurface: Color.lerp(accentOnSurface, other.accentOnSurface, t)!,
      borderControl: Color.lerp(borderControl, other.borderControl, t)!,
      inputForeground: Color.lerp(inputForeground, other.inputForeground, t)!,
      sheetForeground: Color.lerp(sheetForeground, other.sheetForeground, t)!,
      sheetDivider: Color.lerp(sheetDivider, other.sheetDivider, t)!,
    );
  }
}
