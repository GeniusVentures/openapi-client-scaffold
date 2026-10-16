import 'package:flutter/material.dart';

/// Material 3 theme extension holding the font choices frontend_scaffold
/// widgets set explicitly; everything else inherits from the host
/// [TextTheme]. Register on [ThemeData.extensions] to let a host app change
/// them; without one, `context.typography` falls back to [defaultTypography].
///
/// Holds family names only and bundles no font files.
class ScaffoldTypography extends ThemeExtension<ScaffoldTypography> {
  /// Base style for text typed into and hinted in the text entry field. The
  /// widget applies its own color.
  final TextStyle inputStyle;

  /// Merged onto formatted numbers; null leaves their style as is. Its font
  /// features replace the base style's.
  final TextStyle? numericStyle;

  /// Font family for code blocks and inline code.
  final String monoFontFamily;

  const ScaffoldTypography({
    // GENERATED from design_tokens.json scaffold.typography.textStyles. Do not edit.
    this.inputStyle = const TextStyle(fontFamily: 'Roboto', fontSize: 14.0, fontWeight: FontWeight.w400, letterSpacing: 0.0),
    this.numericStyle,
    // END GENERATED scaffold.typography.textStyles
    // GENERATED from design_tokens.json scaffold.typography.fontFamilies. Do not edit.
    this.monoFontFamily = 'monospace',
    // END GENERATED scaffold.typography.fontFamilies
  });

  /// Default typography. Rendered from `design_tokens.json`.
  static const ScaffoldTypography defaultTypography = ScaffoldTypography();

  /// Returns a copy of this typography with the given fields replaced.
  @override
  ScaffoldTypography copyWith({
    TextStyle? inputStyle,
    TextStyle? numericStyle,
    String? monoFontFamily,
  }) {
    return ScaffoldTypography(
      inputStyle: inputStyle ?? this.inputStyle,
      numericStyle: numericStyle ?? this.numericStyle,
      monoFontFamily: monoFontFamily ?? this.monoFontFamily,
    );
  }

  /// The font family cannot interpolate, so it switches at `t == 0.5`.
  @override
  ScaffoldTypography lerp(ThemeExtension<ScaffoldTypography>? other, double t) {
    if (other is! ScaffoldTypography) {
      return this;
    }
    return ScaffoldTypography(
      inputStyle: TextStyle.lerp(inputStyle, other.inputStyle, t) ?? inputStyle,
      numericStyle: TextStyle.lerp(numericStyle, other.numericStyle, t),
      monoFontFamily: t < 0.5 ? monoFontFamily : other.monoFontFamily,
    );
  }
}
