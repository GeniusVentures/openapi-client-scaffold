import 'package:fl_chart/fl_chart.dart';
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
  ValueChanged<int>? onSpotTouched,
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
          chart.data.lineTouchData.getTouchedSpotIndicator!(
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
      final List<int> received = <int>[];
      final LineChart chart = _buildFramed(
        reducedMotion: false,
        onSpotTouched: received.add,
      ) as LineChart;

      final LineChartBarData barData = chart.data.lineBarsData.first;
      final LineBarSpot spot =
          LineBarSpot(barData, 3, const FlSpot(3, 35));
      final LineTouchResponse response =
          LineTouchResponse(<LineBarSpot>[spot]);

      chart.data.lineTouchData.touchCallback!(
        FlTapDownEvent(),
        response,
      );
      expect(received, <int>[3]);
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
        onSpotTouched: (int _) {},
      ) as LineChart;
      expect(chart.data.lineTouchData.enabled, isTrue);
    });
  });
}
