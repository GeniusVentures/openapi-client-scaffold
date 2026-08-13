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
}
