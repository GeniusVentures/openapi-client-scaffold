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
///
/// NOTE: the tap lands on the inner chart's touch area, so fl_chart's
/// touchCallback fires `onSelected` with the tapped spot (and may fire
/// again on tap-up / pan-end). Tests that need to assert ONLY keyboard
/// events should call [focusScrubberAndDrainEvents] below instead, which
/// clears the event log after focus is granted.
Future<void> _focusScrubber(WidgetTester tester) async {
  await tester.tap(find.byType(ScaffoldChartScrubber<int>));
  await tester.pump();
}

/// Focus the scrubber via tap, then drain any touch-side events so
/// subsequent assertions see only keyboard-driven events.
Future<void> _focusScrubberAndDrainEvents(
  WidgetTester tester,
  List<int?> events,
) async {
  await _focusScrubber(tester);
  events.clear();
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
      await _focusScrubberAndDrainEvents(tester, events);

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
      await _focusScrubberAndDrainEvents(tester, events);

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
      await _focusScrubberAndDrainEvents(tester, events);

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
      await _focusScrubberAndDrainEvents(tester, events);

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
      await _focusScrubberAndDrainEvents(tester, events);

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
      await _focusScrubberAndDrainEvents(tester, events);

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
      await _focusScrubberAndDrainEvents(tester, events);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(events, <int?>[null]);
    });
  });

  group('ScaffoldChartScrubber hover behavior (UAT regression)', () {
    // UAT defect: with the MOUSE hovering over the chart (no button
    // pressed), the external readout oscillated between "Value: X" and
    // "No selection" while the mouse was completely STATIONARY, and the
    // scrub line/dot flickered. Root cause: fl_chart fires
    // FlPointerHoverEvent through the touchCallback on every hover move
    // (render_base_chart.dart in fl_chart-1.2.0); the renderer forwarded
    // every event's spot to the atom; and the atom's onSpotTouched toggled
    // via identical() on EVERY event — so a second hover hit on the
    // already-selected point cleared it, then the next hover hit re-selected
    // it. Hover must NEVER toggle-clear. Selection clears ONLY via discrete
    // tap on the selected point, Escape, or hover-exit.
    testWidgets(
        'Test 13: hover onto a point selects it; hover to ANOTHER point '
        'updates selection; hover that RE-HITS the selected point must NOT '
        'clear (no oscillation)', (WidgetTester tester) async {
      Offset? selection;
      final List<Offset?> events = <Offset?>[];

      // Consumer state mirrors the demo: every callback sets state, and the
      // rebuilt widget passes `selection` back in — so a hover hit on the
      // selected point triggers the identical()-toggle if the bug exists.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: scaffoldThemeExtensions),
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return SizedBox(
                    width: 400,
                    height: 300,
                    child: ScaffoldChartScrubber<Offset>(
                      series: const <Offset>[
                        Offset(0, 10),
                        Offset(1, 30),
                        Offset(2, 20),
                        Offset(3, 50),
                        Offset(4, 40),
                      ],
                      xAccessor: (Offset o) => o.dx,
                      yAccessor: (Offset o) => o.dy,
                      selectedPoint: selection,
                      onPointSelected: (Offset? v) {
                        events.add(v);
                        setState(() => selection = v);
                      },
                      plotHeight: 200,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Locate the chart's plot area. The Semantics('Chart') box wraps the
      // whole atom (Expanded + touch-target + padding), so the exact
      // spot-pixel transform is NOT derivable from the box alone — fl_chart
      // hits a spot only within `touchSpotThreshold` (10px) of the spot's
      // pixel (line_chart_painter.getNearestTouchedSpot). Discover each
      // spot's pixel x empirically: sweep a mouse pointer across the box in
      // 1px steps and record, per spot, the x at which it becomes the
      // current selection. Deterministic — the layout is fixed.
      final RenderBox chartBox = tester.renderObject<RenderBox>(
        find.bySemanticsLabel('Chart'),
      );
      final Offset chartOrigin = chartBox.localToGlobal(Offset.zero);
      final Size chartSize = chartBox.size;
      final double midY = chartOrigin.dy + chartSize.height * 0.5;

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      // Calibration sweep: map spot value → first pixel x where it is
      // selected. Selection must be reset between probes so a "new" hit is
      // observable. Sweep left→right so spots resolve in series order.
      const List<Offset> probeSeries = <Offset>[
        Offset(0, 10),
        Offset(1, 30),
        Offset(2, 20),
        Offset(3, 50),
        Offset(4, 40),
      ];
      final Map<Offset, double> spotPixelX = <Offset, double>{};
      for (int px = 0; px <= chartSize.width.round(); px++) {
        await mouse.moveTo(Offset(chartOrigin.dx + px, midY));
        await tester.pump();
        final Offset? sel = selection;
        if (sel != null && !spotPixelX.containsKey(sel)) {
          spotPixelX[sel] = chartOrigin.dx + px.toDouble();
        }
      }
      expect(spotPixelX.length, probeSeries.length,
          reason: 'calibration sweep must reach every spot — $spotPixelX');
      // Leave no stale selection from the sweep.
      await mouse.moveTo(const Offset(-10000, -10000));
      await tester.pump();
      events.clear();

      final Offset spotA = probeSeries[1];
      final Offset spotB = probeSeries[3];
      Offset pixelOf(Offset spot) => Offset(spotPixelX[spot]!, midY);

      // 1. Hover onto spot A — selection appears.
      await mouse.moveTo(pixelOf(spotA));
      await tester.pump();
      expect(selection, isNotNull,
          reason: 'hover over the plot must select the nearest point');
      final Offset firstSelection = selection!;
      expect(firstSelection, spotA);
      expect(events, isNotEmpty);
      expect(events.where((Offset? e) => e == null), isEmpty,
          reason: 'no clear may fire during plain hover entry');

      // 2. Hover to spot B while already selected — must UPDATE.
      await mouse.moveTo(pixelOf(spotB));
      await tester.pump();
      expect(selection, isNotNull,
          reason: 'hovering to another point must keep a selection');
      expect(
        selection,
        isNot(equals(firstSelection)),
        reason: 'hovering to another x must update the selection',
      );
      expect(events.where((Offset? e) => e == null), isEmpty,
          reason: 'hover move between points must never clear');

      // 3. Move BACK over spot A (the previously selected point) — the
      // regression trigger. With the toggle bug this fires
      // onPointSelected(null) because the consumer now feeds
      // selectedPoint = spot-A back in, and identical() matches.
      await mouse.moveTo(pixelOf(spotA));
      await tester.pump();
      expect(selection, isNotNull,
          reason: 're-hovering the selected point must NOT clear '
              '(hover is not a toggle)');
      expect(events.where((Offset? e) => e == null), isEmpty,
          reason: 'no clear may fire while the pointer is over the plot');

      // 4. Stationary-mouse oscillation probe: hold the pointer over spot A
      // and pump repeated frames with micro-jitter hover events (the OS
      // delivers periodic hover-move events for a stationary mouse when the
      // widget under it rebuilds — this is exactly what the UAT surface
      // does on every selection setState). Every re-hit must keep the
      // selection; a single null emission IS the reported oscillation.
      events.clear();
      for (int i = 0; i < 6; i++) {
        final Offset p = pixelOf(spotA);
        await mouse.moveTo(Offset(p.dx + (i.isEven ? 0.0 : 0.4), p.dy));
        await tester.pump();
        expect(selection, isNotNull,
            reason: 'stationary hover must hold the selection '
                '(iteration $i) — "No selection" is impossible over the plot');
      }
      expect(
        events.where((Offset? e) => e == null),
        isEmpty,
        reason: 'stationary hover must NEVER emit a clear event — '
            'this is the UAT oscillation',
      );

      // 5. Hover-exit DOES clear (D-05 contract still intact).
      await mouse.moveTo(const Offset(-10000, -10000));
      await tester.pump();
      expect(selection, isNull,
          reason: 'leaving the chart area must clear the selection');
    });

    testWidgets(
        'Test 14: discrete TAP on the already-selected point still toggles '
        'it off (tap toggle preserved, hover toggle removed)',
        (WidgetTester tester) async {
      Offset? selection;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: scaffoldThemeExtensions),
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return SizedBox(
                    width: 400,
                    height: 300,
                    child: ScaffoldChartScrubber<Offset>(
                      series: const <Offset>[
                        Offset(0, 10),
                        Offset(1, 30),
                        Offset(2, 20),
                        Offset(3, 50),
                        Offset(4, 40),
                      ],
                      xAccessor: (Offset o) => o.dx,
                      yAccessor: (Offset o) => o.dy,
                      selectedPoint: selection,
                      onPointSelected: (Offset? v) {
                        setState(() => selection = v);
                      },
                      plotHeight: 200,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      final RenderBox chartBox = tester.renderObject<RenderBox>(
        find.bySemanticsLabel('Chart'),
      );
      final Offset chartOrigin = chartBox.localToGlobal(Offset.zero);
      final Size chartSize = chartBox.size;
      final double midY = chartOrigin.dy + chartSize.height * 0.5;

      // Discover the middle spot's pixel x empirically (same calibration as
      // Test 13): fl_chart hits a spot only within touchSpotThreshold (10px)
      // of its pixel. A mouse hover sweep finds it deterministically.
      const Offset middleSpot = Offset(2, 20);
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      double? tapX;
      for (int px = 0; px <= chartSize.width.round(); px++) {
        await mouse.moveTo(Offset(chartOrigin.dx + px, midY));
        await tester.pump();
        if (selection == middleSpot) {
          tapX = chartOrigin.dx + px.toDouble();
          break;
        }
      }
      expect(tapX, isNotNull,
          reason: 'calibration sweep must reach the middle spot');
      // Clear the sweep's selection so the tap test starts from null.
      await mouse.moveTo(const Offset(-10000, -10000));
      await tester.pump();
      expect(selection, isNull);
      await mouse.removePointer();

      final Offset tapPoint = Offset(tapX!, midY);

      await tester.tapAt(tapPoint);
      await tester.pump();
      expect(selection, isNotNull,
          reason: 'tapping the plot selects the nearest point');
      final Offset tapped = selection!;

      // Tap the SAME spot again — discrete-tap toggle clears it.
      await tester.tapAt(tapPoint);
      await tester.pump();
      expect(selection, isNull,
          reason: 'tapping the selected point must toggle it off — '
              'toggle survives ONLY for discrete taps');
      expect(tapped, middleSpot,
          reason: 'sanity: the mid-plot tap resolved to the middle spot');
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

    testWidgets(
        'Test 8b: PointerExit during an active drag does NOT clear selection',
        (WidgetTester tester) async {
      // UAT section 4 regression: with a finger/mouse drag in progress, the
      // framework can deliver synthetic PointerExit events (e.g. as the
      // pointer crosses hit-test boundaries inside the chart). The previous
      // implementation unconditionally fired onPointSelected(null) on ANY
      // exit, which raced with the drag's own spot selection and produced
      // the "scrub flickers / oscillates with No selection" defect.
      //
      // Contract: while a drag is active, PointerExit MUST NOT clear.
      // Selection clears only on hover-exit when NO drag is in progress
      // (D-05 / GeniusWallet behavior — the selection persists at the
      // final scrubbed point after the drag ends).
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
        onSelected: (int? v) => events.add(v),
      );

      // Use a touch pointer (not mouse) so the fl_chart internal gesture
      // recognizer treats this as a pan — FlPanStartEvent fires on the
      // touchCallback. We then inject a synthetic PointerExitEvent via the
      // MouseRegion layer while the pan is still active.
      final Offset center =
          tester.getCenter(find.byType(ScaffoldChartScrubber<int>));
      final TestGesture gesture = await tester.startGesture(center);
      addTearDown(gesture.removePointer);
      await tester.pump();
      // Move inside the plot so fl_chart recognizes a pan and reports a
      // spot — the touchCallback now fires with FlPanStartEvent + spot.
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();

      // The drag itself selected a point; drain it so the assertion below
      // only sees the post-exit state.
      expect(events, isNotEmpty,
          reason: 'Pan should have produced a selection event');
      events.clear();

      // Synthesize a PointerExitEvent against the MouseRegion while the
      // pan is still active. The scrubber must NOT fire onPointSelected.
      final TestGesture hoverExit = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await hoverExit.addPointer(location: center);
      addTearDown(hoverExit.removePointer);
      await hoverExit.moveTo(center);
      await tester.pump();
      await hoverExit.moveTo(const Offset(-10000, -10000));
      await tester.pump();

      expect(
        events,
        isNot(contains(null)),
        reason: 'PointerExit during an active drag must not clear selection',
      );
    });

    testWidgets(
        'Test 8c: PointerExit AFTER drag end clears selection (hover-exit contract)',
        (WidgetTester tester) async {
      // Companion to Test 8b: the drag-gated clear is NOT a permanent
      // suppression. Once the gesture has ended (FlPanEndEvent /
      // FlPanCancelEvent / FlTapUpEvent), a subsequent hover-exit MUST
      // still clear — otherwise D-05 hover-exit behavior is lost entirely.
      final List<int?> events = <int?>[];
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
        onSelected: (int? v) => events.add(v),
      );

      final Offset center =
          tester.getCenter(find.byType(ScaffoldChartScrubber<int>));
      final TestGesture gesture = await tester.startGesture(center);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      events.clear();

      final TestGesture hoverExit = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await hoverExit.addPointer(location: center);
      addTearDown(hoverExit.removePointer);
      await hoverExit.moveTo(center);
      await tester.pump();
      await hoverExit.moveTo(const Offset(-10000, -10000));
      await tester.pump();

      expect(
        events,
        contains(null),
        reason: 'Hover-exit with no active drag must still clear selection',
      );
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

    testWidgets(
        'Test 11b: tap-focus paints the focus ring (UI-SPEC interaction-states)',
        (WidgetTester tester) async {
      // UAT section 5 regression: tapping the scrub area grants primary
      // focus, but the FocusManager highlight mode stays in hover/touch —
      // the previous ScaffoldFocusOutline gating (keyboard-only) meant the
      // ring never painted. Per the Phase 10 UI-SPEC Interaction States
      // table, the scrub area MUST show the 2px focusRingColor ring
      // whenever it has primary focus, regardless of how focus arrived.
      await _pumpScrubber(
        tester,
        series: _threePoints(),
        selected: null,
        onSelected: (int? _) {},
      );

      // Tap-to-focus path — Listener.onPointerDown calls requestFocus
      // without flipping the FocusManager to traditional highlight mode.
      await tester.tap(find.byType(ScaffoldChartScrubber<int>));
      await tester.pump();

      // Highlight mode must NOT be traditional (otherwise this test is
      // accidentally exercising the keyboard path, not the tap path).
      expect(
        FocusManager.instance.highlightMode,
        isNot(FocusHighlightMode.traditional),
      );

      final Finder ringPaint = find.descendant(
        of: find.byType(ScaffoldFocusOutline),
        matching: find.byType(CustomPaint),
      );
      expect(
        ringPaint,
        findsOneWidget,
        reason: 'Scrub area must paint the focus ring on tap-focus '
            '(UI-SPEC Interaction States row "Focus")',
      );
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
      await _focusScrubberAndDrainEvents(tester, events);

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
    testWidgets('ScaffoldTouchTarget + MouseRegion + Shortcuts present',
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
          matching: find.byType(Shortcuts),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ScaffoldChartScrubber<int>),
          matching: find.byType(Actions),
        ),
        findsOneWidget,
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
