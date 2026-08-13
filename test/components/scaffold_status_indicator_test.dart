import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
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

Container _indicator(WidgetTester tester) {
  return tester.widget<Container>(
    find.descendant(
      of: find.byType(ScaffoldStatusIndicator),
      matching: find.byType(Container),
    ),
  );
}

void main() {
  testWidgets('success renders 12px circle in statusSuccess', (tester) async {
    await _pump(tester, const ScaffoldStatusIndicator(status: StatusVariant.success));

    final Container circle = _indicator(tester);
    expect(circle.constraints, const BoxConstraints.tightFor(width: 12, height: 12));
    final BoxDecoration decoration = circle.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, ScaffoldPalette.defaultPalette.statusSuccess);
  });

  testWidgets('warning renders in statusWarningText', (tester) async {
    await _pump(tester, const ScaffoldStatusIndicator(status: StatusVariant.warning));

    final BoxDecoration decoration = _indicator(tester).decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.statusWarningText);
  });

  testWidgets('error renders in statusError', (tester) async {
    await _pump(tester, const ScaffoldStatusIndicator(status: StatusVariant.error));

    final BoxDecoration decoration = _indicator(tester).decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.statusError);
  });

  testWidgets('info renders in blue500', (tester) async {
    await _pump(tester, const ScaffoldStatusIndicator(status: StatusVariant.info));

    final BoxDecoration decoration = _indicator(tester).decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.blue500);
  });

  testWidgets('neutral renders in textSecondary', (tester) async {
    await _pump(tester, const ScaffoldStatusIndicator(status: StatusVariant.neutral));

    final BoxDecoration decoration = _indicator(tester).decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.textSecondary);
  });

  testWidgets('registers SemanticsRole.status with configured label', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldStatusIndicator(status: StatusVariant.success, label: 'Connected'),
    );

    final Semantics semantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(ScaffoldStatusIndicator),
            matching: find.byType(Semantics),
          ),
        )
        .first;
    expect(semantics.properties.role, SemanticsRole.status);
    expect(semantics.properties.label, 'Connected');
  });
}
