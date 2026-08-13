import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool accessibleNavigation = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(accessibleNavigation: accessibleNavigation),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}

Finder _ringPaint() => find.descendant(
      of: find.byType(ScaffoldFocusOutline),
      matching: find.byType(CustomPaint),
    );

void main() {
  testWidgets('renders ring when focused with keyboard', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pump(
      tester,
      ScaffoldFocusOutline(
        focusNode: focusNode,
        child: Focus(focusNode: focusNode, child: const Text('x')),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(
      FocusManager.instance.highlightMode,
      FocusHighlightMode.traditional,
    );
    expect(_ringPaint(), findsOneWidget);
  });

  testWidgets('no ring when not focused', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pump(
      tester,
      ScaffoldFocusOutline(
        focusNode: focusNode,
        child: Focus(focusNode: focusNode, child: const Text('x')),
      ),
    );
    await tester.pump();

    expect(_ringPaint(), findsNothing);
  });

  testWidgets('renders ring when accessibleNavigation even without keyboard', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pump(
      tester,
      ScaffoldFocusOutline(
        focusNode: focusNode,
        child: Focus(focusNode: focusNode, child: const Text('x')),
      ),
      accessibleNavigation: true,
    );

    focusNode.requestFocus();
    await tester.pump();

    expect(_ringPaint(), findsOneWidget);
  });

  testWidgets('ring uses focusRingColor and focusRingWidth tokens', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pump(
      tester,
      ScaffoldFocusOutline(
        focusNode: focusNode,
        child: Focus(focusNode: focusNode, child: const Text('x')),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    final paint = tester.widget<CustomPaint>(_ringPaint());
    final painter = paint.painter! as ScaffoldFocusRingPainter;
    expect(painter.color, ScaffoldPalette.defaultPalette.focusRingColor);
    expect(painter.strokeWidth, ScaffoldDimens.defaultDimens.focusRingWidth);
  });
}
