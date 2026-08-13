import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_overflow_fade.dart';
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
}
