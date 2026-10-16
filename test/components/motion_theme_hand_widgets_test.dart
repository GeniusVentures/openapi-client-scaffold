import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_code_block.dart';
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/components/scaffold_drop_target.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_scroll_edge_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_selectable_surface.dart';
import 'package:frontend_scaffold/components/scaffold_selection_actions.dart';
import 'package:frontend_scaffold/components/scaffold_selection_copy_action.dart';
import 'package:frontend_scaffold/components/scaffold_skeleton.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_copy_button.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_rich_text.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_rich_text_cubit.dart';
import 'package:frontend_scaffold/theme/scaffold_motion_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_typography.dart';
import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';

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
  ScaffoldTypography? typography,
}) {
  final List<ThemeExtension<dynamic>> extensions =
      List<ThemeExtension<dynamic>>.of(scaffoldThemeExtensions);
  if (motion != null) {
    extensions.add(motion);
  }
  if (typography != null) {
    extensions.add(typography);
  }
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: extensions),
      themeAnimationDuration: Duration.zero,
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

  group('code block, streaming rich text and skeleton', () {
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

    const ScaffoldTypography courier = ScaffoldTypography(
      monoFontFamily: 'Courier',
    );

    Set<String> families(WidgetTester tester, Type owner) {
      final Set<String> result = <String>{};
      for (final RichText rich in tester.widgetList<RichText>(
        find.descendant(of: find.byType(owner), matching: find.byType(RichText)),
      )) {
        rich.text.visitChildren((InlineSpan span) {
          final String? family = span.style?.fontFamily;
          if (family != null) {
            result.add(family);
          }
          return true;
        });
      }
      return result;
    }

    const Widget codeBlock = ScaffoldCodeBlock(
      lines: <ScaffoldCodeLine>[ScaffoldCodeLine(rawText: 'void main() {}')],
    );

    testWidgets('code block uses the registered mono family', (tester) async {
      await _pump(tester, codeBlock, typography: courier);
      expect(families(tester, ScaffoldCodeBlock), contains('Courier'));
      expect(families(tester, ScaffoldCodeBlock), isNot(contains('monospace')));
    });

    testWidgets('code block defaults to monospace', (tester) async {
      await _pump(tester, codeBlock);
      expect(families(tester, ScaffoldCodeBlock), contains('monospace'));
    });

    testWidgets('code block copy feedback reverts after the registered medium', (
      tester,
    ) async {
      await _pump(tester, codeBlock, motion: _custom);
      AnimatedSwitcher switcher() =>
          tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
      bool showsCheck() =>
          (switcher().child! as Icon).key == const ValueKey<bool>(true);

      expect(switcher().duration, const Duration(milliseconds: 888));
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();
      expect(showsCheck(), isTrue);
      await tester.pump(const Duration(milliseconds: 800));
      expect(showsCheck(), isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(showsCheck(), isFalse);
      await tester.pump(const Duration(seconds: 1));
    });

    Future<void> pumpRichText(
      WidgetTester tester, {
      ScaffoldMotionTheme? motion,
      ScaffoldTypography? typography,
    }) async {
      final ScaffoldStreamingRichTextCubit cubit =
          ScaffoldStreamingRichTextCubit()
            ..appendSpans(const <ScaffoldRichSpan>[
              ScaffoldTextSpan('text '),
              ScaffoldCodeInlineSpan('inlineCode'),
              ScaffoldCitationSpan(
                id: 'cite-1',
                marker: '[1]',
                title: 'Source Title',
                body: 'Source body text',
              ),
            ]);
      addTearDown(cubit.close);
      await _pump(
        tester,
        ScaffoldStreamingRichText(cubit: cubit),
        motion: motion,
        typography: typography,
      );
      await tester.pump();
    }

    testWidgets('inline code uses the registered mono family', (tester) async {
      await pumpRichText(tester, typography: courier);
      expect(families(tester, ScaffoldStreamingRichText), contains('Courier'));
      expect(
        families(tester, ScaffoldStreamingRichText),
        isNot(contains('monospace')),
      );
    });

    testWidgets('inline code defaults to monospace', (tester) async {
      await pumpRichText(tester);
      expect(families(tester, ScaffoldStreamingRichText), contains('monospace'));
    });

    testWidgets('citation reveal uses the registered motion', (tester) async {
      await pumpRichText(tester, motion: _custom);
      await tester.tap(find.text('[1]'));
      await tester.pump();
      final AnimatedSize size = _in<AnimatedSize>(
        tester,
        ScaffoldStreamingRichText,
      );
      expect(size.duration, const Duration(milliseconds: 888));
      expect(size.curve, Curves.linear);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('citation reveal defaults to 300 ms easeInOut', (tester) async {
      await pumpRichText(tester);
      await tester.tap(find.text('[1]'));
      await tester.pump();
      final AnimatedSize size = _in<AnimatedSize>(
        tester,
        ScaffoldStreamingRichText,
      );
      expect(size.duration, const Duration(milliseconds: 300));
      expect(size.curve, Curves.easeInOut);
      await tester.pump(const Duration(seconds: 1));
    });

    group('skeleton pulse', () {
      const ScaffoldMotionTheme slow = ScaffoldMotionTheme(
        medium: Duration(milliseconds: 900),
      );

      Future<void> pumpSkeleton(
        WidgetTester tester, {
        ScaffoldMotionTheme? motion,
      }) {
        return _pump(
          tester,
          const ScaffoldSkeleton(width: 40, height: 10),
          motion: motion,
          reducedMotion: true,
        );
      }

      double opacity(WidgetTester tester) => tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(ScaffoldSkeleton),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value;

      testWidgets('default period is 300 ms', (tester) async {
        await pumpSkeleton(tester);
        await tester.pump(const Duration(milliseconds: 150));
        expect(opacity(tester), closeTo(0.8, 0.01));
      });

      testWidgets('registered medium sets the period', (tester) async {
        await pumpSkeleton(tester, motion: slow);
        await tester.pump(const Duration(milliseconds: 150));
        expect(opacity(tester), closeTo(0.667, 0.01));
      });

      testWidgets('changing the registered medium after mount updates the '
          'period', (tester) async {
        await pumpSkeleton(tester);
        await tester.pump(const Duration(milliseconds: 100));
        await pumpSkeleton(tester, motion: slow);
        await tester.pump(const Duration(milliseconds: 450));
        expect(tester.takeException(), isNull);
        // A 300 ms period would have turned around (about 0.67 on the way
        // back); the 900 ms period is still rising to about 0.93.
        expect(opacity(tester), closeTo(0.933, 0.02));
      });
    });
  });
}
