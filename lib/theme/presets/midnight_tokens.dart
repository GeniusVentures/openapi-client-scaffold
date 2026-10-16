import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_motion_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_shadows.dart';
import 'package:frontend_scaffold/theme/scaffold_typography.dart';

/// The values of the opt-in midnight preset, generated from
/// tokens/midnight.json. Not exported from the package barrel; import
/// `package:frontend_scaffold/theme/presets/midnight_theme.dart` to use it.
abstract final class Midnight {
  /// Dark-mode palette of the midnight preset.
  static const ScaffoldPalette darkPalette = ScaffoldPalette(
    // GENERATED from tokens/midnight.json scaffold.palette.dark. Do not edit.
    deepBlueCardColor: Color(0xFF0C0E14),
    lightGreenPrimary: Color(0xFF0AAEE6),
    lightGreenSecondary: Color(0xFF2BF5B4),
    gray500: Color(0xFF8A8F9D),
    blue500: Color(0xFF14C8FF),
    borderGrey: Color(0x5CFFFFFF),
    grayPrimary: Color(0xFF171A21),
    deepBlueTertiary: Color(0xFF171A21),
    surfaceElevated: Color(0xFF0C0E14),
    borderSubtle: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8A8F9D),
    statusSuccess: Color(0xFF0AD89C),
    statusError: Color(0xFFFF4D4D),
    statusWarningText: Color(0xFFFFC42E),
    focusRingColor: Color(0xFF0AAEE6),
    skeletonBaseColor: Color(0xFF171A21),
    skeletonShimmerColor: Color(0xFF0B0D12),
    disabledOverlayColor: Color(0x66000000),
    dragFeedbackBackground: Color(0xFF0C0E14),
    dropZoneHighlight: Color(0x330AAEE6),
    dropZoneRejected: Color(0x33FF4D4D),
    // END GENERATED scaffold.palette.dark
  );

  /// Light-mode palette of the midnight preset.
  static const ScaffoldPalette lightPalette = ScaffoldPalette(
    // GENERATED from tokens/midnight.json scaffold.palette.light. Do not edit.
    deepBlueCardColor: Color(0xFFFFFFFF),
    lightGreenPrimary: Color(0xFF0AAEE6),
    lightGreenSecondary: Color(0xFF2BF5B4),
    gray500: Color(0xFF5A606E),
    blue500: Color(0xFF0A6885),
    borderGrey: Color(0x7A10131A),
    grayPrimary: Color(0xFFEFF2F6),
    deepBlueTertiary: Color(0xFFEFF2F6),
    surfaceElevated: Color(0xFFFFFFFF),
    borderSubtle: Color(0x1F10131A),
    textPrimary: Color(0xFF10131A),
    textSecondary: Color(0xFF5A606E),
    statusSuccess: Color(0xFF065F46),
    statusError: Color(0xFF991B1B),
    statusWarningText: Color(0xFF92400E),
    focusRingColor: Color(0xFF0A6885),
    skeletonBaseColor: Color(0xFFEFF2F6),
    skeletonShimmerColor: Color(0xFFFFFFFF),
    disabledOverlayColor: Color(0x66000000),
    dragFeedbackBackground: Color(0xFFFFFFFF),
    dropZoneHighlight: Color(0x330AAEE6),
    dropZoneRejected: Color(0x33991B1B),
    // END GENERATED scaffold.palette.light
  );

  /// Dark-mode color roles of the midnight preset.
  static const ScaffoldColorRoles darkColorRoles = ScaffoldColorRoles(
    // GENERATED from tokens/midnight.json scaffold.colorRoles.dark. Do not edit.
    accent: Color(0xFF0AAEE6),
    accentOnSurface: Color(0xFF0AAEE6),
    accentSecondaryOnSurface: Color(0xFF2BF5B4),
    accentTextOnSurface: Color(0xFF0AAEE6),
    borderControl: Color(0x5CFFFFFF),
    inputForeground: Color(0xFFFFFFFF),
    sheetForeground: Color(0xFFFFFFFF),
    sheetDivider: Color(0x1FFFFFFF),
    // END GENERATED scaffold.colorRoles.dark
  );

  /// Light-mode color roles of the midnight preset.
  static const ScaffoldColorRoles lightColorRoles = ScaffoldColorRoles(
    // GENERATED from tokens/midnight.json scaffold.colorRoles.light. Do not edit.
    accent: Color(0xFF0AAEE6),
    accentOnSurface: Color(0xFF0A6885),
    accentSecondaryOnSurface: Color(0xFF07875F),
    accentTextOnSurface: Color(0xFF0A6885),
    borderControl: Color(0x7A10131A),
    inputForeground: Color(0xFF10131A),
    sheetForeground: Color(0xFF10131A),
    sheetDivider: Color(0x1F10131A),
    // END GENERATED scaffold.colorRoles.light
  );

  /// Spacing, radius and size values of the midnight preset.
  static const ScaffoldDimens dimens = ScaffoldDimens(
    // GENERATED from tokens/midnight.json scaffold.dimens. Do not edit.
    horizontalPadding: 20.0,
    horizontalDesktopPadding: 40.0,
    verticalDesktopPadding: 40.0,
    itemSpacing: 16.0,
    borderRadiusCard: 15.0,
    borderRadiusButton: 48.0,
    appBarHeight: 68.0,
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
    // END GENERATED scaffold.dimens
  );

  /// Dark-mode shadows of the midnight preset.
  static const ScaffoldShadows darkShadows = ScaffoldShadows(
    // GENERATED from tokens/midnight.json scaffold.shadows.dark. Do not edit.
    card: [BoxShadow(color: Color(0x59000000), blurRadius: 16.0, offset: Offset(0.0, 4.0))],
    // END GENERATED scaffold.shadows.dark
  );

  /// Light-mode shadows of the midnight preset.
  static const ScaffoldShadows lightShadows = ScaffoldShadows(
    // GENERATED from tokens/midnight.json scaffold.shadows.light. Do not edit.
    card: [BoxShadow(color: Color(0x1F000000), blurRadius: 16.0, offset: Offset(0.0, 4.0))],
    // END GENERATED scaffold.shadows.light
  );

  /// Durations and curves of the midnight preset.
  static const ScaffoldMotionTheme motion = ScaffoldMotionTheme(
    // GENERATED from tokens/midnight.json scaffold.motion.durations. Do not edit.
    short: Duration(milliseconds: 120),
    medium: Duration(milliseconds: 200),
    long: Duration(milliseconds: 320),
    // END GENERATED scaffold.motion.durations
    // GENERATED from tokens/midnight.json scaffold.motion.curves. Do not edit.
    standard: Curves.easeOutCubic,
    decelerate: Curves.easeOut,
    emphasized: Curves.easeOutExpo,
    // END GENERATED scaffold.motion.curves
  );

  /// Input text style and mono font family of the midnight preset.
  static const ScaffoldTypography typography = ScaffoldTypography(
    // GENERATED from tokens/midnight.json scaffold.typography.textStyles. Do not edit.
    inputStyle: TextStyle(fontFamily: 'Inter', fontSize: 16.0, fontWeight: FontWeight.w400, letterSpacing: 0.0),
    // END GENERATED scaffold.typography.textStyles
    // GENERATED from tokens/midnight.json scaffold.typography.fontFamilies. Do not edit.
    monoFontFamily: 'JetBrainsMono',
    // END GENERATED scaffold.typography.fontFamilies
  );

  /// Dark-mode colors of the midnight preset that have no palette or role field.
  static const MidnightColors darkColors = MidnightColors(
    // GENERATED from tokens/midnight.json preset.colors.dark. Do not edit.
    surfaceBase: Color(0xFF0B0D12),
    surfaceSheet: Color(0xFF171A21),
    surfaceSunken: Color(0xFF06080C),
    scrim: Color(0x99000000),
    accentPrimary: Color(0xFF14C8FF),
    accentPrimaryStrong: Color(0xFF0AAEE6),
    accentSecondary: Color(0xFF2BF5B4),
    accentSecondaryStrong: Color(0xFF0AD89C),
    accentSecondaryBright: Color(0xFF5BFFD0),
    accentTertiary: Color(0xFFC28FFF),
    accentBadgeText: Color(0xFF0AB2EB),
    textOnAccent: Color(0xFF000B18),
    textOnError: Color(0xFF000B18),
    textTertiary: Color(0xFF35363D),
    borderStrong: Color(0x3DFFFFFF),
    borderControlOnAccent: Color(0x94FFFFFF),
    statusWarning: Color(0xFFFFC42E),
    selection: Color(0xFF8A8F9D),
    // END GENERATED preset.colors.dark
  );

  /// Light-mode colors of the midnight preset that have no palette or role field.
  static const MidnightColors lightColors = MidnightColors(
    // GENERATED from tokens/midnight.json preset.colors.light. Do not edit.
    surfaceBase: Color(0xFFDCE0E6),
    surfaceSheet: Color(0xFFEFF2F6),
    surfaceSunken: Color(0xFFCFD4DB),
    scrim: Color(0x99000000),
    accentPrimary: Color(0xFF14C8FF),
    accentPrimaryStrong: Color(0xFF0AAEE6),
    accentSecondary: Color(0xFF2BF5B4),
    accentSecondaryStrong: Color(0xFF0AD89C),
    accentSecondaryBright: Color(0xFF5BFFD0),
    accentTertiary: Color(0xFFC28FFF),
    accentBadgeText: Color(0xFF0A6480),
    textOnAccent: Color(0xFF000B18),
    textOnError: Color(0xFFFFFFFF),
    textTertiary: Color(0xFF35363D),
    borderStrong: Color(0x3D10131A),
    borderControlOnAccent: Color(0x8510131A),
    statusWarning: Color(0xFFFFC42E),
    selection: Color(0xFF8A8F9D),
    // END GENERATED preset.colors.light
  );

  /// Dark-mode dialog and glow shadows of the midnight preset.
  static const MidnightElevation darkElevation = MidnightElevation(
    // GENERATED from tokens/midnight.json preset.shadows.dark. Do not edit.
    dialog: [BoxShadow(color: Color(0x73000000), blurRadius: 32.0, offset: Offset(0.0, 8.0))],
    glowAccent: [BoxShadow(color: Color(0x2E14C8FF), blurRadius: 24.0, offset: Offset(0.0, 0.0))],
    glowAccentPair: [BoxShadow(color: Color(0x2614C8FF), blurRadius: 28.0, offset: Offset(-6.0, 8.0)), BoxShadow(color: Color(0x262BF5B4), blurRadius: 28.0, offset: Offset(6.0, 8.0))],
    // END GENERATED preset.shadows.dark
  );

  /// Light-mode dialog and glow shadows of the midnight preset.
  static const MidnightElevation lightElevation = MidnightElevation(
    // GENERATED from tokens/midnight.json preset.shadows.light. Do not edit.
    dialog: [BoxShadow(color: Color(0x33000000), blurRadius: 32.0, offset: Offset(0.0, 8.0))],
    glowAccent: [BoxShadow(color: Color(0x2E14C8FF), blurRadius: 24.0, offset: Offset(0.0, 0.0))],
    glowAccentPair: [BoxShadow(color: Color(0x2614C8FF), blurRadius: 28.0, offset: Offset(-6.0, 8.0)), BoxShadow(color: Color(0x262BF5B4), blurRadius: 28.0, offset: Offset(6.0, 8.0))],
    // END GENERATED preset.shadows.light
  );

  /// Dark-mode gradients of the midnight preset.
  static const MidnightGradients darkGradients = MidnightGradients(
    // GENERATED from tokens/midnight.json preset.gradients.dark. Do not edit.
    accentFill: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF0AD89C), Color(0xFF0AAEE6)]),
    accentBorder: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF14C8FF), Color(0xFF5BFFD0)]),
    heroWash: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B0D12), Color(0xFF0C0E14)]),
    canvas: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF14171E), Color(0xFF0B0D12), Color(0xFF07090D)], stops: [0.0, 0.4, 1.0]),
    surfaceSheen: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0C0E14), Color(0xFF0C0E14)]),
    canvasGlow: RadialGradient(center: Alignment(0.0, -0.9), radius: 1.0, colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)], stops: [0.0, 0.6]),
    // END GENERATED preset.gradients.dark
  );

  /// Light-mode gradients of the midnight preset. Has no [MidnightGradients.canvasGlow].
  static const MidnightGradients lightGradients = MidnightGradients(
    // GENERATED from tokens/midnight.json preset.gradients.light. Do not edit.
    accentFill: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF0AD89C), Color(0xFF0AAEE6)]),
    accentBorder: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF14C8FF), Color(0xFF5BFFD0)]),
    heroWash: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDCE0E6), Color(0xFFFFFFFF)]),
    canvas: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE3E6EB), Color(0xFFDCE0E6), Color(0xFFD3D7DE)], stops: [0.0, 0.4, 1.0]),
    surfaceSheen: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)]),
    // END GENERATED preset.gradients.light
  );
}

