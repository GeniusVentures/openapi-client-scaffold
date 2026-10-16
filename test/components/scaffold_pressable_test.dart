import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
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

const _hoverFill = Color(0x1414C8FF);
const _hoverEdge = Color(0x3D14C8FF);
const _radius = BorderRadius.all(Radius.circular(12));

Future<void> _pumpWithRoles(
  WidgetTester tester,
  ScaffoldColorRoles roles, {
  BorderRadiusGeometry? borderRadius,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [...scaffoldThemeExtensions, roles]),
      home: Scaffold(
        body: Center(
          child: ScaffoldPressable(
            onPressed: () {},
            borderRadius: borderRadius,
            child: const Text('x'),
          ),
        ),
      ),
    ),
  );
}

Future<TestGesture> _hover(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: Offset.zero);
  await gesture.moveTo(tester.getCenter(find.byType(ScaffoldPressable)));
  await tester.pumpAndSettle();
  return gesture;
}

Finder _hoverDecoration() => find.descendant(
  of: find.byType(ScaffoldPressable),
  matching: find.byType(DecoratedBox),
);

Finder _textPrimaryLayer() => find.descendant(
  of: find.byType(ScaffoldPressable),
  matching: find.byWidgetPredicate(
    (w) =>
        w is ColoredBox &&
        w.color == ScaffoldPalette.defaultPalette.textPrimary,
  ),
);

double _opacityAbove(WidgetTester tester, Finder child) {
  return tester
      .widget<AnimatedOpacity>(
        find.ancestor(of: child, matching: find.byType(AnimatedOpacity)).first,
      )
      .opacity;
}

void main() {
  testWidgets('renders child wrapped in TouchTarget + state layer', (
    tester,
  ) async {
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

  testWidgets('registers button semantics and responds to Enter key', (
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
        .firstWhere((Semantics s) => s.properties.button == true);
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.enabled, isTrue);

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

    await tester.tap(find.byType(ScaffoldPressable), warnIfMissed: false);
    await tester.pump();
    expect(pressed, 0);
  });

  group('hover treatment', () {
    testWidgets('default theme: hover shows the 8% textPrimary layer', (
      tester,
    ) async {
      await _pump(
        tester,
        ScaffoldPressable(onPressed: () {}, child: const Text('x')),
      );
      expect(_hoverDecoration(), findsNothing);
      await _hover(tester);
      expect(_hoverDecoration(), findsNothing);
      expect(_opacityAbove(tester, _textPrimaryLayer()), 0.08);
    });

    testWidgets('default theme ignores borderRadius', (tester) async {
      await _pump(
        tester,
        ScaffoldPressable(
          onPressed: () {},
          borderRadius: _radius,
          child: const Text('x'),
        ),
      );
      await _hover(tester);
      expect(_hoverDecoration(), findsNothing);
      expect(_opacityAbove(tester, _textPrimaryLayer()), 0.08);
    });

    testWidgets('roles set: hover paints fill, edge and radius', (
      tester,
    ) async {
      await _pumpWithRoles(
        tester,
        const ScaffoldColorRoles(hoverFill: _hoverFill, hoverEdge: _hoverEdge),
        borderRadius: _radius,
      );
      final decoration = find.descendant(
        of: find.byType(ScaffoldPressable),
        matching: find.byType(DecoratedBox),
      );
      expect(_opacityAbove(tester, decoration), 0.0);

      await _hover(tester);

      final box =
          tester.widget<DecoratedBox>(decoration).decoration as BoxDecoration;
      expect(box.color, _hoverFill);
      expect(box.borderRadius, _radius);
      final border = box.border! as Border;
      expect(border.top.color, _hoverEdge);
      expect(border.top.width, 1);
      expect(_opacityAbove(tester, decoration), 1.0);
      expect(_opacityAbove(tester, _textPrimaryLayer()), 0.0);
    });

    testWidgets('roles set: hover paints no edge when hoverEdge is null', (
      tester,
    ) async {
      await _pumpWithRoles(
        tester,
        const ScaffoldColorRoles(hoverFill: _hoverFill),
      );
      await _hover(tester);
      final box =
          tester.widget<DecoratedBox>(_hoverDecoration()).decoration
              as BoxDecoration;
      expect(box.color, _hoverFill);
      expect(box.border, isNull);
      expect(box.borderRadius, isNull);
    });

    testWidgets('roles set: pressed adds the 12% textPrimary layer', (
      tester,
    ) async {
      await _pumpWithRoles(
        tester,
        const ScaffoldColorRoles(hoverFill: _hoverFill, hoverEdge: _hoverEdge),
      );
      final gesture = await _hover(tester);
      await gesture.down(tester.getCenter(find.byType(ScaffoldPressable)));
      await tester.pumpAndSettle();
      expect(_opacityAbove(tester, _textPrimaryLayer()), 0.12);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_opacityAbove(tester, _textPrimaryLayer()), 0.0);
    });
  });
}
