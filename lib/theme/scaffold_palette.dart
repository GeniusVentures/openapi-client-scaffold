import 'package:flutter/material.dart';
import 'package:genius_scaffold/theme/scaffold_colors.dart';

/// Material 3 theme extension holding the semantic colors consumed by
/// genius_scaffold widgets. Register on [ThemeData.extensions] to allow
/// host apps to override the defaults without forking the package.
class ScaffoldPalette extends ThemeExtension<ScaffoldPalette> {
  /// Card / raised-surface deep blue used by [ActionButton] backgrounds.
  final Color deepBlueCardColor;

  /// Primary accent green used for focused borders and loading dots.
  final Color lightGreenPrimary;

  /// Secondary accent green used for icon tints.
  final Color lightGreenSecondary;

  /// Muted gray used for hint text and secondary labels.
  final Color gray500;

  /// Accent blue used for the right loading dot.
  final Color blue500;

  /// Translucent gray used for enabled input borders.
  final Color borderGrey;

  /// Input fill gray.
  final Color grayPrimary;

  /// Deepest surface blue used by drawers and bottom sheets.
  final Color deepBlueTertiary;

  /// Creates a palette with the given semantic colors.
  const ScaffoldPalette({
    required this.deepBlueCardColor,
    required this.lightGreenPrimary,
    required this.lightGreenSecondary,
    required this.gray500,
    required this.blue500,
    required this.borderGrey,
    required this.grayPrimary,
    required this.deepBlueTertiary,
  });

  /// Default palette seeded from the raw [ScaffoldColors] constants.
  static const ScaffoldPalette defaultPalette = ScaffoldPalette(
    deepBlueCardColor: ScaffoldColors.deepBlueCardColor,
    lightGreenPrimary: ScaffoldColors.lightGreenPrimary,
    lightGreenSecondary: ScaffoldColors.lightGreenSecondary,
    gray500: ScaffoldColors.gray500,
    blue500: ScaffoldColors.blue500,
    borderGrey: ScaffoldColors.borderGrey,
    grayPrimary: ScaffoldColors.grayPrimary,
    deepBlueTertiary: ScaffoldColors.deepBlueTertiary,
  );

  /// Returns a copy of this palette with the given fields replaced.
  @override
  ScaffoldPalette copyWith({
    Color? deepBlueCardColor,
    Color? lightGreenPrimary,
    Color? lightGreenSecondary,
    Color? gray500,
    Color? blue500,
    Color? borderGrey,
    Color? grayPrimary,
    Color? deepBlueTertiary,
  }) {
    return ScaffoldPalette(
      deepBlueCardColor: deepBlueCardColor ?? this.deepBlueCardColor,
      lightGreenPrimary: lightGreenPrimary ?? this.lightGreenPrimary,
      lightGreenSecondary: lightGreenSecondary ?? this.lightGreenSecondary,
      gray500: gray500 ?? this.gray500,
      blue500: blue500 ?? this.blue500,
      borderGrey: borderGrey ?? this.borderGrey,
      grayPrimary: grayPrimary ?? this.grayPrimary,
      deepBlueTertiary: deepBlueTertiary ?? this.deepBlueTertiary,
    );
  }

  /// Linearly interpolates between two palettes.
  @override
  ScaffoldPalette lerp(ThemeExtension<ScaffoldPalette>? other, double t) {
    if (other is! ScaffoldPalette) {
      return this;
    }
    return ScaffoldPalette(
      deepBlueCardColor:
          Color.lerp(deepBlueCardColor, other.deepBlueCardColor, t)!,
      lightGreenPrimary:
          Color.lerp(lightGreenPrimary, other.lightGreenPrimary, t)!,
      lightGreenSecondary:
          Color.lerp(lightGreenSecondary, other.lightGreenSecondary, t)!,
      gray500: Color.lerp(gray500, other.gray500, t)!,
      blue500: Color.lerp(blue500, other.blue500, t)!,
      borderGrey: Color.lerp(borderGrey, other.borderGrey, t)!,
      grayPrimary: Color.lerp(grayPrimary, other.grayPrimary, t)!,
      deepBlueTertiary:
          Color.lerp(deepBlueTertiary, other.deepBlueTertiary, t)!,
    );
  }
}
