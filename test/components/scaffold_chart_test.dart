import 'dart:ui' show FontFeature;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_chart.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Domain type used to prove the generic `T` flows through accessors.
class _TestPoint {
  const _TestPoint(this.x, this.y);
  final int x;
  final int y;
}

/// Deterministic 5-point series — used by both the framed and axis-free
/// layout tests.
List<_TestPoint> _fivePoints() {
  return const <_TestPoint>[
    _TestPoint(0, 10),
    _TestPoint(1, 30),
    _TestPoint(2, 20),
    _TestPoint(3, 50),
    _TestPoint(4, 40),
  ];
}

/// Pump helper. Wraps the chart in a MaterialApp + bounded SizedBox so the
/// LayoutBuilder in the atom always sees a finite maxHeight. Width is fixed
/// at 400px so `chartXLabelCount(plotWidth: 400, sampleCount: 5)` is stable.
Future<void> _pump(
  WidgetTester tester,
  Widget chart, {
  double height = 300,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 400, height: height, child: chart),
        ),
      ),
    ),
  );
}

/// Default-chart convenience — a framed ScaffoldChart<int> over `_fivePoints`.
Widget _defaultChart({
  double? plotHeight,
  Color? lineColor,
  String? semanticsLabel,
  String Function(double)? xLabelFormatter,
  String Function(double, double)? yLabelFormatter,
  ValueChanged<_TestPoint>? onPointSelected,
  List<_TestPoint>? series,
}) {
  final List<_TestPoint> points = series ?? _fivePoints();
  return ScaffoldChart<_TestPoint>(
    series: points,
    xAccessor: (_TestPoint p) => p.x.toDouble(),
    yAccessor: (_TestPoint p) => p.y.toDouble(),
    plotHeight: plotHeight,
    lineColor: lineColor,
    semanticsLabel: semanticsLabel,
    xLabelFormatter: xLabelFormatter,
    yLabelFormatter: yLabelFormatter,
    onPointSelected: onPointSelected,
  );
}

/// Reads the LineChart pumped inside the ScaffoldChart under test.
LineChart _lineChart(WidgetTester tester) {
  return tester.widget<LineChart>(find.byType(LineChart));
}

