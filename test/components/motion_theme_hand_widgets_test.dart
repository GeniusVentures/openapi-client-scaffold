import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/components/scaffold_drop_target.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_scroll_edge_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_selectable_surface.dart';
import 'package:frontend_scaffold/components/scaffold_selection_actions.dart';
import 'package:frontend_scaffold/components/scaffold_selection_copy_action.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_copy_button.dart';
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
  bool reducedMotion = false,
}) {
  final List<ThemeExtension<dynamic>> extensions =
      List<ThemeExtension<dynamic>>.of(scaffoldThemeExtensions);
  if (motion != null) {
    extensions.add(motion);
  }
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: extensions),
      home: ScaffoldMotion(
        reducedMotion: reducedMotion,
        child: Scaffold(body: Center(child: child)),
      ),
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

  group('disclosure', () {
    Widget disclosure() => const ScaffoldDisclosure(
      title: 'Header',
      initiallyExpanded: true,
      body: Text('Body'),
    );

    testWidgets('registered motion drives rotation and size', (tester) async {
      await _pump(tester, disclosure(), motion: _custom);
      final AnimatedRotation rotation = _in<AnimatedRotation>(
        tester,
        ScaffoldDisclosure,
      );
      final AnimatedSize size = _in<AnimatedSize>(tester, ScaffoldDisclosure);
      expect(rotation.duration, const Duration(milliseconds: 777));
      expect(rotation.curve, Curves.linear);
      expect(size.duration, const Duration(milliseconds: 888));
      expect(size.curve, Curves.linear);
    });

    testWidgets('default motion drives rotation and size', (tester) async {
      await _pump(tester, disclosure());
      final AnimatedRotation rotation = _in<AnimatedRotation>(
        tester,
        ScaffoldDisclosure,
      );
      final AnimatedSize size = _in<AnimatedSize>(tester, ScaffoldDisclosure);
      expect(rotation.duration, const Duration(milliseconds: 150));
      expect(rotation.curve, Curves.easeInOut);
      expect(size.duration, const Duration(milliseconds: 300));
      expect(size.curve, Curves.easeInOut);
    });

    testWidgets('reduced motion still yields zero durations', (tester) async {
      await _pump(tester, disclosure(), motion: _custom, reducedMotion: true);
      expect(
        _in<AnimatedRotation>(tester, ScaffoldDisclosure).duration,
        Duration.zero,
      );
      expect(
        _in<AnimatedSize>(tester, ScaffoldDisclosure).duration,
        Duration.zero,
      );
    });
  });

  group('selection actions toolbar', () {
    Future<AnimatedOpacity> toolbarFade(
      WidgetTester tester, {
      ScaffoldMotionTheme? motion,
      bool reducedMotion = false,
    }) async {
      await _pump(
        tester,
        ScaffoldSelectionActions(
          toolbarBuilder: (BuildContext c, TextSelection s, String t) =>
              const Text('toolbar'),
          child: const SelectableText('hello world'),
        ),
        motion: motion,
        reducedMotion: reducedMotion,
      );
      final dynamic state = tester.state(find.byType(ScaffoldSelectionActions));
      // ignore: invalid_use_of_visible_for_testing_member
      ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
      await tester.pump();
      await tester.pump();
      return tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    }

    testWidgets('registered motion drives the toolbar fade', (tester) async {
      final AnimatedOpacity fade = await toolbarFade(tester, motion: _custom);
      expect(fade.duration, const Duration(milliseconds: 777));
      expect(fade.curve, Curves.bounceIn);
    });

    testWidgets('default motion drives the toolbar fade', (tester) async {
      final AnimatedOpacity fade = await toolbarFade(tester);
      expect(fade.duration, const Duration(milliseconds: 150));
      expect(fade.curve, Curves.easeOut);
    });

    testWidgets('reduced motion still yields a zero toolbar fade', (
      tester,
    ) async {
      final AnimatedOpacity fade = await toolbarFade(
        tester,
        motion: _custom,
        reducedMotion: true,
      );
      expect(fade.duration, Duration.zero);
    });
  });

  group('copy buttons', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (MethodCall call) async => null,
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final Map<String, Widget Function()> buttons = <String, Widget Function()>{
      'ScaffoldSelectionCopyAction': () =>
          const ScaffoldSelectionCopyAction(selectedText: 'payload'),
      'ScaffoldStreamingCopyButton': () =>
          const ScaffoldStreamingCopyButton(textToCopy: 'payload'),
    };

    AnimatedSwitcher switcher(WidgetTester tester) =>
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));

    bool showsCheck(WidgetTester tester) =>
        (switcher(tester).child! as Icon).key == const ValueKey<bool>(true);

    for (final MapEntry<String, Widget Function()> entry in buttons.entries) {
      testWidgets('${entry.key} reverts after the registered medium', (
        tester,
      ) async {
        await _pump(tester, entry.value(), motion: _custom);
        expect(switcher(tester).duration, const Duration(milliseconds: 888));

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        expect(showsCheck(tester), isTrue);

        await tester.pump(const Duration(milliseconds: 800));
        expect(showsCheck(tester), isTrue);

        await tester.pump(const Duration(milliseconds: 100));
        expect(showsCheck(tester), isFalse);
        await tester.pump(const Duration(seconds: 1));
      });

      testWidgets('${entry.key} reverts after 300 ms by default', (
        tester,
      ) async {
        await _pump(tester, entry.value());
        expect(switcher(tester).duration, const Duration(milliseconds: 300));

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        expect(showsCheck(tester), isTrue);

        await tester.pump(const Duration(milliseconds: 250));
        expect(showsCheck(tester), isTrue);

        await tester.pump(const Duration(milliseconds: 100));
        expect(showsCheck(tester), isFalse);
        await tester.pump(const Duration(seconds: 1));
      });

      testWidgets('${entry.key} reduced motion keeps a zero switch', (
        tester,
      ) async {
        await _pump(
          tester,
          entry.value(),
          motion: _custom,
          reducedMotion: true,
        );
        expect(switcher(tester).duration, Duration.zero);
        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });
}
