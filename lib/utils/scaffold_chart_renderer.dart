/// fl_chart-backed LineChart builder — the ONLY scaffold file importing
/// `package:fl_chart` (D-02 / D-08 support-part isolation).
///
/// The renderer is a pure function from (spots, geometry, theme tokens,
/// callbacks) to a configured `LineChart` widget. Base atoms in
/// `lib/components/` call this — they do NOT import fl_chart.
///
/// All fl_chart API surface (`LineChart`, `LineChartData`, `LineTouchData`,
/// `FlGridData`, `FlTitlesData`, `FlDotCirclePainter`) is concentrated in
/// this one auditable location so that:
///
/// - base atoms don't pay the fl_chart dependency cost;
/// - a consumer swapping chart engines replaces exactly one file;
/// - fl_chart API churn is contained.
///
/// ## reducedMotion contract
///
/// fl_chart 1.2.0 does not animate implicitly when handed static data —
/// animations exist only when the consumer re-creates the widget with new
/// data (and even then only via explicit `swapAnimationDuration` on
/// `LineChart`). Because this renderer hands static data, the
/// `reducedMotion` parameter is a **pass-through contract**: it is
/// documented and required at the boundary so callers respect D-07
/// reduced-motion gating, but no code here reads it. If a future variant
/// introduces explicit swap animation, this parameter MUST be the gate.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'chart_geometry.dart';

/// The line bar's stroke width in logical pixels.
const double _kChartBarWidth = 2.0;

/// Radius of the touched-spot indicator dot in logical pixels.
const double _kTouchedDotRadius = 5.0;

/// Stroke width of the touched-spot indicator ring in logical pixels.
const double _kTouchedDotStrokeWidth = 4.0;

/// Stroke width of the scrub vertical rule in logical pixels.
const double _kScrubLineStrokeWidth = 1.0;

/// Stroke width of the framed chart's horizontal gridlines.
const double _kGridLineStrokeWidth = 1.0;

/// Horizontal gap between a Y-axis gridline and its label.
const double _kAxisLabelGap = 8.0;

/// Alpha of the below-bar fill gradient at the top of the plot.
const double _kFillGradientTopAlpha = 0.26;

/// Alpha of the below-bar fill gradient at the fade-stop point.
const double _kFillGradientBottomAlpha = 0.0;

/// Alpha of the framed chart's horizontal gridline color (WCAG 1.4.11
/// exempts graduated gridlines from the 3:1 gate — see GeniusWallet port
/// comments).
const double _kGridLineAlpha = 0.06;

/// Alpha of the touched-spot indicator ring color.
const double _kTouchedDotRingAlpha = 0.26;

