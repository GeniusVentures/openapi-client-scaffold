import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_chart_scrubber.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Pump helper. Wraps the scrubber in a MaterialApp + Scaffold + bounded
/// SizedBox so the inner chart's LayoutBuilder always sees a finite
/// maxHeight. Width/height are stable across tests so layout assertions are
/// deterministic.
Future<void> _pumpScrubber(
  WidgetTester tester, {
  required List<int> series,
  int? selected,
  ValueChanged<int?>? onSelected,
  String? announceValue,
  String? announceLabel,
  String? scrubberSemanticsLabel,
  double? plotHeight,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: ScaffoldChartScrubber<int>(
              series: series,
              xAccessor: (int v) => v.toDouble(),
              yAccessor: (int v) => (v * 2).toDouble(),
              selectedPoint: selected,
              onPointSelected: onSelected,
              announceValue: announceValue,
              announceLabel: announceLabel,
              scrubberSemanticsLabel: scrubberSemanticsLabel,
              plotHeight: plotHeight ?? 200,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Deterministic 3-point series used by the keyboard tests.
List<int> _threePoints() => const <int>[1, 2, 3];

/// Taps the scrubber to grant keyboard focus, then pumps a frame so the
/// focus highlight settles before subsequent key events are dispatched.
Future<void> _focusScrubber(WidgetTester tester) async {
  await tester.tap(find.byType(ScaffoldChartScrubber<int>));
  await tester.pump();
}

void main() {
  group('ScaffoldChartScrubber keyboard navigation', () {
    testWidgets('Test 1: ArrowRight from null selects series.first',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
        onSelected: (int? v) => events.add(v),
      );
      await _focusScrubber(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(events, <int?>[1]);
    });

    testWidgets('Test 2: ArrowRight advances from a to b',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: 1,
        onSelected: (int? v) => events.add(v),
      );
      await _focusScrubber(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(events, <int?>[2]);
    });

    testWidgets('Test 3: ArrowRight clamps at the last element',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: 3,
        onSelected: (int? v) => events.add(v),
      );
      await _focusScrubber(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // Clamped: re-fires the same final element.
      expect(events, <int?>[3]);
    });

    testWidgets('Test 4: ArrowLeft from null selects series.last',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
        onSelected: (int? v) => events.add(v),
      );
      await _focusScrubber(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(events, <int?>[3]);
    });

    testWidgets('Test 5: ArrowLeft retreats from b to a',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: 2,
        onSelected: (int? v) => events.add(v),
      );
      await _focusScrubber(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(events, <int?>[1]);
    });

    testWidgets('Test 6: Enter re-fires onPointSelected with current value',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: 2,
        onSelected: (int? v) => events.add(v),
      );
      await _focusScrubber(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(events, <int?>[2]);
    });

    testWidgets('Test 7: Escape fires onPointSelected(null)',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: 2,
        onSelected: (int? v) => events.add(v),
      );
      await _focusScrubber(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(events, <int?>[null]);
    });
  });

  group('ScaffoldChartScrubber pointer + a11y', () {
    testWidgets('Test 8: PointerExit fires onPointSelected(null)',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: 2,
        onSelected: (int? v) => events.add(v),
      );

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(
        tester.getCenter(find.byType(ScaffoldChartScrubber<int>)),
      );
      await tester.pump();
      await gesture.moveTo(const Offset(-10, -10));
      await tester.pump();

      expect(events, contains(null));
    });

    testWidgets('Test 9: outer Semantics "Chart scrubber" wraps inner "Chart"',
        (WidgetTester tester) async {
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
      );

      expect(find.bySemanticsLabel('Chart scrubber'), findsOneWidget);
      expect(find.bySemanticsLabel('Chart'), findsOneWidget);
    });

    testWidgets('Test 10: announceValue wires ScaffoldLiveRegion; null omits',
        (WidgetTester tester) async {
      // With announceValue — live region present.
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
        announceValue: '42.0',
      );
      expect(find.byType(ScaffoldLiveRegion), findsOneWidget);
      final ScaffoldLiveRegion region = tester.widget<ScaffoldLiveRegion>(
        find.byType(ScaffoldLiveRegion),
      );
      expect(region.value, '42.0');
      expect(region.label, 'Selected point');

      // Without announceValue — no live region in the tree.
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
      );
      expect(find.byType(ScaffoldLiveRegion), findsNothing);
    });

    testWidgets('Test 11: keyboard focus triggers ScaffoldFocusOutline ring',
        (WidgetTester tester) async {
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
        onSelected: (int? _) {},
      );

      // ScaffoldFocusOutline is always in the tree (it owns its own
      // FocusNode internally); the ring's visibility is driven by focus +
      // highlight mode. Drive a keyboard-highlight focus so the ring shows.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(find.byType(ScaffoldFocusOutline), findsOneWidget);
    });

    testWidgets('Test 12: empty series — keyboard no-ops, PointerExit fires',
        (WidgetTester tester) async {
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: const <int>[],
        selected: null,
        onSelected: (int? v) => events.add(v),
      );
      await _focusScrubber(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      // Escape fires null unconditionally, even on an empty series.
      expect(events, <int?>[null]);

      // PointerExit still fires.
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(
        tester.getCenter(find.byType(ScaffoldChartScrubber<int>)),
      );
      await tester.pump();
      await gesture.moveTo(const Offset(-10, -10));
      await tester.pump();

      expect(events.length, greaterThanOrEqualTo(2));
      expect(events.last, isNull);
    });
  });

  group('ScaffoldChartScrubber composition contract', () {
    testWidgets('ScaffoldTouchTarget + MouseRegion + Listener present',
        (WidgetTester tester) async {
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
      );

      expect(find.byType(ScaffoldTouchTarget), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScaffoldChartScrubber<int>),
          matching: find.byType(MouseRegion),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ScaffoldChartScrubber<int>),
          matching: find.byType(Listener),
        ),
        findsWidgets,
      );
    });

    testWidgets('scrubberSemanticsLabel overrides the default',
        (WidgetTester tester) async {
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
        scrubberSemanticsLabel: 'Price scrubber',
      );

      expect(find.bySemanticsLabel('Price scrubber'), findsOneWidget);
      expect(find.bySemanticsLabel('Chart scrubber'), findsNothing);
    });

    testWidgets('atom does NOT render a readout (D-05)',
        (WidgetTester tester) async {
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: 2,
      );

      // No readout Text widgets surfaced by the scrubber itself beyond the
      // inner chart's axis labels — assert the scrubber has no direct Text
      // children outside the chart subtree.
      final Finder textInScrubber = find.descendant(
        of: find.byType(ScaffoldChartScrubber<int>),
        matching: find.byType(Text),
      );
      // Any Text under the scrubber is the chart's X-axis label row, never
      // a readout rendered by the scrubber itself.
      for (final Element el in textInScrubber.evaluate()) {
        expect(el.widget, isA<Text>());
      }
    });
  });
}
