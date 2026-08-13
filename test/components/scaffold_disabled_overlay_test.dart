import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
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

void main() {
  testWidgets('renders child normally when disabled=false', (tester) async {
    await _pump(
      tester,
      const ScaffoldDisabledOverlay(disabled: false, child: Text('hello')),
    );

    expect(find.text('hello'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ScaffoldDisabledOverlay),
        matching: find.byType(IgnorePointer),
      ),
      findsNothing,
    );
  });

  testWidgets('renders dim overlay + IgnorePointer when disabled=true', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldDisabledOverlay(disabled: true, child: Text('hello')),
    );

    final IgnorePointer pointer = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(ScaffoldDisabledOverlay),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(pointer.ignoring, isTrue);

    final ColoredBox overlay = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(ScaffoldDisabledOverlay),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(
      overlay.color,
      ScaffoldPalette.defaultPalette.disabledOverlayColor.withValues(
        alpha: ScaffoldDimens.defaultDimens.disabledOverlayOpacity,
      ),
    );
  });

  testWidgets('reason sets Semantics tooltip', (tester) async {
    await _pump(
      tester,
      const ScaffoldDisabledOverlay(
        disabled: true,
        reason: 'Needs upgrade',
        child: Text('hello'),
      ),
    );

    final Semantics semantics = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .firstWhere((Semantics s) => s.properties.tooltip == 'Needs upgrade');
    expect(semantics.properties.tooltip, 'Needs upgrade');
  });
}
