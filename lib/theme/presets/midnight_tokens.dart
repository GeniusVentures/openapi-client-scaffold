import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

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
}
