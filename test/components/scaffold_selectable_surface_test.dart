import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/components/scaffold_selectable_surface.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
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
  testWidgets('unselected renders deepBlueCardColor Surface', (tester) async {
    await _pump(tester, const ScaffoldSelectableSurface(child: Text('x')));

    final Container container = tester.widget<Container>(
      find.descendant(
        of: find.byType(ScaffoldSurface),
        matching: find.byType(Container),
      ),
    );
    final BoxDecoration decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
  });

  testWidgets('selected shows 12% lightGreenPrimary overlay + 1px border', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldSelectableSurface(selected: true, child: Text('x')),
    );

    final AnimatedContainer animated = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ScaffoldSelectableSurface),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final BoxDecoration decoration = animated.decoration! as BoxDecoration;
    expect(
      decoration.border,
      Border.all(color: ScaffoldPalette.defaultPalette.lightGreenPrimary),
    );

    final ColoredBox overlay = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(ScaffoldSelectableSurface),
            matching: find.byType(ColoredBox),
          ),
        )
        .firstWhere(
          (ColoredBox b) =>
              b.color ==
              ScaffoldPalette.defaultPalette.lightGreenPrimary.withValues(
                alpha: 0.12,
              ),
        );
    expect(overlay.color, isNotNull);
  });

  testWidgets('focused shows FocusOutline ring', (tester) async {
    await _pump(
      tester,
      ScaffoldSelectableSurface(onTap: () {}, child: const Text('x')),
    );

    final Focus focus = tester.widget<Focus>(
      find.descendant(
        of: find.byType(ScaffoldSelectableSurface),
        matching: find.byType(Focus),
      ),
    );
    focus.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(ScaffoldFocusOutline),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('onTap fires and disabled blocks interaction', (tester) async {
    int taps = 0;
    await _pump(
      tester,
      ScaffoldSelectableSurface(onTap: () => taps++, child: const Text('x')),
    );
    await tester.tap(find.byType(ScaffoldSelectableSurface));
    await tester.pump();
    expect(taps, 1);

    taps = 0;
    await _pump(
      tester,
      ScaffoldSelectableSurface(
        disabled: true,
        onTap: () => taps++,
        child: const Text('x'),
      ),
    );
    expect(find.byType(ScaffoldDisabledOverlay), findsOneWidget);
    await tester.tap(find.byType(ScaffoldSelectableSurface), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('state transitions use medium duration and standard curve', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSelectableSurface(child: Text('x')));

    final AnimatedContainer animated = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ScaffoldSelectableSurface),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(animated.duration, const Duration(milliseconds: 300));
    expect(animated.curve, Curves.easeInOut);
  });
}
