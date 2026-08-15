import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/components/scaffold_numeric_input.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
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
  testWidgets('renders value in bodyLarge between decrement/increment buttons', (
    tester,
  ) async {
    await _pump(tester, ScaffoldNumericInput(value: 5, onChanged: (_) {}));

    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    final Text text = tester.widget<Text>(find.text('5'));
    final BuildContext context = tester.element(
      find.byType(ScaffoldNumericInput),
    );
    expect(text.style, Theme.of(context).textTheme.bodyLarge);
  });

  testWidgets('increment fires onChanged with value + step', (tester) async {
    num? changed;
    await _pump(
      tester,
      ScaffoldNumericInput(value: 5, onChanged: (num v) => changed = v),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(changed, 6);
  });

  testWidgets('decrement at min=0 does not fire below 0', (tester) async {
    num? changed;
    await _pump(
      tester,
      ScaffoldNumericInput(value: 0, min: 0, onChanged: (num v) => changed = v),
    );

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(changed, isNull);
  });

  testWidgets('increment at max=10 does not fire above 10', (tester) async {
    num? changed;
    await _pump(
      tester,
      ScaffoldNumericInput(
        value: 10,
        max: 10,
        onChanged: (num v) => changed = v,
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(changed, isNull);
  });

  testWidgets('increment clamps a step that crosses max', (tester) async {
    num? changed;
    await _pump(
      tester,
      ScaffoldNumericInput(
        value: 9,
        step: 2,
        max: 10,
        onChanged: (num v) => changed = v,
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(changed, 10);
  });

  testWidgets('decrement clamps a step that crosses min', (tester) async {
    num? changed;
    await _pump(
      tester,
      ScaffoldNumericInput(
        value: 1,
        step: 2,
        min: 0,
        onChanged: (num v) => changed = v,
      ),
    );

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(changed, 0);
  });

  testWidgets('value formats to decimalPlaces=2 as "5.00"', (tester) async {
    await _pump(
      tester,
      ScaffoldNumericInput(value: 5, decimalPlaces: 2, onChanged: (_) {}),
    );

    expect(find.text('5.00'), findsOneWidget);
  });

  testWidgets('increment quantizes floating-point sums to decimalPlaces', (
    tester,
  ) async {
    num? changed;
    await _pump(
      tester,
      ScaffoldNumericInput(
        value: 0.1,
        step: 0.2,
        decimalPlaces: 1,
        onChanged: (num v) => changed = v,
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(changed, 0.3);
  });

  testWidgets('error renders statusError tint on value text', (tester) async {
    await _pump(
      tester,
      ScaffoldNumericInput(value: 5, error: 'Invalid', onChanged: (_) {}),
    );

    final Text text = tester.widget<Text>(find.text('5'));
    expect(text.style?.color, ScaffoldPalette.defaultPalette.statusError);
  });

  testWidgets('disabled blocks increment/decrement via DisabledOverlay', (
    tester,
  ) async {
    num? changed;
    await _pump(
      tester,
      ScaffoldNumericInput(
        value: 5,
        disabled: true,
        onChanged: (num v) => changed = v,
      ),
    );

    expect(find.byType(ScaffoldDisabledOverlay), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
    await tester.pump();
    expect(changed, isNull);
  });

  testWidgets('announces value via LiveRegion and labels buttons', (
    tester,
  ) async {
    await _pump(tester, ScaffoldNumericInput(value: 5, onChanged: (_) {}));

    final ScaffoldLiveRegion liveRegion = tester.widget<ScaffoldLiveRegion>(
      find.descendant(
        of: find.byType(ScaffoldNumericInput),
        matching: find.byType(ScaffoldLiveRegion),
      ),
    );
    expect(liveRegion.value, '5');

    final List<String?> labels = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(ScaffoldNumericInput),
            matching: find.byType(Semantics),
          ),
        )
        .where((Semantics s) => s.properties.button == true)
        .map((Semantics s) => s.properties.label)
        .toList();
    expect(labels, contains('Increment'));
    expect(labels, contains('Decrement'));
  });
}
