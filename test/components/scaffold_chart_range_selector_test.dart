import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_chart.dart';
import 'package:frontend_scaffold/components/scaffold_chart_range_selector.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// First drag-move step, in px — just over the touch slop so the overlay's
/// horizontal-drag recognizer accepts near the down position, keeping the
/// band's start anchor mapped to the intended point.
const double _kDragSlopStep = 24.0;

/// Pump helper. Wraps the range selector in a MaterialApp + Scaffold +
/// bounded SizedBox so the inner chart's LayoutBuilder always sees a finite
/// maxHeight. Width/height are stable (400x300) so layout + pixel mapping
/// are deterministic. plotHeight 300 >= 220 frames the chart (62px axis
/// gutter), exercising the full renderer pixel mapping.
Future<void> _pumpRangeSelector(
  WidgetTester tester, {
  required List<int> series,
  (int, int)? selectedRange,
  ValueChanged<(int, int)?>? onRangeSelected,
  ValueChanged<int?>? onPointSelected,
  int? selectedPoint,
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
            child: ScaffoldChartRangeSelector<int>(
              series: series,
              xAccessor: (int v) => v.toDouble(),
              yAccessor: (int v) => (v * 2).toDouble(),
              selectedRange: selectedRange,
              onRangeSelected: onRangeSelected,
              selectedPoint: selectedPoint,
              onPointSelected: onPointSelected,
              plotHeight: plotHeight ?? 300,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Deterministic 5-point series used by the drag tests.
List<int> _fivePoints() => const <int>[10, 20, 30, 40, 50];

/// Taps the selector to grant keyboard focus, then pumps a frame.
Future<void> _focusSelector(WidgetTester tester) async {
  await tester.tap(find.byType(ScaffoldChartRangeSelector<int>));
  await tester.pump();
}

/// Calibrates value -> global pixel x by sweeping a mouse pointer across the
/// chart in 1px steps and recording the first pixel where each point becomes
/// the current selection. Mirrors the scrubber test's empirical calibration;
/// deterministic because the layout is fixed.
Future<Map<double, double>> _calibrateValueToPixelX(
  WidgetTester tester,
  int? Function() currentSelection,
) async {
  final RenderBox box = tester.renderObject<RenderBox>(
    find.byType(ScaffoldChart<int>),
  );
  final Offset origin = box.localToGlobal(Offset.zero);
  final double midY = origin.dy + box.size.height * 0.5;
  final Map<double, double> valueToPixelX = <double, double>{};
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  for (int px = 0; px <= box.size.width.round(); px++) {
    await mouse.moveTo(Offset(origin.dx + px, midY));
    await tester.pump();
    final int? sel = currentSelection();
    if (sel != null && !valueToPixelX.containsKey(sel.toDouble())) {
      valueToPixelX[sel.toDouble()] = origin.dx + px.toDouble();
    }
  }
  await mouse.moveTo(const Offset(-10000, -10000));
  await tester.pump();
  await mouse.removePointer();
  return valueToPixelX;
}

/// Drives a horizontal band drag from [from] to [to] using a touch pointer,
/// stepping the first move just over the slop so the recognizer accepts and
/// subsequent moves fire `onHorizontalDragUpdate` with accurate positions.
Future<void> _dragBand(WidgetTester tester, Offset from, Offset to) async {
  final TestGesture gesture = await tester.startGesture(from);
  addTearDown(gesture.removePointer);
  await tester.pump();
  final Offset delta = to - from;
  final double sign = delta.dx.sign;
  await gesture.moveBy(Offset(_kDragSlopStep * sign, 0.0));
  await tester.pump();
  await gesture.moveBy(Offset(delta.dx - _kDragSlopStep * sign, 0.0));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  group('ScaffoldChartRangeSelector drag-band (D-09)', () {
    testWidgets(
        'Test 15: horizontal drag fires onRangeSelected with nearest points',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      int? selected;
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
        onPointSelected: (int? v) => selected = v,
      );

      final Map<double, double> valueToPixelX =
          await _calibrateValueToPixelX(tester, () => selected);
      final double midY =
          tester.getCenter(find.byType(ScaffoldChart<int>)).dy;
      await _dragBand(
        tester,
        Offset(valueToPixelX[10]!, midY),
        Offset(valueToPixelX[30]!, midY),
      );

      expect(ranges, isNotEmpty,
          reason: 'a horizontal band drag must fire onRangeSelected');
      expect(ranges.last, (10, 30),
          reason: 'drag from point 10 to point 30 must map to (10, 30)');
    });

    testWidgets(
        'Test 16: band painter draws fill + edge rules (selectedRange)',
        (WidgetTester tester) async {
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        selectedRange: (10, 30),
      );

      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(CustomPaint),
        ),
      );
      final CustomPainter painter = paint.painter!;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      painter.paint(ui.Canvas(recorder), const Size(400, 300));
      final ui.Picture picture = recorder.endRecording();
      expect(picture.approximateBytesUsed, greaterThan(0),
          reason: 'a selected range must paint a non-empty band');
    });

    testWidgets(
        'Test 17: report-only — atom never modifies its own window',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
      );

      final Offset center =
          tester.getCenter(find.byType(ScaffoldChart<int>));
      await _dragBand(tester, center, center + const Offset(100, 0));

      expect(ranges, isNotEmpty,
          reason: 'the drag must still fire onRangeSelected');
      final ScaffoldChart<int> chart =
          tester.widget<ScaffoldChart<int>>(find.byType(ScaffoldChart<int>));
      expect(chart.viewMinX, isNull,
          reason: 'report-only: atom must not modify viewMinX');
      expect(chart.viewMaxX, isNull,
          reason: 'report-only: atom must not modify viewMaxX');
    });

    testWidgets(
        'Test 18: band drag suppresses inner chart pan-scrub (D-10)',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      final List<int?> pointEvents = <int?>[];
      int? selected;
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
        onPointSelected: (int? v) {
          selected = v;
          pointEvents.add(v);
        },
      );

      final Map<double, double> valueToPixelX =
          await _calibrateValueToPixelX(tester, () => selected);
      final double midY =
          tester.getCenter(find.byType(ScaffoldChart<int>)).dy;

      pointEvents.clear();
      selected = null;

      // Down at point 10 — the chart's tap recognizer may fire a single
      // tap-down selection here (pre-drag); capture the baseline so the
      // assertion below checks ONLY the drag movement.
      final TestGesture gesture =
          await tester.startGesture(Offset(valueToPixelX[10]!, midY));
      await tester.pump();
      final int afterDown = pointEvents.length;

      // Drag to point 30 — the overlay claims the horizontal drag, so the
      // chart's pan recognizer must be rejected and fire no further
      // onPointSelected.
      await gesture.moveBy(const Offset(_kDragSlopStep, 0));
      await tester.pump();
      await gesture.moveBy(
        Offset(valueToPixelX[30]! - valueToPixelX[10]! - _kDragSlopStep, 0),
      );
      await tester.pump();

      expect(pointEvents.length, afterDown,
          reason: 'pan-scrub must not fire during a band drag (D-10)');
      await gesture.up();
      await tester.pump();
      expect(ranges, isNotEmpty,
          reason: 'the band drag must fire onRangeSelected');
    });

    testWidgets(
        'Test 19: tap and hover pass through to point-scrub (D-10)',
        (WidgetTester tester) async {
      final List<int?> pointEvents = <int?>[];
      int? selected;
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        onPointSelected: (int? v) {
          selected = v;
          pointEvents.add(v);
        },
      );

      // The framed chart's right-axis gutter (kChartAxisGutter) insets the
      // plot area, so the widget's geometric center is NOT over point 30
      // (the center data value). Calibrate the real pixel location of a
      // point first, then target it — the same pattern the drag tests use.
      final Map<double, double> valueToPixelX =
          await _calibrateValueToPixelX(tester, () => selected);
      final double midY =
          tester.getCenter(find.byType(ScaffoldChart<int>)).dy;
      final Offset point30 = Offset(valueToPixelX[30]!, midY);

      pointEvents.clear();
      selected = null;

      // Tap (touch, no drag) — must reach the chart and select a point.
      await tester.tapAt(point30);
      await tester.pump();
      expect(selected, 30,
          reason: 'a tap must pass through to point-scrub');

      pointEvents.clear();
      selected = null;

      // Hover (mouse) — must reach the chart and select a point.
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(point30);
      await tester.pump();
      expect(selected, 30,
          reason: 'hover must pass through to point-scrub');
    });

    testWidgets(
        'Test 21: new drag replaces the previous range',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      int? selected;
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        selectedRange: (10, 20),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
        onPointSelected: (int? v) => selected = v,
      );

      final Map<double, double> valueToPixelX =
          await _calibrateValueToPixelX(tester, () => selected);
      final double midY =
          tester.getCenter(find.byType(ScaffoldChart<int>)).dy;
      await _dragBand(
        tester,
        Offset(valueToPixelX[30]!, midY),
        Offset(valueToPixelX[50]!, midY),
      );

      expect(ranges, isNotEmpty);
      expect(ranges.last, (30, 50),
          reason: 'a new drag must replace the active range');
    });
  });

  group('ScaffoldChartRangeSelector keyboard', () {
    testWidgets('Test 20: Escape clears range (onRangeSelected(null))',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        selectedRange: (20, 30),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
      );
      await _focusSelector(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(ranges, <(int, int)?>[null]);
    });

    testWidgets('Test 22: Shift+ArrowRight extends range end',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        selectedRange: (10, 20),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
      );
      await _focusSelector(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(ranges, <(int, int)?>[(10, 30)]);
    });

    testWidgets('Test 23: Shift+ArrowLeft shrinks range end',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        selectedRange: (30, 50),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
      );
      await _focusSelector(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(ranges, <(int, int)?>[(30, 40)]);
    });

    testWidgets('Test 24: Enter confirms (re-fires) range',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        selectedRange: (20, 30),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
      );
      await _focusSelector(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(ranges, <(int, int)?>[(20, 30)]);
    });

    testWidgets(
        'Test 25: plain ArrowLeft/Right do NOT fire onRangeSelected',
        (WidgetTester tester) async {
      final List<(int, int)?> ranges = <(int, int)?>[];
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        selectedRange: (20, 30),
        onRangeSelected: ((int, int)? r) => ranges.add(r),
      );
      await _focusSelector(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(ranges, isEmpty,
          reason: 'plain arrows route to the inner scrubber, not range '
              'selection');
    });
  });

  group('ScaffoldChartRangeSelector composition + a11y', () {
    testWidgets('Test 26: default Semantics label "Chart range selector"',
        (WidgetTester tester) async {
      await _pumpRangeSelector(tester, series: _fivePoints());
      expect(find.bySemanticsLabel('Chart range selector'), findsOneWidget);
    });

    testWidgets(
        'Test 27: tap-focus paints ring via ScaffoldFocusOutline(showRingWhenFocused: true)',
        (WidgetTester tester) async {
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        onPointSelected: (int? _) {},
      );
      await _focusSelector(tester);

      final ScaffoldFocusOutline outline =
          tester.widget<ScaffoldFocusOutline>(
        find.byType(ScaffoldFocusOutline),
      );
      expect(outline.showRingWhenFocused, isTrue);
      expect(outline.focusNode, isNotNull);
      expect(outline.focusNode!.hasFocus, isTrue,
          reason: 'tap must grant the range selector primary focus');
    });

    testWidgets(
        'Test 28: ScaffoldTouchTarget + translucent overlay give full-band hit area',
        (WidgetTester tester) async {
      await _pumpRangeSelector(
        tester,
        series: _fivePoints(),
        selectedRange: (10, 30),
      );

      expect(find.byType(ScaffoldTouchTarget), findsOneWidget);
      final GestureDetector overlay =
          tester.widget<GestureDetector>(find.byType(GestureDetector));
      expect(overlay.behavior, HitTestBehavior.translucent,
          reason: 'overlay must be translucent so band edges (and the full '
              'plot) hit-test through to the chart');
    });
  });
}
