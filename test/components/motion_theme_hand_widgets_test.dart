import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_drop_target.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_scroll_edge_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_selectable_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_motion_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

const ScaffoldMotionTheme _custom = ScaffoldMotionTheme(
  short: Duration(milliseconds: 777),
  medium: Duration(milliseconds: 888),
  standard: Curves.linear,
  decelerate: Curves.bounceIn,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ScaffoldMotionTheme? motion,
}) {
  final List<ThemeExtension<dynamic>> extensions =
      List<ThemeExtension<dynamic>>.of(scaffoldThemeExtensions);
  if (motion != null) {
    extensions.add(motion);
  }
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: extensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

T _in<T extends Widget>(WidgetTester tester, Type owner) {
  return tester.widget<T>(
    find.descendant(of: find.byType(owner), matching: find.byType(T)),
  );
}

void main() {
  group('pressable, selectable surface, drop target', () {
    testWidgets('registered motion drives ScaffoldPressable', (tester) async {
      await _pump(
        tester,
        ScaffoldPressable(onPressed: () {}, child: const Text('x')),
        motion: _custom,
      );
      final AnimatedOpacity layer = _in<AnimatedOpacity>(
        tester,
        ScaffoldPressable,
      );
      expect(layer.duration, const Duration(milliseconds: 777));
      expect(layer.curve, Curves.linear);
    });

    testWidgets('default motion drives ScaffoldPressable', (tester) async {
      await _pump(
        tester,
        ScaffoldPressable(onPressed: () {}, child: const Text('x')),
      );
      final AnimatedOpacity layer = _in<AnimatedOpacity>(
        tester,
        ScaffoldPressable,
      );
      expect(layer.duration, const Duration(milliseconds: 150));
      expect(layer.curve, Curves.easeInOut);
    });

    testWidgets('registered motion drives ScaffoldSelectableSurface', (
      tester,
    ) async {
      await _pump(
        tester,
        const ScaffoldSelectableSurface(child: Text('x')),
        motion: _custom,
      );
      final AnimatedContainer c = _in<AnimatedContainer>(
        tester,
        ScaffoldSelectableSurface,
      );
      expect(c.duration, const Duration(milliseconds: 888));
      expect(c.curve, Curves.linear);
    });

    testWidgets('default motion drives ScaffoldSelectableSurface', (
      tester,
    ) async {
      await _pump(tester, const ScaffoldSelectableSurface(child: Text('x')));
      final AnimatedContainer c = _in<AnimatedContainer>(
        tester,
        ScaffoldSelectableSurface,
      );
      expect(c.duration, const Duration(milliseconds: 300));
      expect(c.curve, Curves.easeInOut);
    });

    testWidgets('registered motion drives ScaffoldDropTarget', (tester) async {
      await _pump(
        tester,
        ScaffoldDropTarget(child: const SizedBox(width: 100, height: 50)),
        motion: _custom,
      );
      final AnimatedContainer c = _in<AnimatedContainer>(
        tester,
        ScaffoldDropTarget,
      );
      expect(c.duration, const Duration(milliseconds: 888));
      expect(c.curve, Curves.linear);
    });

    testWidgets('default motion drives ScaffoldDropTarget', (tester) async {
      await _pump(
        tester,
        ScaffoldDropTarget(child: const SizedBox(width: 100, height: 50)),
      );
      final AnimatedContainer c = _in<AnimatedContainer>(
        tester,
        ScaffoldDropTarget,
      );
      expect(c.duration, const Duration(milliseconds: 300));
      expect(c.curve, Curves.easeInOut);
    });
  });

  group('scroll edge indicator', () {
    Future<void> pumpIndicator(
      WidgetTester tester,
      ScrollController controller, {
      ScaffoldMotionTheme? motion,
    }) {
      return _pump(
        tester,
        SizedBox(
          height: 400,
          width: 400,
          child: Stack(
            children: <Widget>[
              SingleChildScrollView(
                controller: controller,
                child: const SizedBox(height: 2000, width: double.infinity),
              ),
              Positioned.fill(
                child: ScaffoldScrollEdgeIndicator(scrollController: controller),
              ),
            ],
          ),
        ),
        motion: motion,
      );
    }

    AnimatedOpacity edge(WidgetTester tester, String key) =>
        tester.widget<AnimatedOpacity>(find.byKey(Key(key)));

    testWidgets('registered motion drives both edges', (tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpIndicator(tester, controller, motion: _custom);
      for (final String key in <String>[
        'scroll_edge_start',
        'scroll_edge_end',
      ]) {
        expect(edge(tester, key).duration, const Duration(milliseconds: 777));
        expect(edge(tester, key).curve, Curves.linear);
      }
    });

    testWidgets('default motion drives both edges', (tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpIndicator(tester, controller);
      for (final String key in <String>[
        'scroll_edge_start',
        'scroll_edge_end',
      ]) {
        expect(edge(tester, key).duration, const Duration(milliseconds: 150));
        expect(edge(tester, key).curve, Curves.easeInOut);
      }
    });
  });
}
