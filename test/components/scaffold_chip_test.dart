import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_chip.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
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

Future<void> _pumpLight(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[
          ScaffoldPalette.lightPalette,
          ScaffoldDimens.defaultDimens,
        ],
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Locates the [ScaffoldSurface] that backs the chip (inside the pressable
/// stack) and returns its resolved decoration for color/border assertions.
Container _chipContainer(WidgetTester tester) {
  return tester.widget<Container>(
    find.descendant(
      of: find.byType(ScaffoldSurface),
      matching: find.byType(Container),
    ),
  );
}

void main() {
  // Test 1 — default chip renders label with labelMedium + deepBlueCardColor fill.
  testWidgets('default chip renders labelMedium text on deepBlueCardColor',
      (tester) async {
    await _pump(
      tester,
      ScaffoldChip(label: 'Chip', onPressed: () {}),
    );

    final Text label = tester.widget<Text>(find.text('Chip'));
    final BuildContext chipContext = tester.element(find.byType(ScaffoldChip));
    expect(label.style, Theme.of(chipContext).textTheme.labelMedium);

    final BoxDecoration decoration =
        _chipContainer(tester).decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
    expect(decoration.border, isNull);
  });

  // Test 2 — selected chip = 2px lightGreenPrimary BORDER, fill unchanged.
  testWidgets('selected chip adds 2px lightGreenPrimary border, fill unchanged',
      (tester) async {
    await _pump(
      tester,
      ScaffoldChip(label: 'Chip', selected: true, onPressed: () {}),
    );

    final BoxDecoration decoration =
        _chipContainer(tester).decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
    final Border border = decoration.border! as Border;
    expect(border.top.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);
    expect(border.top.width, 2.0);
    expect(border.bottom.color,
        ScaffoldPalette.defaultPalette.lightGreenPrimary);
    expect(border.bottom.width, 2.0);
  });

  // Test 3 — tapping fires onPressed exactly once.
  testWidgets('tapping the chip fires onPressed exactly once', (tester) async {
    int taps = 0;
    await _pump(
      tester,
      ScaffoldChip(label: 'Chip', onPressed: () => taps++),
    );

    await tester.tap(find.byType(ScaffoldChip));
    await tester.pump();
    expect(taps, 1);
  });

  // Test 4 — disabled chip does not fire onPressed and renders overlay.
  testWidgets('disabled chip blocks onPressed and renders DisabledOverlay',
      (tester) async {
    int taps = 0;
    await _pump(
      tester,
      ScaffoldChip(label: 'Chip', disabled: true, onPressed: () => taps++),
    );

    expect(find.byType(ScaffoldDisabledOverlay), findsOneWidget);

    await tester.tap(find.byType(ScaffoldChip));
    await tester.pump();
    expect(taps, 0);
  });

  // Test 5 — icon + label renders with space2 gap.
  testWidgets('icon + label renders icon then label with space2 gap',
      (tester) async {
    await _pump(
      tester,
      ScaffoldChip(label: 'Add', icon: Icons.add, onPressed: () {}),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    // Verify space2 gap sits between icon and label.
    final SizedBox gap = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(ScaffoldChip),
        matching: find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.width == ScaffoldDimens.defaultDimens.space2,
        ),
      ),
    );
    expect(gap.width, ScaffoldDimens.defaultDimens.space2);
  });

  // Test 6 — icon + label + status renders all three with space2 gaps.
  testWidgets('icon + label + status renders all three slots', (tester) async {
    await _pump(
      tester,
      ScaffoldChip(
        label: 'Active',
        icon: Icons.check,
        status: StatusVariant.success,
        onPressed: () {},
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byType(ScaffoldStatusIndicator), findsOneWidget);

    // Two space2 gaps: icon↔label and label↔status.
    final Iterable<SizedBox> gaps = tester.widgetList<SizedBox>(
      find.descendant(
        of: find.byType(ScaffoldChip),
        matching: find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.width == ScaffoldDimens.defaultDimens.space2,
        ),
      ),
    );
    expect(gaps.length, 2);
  });

  // Test 7 — icon-only chip asserts when semanticLabel is null.
  testWidgets('icon-only chip asserts when semanticLabel is null', (tester) async {
    expect(
      () => ScaffoldChip(icon: Icons.add, onPressed: () {}),
      throwsAssertionError,
    );
  });

  // Test 8 — icon-only chip with semanticLabel pumps and registers the label.
  testWidgets('icon-only chip with semanticLabel pumps and registers label',
      (tester) async {
    await _pump(
      tester,
      ScaffoldChip(
        icon: Icons.close,
        semanticLabel: 'Close',
        onPressed: () {},
      ),
    );

    expect(find.byType(ScaffoldChip), findsOneWidget);

    // The semantics tree must expose the "Close" label on a button node.
    final Semantics buttonSemantics = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(ScaffoldChip),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Close',
        ),
      ),
    ).first;
    expect(buttonSemantics.properties.label, 'Close');
  });

  // Test 9 — Semantics node reports button: true and selected matching flag.
  testWidgets('Semantics reports button:true and selected matches flag',
      (tester) async {
    await _pump(
      tester,
      ScaffoldChip(label: 'A', selected: true, onPressed: () {}),
    );

    final Semantics selectedNode = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(ScaffoldChip),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.selected == true,
        ),
      ),
    ).first;
    expect(selectedNode.properties.selected, isTrue);

    // Pressable supplies button: true.
    final Semantics buttonNode = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(ScaffoldChip),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.button == true,
        ),
      ),
    ).first;
    expect(buttonNode.properties.button, isTrue);
  });

  // Test 10 — renders under lightPalette without exception.
  testWidgets('renders under lightPalette without exception', (tester) async {
    await _pumpLight(
      tester,
      ScaffoldChip(label: 'Chip', selected: true, onPressed: () {}),
    );
    expect(find.byType(ScaffoldChip), findsOneWidget);
    expect(find.text('Chip'), findsOneWidget);
  });
}