/// Midnight colors with no [ScaffoldPalette] or [ScaffoldColorRoles] field.
///
/// Read by `midnightTheme` and available to apps through [Midnight.darkColors]
/// and [Midnight.lightColors].
final class MidnightColors {
  const MidnightColors({
    required this.surfaceBase,
    required this.surfaceSheet,
    required this.surfaceSunken,
    required this.scrim,
    required this.accentPrimary,
    required this.accentPrimaryStrong,
    required this.accentSecondary,
    required this.accentSecondaryStrong,
    required this.accentSecondaryBright,
    required this.accentTertiary,
    required this.accentBadgeText,
    required this.textOnAccent,
    required this.textOnError,
    required this.textTertiary,
    required this.borderStrong,
    required this.borderControlOnAccent,
    required this.statusWarning,
    required this.selection,
  });

  /// Page background under cards and sheets.
  final Color surfaceBase;

  /// Background of sheets, menus and drawers.
  final Color surfaceSheet;

  /// Recessed track or well background.
  final Color surfaceSunken;

  /// Modal barrier behind sheets and dialogs.
  final Color scrim;

  /// Primary accent fill and gradient stop.
  final Color accentPrimary;

  /// Stronger primary accent fill.
  final Color accentPrimaryStrong;

  /// Secondary accent fill and gradient stop.
  final Color accentSecondary;