/// Builds a fully-configured `LineChart` widget from scaffold-neutral
/// inputs.
///
/// This is the single entry point for the fl_chart seam. The caller
/// (typically `ScaffoldChart`) resolves:
///
/// - the `spots` list (already mapped from `List<T>` via accessors);
/// - the `yBounds` pair (already computed via `chartBandedBounds` or
///   `chartYBounds` — the renderer NEVER recomputes them);
/// - the palette-derived colors and axis label text style;
/// - the `reducedMotion` flag (documented pass-through — see library
///   doc comment above).
///
/// Selection between the framed (scheme B, plot height ≥
/// `kChartFrameMinHeight`) and axis-free (scheme A) variants is automatic
/// via `chartUsesFrame(plotHeight)`.
///
/// Returns `SizedBox.shrink()` if `spots` is empty — never constructs a
/// `LineChart` with an empty series.
Widget buildScaffoldLineChart({
  required List<ChartPoint> spots,
  required double plotHeight,
  required double plotWidth,
  required Color lineColor,
  required Color borderControl,
  required Color borderSubtle,
  required Color textSecondary,
  required TextStyle axisLabelStyle,
  required bool reducedMotion,
  required (double, double) yBounds,
  ValueChanged<int>? onSpotTouched,
  double? viewMinX,
  double? viewMaxX,
  double? minX,
  double? maxX,
}) {
  if (spots.isEmpty) {
    return const SizedBox.shrink();
  }

  // plotWidth is part of the public contract so the caller's geometry
  // decisions (X-label count, band bounds) are taken with the SAME width
  // the renderer sees. The renderer itself does not currently branch on
  // plotWidth — fl_chart sizes from its parent's constraints — but
  // keeping the parameter prevents a silent contract break if a future
  // variant needs it (e.g. axis-free label count computed inside the
  // renderer).
  assert(plotWidth > 0, 'plotWidth must be positive');

  // reducedMotion is a pass-through contract parameter. fl_chart does
  // not animate static data, so there is nothing to disable here; the
  // parameter exists so callers remember to gate any future animation.
  // Documented in the library doc comment above.
  assert(reducedMotion == true || reducedMotion == false,
      'reducedMotion must be explicit');

  // viewMinX / viewMaxX are used by the CALLER to compute yBounds and
  // the visible-window X labels. They are part of the contract so the
  // caller's computation is auditable against the rendered window.
  // The renderer hands minX/maxX directly to fl_chart.
  final double effectiveMinX = minX ?? spots.first.x;
  final double effectiveMaxX = maxX ?? spots.last.x;
  assert(
    viewMinX == null || viewMinX <= effectiveMaxX,
    'viewMinX must not exceed effective maxX',
  );
  assert(
    viewMaxX == null || viewMaxX >= effectiveMinX,
    'viewMaxX must not precede effective minX',
  );

  final (double yLo, double yHi) = yBounds;
  final bool useFrame = chartUsesFrame(plotHeight);

  // For the framed chart, gridlines and right-side titles BOTH iterate
  // from the axis baseline by `interval` — handing them the same step
  // makes every label land on a gridline by construction (see the
  // GeniusWallet port source comment).
  double step = 1.0;
  if (useFrame) {
    final (_, double s) = chartTickStep(
      yLo,
      yHi,
      chartYTickCount(plotHeight - kChartTimeRowHeight),
    );
    step = s;
  }

  final LineChartBarData barData = LineChartBarData(
    spots: <FlSpot>[
      for (final ChartPoint p in spots) FlSpot(p.x, p.y),
    ],
    isCurved: false,
    color: lineColor,
    barWidth: _kChartBarWidth,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: <Color>[
          lineColor.withValues(alpha: _kFillGradientTopAlpha),
          lineColor.withValues(alpha: _kFillGradientBottomAlpha),
        ],
        // fl_chart shades this gradient over `belowBarLargestRect` (top
        // of the highest spot to the plot floor) — the SAME box the
        // design sketch's `objectBoundingBox` gradient spanned, so the
        // kChartFillFadeStop constant ports 1:1.
        stops: const <double>[0.0, kChartFillFadeStop],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
  );

  final FlGridData gridData = useFrame
      ? FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) => FlLine(
            color: borderSubtle.withValues(alpha: _kGridLineAlpha),
            strokeWidth: _kGridLineStrokeWidth,
          ),
        )
      : const FlGridData(show: false);

  final FlBorderData borderData = FlBorderData(show: false);
  const AxisTitles hiddenAxis = AxisTitles(
    sideTitles: SideTitles(showTitles: false),
  );

  final FlTitlesData titlesData = useFrame
      ? FlTitlesData(
          leftTitles: hiddenAxis,
          topTitles: hiddenAxis,
          // Bottom titles are NEVER used (D-06): fl_chart anchors its x
          // intervals to baselineX, which cannot express epoch-second
          // sample positions. The atom renders X labels as a separate
          // Row of Texts below the LineChart.
          bottomTitles: hiddenAxis,
          // Right side because on a time series the newest value sits at
          // the right edge and would otherwise be furthest from its own
          // scale (de-facto convention — see GeniusWallet port comment).
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: kChartAxisGutter,
              interval: step,
              // MUST be false — otherwise fl_chart ALSO prints the raw
              // padded minY/maxY, which are not on the nice-number
              // ladder.
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (double value, TitleMeta meta) =>
                  SideTitleWidget(
                meta: meta,
                space: _kAxisLabelGap,
                child: Text(
                  chartAxisLabel(value, step),
                  style: axisLabelStyle,
                ),
              ),
            ),
          ),
        )
      : const FlTitlesData(
          leftTitles: hiddenAxis,
          topTitles: hiddenAxis,
          bottomTitles: hiddenAxis,
          rightTitles: hiddenAxis,
        );

  final LineTouchData lineTouchData = LineTouchData(
    enabled: onSpotTouched != null,
    handleBuiltInTouches: true,
    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
      final LineBarSpot? spot = response?.lineBarSpots?.firstOrNull;
      if (spot != null) {
        onSpotTouched?.call(spot.spotIndex);
      }
    },
    // Full-height crosshair: the line runs floor to ceiling instead of
    // stopping at the touched spot.
    getTouchLineStart: (LineChartBarData bar, int index) => yLo,
    getTouchLineEnd: (LineChartBarData bar, int index) => yHi,
    getTouchedSpotIndicator:
        (LineChartBarData bar, List<int> spotIndexes) {
      return spotIndexes.map((int index) {
        return TouchedSpotIndicatorData(
          // borderControl (3.30:1 dark / 3.10:1 light) clears WCAG
          // 1.4.11's 3:1 gate for a meaningful graphical object;
          // borderStrong (2.10:1) did not.
          FlLine(
            color: borderControl,
            strokeWidth: _kScrubLineStrokeWidth,
          ),
          FlDotData(
            getDotPainter:
                (FlSpot spot, double percent, LineChartBarData bar,
                        int index) =>
                    FlDotCirclePainter(
              radius: _kTouchedDotRadius,
              color: lineColor,
              strokeWidth: _kTouchedDotStrokeWidth,
              strokeColor:
                  lineColor.withValues(alpha: _kTouchedDotRingAlpha),
            ),
          ),
        );
      }).toList();
    },
    // Tooltip ALWAYS suppressed — no floating bubble paints over the
    // data. The consumer renders the readout externally.
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => Colors.transparent,
      tooltipBorder: BorderSide.none,
      tooltipPadding: EdgeInsets.zero,
      getTooltipItems: (List<LineBarSpot> touchedSpots) =>
          touchedSpots.map((_) => null).toList(),
    ),
  );

  return LineChart(
    LineChartData(
      clipData: const FlClipData.all(),
      minX: effectiveMinX,
      maxX: effectiveMaxX,
      minY: yLo,
      maxY: yHi,
      lineBarsData: <LineChartBarData>[barData],
      gridData: gridData,
      borderData: borderData,
      titlesData: titlesData,
      lineTouchData: lineTouchData,
    ),
  );
}
