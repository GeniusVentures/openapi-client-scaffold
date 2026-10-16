import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_selectable_surface.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
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

void _noop() {}

void main() {
  testWidgets('selection tint follows the accent role', (tester) async {
    const accent = Color(0xFF123456);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            ...scaffoldThemeExtensions,
            const ScaffoldColorRoles(accent: accent),
          ],
        ),
        home: const Scaffold(
          body: Center(
            child: ScaffoldSelectableSurface(selected: true, child: Text('x')),
          ),
        ),
      ),
    );

    final Iterable<Color> tints = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(ScaffoldSelectableSurface),
            matching: find.byType(ColoredBox),
          ),
        )
        .map((ColoredBox b) => b.color);
    expect(tints, contains(accent.withValues(alpha: 0.12)));
  });

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
    await tester.tap(
      find.byType(ScaffoldSelectableSurface),
      warnIfMissed: false,
    );
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

  testWidgets(
    'midnight: hovering ScaffoldSelectableSurface clips the hover treatment to its radius',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: midnightTheme(Brightness.dark),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                child: ScaffoldSelectableSurface(
                  onTap: _noop,
                  child: Text('x'),
                ),
              ),
            ),
          ),
        ),
      );
      final pressable = tester.widget<ScaffoldPressable>(
        find.byType(ScaffoldPressable),
      );
      expect(
        pressable.borderRadius,
        BorderRadius.circular(Midnight.dimens.borderRadiusCard),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byType(ScaffoldPressable)));
      await tester.pumpAndSettle();

      final box =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(ScaffoldPressable),
                      matching: find.byWidgetPredicate(
                        (w) =>
                            w is DecoratedBox &&
                            w.decoration is BoxDecoration &&
                            (w.decoration as BoxDecoration).color ==
                                Midnight.darkColorRoles.hoverFill,
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(
        box.borderRadius,
        BorderRadius.circular(Midnight.dimens.borderRadiusCard),
      );
      expect(
        (box.border! as Border).top.color,
        Midnight.darkColorRoles.hoverEdge,
      );
    },
  );
}