  /// Stronger secondary accent fill.
  final Color accentSecondaryStrong;

  /// Brighter secondary accent, for highlights.
  final Color accentSecondaryBright;

  /// Tertiary accent fill.
  final Color accentTertiary;

  /// Primary accent tuned for badge text.
  final Color accentBadgeText;

  /// Foreground on an accent fill.
  final Color textOnAccent;

  /// Foreground on an error fill.
  final Color textOnError;

  /// Disabled and placeholder label color.
  final Color textTertiary;

  /// Emphasized hairline border.
  final Color borderStrong;

  /// Control edge drawn over an accent fill.
  final Color borderControlOnAccent;

  /// Warning fill.
  final Color statusWarning;

  /// Text selection highlight color.
  final Color selection;
}

/// Midnight shadows with no [ScaffoldShadows] field.
///
/// Available to apps through [Midnight.darkElevation] and
/// [Midnight.lightElevation].
final class MidnightElevation {
  const MidnightElevation({
    required this.dialog,
    required this.glowAccent,
    required this.glowAccentPair,
  });

  /// Shadow under dialogs.
  final List<BoxShadow> dialog;

  /// Cyan glow under an accent element.
  final List<BoxShadow> glowAccent;

  /// Cyan and mint glow pair under a hero call to action.
  final List<BoxShadow> glowAccentPair;
}

/// Midnight gradients with no [ScaffoldGradients] field.
///
/// No widget draws these yet. Available to apps through
/// [Midnight.darkGradients] and [Midnight.lightGradients].
final class MidnightGradients {
  const MidnightGradients({
    required this.accentFill,
    required this.accentBorder,
    required this.heroWash,
    required this.canvas,
    required this.surfaceSheen,
    this.canvasGlow,
  });

  /// Fill of a primary call to action, left to right.
  final LinearGradient accentFill;

  /// Outline of an accent card, left to right.
  final LinearGradient accentBorder;

  /// Background wash of a hero section.
  final LinearGradient heroWash;

  /// Page background wash.
  final LinearGradient canvas;

  /// Fill of an elevated surface.
  final LinearGradient surfaceSheen;

  /// Faint light near the top of the canvas. Dark mode only, so null in light.
  final RadialGradient? canvasGlow;
}
