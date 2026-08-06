import 'package:flutter/material.dart';

/// Material 3 theme extension holding the layout dimension tokens consumed
/// by frontend_scaffold widgets. Register on [ThemeData.extensions] to allow
/// host apps to override the defaults without forking the package.
class ScaffoldDimens extends ThemeExtension<ScaffoldDimens> {
  /// Horizontal page padding for phone layouts.
  final double horizontalPadding;

  /// Horizontal page padding for desktop layouts.
  final double horizontalDesktopPadding;

  /// Vertical page padding for desktop layouts.
  final double verticalDesktopPadding;

  /// Standard spacing between stacked items.
  final double itemSpacing;

  /// Corner radius for cards and card-like buttons.
  final double borderRadiusCard;

  /// Corner radius for pill-shaped buttons.
  final double borderRadiusButton;

  /// Height of the scaffold app bar.
  final double appBarHeight;

  /// Creates a dimension set with the given values.
  const ScaffoldDimens({
    required this.horizontalPadding,
    required this.horizontalDesktopPadding,
    required this.verticalDesktopPadding,
    required this.itemSpacing,
    required this.borderRadiusCard,
    required this.borderRadiusButton,
    required this.appBarHeight,
  });

  /// Default dimensions matching the previous static token values.
  static const ScaffoldDimens defaultDimens = ScaffoldDimens(
    horizontalPadding: 20.0,
    horizontalDesktopPadding: 40.0,
    verticalDesktopPadding: 40.0,
    itemSpacing: 16.0,
    borderRadiusCard: 15.0,
    borderRadiusButton: 48.0,
    appBarHeight: 65.0,
  );

  /// Returns a copy of this dimension set with the given fields replaced.
  @override
  ScaffoldDimens copyWith({
    double? horizontalPadding,
    double? horizontalDesktopPadding,
    double? verticalDesktopPadding,
    double? itemSpacing,
    double? borderRadiusCard,
    double? borderRadiusButton,
    double? appBarHeight,
  }) {
    return ScaffoldDimens(
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      horizontalDesktopPadding:
          horizontalDesktopPadding ?? this.horizontalDesktopPadding,
      verticalDesktopPadding:
          verticalDesktopPadding ?? this.verticalDesktopPadding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      borderRadiusCard: borderRadiusCard ?? this.borderRadiusCard,
      borderRadiusButton: borderRadiusButton ?? this.borderRadiusButton,
      appBarHeight: appBarHeight ?? this.appBarHeight,
    );
  }

  /// Linearly interpolates between two dimension sets.
  @override
  ScaffoldDimens lerp(ThemeExtension<ScaffoldDimens>? other, double t) {
    if (other is! ScaffoldDimens) {
      return this;
    }
    double lerpDouble(double a, double b) => a + (b - a) * t;
    return ScaffoldDimens(
      horizontalPadding:
          lerpDouble(horizontalPadding, other.horizontalPadding),
      horizontalDesktopPadding:
          lerpDouble(horizontalDesktopPadding, other.horizontalDesktopPadding),
      verticalDesktopPadding:
          lerpDouble(verticalDesktopPadding, other.verticalDesktopPadding),
      itemSpacing: lerpDouble(itemSpacing, other.itemSpacing),
      borderRadiusCard: lerpDouble(borderRadiusCard, other.borderRadiusCard),
      borderRadiusButton:
          lerpDouble(borderRadiusButton, other.borderRadiusButton),
      appBarHeight: lerpDouble(appBarHeight, other.appBarHeight),
    );
  }
}
