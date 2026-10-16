import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'wcag_contrast.dart';

void main() {
  test('black on white is 21:1 in either order', () {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    expect(contrastRatio(black, white), closeTo(21.0, 0.01));
    expect(contrastRatio(white, black), closeTo(21.0, 0.01));
  });

  test('#00EAAE on white is about 1.57', () {
    expect(
      contrastRatio(const Color(0xFF00EAAE), const Color(0xFFFFFFFF)),
      closeTo(1.57, 0.01),
    );
  });

  test('a translucent foreground is composited onto the background first', () {
    expect(
      contrastRatio(const Color(0x4DFFFFFF), const Color(0xFF0C0E14)),
      closeTo(2.66, 0.02),
    );
  });

  test('a translucent background fails the assertion', () {
    expect(
      () => contrastRatio(const Color(0xFF000000), const Color(0x80FFFFFF)),
      throwsA(isA<AssertionError>()),
    );
  });

  test('argbHex pads to 8 digits', () {
    expect(argbHex(const Color(0x0100000F)), '0x0100000F');
  });
}
