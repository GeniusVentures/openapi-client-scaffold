import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_numeric_input_with_keypad.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Pumps the composable at [value] with bounds `0..20` and captures
/// [ScaffoldNumericInputWithKeypad.onChanged] into [changed].
Future<void> _pumpField(
  WidgetTester tester,
  num value, {
  int decimalPlaces = 0,
  num min = 0,
  num max = 20,
  required void Function(num v) onChanged,
}) {
  return _pump(
    tester,
    ScaffoldNumericInputWithKeypad(
      value: value,
      min: min,
      max: max,
      decimalPlaces: decimalPlaces,
      onChanged: onChanged,
    ),
  );
}

void main() {
  group('ScaffoldKeypadEntry (pure draft)', () {
    test('append digit concatenates', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('1');
      expect(entry.append('7').text, '17');
    });

    test('append decimal point rejected at decimalPlaces 0', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('1');
      expect(entry.append('.').text, '1');
    });

    test('second decimal point rejected', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('1.5', decimalPlaces: 2);
      expect(entry.append('.').text, '1.5');
    });

    test('fraction capped at decimalPlaces digits', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('1.23', decimalPlaces: 2);
      expect(entry.append('4').text, '1.23');
    });

    test('backspace deletes the last character', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('17');
      expect(entry.backspace().text, '1');
    });

    test('backspace on empty stays empty', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('');
      expect(entry.backspace().text, '');
    });

    test('clear empties the draft', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('17');
      expect(entry.clear().text, '');
    });

    test('parse reads the draft as num', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('1.5', decimalPlaces: 2);
      expect(entry.parse(), 1.5);
    });

    test('parse of empty draft is 0', () {
      const ScaffoldKeypadEntry entry = ScaffoldKeypadEntry('');
      expect(entry.parse(), 0);
    });
  });

  testWidgets('steppers still fire alongside the keypad', (tester) async {
    final List<num> changes = <num>[];
    await _pumpField(tester, 5, onChanged: changes.add);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(changes, <num>[6]);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(changes, <num>[6, 4]);
  });

  testWidgets('tap value -> sheet; digits 1, 2, Apply -> onChanged(12)', (
    tester,
  ) async {
    num? changed;
    await _pumpField(tester, 5, onChanged: (num v) => changed = v);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(changed, 12);
  });

  testWidgets('out-of-range draft clamps at the commit edge (500 -> 20)', (
    tester,
  ) async {
    num? changed;
    await _pumpField(tester, 5, max: 20, onChanged: (num v) => changed = v);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(changed, 20, reason: 'clamped, not rejected');
  });

  testWidgets('decimalPlaces 0 renders no decimal key', (tester) async {
    await _pumpField(tester, 5, onChanged: (_) {});

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('.'), findsNothing);
  });

  testWidgets('decimalPlaces 2 accepts 1.5 -> onChanged(1.5)', (tester) async {
    num? changed;
    await _pumpField(
      tester,
      5,
      decimalPlaces: 2,
      onChanged: (num v) => changed = v,
    );

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('.'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(changed, 1.5);
  });

  testWidgets('barrier dismiss fires no onChanged', (tester) async {
    num? changed;
    await _pumpField(tester, 5, onChanged: (num v) => changed = v);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(changed, isNull);
  });

  testWidgets('disabled opens nothing on value tap', (tester) async {
    num? changed;
    await _pump(
      tester,
      ScaffoldNumericInputWithKeypad(
        value: 5,
        min: 0,
        max: 20,
        disabled: true,
        onChanged: (num v) => changed = v,
      ),
    );

    await tester.tap(find.text('5'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(changed, isNull);
  });

  testWidgets('Clear empties the draft inside the sheet', (tester) async {
    num? changed;
    await _pumpField(tester, 5, onChanged: (num v) => changed = v);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(changed, 7);
  });

  testWidgets('backspace edits the draft inside the sheet', (tester) async {
    num? changed;
    await _pumpField(tester, 5, onChanged: (num v) => changed = v);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(changed, 1);
  });
}
