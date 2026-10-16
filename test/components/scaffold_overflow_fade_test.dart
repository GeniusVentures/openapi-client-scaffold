import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_overflow_fade.dart';
import 'package:frontend_scaffold/theme/scaffold_gradients.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('renders a ShaderMask when fadeDirection is horizontal', (
    tester,
  ) async {
    await _pump(tester, ScaffoldOverflowFade(child: const Text('content')));

    expect(find.byType(ShaderMask), findsOneWidget);
  });

  test('fadeExtent=32 creates gradient stops 32px from the edges', () {
    final gradient =
        ScaffoldOverflowFade.gradientFor(
          direction: FadeDirection.horizontal,
          extent: 32,
          bounds: const Rect.fromLTWH(0, 0, 400, 100),
          color: Colors.black,
        ) as LinearGradient;

    final stops = gradient.stops!;
    expect(stops.length, 4);
    expect(stops[0], 0.0);
    expect(stops[1], closeTo(32 / 400, 1e-9));
    expect(stops[2], closeTo(1 - 32 / 400, 1e-9));
    expect(stops[3], 1.0);

    // dstOut shader: opaque at the edges (content hidden), transparent in the
    // center (content visible).
    expect(gradient.colors[0].a, 1.0);
    expect(gradient.colors[1].a, 0.0);
    expect(gradient.colors[2].a, 0.0);
    expect(gradient.colors[3].a, 1.0);
  });

  group('ramp', () {
    const bounds = Rect.fromLTWH(0, 0, 400, 100);
    const defaultRamp = LinearGradient(
      colors: [Color(0xFF000000), Color(0x00000000)],
    );

    test('the default two-stop ramp reproduces the built-in gradient', () {
      for (final direction in FadeDirection.values) {
        final plain = ScaffoldOverflowFade.gradientFor(
          direction: direction,
          extent: 32,
          bounds: bounds,
          color: Colors.black,
        );
        final ramped = ScaffoldOverflowFade.gradientFor(
          direction: direction,
          extent: 32,
          bounds: bounds,
          color: Colors.black,
          ramp: defaultRamp,
        );
        expect(ramped, plain, reason: direction.name);
      }
    });

    test('left scales ramp alphas and stops into the edge fraction', () {
      final gradient = ScaffoldOverflowFade.gradientFor(
        direction: FadeDirection.left,
        extent: 40,
        bounds: bounds,
        color: Colors.black,
        ramp: const LinearGradient(
          colors: [Color(0xFF000000), Color(0x80000000), Color(0x00000000)],
          stops: [0.0, 0.5, 1.0],
        ),
      ) as LinearGradient;

      expect(gradient.stops, hasLength(3));
      expect(gradient.stops![0], closeTo(0.0, 1e-9));
      expect(gradient.stops![1], closeTo(0.05, 1e-9));
      expect(gradient.stops![2], closeTo(0.1, 1e-9));
      expect(gradient.colors[0].a, closeTo(1.0, 1e-9));
      expect(gradient.colors[1].a, closeTo(0.5, 0.01));
      expect(gradient.colors[2].a, closeTo(0.0, 1e-9));
    });

    test('horizontal mirrors the ramp on the far edge', () {
      final gradient = ScaffoldOverflowFade.gradientFor(
        direction: FadeDirection.horizontal,
        extent: 40,
        bounds: bounds,
        color: Colors.black,
        ramp: const LinearGradient(
          colors: [Color(0xFF000000), Color(0x80000000), Color(0x00000000)],
          stops: [0.0, 0.5, 1.0],
        ),
      ) as LinearGradient;

      const stops = [0.0, 0.05, 0.1, 0.9, 0.95, 1.0];
      const alphas = [1.0, 0.5, 0.0, 0.0, 0.5, 1.0];
      expect(gradient.stops, hasLength(6));
      for (var i = 0; i < 6; i++) {
        expect(gradient.stops![i], closeTo(stops[i], 1e-9), reason: 'stop $i');
        expect(gradient.colors[i].a, closeTo(alphas[i], 0.01), reason: 'alpha $i');
      }
    });

    test('a ramp without stops is spaced evenly', () {
      final gradient = ScaffoldOverflowFade.gradientFor(
        direction: FadeDirection.top,
        extent: 20,
        bounds: bounds,
        color: Colors.black,
        ramp: const LinearGradient(
          colors: [Color(0xFF000000), Color(0x80000000), Color(0x00000000)],
        ),
      ) as LinearGradient;

      expect(gradient.stops![0], closeTo(0.0, 1e-9));
      expect(gradient.stops![1], closeTo(0.1, 1e-9));
      expect(gradient.stops![2], closeTo(0.2, 1e-9));
    });
  });

  group('drawn fade', () {
    final boundaryKey = GlobalKey();

    Future<int> alphaAt(WidgetTester tester, ThemeData theme, int x, int y) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: const SizedBox(
                width: 100,
                height: 20,
                child: ScaffoldOverflowFade(
                  fadeDirection: FadeDirection.left,
                  fadeExtent: 40,
                  child: ColoredBox(color: Color(0xFFFF0000)),
                ),
              ),
            ),
          ),
        ),
      );
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final int? alpha = await tester.runAsync(() async {
        final ui.Image image = await boundary.toImage();
        final ByteData? data = await image.toByteData();
        return data!.getUint8((y * image.width + x) * 4 + 3);
      });
      return alpha!;
    }

    testWidgets('nothing registered draws the built-in fade', (tester) async {
      final alpha = await alphaAt(
        tester,
        ThemeData(extensions: scaffoldThemeExtensions),
        20,
        10,
      );
      expect(alpha, inInclusiveRange(96, 160));
    });

    testWidgets('a registered edgeFade ramp changes the drawn fade', (tester) async {
      final alpha = await alphaAt(
        tester,
        ThemeData(
          extensions: [
            ...scaffoldThemeExtensions,
            const ScaffoldGradients(
              edgeFade: LinearGradient(
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0.0, 0.75, 1.0],
              ),
            ),
          ],
        ),
        20,
        10,
      );
      expect(alpha, lessThanOrEqualTo(24));
    });
  });
}
