import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_colors.dart';

/// Material 3 theme extension holding the semantic colors consumed by
/// frontend_scaffold widgets. Register on [ThemeData.extensions] to allow
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

  /// Elevated surface fill used by toasts painted into the root Overlay.
  final Color surfaceElevated;

  /// Subtle hairline border for elevated surfaces.
  final Color borderSubtle;

  /// Primary text color on dark surfaces.
  final Color textPrimary;

  /// Secondary text color on dark surfaces.
  final Color textSecondary;

  /// Success status accent.
  final Color statusSuccess;

  /// Error status accent.
  final Color statusError;

  /// Warning status accent (foreground-purposed).
  final Color statusWarningText;

  /// Focus ring color — visible in all focus states (keyboard + screen
  /// reader). Seeded from the primary accent so it never fights the brand.
  final Color focusRingColor;

  /// Skeleton placeholder base fill.
  final Color skeletonBaseColor;

  /// Skeleton shimmer sweep color, contrasted against [skeletonBaseColor].
  final Color skeletonShimmerColor;

  /// Dim overlay painted over disabled atoms (dark-theme default).
  final Color disabledOverlayColor;

  /// Drag-feedback chip background.
  final Color dragFeedbackBackground;

  /// Drop-target accepted/over highlight.
  final Color dropZoneHighlight;

  /// Drop-target rejected highlight.
  final Color dropZoneRejected;

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
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.statusSuccess,
    required this.statusError,
    required this.statusWarningText,
    required this.focusRingColor,
    required this.skeletonBaseColor,
    required this.skeletonShimmerColor,
    required this.disabledOverlayColor,
    required this.dragFeedbackBackground,
    required this.dropZoneHighlight,
    required this.dropZoneRejected,
  });

  /// Default palette seeded from the raw [ScaffoldColors] constants, plus
  /// the toast-needed tokens with dark-mode defaults.
  static const ScaffoldPalette defaultPalette = ScaffoldPalette(
    deepBlueCardColor: ScaffoldColors.deepBlueCardColor,
    lightGreenPrimary: ScaffoldColors.lightGreenPrimary,
    lightGreenSecondary: ScaffoldColors.lightGreenSecondary,
    gray500: ScaffoldColors.gray500,
    blue500: ScaffoldColors.blue500,
    borderGrey: ScaffoldColors.borderGrey,
    grayPrimary: ScaffoldColors.grayPrimary,
    deepBlueTertiary: ScaffoldColors.deepBlueTertiary,
    surfaceElevated: Color(0xFF0C0E14),
    borderSubtle: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8A8F9D),
    statusSuccess: Color(0xFF0AD89C),
    statusError: Color(0xFFFF4D4D),
    statusWarningText: Color(0xFFFFC42E),
    focusRingColor: ScaffoldColors.lightGreenPrimary,
    skeletonBaseColor: Color(0xFF0C0E14),
    skeletonShimmerColor: Color(0xFF0A121F),
    disabledOverlayColor: Color(0x66000000),
    dragFeedbackBackground: Color(0xFF0C0E14),
    dropZoneHighlight: Color(0x3300EAAE),
    dropZoneRejected: Color(0x33FF4D4D),
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
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? statusSuccess,
    Color? statusError,
    Color? statusWarningText,
    Color? focusRingColor,
    Color? skeletonBaseColor,
    Color? skeletonShimmerColor,
    Color? disabledOverlayColor,
    Color? dragFeedbackBackground,
    Color? dropZoneHighlight,
    Color? dropZoneRejected,
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
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusError: statusError ?? this.statusError,
      statusWarningText: statusWarningText ?? this.statusWarningText,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      skeletonBaseColor: skeletonBaseColor ?? this.skeletonBaseColor,
      skeletonShimmerColor: skeletonShimmerColor ?? this.skeletonShimmerColor,
      disabledOverlayColor: disabledOverlayColor ?? this.disabledOverlayColor,
      dragFeedbackBackground:
          dragFeedbackBackground ?? this.dragFeedbackBackground,
      dropZoneHighlight: dropZoneHighlight ?? this.dropZoneHighlight,
      dropZoneRejected: dropZoneRejected ?? this.dropZoneRejected,
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
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusWarningText:
          Color.lerp(statusWarningText, other.statusWarningText, t)!,
      focusRingColor: Color.lerp(focusRingColor, other.focusRingColor, t)!,
      skeletonBaseColor:
          Color.lerp(skeletonBaseColor, other.skeletonBaseColor, t)!,
      skeletonShimmerColor:
          Color.lerp(skeletonShimmerColor, other.skeletonShimmerColor, t)!,
      disabledOverlayColor:
          Color.lerp(disabledOverlayColor, other.disabledOverlayColor, t)!,
      dragFeedbackBackground:
          Color.lerp(dragFeedbackBackground, other.dragFeedbackBackground, t)!,
      dropZoneHighlight:
          Color.lerp(dropZoneHighlight, other.dropZoneHighlight, t)!,
      dropZoneRejected:
          Color.lerp(dropZoneRejected, other.dropZoneRejected, t)!,
    );
  }
}