void main() {
  group('ScaffoldChart', () {
    testWidgets('Test 1: empty series renders SizedBox.shrink inside '
        'Semantics(label: Chart)', (WidgetTester tester) async {
      await _pump(
        tester,
        ScaffoldChart<int>(
          series: const <int>[],
          xAccessor: (int v) => v.toDouble(),
          yAccessor: (int v) => v.toDouble(),
        ),
      );

      // SizedBox.shrink is the visual empty state.
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(LineChart), findsNothing);

      // The outer Semantics wrapper defaults to 'Chart'.
      final Semantics semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(ScaffoldChart<int>),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.properties.label, 'Chart');
    });

    testWidgets('Test 2: framed chart (plotHeight 300) renders X-axis Row '
        'of Text widgets', (WidgetTester tester) async {
      await _pump(tester, _defaultChart(plotHeight: 300));

      // Framed: a Row of Texts below the LineChart carries the X labels.
      final Finder rows = find.descendant(
        of: find.byType(ScaffoldChart<_TestPoint>),
        matching: find.byType(Row),
      );
      expect(rows, findsWidgets);

      bool sawXLabelRow = false;
      for (final Element el in rows.evaluate()) {
        final Row row = el.widget as Row;
        if (row.children.length >= 2 &&
            row.children.every((Widget w) => w is Text)) {
          sawXLabelRow = true;
          break;
        }
      }
      expect(sawXLabelRow, isTrue,
          reason: 'framed chart must render a Row of >=2 Text X-labels');
    });

    testWidgets('Test 3: axis-free chart (plotHeight 100) renders NO X-axis '
        'Row of Text widgets', (WidgetTester tester) async {
      await _pump(tester, _defaultChart(plotHeight: 100), height: 100);

      final Finder rows = find.descendant(
        of: find.byType(ScaffoldChart<_TestPoint>),
        matching: find.byType(Row),
      );
      // Either no Row at all, or no Row containing >=2 Texts.
      for (final Element el in rows.evaluate()) {
        final Row row = el.widget as Row;
        final bool looksLikeXAxis = row.children.length >= 2 &&
            row.children.every((Widget w) => w is Text);
        expect(looksLikeXAxis, isFalse,
            reason: 'axis-free chart must NOT render a Text-only Row');
      }
    });

    testWidgets('Test 4: theme tokens — palette.lightGreenPrimary becomes '
        'the LineChartBarData color', (WidgetTester tester) async {
      final ThemeData customTheme = ThemeData(
        extensions: <ThemeExtension<dynamic>>[
          ScaffoldPalette.defaultPalette.copyWith(
            lightGreenPrimary: Colors.red,
          ),
          ScaffoldDimens.defaultDimens,
        ],
      );
      await _pump(tester, _defaultChart(plotHeight: 300), theme: customTheme);

      final LineChart chart = _lineChart(tester);
      expect(chart.data.lineBarsData.first.color, Colors.red);
    });

    testWidgets('Test 5: lineColor override beats the palette default',
        (WidgetTester tester) async {
      await _pump(
        tester,
        _defaultChart(plotHeight: 300, lineColor: Colors.blue),
      );

      final LineChart chart = _lineChart(tester);
      expect(chart.data.lineBarsData.first.color, Colors.blue);
    });

    testWidgets('Test 6: generic T flows through accessors — LineChart spots '
        'match series values', (WidgetTester tester) async {
      int xCalls = 0;
      int yCalls = 0;
      await _pump(
        tester,
        ScaffoldChart<_TestPoint>(
          series: _fivePoints(),
          xAccessor: (_TestPoint p) {
            xCalls++;
            return p.x.toDouble();
          },
          yAccessor: (_TestPoint p) {
            yCalls++;
            return p.y.toDouble();
          },
          plotHeight: 300,
        ),
      );

      // Accessors were called at least once per item.
      expect(xCalls, greaterThanOrEqualTo(5));
      expect(yCalls, greaterThanOrEqualTo(5));

      // The LineChart's FlSpots carry the mapped values.
      final LineChart chart = _lineChart(tester);
      final List<FlSpot> spots = chart.data.lineBarsData.first.spots;
      expect(spots, hasLength(5));
      for (int i = 0; i < 5; i++) {
        expect(spots[i].x, _fivePoints()[i].x.toDouble());
        expect(spots[i].y, _fivePoints()[i].y.toDouble());
      }
    });

    testWidgets('Test 7: semanticsLabel override replaces "Chart"',
        (WidgetTester tester) async {
      await _pump(
        tester,
        _defaultChart(plotHeight: 300, semanticsLabel: 'Price chart'),
      );

      final Semantics semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(ScaffoldChart<_TestPoint>),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.properties.label, 'Price chart');
    });

    testWidgets('Test 8: axisLabelStyle forwarded to the renderer uses '
        'tabularFigures', (WidgetTester tester) async {
      await _pump(tester, _defaultChart(plotHeight: 300));

      // Find any Text widget rendered inside the chart that uses the axis
      // label style. The framed chart's rightTitles render labels with this
      // style — we verify the style by reading one of the X-label Texts.
      final Finder rows = find.descendant(
        of: find.byType(ScaffoldChart<_TestPoint>),
        matching: find.byType(Row),
      );
      TextStyle? axisStyle;
      for (final Element el in rows.evaluate()) {
        final Row row = el.widget as Row;
        if (row.children.length >= 2 &&
            row.children.every((Widget w) => w is Text)) {
          final Text first = row.children.first as Text;
          axisStyle = first.style;
          break;
        }
      }
      expect(axisStyle, isNotNull);
      final List<FontFeature>? features = axisStyle!.fontFeatures;
      expect(features, isNotNull);
      expect(
        features!.any((FontFeature f) => f.feature == 'tnum'),
        isTrue,
        reason: 'axisLabelStyle must include FontFeature.tabularFigures()',
      );
    });

    testWidgets('Test 9: xLabelFormatter overrides the default toStringAsFixed',
        (WidgetTester tester) async {
      await _pump(
        tester,
        _defaultChart(
          plotHeight: 300,
          xLabelFormatter: (double x) => 'T${x.round()}',
        ),
      );

      // The framed X-row should contain Texts like 'T0', 'T1', ...
      final Finder rows = find.descendant(
        of: find.byType(ScaffoldChart<_TestPoint>),
        matching: find.byType(Row),
      );
      final List<String> labels = <String>[];
      for (final Element el in rows.evaluate()) {
        final Row row = el.widget as Row;
        if (row.children.length >= 2 &&
            row.children.every((Widget w) => w is Text)) {
          for (final Widget w in row.children) {
            labels.add((w as Text).data!);
          }
          break;
        }
      }
      expect(labels, isNotEmpty);
      for (final String label in labels) {
        expect(label.startsWith('T'), isTrue,
            reason: 'expected xLabelFormatter output, got "$label"');
      }
    });

    testWidgets('Test 10: touch callback maps spotIndex back to T',
        (WidgetTester tester) async {
      final List<_TestPoint> series = _fivePoints();
      _TestPoint? selected;
      await _pump(
        tester,
        _defaultChart(
          plotHeight: 300,
          series: series,
          onPointSelected: (_TestPoint? p) {
            selected = p;
          },
        ),
      );

      final LineChart chart = _lineChart(tester);
      final LineChartBarData barData = chart.data.lineBarsData.first;
      // Use the EXISTING FlSpot at index 1 — spotIndex is derived via
      // bar.spots.indexOf(spot), so the spot must be identical to an entry.
      final FlSpot spot = barData.spots[1];
      final TouchLineBarSpot touchSpot =
          TouchLineBarSpot(barData, 0, spot, 0.0);
      final LineTouchResponse response = LineTouchResponse(
        touchLocation: Offset.zero,
        touchChartCoordinate: Offset.zero,
        lineBarSpots: <TouchLineBarSpot>[touchSpot],
      );

      chart.data.lineTouchData.touchCallback!(
        FlTapDownEvent(TapDownDetails()),
        response,
      );

      expect(selected, isNotNull);
      expect(identical(selected, series[1]), isTrue);
    });
  });
}
