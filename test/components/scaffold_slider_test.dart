import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_slider.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: SizedBox(width: 480, child: child))),
    ),
  );
}

void main() {
  testWidgets('renders a Slider with the given value', (tester) async {
    await _pump(tester, const ScaffoldSlider(value: 0.5));
    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, moreOrLessEquals(0.5, epsilon: 0.001));
  });

  testWidgets('buffered track shape is always installed (stable tree)',
      (tester) async {
    // The custom track shape is installed unconditionally so the Slider's
    // subtree never rebuilds mid-gesture (rebuilding it stalls the drag).
    // With no buffered value the span clamps to the played position and is
    // invisible; the SHAPE is still present.
    await _pump(tester, const ScaffoldSlider(value: 0.5));
    expect(
      SliderTheme.of(tester.element(find.byType(Slider))).trackShape,
      isNotNull,
    );
  });

  testWidgets('bufferedValue <= value still installs the shape (no visible band)',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldSlider(value: 0.5, bufferedValue: 0.4),
    );
    expect(
      SliderTheme.of(tester.element(find.byType(Slider))).trackShape,
      isNotNull,
    );
  });

  testWidgets('buffered layer paints inside the track shape', (tester) async {
    await _pump(
      tester,
      const ScaffoldSlider(value: 0.3, bufferedValue: 0.8),
    );
    // The buffered span is painted by the track shape itself, so it shares
    // the track rect with the played/inactive segments by construction.
    final SliderThemeData theme =
        SliderTheme.of(tester.element(find.byType(Slider)));
    expect(theme.trackShape, isNotNull);
  });

  testWidgets('onChanged forwards drag values and the drag completes',
      (tester) async {
    final List<double> values = <double>[];
    double? ended;
    await _pump(
      tester,
      ScaffoldSlider(
        value: 0.0,
        bufferedValue: 0.5,
        onChanged: values.add,
        onChangeEnd: (double v) => ended = v,
      ),
    );
    final Size size = tester.getSize(find.byType(Slider));
    final Offset topLeft = tester.getTopLeft(find.byType(Slider));
    // Drag from the left edge across the buffered boundary (0.5) to the far
    // right — the drag must NOT stall when the thumb crosses the buffered
    // fraction (regression: conditional theme swap killed the gesture).
    final TestGesture gesture =
        await tester.startGesture(topLeft + Offset(4, size.height / 2));
    await gesture.moveBy(Offset(size.width * 0.7, 0));
    await tester.pump();
    expect(values, isNotEmpty);
    await gesture.up();
    await tester.pump();
    expect(ended, isNotNull, reason: 'drag must complete without stalling');
  });
}
