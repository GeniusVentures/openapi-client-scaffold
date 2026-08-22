import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/utils/chart_geometry.dart';
import 'package:frontend_scaffold/utils/scaffold_chart_renderer.dart';

/// Deterministic spots for the framed-chart tests — 10 points with a
/// monotonically increasing Y so the nice-number ladder has room to pick.
List<ChartPoint> _spots() {
  return List<ChartPoint>.generate(
    10,
    (int i) => (x: i.toDouble(), y: (i * 10).toDouble() + 5.0),
  );
}

/// Y-bounds precomputed to match [_spots] (lo=5, hi=95) with 8% padding
/// baked in by the caller. The renderer takes this precomputed value per
/// the plan — it MUST NOT recompute bounds.
(double, double) _bounds() => (0.0, 100.0);

Widget _buildFramed({
  required bool reducedMotion,
  ScaffoldSpotTouched? onSpotTouched,
}) {
  return buildScaffoldLineChart(
    spots: _spots(),
    plotHeight: 300.0,
    plotWidth: 400.0,
    lineColor: const Color(0xFF00EAAE),
    borderControl: const Color(0xFF3A3F4E),
    borderSubtle: const Color(0x1FFFFFFF),
    textSecondary: const Color(0xFF8A8F9D),
    axisLabelStyle: const TextStyle(fontSize: 11),
    reducedMotion: reducedMotion,
    onSpotTouched: onSpotTouched,
    yBounds: _bounds(),
  );
}

Widget _buildAxisFree() {
  return buildScaffoldLineChart(
    spots: _spots(),
    plotHeight: 100.0,
    plotWidth: 200.0,
    lineColor: const Color(0xFF00EAAE),
    borderControl: const Color(0xFF3A3F4E),
    borderSubtle: const Color(0x1FFFFFFF),
    textSecondary: const Color(0xFF8A8F9D),
    axisLabelStyle: const TextStyle(fontSize: 11),
    reducedMotion: false,
    yBounds: _bounds(),
  );
}

/// Shared smooth-mode spots list — a distinct reference from [_spots]'s
/// (the builder asserts callback and spots list arrive together; the
/// interpolation helper reads ONLY this list).
final List<ChartPoint> _smoothSpots = _spots();

Widget _buildSmooth({
  ScaffoldScrubPositionChanged? onScrubPositionChanged,
  ScaffoldSpotTouched? onSpotTouched,
}) {
  return buildScaffoldLineChart(
    spots: _spots(),
    plotHeight: 300.0,
    plotWidth: 400.0,
    lineColor: const Color(0xFF00EAAE),
    borderControl: const Color(0xFF3A3F4E),
    borderSubtle: const Color(0x1FFFFFFF),
    textSecondary: const Color(0xFF8A8F9D),
    axisLabelStyle: const TextStyle(fontSize: 11),
    reducedMotion: false,
    yBounds: _bounds(),
    onSpotTouched: onSpotTouched,
    onScrubPositionChanged: onScrubPositionChanged,
    smoothSpots: onScrubPositionChanged == null ? null : _smoothSpots,
  );
}

