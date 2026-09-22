import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';

void main() {
  group('ScaffoldDimens Wave 0 tokens', () {
    const dimens = ScaffoldDimens.defaultDimens;

    test('focusRingWidth defaults to 2.0', () {
      expect(dimens.focusRingWidth, 2.0);
    });

    test('skeletonCornerRadius defaults to 4.0', () {
      expect(dimens.skeletonCornerRadius, 4.0);
    });

    test('disabledOverlayOpacity defaults to 0.40', () {
      expect(dimens.disabledOverlayOpacity, 0.40);
    });

    test('dragHandleSize defaults to 24.0', () {
      expect(dimens.dragHandleSize, 24.0);
    });

    test('minTouchTarget defaults to 48.0', () {
      expect(dimens.minTouchTarget, 48.0);
    });

    test('touchTargetPadding defaults to 12.0', () {
      expect(dimens.touchTargetPadding, 12.0);
    });

    test('copyWith(minTouchTarget:) replaces only that field', () {
      final copy = dimens.copyWith(minTouchTarget: 56.0);
      expect(copy.minTouchTarget, 56.0);
      // Every other field is untouched.
      expect(copy.horizontalPadding, dimens.horizontalPadding);
      expect(copy.focusRingWidth, dimens.focusRingWidth);
      expect(copy.skeletonCornerRadius, dimens.skeletonCornerRadius);
      expect(copy.disabledOverlayOpacity, dimens.disabledOverlayOpacity);
      expect(copy.dragHandleSize, dimens.dragHandleSize);
      expect(copy.touchTargetPadding, dimens.touchTargetPadding);
      expect(copy.borderRadiusCard, dimens.borderRadiusCard);
    });

    test('lerp is identity on itself and midpoint against a different set', () {
      final same = dimens.lerp(dimens, 0.5);
      expect(same.focusRingWidth, dimens.focusRingWidth);
      expect(same.minTouchTarget, dimens.minTouchTarget);
      expect(same.touchTargetPadding, dimens.touchTargetPadding);

      final other = dimens.copyWith(minTouchTarget: 56.0);
      final mid = dimens.lerp(other, 0.5);
      // (48 + 56) / 2.
      expect(mid.minTouchTarget, 52.0);
    });
  });
}
