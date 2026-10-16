import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_checkbox.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_radio.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_toggle.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
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

Future<void> _pumpMidnight(
  WidgetTester tester,
  Brightness brightness,
  Widget child,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: midnightTheme(brightness),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

BoxDecoration _checkboxDecoration(WidgetTester tester) {
  final Container box = tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(ScaffoldSelectionIndicatorCheckbox),
          matching: find.byType(Container),
        ),
      )
      .firstWhere((Container c) => c.constraints?.maxWidth == 20);
  return box.decoration! as BoxDecoration;
}

Color? _markColor(WidgetTester tester, IconData icon) {
  return tester
      .widget<Icon>(
        find.descendant(
          of: find.byType(ScaffoldSelectionIndicatorCheckbox),
          matching: find.byIcon(icon),
        ),
      )
      .color;
}

void main() {
  testWidgets('checkbox with the default theme keeps today\'s look', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSelectionIndicatorCheckbox(value: true));

    final BoxDecoration decoration = _checkboxDecoration(tester);
    expect(decoration.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);
    expect(decoration.borderRadius, BorderRadius.circular(2));
    expect(
      decoration.border,
      Border.all(color: ScaffoldPalette.defaultPalette.textSecondary, width: 2),
    );
    expect(_markColor(tester, Icons.check), Colors.white);
  });

  testWidgets('default indeterminate checkbox has no fill and a white dash', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSelectionIndicatorCheckbox(value: null));

    expect(_checkboxDecoration(tester).color, isNull);
    expect(_markColor(tester, Icons.remove), Colors.white);
  });

  for (final Brightness brightness in Brightness.values) {
    final roles = brightness == Brightness.dark
        ? Midnight.darkColorRoles
        : Midnight.lightColorRoles;

    testWidgets('midnight $brightness checked checkbox takes the themed look', (
      tester,
    ) async {
      await _pumpMidnight(
        tester,
        brightness,
        const ScaffoldSelectionIndicatorCheckbox(value: true),
      );

      final BoxDecoration decoration = _checkboxDecoration(tester);
      expect(decoration.color, const Color(0xFF0AAEE6));
      expect(decoration.borderRadius, BorderRadius.circular(4));
      expect(
        decoration.border,
        Border.all(color: roles.accentOnSurface, width: 1.5),
      );
      expect(_markColor(tester, Icons.check), const Color(0xFF000B18));
    });

    testWidgets('midnight $brightness unchecked checkbox has no fill', (
      tester,
    ) async {
      await _pumpMidnight(
        tester,
        brightness,
        const ScaffoldSelectionIndicatorCheckbox(value: false),
      );

      final BoxDecoration decoration = _checkboxDecoration(tester);
      expect(decoration.color, isNull);
      expect(
        decoration.border,
        Border.all(color: roles.accentOnSurface, width: 1.5),
      );
    });

    testWidgets('midnight $brightness indeterminate dash sits on the fill', (
      tester,
    ) async {
      await _pumpMidnight(
        tester,
        brightness,
        const ScaffoldSelectionIndicatorCheckbox(value: null),
      );

      expect(_checkboxDecoration(tester).color, const Color(0xFF0AAEE6));
      expect(_markColor(tester, Icons.remove), const Color(0xFF000B18));
    });
  }
  testWidgets(
    'radio value=true renders filled inner circle in lightGreenPrimary',
    (tester) async {
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
    },
  );

  testWidgets(
    'checkbox value=true renders checkmark icon on lightGreenPrimary fill',
    (tester) async {
      await _pump(
        tester,
        const ScaffoldSelectionIndicatorCheckbox(value: true),
      );

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
    },
  );

  testWidgets(
    'toggle value=true renders lightGreenPrimary track with thumb at end',
    (tester) async {
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
    },
  );

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
