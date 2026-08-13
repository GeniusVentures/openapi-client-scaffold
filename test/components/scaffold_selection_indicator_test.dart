import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_checkbox.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_radio.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_toggle.dart';
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

Container _filledContainer(WidgetTester tester, Finder root, Color color) {
  return tester
      .widgetList<Container>(
        find.descendant(of: root, matching: find.byType(Container)),
      )
      .firstWhere((Container c) {
        final Decoration? decoration = c.decoration;
        return decoration is BoxDecoration && decoration.color == color;
      });
}

void main() {
  testWidgets('radio value=true renders filled inner circle in lightGreenPrimary', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSelectionIndicatorRadio(value: true));

    final Container inner = _filledContainer(
      tester,
      find.byType(ScaffoldSelectionIndicatorRadio),
      ScaffoldPalette.defaultPalette.lightGreenPrimary,
    );
    expect(
      inner.constraints,
      const BoxConstraints.tightFor(width: 12, height: 12),
    );
    expect((inner.decoration! as BoxDecoration).shape, BoxShape.circle);
  });

  testWidgets('checkbox value=true renders checkmark icon on lightGreenPrimary fill', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSelectionIndicatorCheckbox(value: true));

    expect(
      find.descendant(
        of: find.byType(ScaffoldSelectionIndicatorCheckbox),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );

    final Container fill = _filledContainer(
      tester,
      find.byType(ScaffoldSelectionIndicatorCheckbox),
      ScaffoldPalette.defaultPalette.lightGreenPrimary,
    );
    expect(fill, isNotNull);
  });

  testWidgets('toggle value=true renders lightGreenPrimary track with thumb at end', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSelectionIndicatorToggle(value: true));

    final Container track = _filledContainer(
      tester,
      find.byType(ScaffoldSelectionIndicatorToggle),
      ScaffoldPalette.defaultPalette.lightGreenPrimary,
    );
    expect(track, isNotNull);

    final AnimatedPositioned thumb = tester.widget<AnimatedPositioned>(
      find.descendant(
        of: find.byType(ScaffoldSelectionIndicatorToggle),
        matching: find.byType(AnimatedPositioned),
      ),
    );
    expect(thumb.left, 18.0);
  });

  testWidgets('tapping fires onChanged with toggled value', (tester) async {
    bool? changed;
    await _pump(
      tester,
      ScaffoldSelectionIndicatorRadio(
        value: false,
        onChanged: (bool v) => changed = v,
      ),
    );

    await tester.tap(find.byType(ScaffoldSelectionIndicatorRadio));
    await tester.pump();
    expect(changed, true);
  });

  testWidgets('disabled blocks interaction and applies 0.4 opacity', (
    tester,
  ) async {
    bool? changed;
    await _pump(
      tester,
      ScaffoldSelectionIndicatorToggle(
        value: false,
        disabled: true,
        onChanged: (bool v) => changed = v,
      ),
    );

    final Opacity opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(ScaffoldSelectionIndicatorToggle),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.4);

    await tester.tap(
      find.byType(ScaffoldSelectionIndicatorToggle),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(changed, isNull);
  });
}
