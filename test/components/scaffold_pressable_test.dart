import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
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
  testWidgets('renders child wrapped in TouchTarget + state layer', (tester) async {
    await _pump(
      tester,
      ScaffoldPressable(onPressed: () {}, child: const Text('press me')),
    );

    expect(find.byType(ScaffoldTouchTarget), findsOneWidget);
    expect(find.text('press me'), findsOneWidget);

    final AnimatedOpacity layer = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(ScaffoldPressable),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(layer.opacity, 0.0);

    final ColoredBox color = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(AnimatedOpacity),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(color.color, ScaffoldPalette.defaultPalette.textPrimary);
  });

  testWidgets('onPressed fires when tapped', (tester) async {
    int pressed = 0;
    await _pump(
      tester,
      ScaffoldPressable(onPressed: () => pressed++, child: const Text('x')),
    );

    await tester.tap(find.byType(ScaffoldPressable));
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('registers SemanticsRole.button and responds to Enter key', (
    tester,
  ) async {
    int pressed = 0;
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pump(
      tester,
      ScaffoldPressable(
        onPressed: () => pressed++,
        focusNode: focusNode,
        child: const Text('x'),
      ),
    );

    final Semantics semantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(ScaffoldPressable),
            matching: find.byType(Semantics),
          ),
        )
        .first;
    expect(semantics.properties.role, SemanticsRole.button);

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('disabled applies DisabledOverlay and blocks onPressed', (
    tester,
  ) async {
    int pressed = 0;
    await _pump(
      tester,
      ScaffoldPressable(
        disabled: true,
        onPressed: () => pressed++,
        child: const Text('x'),
      ),
    );

    expect(find.byType(ScaffoldDisabledOverlay), findsOneWidget);

    final Iterable<IgnorePointer> ignoring = tester
        .widgetList<IgnorePointer>(
          find.descendant(
            of: find.byType(ScaffoldPressable),
            matching: find.byType(IgnorePointer),
          ),
        )
        .where((IgnorePointer w) => w.ignoring);
    expect(ignoring, isNotEmpty);

    await tester.tap(find.byType(ScaffoldPressable));
    await tester.pump();
    expect(pressed, 0);
  });
}
