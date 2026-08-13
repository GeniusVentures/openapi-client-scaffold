import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_resize_handle.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
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
  testWidgets('horizontal renders a horizontal stripe', (tester) async {
    await _pump(
      tester,
      const ScaffoldResizeHandle(direction: ResizeDirection.horizontal),
    );

    final Container stripe = tester.widget<Container>(
      find.descendant(
        of: find.byType(ScaffoldResizeHandle),
        matching: find.byType(Container),
      ),
    );
    expect(stripe.constraints?.maxWidth, ScaffoldDimens.defaultDimens.dragHandleSize);
    expect(stripe.constraints?.maxHeight, 2);
  });

  testWidgets('both renders an L-shaped corner grip', (tester) async {
    await _pump(
      tester,
      const ScaffoldResizeHandle(direction: ResizeDirection.both),
    );

    expect(
      find.descendant(
        of: find.byType(ScaffoldResizeHandle),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('registers dragHandle role with "Drag to resize" label', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldResizeHandle());

    final Semantics semantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(ScaffoldResizeHandle),
            matching: find.byType(Semantics),
          ),
        )
        .firstWhere((Semantics s) => s.properties.role == SemanticsRole.dragHandle);
    expect(semantics.properties.label, 'Drag to resize');
  });
}
