import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_drag_handle.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
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

List<Container> _lines(WidgetTester tester, Color color) {
  return tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(ScaffoldDragHandle),
          matching: find.byType(Container),
        ),
      )
      .where((Container c) => c.color == color)
      .toList();
}

void main() {
  testWidgets('renders 3 parallel lines at dragHandleSize width and 2px height', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldDragHandle());

    final Color lineColor = ScaffoldPalette.defaultPalette.textSecondary
        .withValues(alpha: 0.6);
    final List<Container> lines = _lines(tester, lineColor);
    expect(lines, hasLength(3));
    for (final Container line in lines) {
      expect(line.constraints?.maxWidth, ScaffoldDimens.defaultDimens.dragHandleSize);
      expect(line.constraints?.maxHeight, 2);
    }
  });

  testWidgets('wraps the grip in a 48px ScaffoldTouchTarget', (tester) async {
    await _pump(tester, const ScaffoldDragHandle());

    expect(
      find.descendant(
        of: find.byType(ScaffoldDragHandle),
        matching: find.byType(ScaffoldTouchTarget),
      ),
      findsOneWidget,
    );
  });

  testWidgets('registers "Drag to reorder" label', (tester) async {
    await _pump(tester, const ScaffoldDragHandle());

    final Semantics semantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(ScaffoldDragHandle),
            matching: find.byType(Semantics),
          ),
        )
        .firstWhere((Semantics s) => s.properties.label == 'Drag to reorder');
    expect(semantics.properties.label, 'Drag to reorder');
  });
}
