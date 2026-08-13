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

  /// 4pt spacing scale step.
  final double space2;

  /// 6pt spacing scale step.
  final double space3;

  /// 8pt spacing scale step.
  final double space4;

  /// 12pt spacing scale step.
  final double space6;

  /// 16pt spacing scale step.
  final double space8;

  /// 24pt spacing scale step.
  final double space12;

  /// Corner radius for alert cards. Kept separate from
  /// [borderRadiusCard] (15.0) so existing card consumers are unaffected.
  final double radiusMd;

  /// Corner radius for pill shapes.
  final double radiusPill;

  /// Focus ring stroke width.
  final double focusRingWidth;

  /// Skeleton placeholder corner radius.
  final double skeletonCornerRadius;

  /// Dim overlay opacity for disabled atoms.
  final double disabledOverlayOpacity;

  /// Drag-handle grip width.
  final double dragHandleSize;

  /// Minimum touch target in both dimensions.
  final double minTouchTarget;

  /// Internal padding used to bring small content up to the touch target.
  final double touchTargetPadding;

  /// Creates a dimension set with the given values.
  const ScaffoldDimens({
    required this.horizontalPadding,
    required this.horizontalDesktopPadding,
    required this.verticalDesktopPadding,
    required this.itemSpacing,
    required this.borderRadiusCard,
    required this.borderRadiusButton,
    required this.appBarHeight,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space6,
    required this.space8,
    required this.space12,
    required this.radiusMd,
    required this.radiusPill,
    required this.focusRingWidth,
    required this.skeletonCornerRadius,
    required this.disabledOverlayOpacity,
    required this.dragHandleSize,
    required this.minTouchTarget,
    required this.touchTargetPadding,
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
    space2: 4.0,
    space3: 6.0,
    space4: 8.0,
    space6: 12.0,
    space8: 16.0,
    space12: 24.0,
    radiusMd: 12.0,
    radiusPill: 48.0,
    focusRingWidth: 2.0,
    skeletonCornerRadius: 4.0,
    disabledOverlayOpacity: 0.40,
    dragHandleSize: 24.0,
    minTouchTarget: 48.0,
    touchTargetPadding: 12.0,
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
    double? space2,
    double? space3,
    double? space4,
    double? space6,
    double? space8,
    double? space12,
    double? radiusMd,
    double? radiusPill,
    double? focusRingWidth,
    double? skeletonCornerRadius,
    double? disabledOverlayOpacity,
    double? dragHandleSize,
    double? minTouchTarget,
    double? touchTargetPadding,
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
      space2: space2 ?? this.space2,
      space3: space3 ?? this.space3,
      space4: space4 ?? this.space4,
      space6: space6 ?? this.space6,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusPill: radiusPill ?? this.radiusPill,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      skeletonCornerRadius:
          skeletonCornerRadius ?? this.skeletonCornerRadius,
      disabledOverlayOpacity:
          disabledOverlayOpacity ?? this.disabledOverlayOpacity,
      dragHandleSize: dragHandleSize ?? this.dragHandleSize,
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
      touchTargetPadding: touchTargetPadding ?? this.touchTargetPadding,
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
      space2: lerpDouble(space2, other.space2),
      space3: lerpDouble(space3, other.space3),
      space4: lerpDouble(space4, other.space4),
      space6: lerpDouble(space6, other.space6),
      space8: lerpDouble(space8, other.space8),
      space12: lerpDouble(space12, other.space12),
      radiusMd: lerpDouble(radiusMd, other.radiusMd),
      radiusPill: lerpDouble(radiusPill, other.radiusPill),
      focusRingWidth: lerpDouble(focusRingWidth, other.focusRingWidth),
      skeletonCornerRadius:
          lerpDouble(skeletonCornerRadius, other.skeletonCornerRadius),
      disabledOverlayOpacity:
          lerpDouble(disabledOverlayOpacity, other.disabledOverlayOpacity),
      dragHandleSize: lerpDouble(dragHandleSize, other.dragHandleSize),
      minTouchTarget: lerpDouble(minTouchTarget, other.minTouchTarget),
      touchTargetPadding:
          lerpDouble(touchTargetPadding, other.touchTargetPadding),
    );
  }
}
