import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

void main() {
  group('ScaffoldPalette Wave 0 tokens', () {
    const palette = ScaffoldPalette.defaultPalette;

    test('focusRingColor defaults to lightGreenPrimary', () {
      expect(palette.focusRingColor, const Color(0xFF00EAAE));
      expect(palette.focusRingColor, palette.lightGreenPrimary);
    });

    test('skeletonBaseColor defaults to surfaceElevated', () {
      expect(palette.skeletonBaseColor, const Color(0xFF0C0E14));
      expect(palette.skeletonBaseColor, palette.surfaceElevated);
    });

    test('skeletonShimmerColor defaults to deepBlueCardColor', () {
      expect(palette.skeletonShimmerColor, const Color(0xFF0A121F));
      expect(palette.skeletonShimmerColor, palette.deepBlueCardColor);
    });

    test('disabledOverlayColor defaults to 40% black', () {
      expect(palette.disabledOverlayColor, const Color(0x66000000));
    });

    test('dragFeedbackBackground defaults to surfaceElevated', () {
      expect(palette.dragFeedbackBackground, const Color(0xFF0C0E14));
      expect(palette.dragFeedbackBackground, palette.surfaceElevated);
    });

    test('dropZoneHighlight defaults to lightGreenPrimary at 20%', () {
      expect(palette.dropZoneHighlight, const Color(0x3300EAAE));
    });

    test('dropZoneRejected defaults to statusError at 20%', () {
      expect(palette.dropZoneRejected, const Color(0x33FF4D4D));
    });

    test('copyWith(focusRingColor:) replaces only that field', () {
      final copy = palette.copyWith(focusRingColor: Colors.red);
      expect(copy.focusRingColor, Colors.red);
      // Every other field is untouched.
      expect(copy.deepBlueCardColor, palette.deepBlueCardColor);
      expect(copy.lightGreenPrimary, palette.lightGreenPrimary);
      expect(copy.skeletonBaseColor, palette.skeletonBaseColor);
      expect(copy.skeletonShimmerColor, palette.skeletonShimmerColor);
      expect(copy.disabledOverlayColor, palette.disabledOverlayColor);
      expect(copy.dragFeedbackBackground, palette.dragFeedbackBackground);
      expect(copy.dropZoneHighlight, palette.dropZoneHighlight);
      expect(copy.dropZoneRejected, palette.dropZoneRejected);
      expect(copy.statusError, palette.statusError);
    });

    test('lerp is identity on itself and midpoint against a different palette',
        () {
      final same = palette.lerp(palette, 0.5);
      expect(same.focusRingColor, palette.focusRingColor);
      expect(same.skeletonBaseColor, palette.skeletonBaseColor);
      expect(same.skeletonShimmerColor, palette.skeletonShimmerColor);

      final other = palette.copyWith(focusRingColor: Colors.red);
      final mid = palette.lerp(other, 0.5);
      expect(
        mid.focusRingColor,
        Color.lerp(palette.lightGreenPrimary, Colors.red, 0.5),
      );
    });
  });

  group('ScaffoldPalette lightPalette', () {
    const light = ScaffoldPalette.lightPalette;

    test('uses light surfaces and dark text (contrast-safe)', () {
      expect(light.surfaceElevated, const Color(0xFFFFFFFF));
      expect(light.grayPrimary, const Color(0xFFF1F3F5));
      expect(light.textPrimary, const Color(0xFF17191E));
      expect(light.textSecondary, const Color(0xFF5A6070));
    });

    test('dark hairline border for light surfaces', () {
      expect(light.borderSubtle, const Color(0x1F000000));
    });

    test('shares brand accents with the dark palette', () {
      expect(light.lightGreenPrimary, ScaffoldPalette.defaultPalette.lightGreenPrimary);
      expect(light.focusRingColor, ScaffoldPalette.defaultPalette.focusRingColor);
    });

    test('lightPalette covers all tokens consumed by shipped widgets', () {
      // Tokens consumed by shipped scaffold widgets per 08-UI-SPEC "Color"
      // section. One isNotNull per token locks the coverage contract so a
      // missing lightPalette value trips CI before it ships.
      expect(ScaffoldPalette.lightPalette.surfaceElevated, isNotNull);
      expect(ScaffoldPalette.lightPalette.deepBlueCardColor, isNotNull);
      expect(ScaffoldPalette.lightPalette.lightGreenPrimary, isNotNull);
      expect(ScaffoldPalette.lightPalette.textPrimary, isNotNull);
      expect(ScaffoldPalette.lightPalette.textSecondary, isNotNull);
      expect(ScaffoldPalette.lightPalette.borderSubtle, isNotNull);
      expect(ScaffoldPalette.lightPalette.focusRingColor, isNotNull);
      expect(ScaffoldPalette.lightPalette.statusSuccess, isNotNull);
      expect(ScaffoldPalette.lightPalette.statusError, isNotNull);
      expect(ScaffoldPalette.lightPalette.statusWarningText, isNotNull);
      expect(ScaffoldPalette.lightPalette.blue500, isNotNull);

      // Surface flip contract: light palette must actually flip the
      // dominant surface and primary text from their dark values.
      expect(
        ScaffoldPalette.lightPalette.surfaceElevated,
        isNot(equals(ScaffoldPalette.defaultPalette.surfaceElevated)),
      );
      expect(
        ScaffoldPalette.lightPalette.textPrimary,
        isNot(equals(ScaffoldPalette.defaultPalette.textPrimary)),
      );
    });
  });
}