/// Pumps [widget] into a full-screen 800x600 surface (the test default)
/// and returns the global rect of the smooth chart's Stack. The chart
/// renders at its parent's full width/height, so the Stack rect IS the
/// plot rect for pixel arithmetic in the widget-level tests below.
Future<Rect> _pumpSmoothAndGetRect(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox.expand(child: widget)),
    ),
  );
  await tester.pump();
  final RenderBox box = tester.renderObject<RenderBox>(find.byType(Stack));
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Synthesizes a [LineTouchResponse] carrying ONLY a chart coordinate (no
/// spots) — the shape the continuous-position seam consumes.
LineTouchResponse _coordResponse(double x, double y) {
  return LineTouchResponse(
    touchLocation: Offset.zero,
    touchChartCoordinate: Offset(x, y),
    lineBarSpots: const <TouchLineBarSpot>[],
  );
}

void main() {
  group('buildScaffoldLineChart framed', () {
    test('Test 1: framed chart shows grid + rightTitles with reservedSize',
        () {
      final LineChart chart = _buildFramed(reducedMotion: false) as LineChart;
      final LineChartData data = chart.data;

      expect(data.gridData.show, isTrue);
      expect(data.titlesData.rightTitles.sideTitles.showTitles, isTrue);
      expect(data.titlesData.rightTitles.sideTitles.reservedSize,
          kChartAxisGutter);
      expect(data.titlesData.rightTitles.sideTitles.minIncluded, isFalse);
      expect(data.titlesData.rightTitles.sideTitles.maxIncluded, isFalse);
      expect(data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
      expect(data.titlesData.topTitles.sideTitles.showTitles, isFalse);
      expect(data.titlesData.bottomTitles.sideTitles.showTitles, isFalse);
    });

    test('Test 3 (framed): border always hidden', () {
      final LineChart chart = _buildFramed(reducedMotion: false) as LineChart;
      expect(chart.data.borderData.show, isFalse);
    });

    test('Test 4: tooltip suppressed (transparent color, null items)', () {
      final LineChart chart = _buildFramed(reducedMotion: false) as LineChart;
      final LineTouchTooltipData tooltip =
          chart.data.lineTouchData.touchTooltipData;

      final LineBarSpot fakeSpot = LineBarSpot(
        chart.data.lineBarsData.first,
        0,
        const FlSpot(0, 5),
      );
      expect(tooltip.getTooltipColor(fakeSpot), Colors.transparent);
      expect(tooltip.tooltipBorder, BorderSide.none);
      expect(tooltip.tooltipPadding, EdgeInsets.zero);

      final List<LineTooltipItem?> items =
          tooltip.getTooltipItems(<LineBarSpot>[fakeSpot, fakeSpot]);
      expect(items.length, 2);
      expect(items.every((LineTooltipItem? it) => it == null), isTrue);
    });

    test('Test 5: touch indicator uses borderControl + 5/4 dot', () {
      final LineChart chart = _buildFramed(reducedMotion: false) as LineChart;
      final LineChartBarData barData = chart.data.lineBarsData.first;

      final List<TouchedSpotIndicatorData?> indicators =
          chart.data.lineTouchData.getTouchedSpotIndicator(
              barData, <int>[0]);
      expect(indicators, hasLength(1));
      final TouchedSpotIndicatorData indicator = indicators.first!;

      expect(indicator.indicatorBelowLine.color,
          const Color(0xFF3A3F4E));
      expect(indicator.indicatorBelowLine.strokeWidth, 1);

      final FlDotCirclePainter painter = indicator.touchedSpotDotData
          .getDotPainter(const FlSpot(0, 5), 0.0, barData, 0)
          as FlDotCirclePainter;
      expect(painter.radius, 5);
      expect(painter.strokeWidth, 4);
      expect(painter.color, const Color(0xFF00EAAE));
      // strokeColor = lineColor at 26% alpha
      final int alpha = (painter.strokeColor.a * 255).round();
      expect((alpha - (0.26 * 255).round()).abs() <= 1, isTrue,
          reason: 'stroke alpha expected ~26% of lineColor');
    });

    test('Test 6: touch callback forwards spotIndex to onSpotTouched', () {
      final List<(int, bool)> received = <(int, bool)>[];
      final LineChart chart = _buildFramed(
        reducedMotion: false,
        onSpotTouched: (int i, bool isTap) => received.add((i, isTap)),
      ) as LineChart;

      final LineChartBarData barData = chart.data.lineBarsData.first;
      // LineBarSpot's spotIndex is derived from bar.spots.indexOf(spot),
      // so the FlSpot passed must be IDENTICAL (equality) to an entry in
      // bar.spots — use the existing entry at index 3.
      final FlSpot flSpot = barData.spots[3];
      final TouchLineBarSpot touchSpot =
          TouchLineBarSpot(barData, 0, flSpot, 0.0);
      final LineTouchResponse response = LineTouchResponse(
        touchLocation: Offset.zero,
        touchChartCoordinate: Offset.zero,
        lineBarSpots: <TouchLineBarSpot>[touchSpot],
      );

      chart.data.lineTouchData.touchCallback!(
        FlTapDownEvent(TapDownDetails()),
        response,
      );
      expect(received, <(int, bool)>[(3, true)]);
    });

    test('Test 6b: hover events report isDiscreteTap=false '
        '(hover must never be treated as a toggle-tap)', () {
      final List<(int, bool)> received = <(int, bool)>[];
      final LineChart chart = _buildFramed(
        reducedMotion: false,
        onSpotTouched: (int i, bool isTap) => received.add((i, isTap)),
      ) as LineChart;

      final LineChartBarData barData = chart.data.lineBarsData.first;
      final FlSpot flSpot = barData.spots[1];
      final TouchLineBarSpot touchSpot =
          TouchLineBarSpot(barData, 0, flSpot, 0.0);
      final LineTouchResponse response = LineTouchResponse(
        touchLocation: Offset.zero,
        touchChartCoordinate: Offset.zero,
        lineBarSpots: <TouchLineBarSpot>[touchSpot],
      );

      chart.data.lineTouchData.touchCallback!(
        const FlPointerHoverEvent(PointerHoverEvent()),
        response,
      );
      chart.data.lineTouchData.touchCallback!(
        FlPanUpdateEvent(DragUpdateDetails(globalPosition: Offset.zero)),
        response,
      );
      expect(received, <(int, bool)>[(1, false), (1, false)]);
    });

    test('Test 8: below-bar gradient stops + 26% alpha start color', () {
      final LineChart chart = _buildFramed(reducedMotion: false) as LineChart;
      final BarAreaData below = chart.data.lineBarsData.first.belowBarData;
      expect(below.show, isTrue);

      final LinearGradient gradient = below.gradient as LinearGradient;
      expect(gradient.stops, <double>[0.0, kChartFillFadeStop]);
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);

      final int firstAlpha = (gradient.colors.first.a * 255).round();
      expect((firstAlpha - (0.26 * 255).round()).abs() <= 1, isTrue);
      final int lastAlpha = (gradient.colors.last.a * 255).round();
      expect(lastAlpha, 0);
    });

    test('Test 9: dots hidden, isCurved false, barWidth 2', () {
      final LineChart chart = _buildFramed(reducedMotion: false) as LineChart;
      final LineChartBarData bar = chart.data.lineBarsData.first;
      expect(bar.dotData.show, isFalse);
      expect(bar.isCurved, isFalse);
      expect(bar.barWidth, 2);
    });

    test('empty spots yields SizedBox.shrink()', () {
      final Widget chart = buildScaffoldLineChart(
        spots: const <ChartPoint>[],
        plotHeight: 300.0,
        plotWidth: 400.0,
        lineColor: const Color(0xFF00EAAE),
        borderControl: const Color(0xFF3A3F4E),
        borderSubtle: const Color(0x1FFFFFFF),
        textSecondary: const Color(0xFF8A8F9D),
        axisLabelStyle: const TextStyle(fontSize: 11),
        reducedMotion: false,
        yBounds: _bounds(),
      );
      expect(chart, isA<SizedBox>());
    });
  });

  group('buildScaffoldLineChart axis-free', () {
    test('Test 2: axis-free hides grid + all four titles sides', () {
      final LineChart chart = _buildAxisFree() as LineChart;
      final LineChartData data = chart.data;

      expect(data.gridData.show, isFalse);
      expect(data.titlesData.rightTitles.sideTitles.showTitles, isFalse);
      expect(data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
      expect(data.titlesData.topTitles.sideTitles.showTitles, isFalse);
      expect(data.titlesData.bottomTitles.sideTitles.showTitles, isFalse);
    });

    test('Test 3 (axis-free): border always hidden', () {
      final LineChart chart = _buildAxisFree() as LineChart;
      expect(chart.data.borderData.show, isFalse);
    });
  });

  group('buildScaffoldLineChart touch', () {
    test('Test 7: onSpotTouched null disables lineTouchData', () {
      final LineChart chart = _buildFramed(
        reducedMotion: false,
        onSpotTouched: null,
      ) as LineChart;
      expect(chart.data.lineTouchData.enabled, isFalse);
    });

    test('touch enabled when onSpotTouched is non-null', () {
      final LineChart chart = _buildFramed(
        reducedMotion: false,
        onSpotTouched: (int spotIndex, bool isTap) {},
      ) as LineChart;
      expect(chart.data.lineTouchData.enabled, isTrue);
    });
  });

  group('buildScaffoldLineChart smooth seam (D-08)', () {
    test('Test 7: snap mode unchanged — bare LineChart, dot painter intact',
        () {
      final Widget built = _buildFramed(
        reducedMotion: false,
        onSpotTouched: (int i, bool isTap) {},
      );
      // No Stack wrapper when the smooth callback is null — the snap path
      // returns the bare LineChart (zero overhead for the 10-04 contract).
      expect(built, isA<LineChart>());

      final LineChart chart = built as LineChart;
      final LineChartBarData barData = chart.data.lineBarsData.first;
      final TouchedSpotIndicatorData indicator = chart.data.lineTouchData
          .getTouchedSpotIndicator(barData, <int>[0])
          .first!;
      // Snap mode keeps the existing dot painter (Test 5 above).
      expect(
        indicator.touchedSpotDotData.getDotPainter(
            const FlSpot(0, 5), 0.0, barData, 0),
        isA<FlDotCirclePainter>(),
      );
    });

    test('Test 5: smooth mode wraps LineChart in a Stack with the chart '
        'as a direct child', () {
      final Widget built = _buildSmooth(
        onScrubPositionChanged: (double x, double y) {},
      );
      expect(built, isA<Stack>());
      final Stack stack = built as Stack;
      expect(stack.children.whereType<LineChart>(), hasLength(1));
    });

    test('Test 6: smooth mode hides fl_chart\'s own dot — the widget-space '
        'overlay provides it (line_chart_painter.dart:130-136 cannot paint '
        'at a non-spot coordinate)', () {
      final Stack stack = _buildSmooth(
        onScrubPositionChanged: (double x, double y) {},
      ) as Stack;
      final LineChart chart = stack.children.whereType<LineChart>().first;
      final LineChartBarData barData = chart.data.lineBarsData.first;
      final TouchedSpotIndicatorData indicator = chart.data.lineTouchData
          .getTouchedSpotIndicator(barData, <int>[0])
          .first!;
      expect(indicator.touchedSpotDotData.show, isFalse);
      // The vertical rule is UNCHANGED — still borderControl, 1px.
      expect(indicator.indicatorBelowLine.color, const Color(0xFF3A3F4E));
      expect(indicator.indicatorBelowLine.strokeWidth, 1);
    });

    testWidgets('Test 1: hover forwards continuous chartX + interpolated Y '
        '(real PointerDeviceKind.mouse hover, non-spot x)',
        (WidgetTester tester) async {
      // Spots: (i, i*10 + 5) for i in 0..9 — y = 10x + 5 exactly, so the
      // interpolated y at chartX=2.5 must be 30.0.
      final List<(double, double)> received = <(double, double)>[];
      final Rect plot = await _pumpSmoothAndGetRect(
        tester,
        _buildSmooth(
          onScrubPositionChanged: (double x, double y) =>
              received.add((x, y)),
        ),
      );

      // data.minX=0, data.maxX=9, yBounds=(0,100): chartX=2.5 sits at
      // 2.5/9 of the plot width from the left edge (mirror of fl_chart's
      // axis_chart_painter.getPixelX linear mapping).
      final Offset target =
          Offset(plot.left + plot.width * (2.5 / 9.0), plot.center.dy);

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(target);
      await tester.pump();

      expect(received, isNotEmpty,
          reason: 'hover move must fire onScrubPositionChanged');
      final (double chartX, double interpY) = received.last;
      expect(chartX, closeTo(2.5, 0.05),
          reason: 'chartX must be the CONTINUOUS pointer x, not a '
              'snapped spot index — got $chartX');
      expect(interpY, closeTo(30.0, 0.5),
          reason: 'interpolatedY must be the linear interpolation between '
              'the bracketing samples (10x + 5) — got $interpY');
    });

    testWidgets('Test 2: pan update forwards updated continuous position '
        '(real startGesture/moveBy drag)', (WidgetTester tester) async {
      final List<(double, double)> received = <(double, double)>[];
      final Rect plot = await _pumpSmoothAndGetRect(
        tester,
        _buildSmooth(
          onScrubPositionChanged: (double x, double y) =>
              received.add((x, y)),
        ),
      );

      final Offset start =
          Offset(plot.left + plot.width * (2.5 / 9.0), plot.center.dy);
      final TestGesture drag = await tester.startGesture(start);
      addTearDown(drag.removePointer);
      await tester.pump();
      await drag.moveBy(Offset(plot.width * (2.0 / 9.0), 0));
      await tester.pump();

      expect(received, isNotEmpty,
          reason: 'pan update must fire onScrubPositionChanged');
      final (double chartX, double interpY) = received.last;
      expect(chartX, closeTo(4.5, 0.1),
          reason: 'pan update must carry the UPDATED continuous x — '
              'got $chartX');
      expect(interpY, closeTo(50.0, 1.0));
      await drag.up();
      await tester.pump();
    });

    testWidgets('Test 3: long-press move forwards continuous position '
        '(real long-press gesture)', (WidgetTester tester) async {
      final List<(double, double)> received = <(double, double)>[];
      final Rect plot = await _pumpSmoothAndGetRect(
        tester,
        _buildSmooth(
          onScrubPositionChanged: (double x, double y) =>
              received.add((x, y)),
        ),
      );

      final Offset start =
          Offset(plot.left + plot.width * (2.5 / 9.0), plot.center.dy);
      final TestGesture press = await tester.startGesture(start);
      addTearDown(press.removePointer);
      // Exceed kLongPressTimeout so the LongPressGestureRecognizer fires.
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await press.moveBy(Offset(plot.width * (2.0 / 9.0), 0));
      await tester.pump();

      expect(received, isNotEmpty,
          reason: 'long-press move must fire onScrubPositionChanged');
      final (double chartX, double _) = received.last;
      expect(chartX, closeTo(4.5, 0.1),
          reason: 'long-press move must carry the continuous x — '
              'got $chartX');
      await press.up();
      await tester.pump();
    });

    testWidgets('Test 4: discrete tap does NOT fire onScrubPositionChanged '
        '— only onSpotTouched (existing snap selection preserved)',
        (WidgetTester tester) async {
      final List<(double, double)> positions = <(double, double)>[];
      final List<(int, bool)> spots = <(int, bool)>[];
      final Rect plot = await _pumpSmoothAndGetRect(
        tester,
        _buildSmooth(
          onScrubPositionChanged: (double x, double y) =>
              positions.add((x, y)),
          onSpotTouched: (int i, bool isTap) => spots.add((i, isTap)),
        ),
      );

      // Tap exactly on spot 4's pixel (chartX=4 → 4/9 of plot width).
      final Offset tapPoint =
          Offset(plot.left + plot.width * (4.0 / 9.0), plot.center.dy);
      await tester.tapAt(tapPoint);
      await tester.pump();

      expect(spots, isNotEmpty,
          reason: 'tap must still select the nearest spot');
      expect(spots.last.$1, 4);
      expect(spots.last.$2, isTrue,
          reason: 'tap is a discrete-tap selection');
      expect(positions, isEmpty,
          reason: 'discrete taps carry no continuous-position intent — '
              'the seam fires on hover/pan-move/long-press-move only');
    });

    testWidgets('overlay dot paints at the interpolated pixel while hovering '
        '(widget-space Stack overlay, IgnorePointer-wrapped)',
        (WidgetTester tester) async {
      final Rect plot = await _pumpSmoothAndGetRect(
        tester,
        _buildSmooth(onScrubPositionChanged: (double x, double y) {}),
      );

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
        Offset(plot.left + plot.width * (2.5 / 9.0), plot.center.dy),
      );
      await tester.pump();

      // The overlay dot is a Container wrapped in IgnorePointer, a direct
      // descendant of the smooth-mode Stack (via Positioned).
      final Finder dot = find.descendant(
        of: find.byType(Stack),
        matching: find.descendant(
          of: find.byType(IgnorePointer),
          matching: find.byType(Container),
        ),
      );
      expect(dot, findsOneWidget,
          reason: 'smooth mode paints the interpolated dot overlay');
      final Offset dotCenter = tester.getCenter(dot);

      // Expected pixel: x = left + width * (2.5/9); y interpolates to
      // 30.0 over yBounds (0,100) → top + height * (1 - 0.30).
      expect(
          dotCenter.dx, closeTo(plot.left + plot.width * (2.5 / 9.0), 2.0));
      expect(dotCenter.dy, closeTo(plot.top + plot.height * 0.70, 2.0));
    });

    testWidgets('overlay dot clears when the gesture ends (pan end)',
        (WidgetTester tester) async {
      final Rect plot = await _pumpSmoothAndGetRect(
        tester,
        _buildSmooth(onScrubPositionChanged: (double x, double y) {}),
      );

      final TestGesture drag = await tester.startGesture(
        Offset(plot.left + plot.width * (2.5 / 9.0), plot.center.dy),
      );
      addTearDown(drag.removePointer);
      await tester.pump();
      await drag.moveBy(Offset(plot.width * (1.0 / 9.0), 0));
      await tester.pump();

      final Finder dot = find.descendant(
        of: find.byType(Stack),
        matching: find.descendant(
          of: find.byType(IgnorePointer),
          matching: find.byType(Container),
        ),
      );
      expect(dot, findsOneWidget);

      await drag.up();
      await tester.pump();
      expect(dot, findsNothing,
          reason: 'gesture end must clear the interpolated dot overlay');
    });

    testWidgets('smooth mode keeps the snapped vertical rule hit-testing — '
        'onSpotTouched still fires during smooth-mode hover',
        (WidgetTester tester) async {
      final List<(int, bool)> spots = <(int, bool)>[];
      final Rect plot = await _pumpSmoothAndGetRect(
        tester,
        _buildSmooth(
          onScrubPositionChanged: (double x, double y) {},
          onSpotTouched: (int i, bool isTap) => spots.add((i, isTap)),
        ),
      );

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      // Hover near spot 4's pixel.
      await mouse.moveTo(
        Offset(plot.left + plot.width * (4.0 / 9.0), plot.center.dy),
      );
      await tester.pump();

      expect(spots, isNotEmpty,
          reason: 'snapped spot selection must remain live in smooth '
              'mode — the vertical rule still tracks the nearest spot');
      expect(spots.last.$1, 4);
    });

    test('assert: onScrubPositionChanged without smoothSpots throws', () {
      expect(
        () => buildScaffoldLineChart(
          spots: _spots(),
          plotHeight: 300.0,
          plotWidth: 400.0,
          lineColor: const Color(0xFF00EAAE),
          borderControl: const Color(0xFF3A3F4E),
          borderSubtle: const Color(0x1FFFFFFF),
          textSecondary: const Color(0xFF8A8F9D),
          axisLabelStyle: const TextStyle(fontSize: 11),
          reducedMotion: false,
          yBounds: _bounds(),
          onScrubPositionChanged: (double x, double y) {},
          // smoothSpots deliberately omitted — the interpolation helper
          // has nothing to read without it.
        ),
        throwsAssertionError,
      );
    });

    test('callback-level contract: tap forwards no position even when the '
        'seam is wired (hover does)', () {
      final List<(double, double)> positions = <(double, double)>[];
      final Stack stack = _buildSmooth(
        onScrubPositionChanged: (double x, double y) =>
            positions.add((x, y)),
        onSpotTouched: (int i, bool isTap) {},
      ) as Stack;
      final LineChart chart = stack.children.whereType<LineChart>().first;

      chart.data.lineTouchData.touchCallback!(
        FlTapDownEvent(TapDownDetails()),
        _coordResponse(2.5, 30.0),
      );
      expect(positions, isEmpty);

      chart.data.lineTouchData.touchCallback!(
        const FlPointerHoverEvent(PointerHoverEvent()),
        _coordResponse(2.5, 30.0),
      );
      expect(positions, <(double, double)>[(2.5, 30.0)]);
    });
  });
}
