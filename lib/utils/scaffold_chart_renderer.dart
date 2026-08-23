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
///
/// ## D-08 smooth-scrub contract
///
/// When [buildScaffoldLineChart]'s `onScrubPositionChanged` is non-null,
/// the renderer enters SMOOTH mode:
///
/// - the touch callback fires the callback on `FlPointerHoverEvent`,
///   `FlPanUpdateEvent`, and `FlLongPressMoveUpdate` with the pointer's
///   CONTINUOUS chart-x (via `LineTouchResponse.touchChartCoordinate`)
///   and the linearly interpolated y between the bracketing samples —
///   distinct from `ScaffoldSpotTouched`, which carries the SNAPPED spot
///   index;
/// - fl_chart's own touched-spot DOT is suppressed
///   (`FlDotData(show: false)`) — `line_chart_painter.dart` derives the
///   indicator x from `barData.spots[index]`, so it CANNOT paint at a
///   non-spot coordinate. The dot is painted instead by a widget-space
///   `Stack` overlay whose pixel position mirrors fl_chart's
///   `getPixelX`/`getPixelY` linear mapping
///   (`axis_chart_painter.dart:497-535`);
/// - the overlay clears on gesture end (pan/tap end or cancel) and on
///   pointer exit ([FlPointerExitEvent] — reported to the callback as
///   [kScrubPositionExitSentinel] so the wrapper can suppress the consumer
///   notification).
///
/// When the callback is null (SNAP mode — the WIDG-36 default), the
/// returned widget is the bare `LineChart` with NO Stack wrapper and the
/// existing dot painter unchanged.
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

/// Signature for the renderer's spot-touch callback.
///
/// [spotIndex] indexes into the `spots` list passed to
/// [buildScaffoldLineChart]; [isDiscreteTap] is true only when the touch
/// came from a discrete tap gesture (`FlTapDownEvent`) — hover moves
/// (`FlPointerHoverEvent`) and pan gestures report false so the caller can
/// apply a toggle-clear policy ONLY to taps (UAT regression: hover must
/// never clear a selection).
///
/// Spot selection is forwarded ONLY for intent-carrying events — discrete
/// tap-down, hover move, pan start/update, and long-press start/move.
/// Gesture-END events (`FlTapUpEvent`, `FlPanEndEvent`, cancels) never
/// forward a spot: their spot data would immediately undo a tap-toggle
/// clear (the pointer is still over the same point at tap-up, so a
/// forward would re-select what the tap just cleared).
typedef ScaffoldSpotTouched = void Function(int spotIndex, bool isDiscreteTap);

/// Signature for the renderer's continuous scrub-position callback.
///
/// Fires on hover/pan-move/long-press-move events with the pointer's
/// continuous chart-x and the linearly interpolated y between the
/// bracketing samples. Distinct from [ScaffoldSpotTouched] — that
/// callback carries the SNAPPED spot index; this carries the
/// CONTINUOUS position (D-08).
typedef ScaffoldScrubPositionChanged = void Function(
  double chartX,
  double interpolatedY,
);

/// Sentinel chart-x reported on pointer EXIT ([FlPointerExitEvent]) so the
/// smooth-mode wrapper can clear the interpolated-dot overlay. A pointer
/// exit is not a gesture end, so without this signal the dot would stick
/// after the mouse leaves the chart (CX-2). The wrapper suppresses the
/// consumer callback for this value — exit carries no position intent.
const double kScrubPositionExitSentinel = double.nan;

/// Linearly interpolates the y value at [chartX] between the two
/// bracketing samples in [spots]. Assumes [spots] is sorted by x.
/// Clamps to the first/last sample y when [chartX] is outside the
/// series range. Returns 0 for an empty list (unreachable — the caller
/// guards empty spots before enabling smooth mode).
double _interpolateYAtX(List<ChartPoint> spots, double chartX) {
  if (spots.isEmpty) {
    return 0.0;
  }
  if (chartX <= spots.first.x) {
    return spots.first.y;
  }
  if (chartX >= spots.last.x) {
    return spots.last.y;
  }
  for (int i = 0; i < spots.length - 1; i++) {
    final ChartPoint a = spots[i];
    final ChartPoint b = spots[i + 1];
    if (chartX >= a.x && chartX <= b.x) {
      final double span = b.x - a.x;
      if (span == 0.0) {
        return a.y;
      }
      final double t = (chartX - a.x) / span;
      return a.y + t * (b.y - a.y);
    }
  }
  // Floating-point edge: chartX fell between the final bracket check and
  // the last sample. Clamp to the last sample.
  return spots.last.y;
}

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
///
/// ## Gesture-lifecycle callbacks
///
/// [onScrubGestureStart] / [onScrubGestureEnd] forward fl_chart's
/// gesture-lifecycle events so consumers can gate hover-exit behavior on
/// whether a drag is currently active. The renderer fires
/// `onScrubGestureStart` on `FlPanStartEvent` / `FlTapDownEvent` and
/// `onScrubGestureEnd` on `FlPanEndEvent` / `FlPanCancelEvent` /
/// `FlTapUpEvent` / `FlTapCancelEvent`. These are scaffold-neutral —
/// consumers never see fl_chart types.
///
/// [onScrubPositionChanged] opts into SMOOTH mode (D-08 — see the library
/// doc comment). [smoothSpots] is the SAME visible-spots list the caller
/// passes as `spots`, duplicated as a named parameter so the interpolation
/// helper can access it without the renderer re-deriving visibility. When
/// [onScrubPositionChanged] is non-null, [smoothSpots] MUST also be
/// non-null. When the caller wants smooth visuals without a readout feed
/// it wires an internal no-op here (CX-1: visuals must not be gated on the
/// consumer's optional callback).
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
  ScaffoldSpotTouched? onSpotTouched,
  VoidCallback? onScrubGestureStart,
  VoidCallback? onScrubGestureEnd,
  ScaffoldScrubPositionChanged? onScrubPositionChanged,
  List<ChartPoint>? smoothSpots,
  double? viewMinX,
  double? maxX,
  double? minX,
  double? viewMaxX,
}) {
  if (spots.isEmpty) {
    return const SizedBox.shrink();
  }

  assert(
    onScrubPositionChanged == null || smoothSpots != null,
    'smoothSpots is required when onScrubPositionChanged is wired (D-08) — '
    'the interpolation helper reads the visible spots list',
  );

  if (onScrubPositionChanged == null) {
    // SNAP mode (WIDG-36 default): bare LineChart, no Stack overhead.
    return _buildChart(
      spots: spots,
      plotHeight: plotHeight,
      plotWidth: plotWidth,
      lineColor: lineColor,
      borderControl: borderControl,
      borderSubtle: borderSubtle,
      textSecondary: textSecondary,
      axisLabelStyle: axisLabelStyle,
      reducedMotion: reducedMotion,
      yBounds: yBounds,
      onSpotTouched: onSpotTouched,
      onScrubGestureStart: onScrubGestureStart,
      onScrubGestureEnd: onScrubGestureEnd,
      onScrubPositionChanged: null,
      smoothSpots: null,
      onSmoothPositionPixel: null,
      viewMinX: viewMinX,
      viewMaxX: viewMaxX,
      minX: minX,
      maxX: maxX,
    );
  }

  // SMOOTH mode: the stateful wrapper holds the transient interpolated-dot
  // pixel position and paints the widget-space overlay.
  return _ScaffoldSmoothLineChart(
    spots: spots,
    plotHeight: plotHeight,
    plotWidth: plotWidth,
    lineColor: lineColor,
    borderControl: borderControl,
    borderSubtle: borderSubtle,
    textSecondary: textSecondary,
    axisLabelStyle: axisLabelStyle,
    reducedMotion: reducedMotion,
    yBounds: yBounds,
    onSpotTouched: onSpotTouched,
    onScrubGestureStart: onScrubGestureStart,
    onScrubGestureEnd: onScrubGestureEnd,
    onScrubPositionChanged: onScrubPositionChanged,
    smoothSpots: smoothSpots!,
    viewMinX: viewMinX,
    viewMaxX: viewMaxX,
    minX: minX,
    maxX: maxX,
  );
}

/// Private stateful wrapper for SMOOTH mode (D-08).
///
/// Holds ONLY transient interaction state — the latest interpolated-dot
/// pixel position. All render inputs flow through the constructor; the
/// widget rebuilds cleanly from them.
class _ScaffoldSmoothLineChart extends StatefulWidget {
  const _ScaffoldSmoothLineChart({
    required this.spots,
    required this.plotHeight,
    required this.plotWidth,
    required this.lineColor,
    required this.borderControl,
    required this.borderSubtle,
    required this.textSecondary,
    required this.axisLabelStyle,
    required this.reducedMotion,
    required this.yBounds,
    required this.onScrubPositionChanged,
    required this.smoothSpots,
    this.onSpotTouched,
    this.onScrubGestureStart,
    this.onScrubGestureEnd,
    this.viewMinX,
    this.viewMaxX,
    this.minX,
    this.maxX,
  });

  final List<ChartPoint> spots;
  final double plotHeight;
  final double plotWidth;
  final Color lineColor;
  final Color borderControl;
  final Color borderSubtle;
  final Color textSecondary;
  final TextStyle axisLabelStyle;
  final bool reducedMotion;
  final (double, double) yBounds;
  final ScaffoldSpotTouched? onSpotTouched;
  final VoidCallback? onScrubGestureStart;
  final VoidCallback? onScrubGestureEnd;
  final ScaffoldScrubPositionChanged onScrubPositionChanged;
  final List<ChartPoint> smoothSpots;
  final double? viewMinX;
  final double? viewMaxX;
  final double? minX;
  final double? maxX;

  @override
  State<_ScaffoldSmoothLineChart> createState() =>
      _ScaffoldSmoothLineChartState();
}

class _ScaffoldSmoothLineChartState extends State<_ScaffoldSmoothLineChart> {
  /// Latest interpolated-dot position in STACK-LOCAL pixels (the Stack
  /// sizes to the LineChart, so chart-local == stack-local). Null when no
  /// smooth scrub is active (before first hover / after gesture end).
  Offset? _smoothDotPosition;

  /// Key on the inner [LineChart] so the pixel mapping can read the chart's
  /// ACTUAL laid-out width. fl_chart's getPixelX maps over the chart's
  /// real usable size (axis_chart_painter.dart:497-512); the `plotWidth`
  /// contract parameter is the caller's geometry estimate and can diverge
  /// from the laid-out width, so the dot must track the real one.
  final GlobalKey _chartKey = GlobalKey();

  void _handleSmoothPixel(Offset? pixel) {
    // Skip the setState when nothing actually changed — on gesture end
    // with no active smooth scrub _smoothDotPosition is already null, and
    // rebuilding the wrapper would be wasted work.
    if (pixel == _smoothDotPosition) {
      return;
    }
    setState(() => _smoothDotPosition = pixel);
  }

  /// Routes the renderer's continuous-position events: updates the overlay
  /// on real positions and forwards them to the consumer — EXCEPT the
  /// exit sentinel, which only clears the overlay (the caller's callback
  /// may be an internal no-op when the consumer omitted onPositionChanged,
  /// and exit carries no position intent either way).
  void _onRendererPosition(double chartX, double interpolatedY) {
    if (chartX.isNaN) {
      return; // pointer exit — overlay already cleared by the renderer
    }
    widget.onScrubPositionChanged(chartX, interpolatedY);
  }

  /// The inner chart's current laid-out size, falling back to the
  /// `plotWidth`/`plotHeight` contract parameters before first layout.
  Size _actualPlotSize() {
    final RenderBox? box =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    final Size s = box?.size ?? Size.zero;
    return s.width > 0 && s.height > 0
        ? s
        : Size(widget.plotWidth, widget.plotHeight);
  }

  @override
  Widget build(BuildContext context) {
    final Widget chart = KeyedSubtree(
      key: _chartKey,
      child: _buildChart(
        spots: widget.spots,
        plotHeight: widget.plotHeight,
        plotWidth: widget.plotWidth,
        lineColor: widget.lineColor,
        borderControl: widget.borderControl,
        borderSubtle: widget.borderSubtle,
        textSecondary: widget.textSecondary,
        axisLabelStyle: widget.axisLabelStyle,
        reducedMotion: widget.reducedMotion,
        yBounds: widget.yBounds,
        onSpotTouched: widget.onSpotTouched,
        onScrubGestureStart: widget.onScrubGestureStart,
        onScrubGestureEnd: widget.onScrubGestureEnd,
        onScrubPositionChanged: _onRendererPosition,
        smoothSpots: widget.smoothSpots,
        onSmoothPositionPixel: _handleSmoothPixel,
        actualPlotSize: _actualPlotSize,
        viewMinX: widget.viewMinX,
        viewMaxX: widget.viewMaxX,
        minX: widget.minX,
        maxX: widget.maxX,
      ),
    );

    final Offset? dot = _smoothDotPosition;
    return Stack(
      children: <Widget>[
        chart,
        if (dot != null)
          Positioned(
            left: dot.dx - _kTouchedDotRadius,
            top: dot.dy - _kTouchedDotRadius,
            child: IgnorePointer(
              child: Container(
                width: _kTouchedDotRadius * 2,
                height: _kTouchedDotRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.lineColor,
                  border: Border.all(
                    color: widget.lineColor
                        .withValues(alpha: _kTouchedDotRingAlpha),
                    width: _kTouchedDotStrokeWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shared chart builder — the single site where `LineChart` is
/// constructed. SNAP mode calls this directly; SMOOTH mode calls it from
/// [_ScaffoldSmoothLineChartState.build] with [onSmoothPositionPixel]
/// wired so the overlay can track the interpolated dot.
///
/// [onSmoothPositionPixel] receives the dot's chart-local pixel position
/// on every continuous-position event, and null on gesture end. It is
/// invoked synchronously from the touch callback; the receiver (the
/// wrapper state) applies it via setState.
///
/// [actualPlotSize] resolves the chart's REAL laid-out size at event
/// time (smooth mode only). When null, the [plotWidth]/[plotHeight]
/// parameters are used directly (snap mode never maps pixels, so the
/// estimate is harmless).
Widget _buildChart({
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
  required ScaffoldScrubPositionChanged? onScrubPositionChanged,
  required List<ChartPoint>? smoothSpots,
  required ValueChanged<Offset?>? onSmoothPositionPixel,
  Size Function()? actualPlotSize,
  ScaffoldSpotTouched? onSpotTouched,
  VoidCallback? onScrubGestureStart,
  VoidCallback? onScrubGestureEnd,
  double? viewMinX,
  double? viewMaxX,
  double? minX,
  double? maxX,
}) {

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
    // Enable touch handling whenever ANY touch callback is wired — spot
    // touches, gesture lifecycle, or both. Otherwise the gesture-lifecycle
    // plumbing would silently no-op when the consumer only wants drag
    // notifications (no selection).
    enabled: onSpotTouched != null ||
        onScrubGestureStart != null ||
        onScrubGestureEnd != null ||
        onScrubPositionChanged != null,
    handleBuiltInTouches: true,
    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
      // Forward gesture lifecycle so consumers can distinguish "drag in
      // progress" from "hover only" and gate their PointerExit behavior.
      // fl_chart dispatches FlPanStartEvent/FlTapDownEvent at gesture start
      // and FlPanEndEvent/FlPanCancelEvent/FlTapUpEvent/FlTapCancelEvent at
      // gesture end — this mapping is fl_chart's documented contract.
      final bool isGestureEnd = event is FlPanEndEvent ||
          event is FlPanCancelEvent ||
          event is FlTapUpEvent ||
          event is FlTapCancelEvent;
      if (event is FlPanStartEvent || event is FlTapDownEvent) {
        onScrubGestureStart?.call();
      } else if (isGestureEnd) {
        onScrubGestureEnd?.call();
      }

      // D-08 continuous-position forwarding: hover/pan-move/long-press-move
      // carry the pointer's continuous chart-x via touchChartCoordinate
      // (line_chart_renderer.dart getResponseAtLocation populates it from
      // painter.getChartCoordinateFromPixel; render_base_chart.dart
      // _notifyTouchEvent forwards it on every event with a localPosition).
      // Discrete taps are EXCLUDED — tap selection flows through
      // onSpotTouched (snap contract preserved).
      if (onScrubPositionChanged != null && smoothSpots != null) {
        if (isGestureEnd) {
          // Gesture end clears the interpolated-dot overlay.
          onSmoothPositionPixel?.call(null);
        } else if (event is FlPointerExitEvent) {
          // Pointer EXIT is not a gesture end (CX-2): without this branch
          // the dot would stick after the mouse leaves the chart. Clear
          // the overlay and signal exit via the NaN sentinel so the wrapper
          // can suppress the consumer callback (exit carries no position).
          onSmoothPositionPixel?.call(null);
          onScrubPositionChanged(kScrubPositionExitSentinel, 0.0);
        } else if (event is FlPointerHoverEvent ||
            event is FlPanUpdateEvent ||
            event is FlLongPressMoveUpdate) {
          final Offset? chartCoord = response?.touchChartCoordinate;
          if (chartCoord != null) {
            final double interpY = _interpolateYAtX(smoothSpots, chartCoord.dx);
            onScrubPositionChanged(chartCoord.dx, interpY);

            // Mirror fl_chart's getPixelX/getPixelY linear mapping
            // (axis_chart_painter.dart:497-535) so the widget-space overlay
            // can paint the dot at the continuous position — fl_chart's own
            // indicator cannot (it derives x from barData.spots[index]).
            //
            // The mapping uses the USABLE plot width/height: fl_chart's
            // getPixelX maps over getChartUsableSize, which for the framed
            // variant EXCLUDES the right-titles gutter (kChartAxisGutter)
            // from the width. pixelX/pixelY are relative to the LineChart's
            // own box top-left, which the smooth-mode Stack sizes to, so
            // they are directly usable as Stack-local Positioned coords.
            final Size actual =
                actualPlotSize?.call() ?? Size(plotWidth, plotHeight);
            final double usableWidth =
                actual.width - (useFrame ? kChartAxisGutter : 0.0);
            final double usableHeight = actual.height;
            final double xSpan = effectiveMaxX - effectiveMinX;
            final double ySpan = yHi - yLo;
            if (xSpan > 0 && ySpan > 0 && usableWidth > 0 && usableHeight > 0) {
              final double pixelX =
                  ((chartCoord.dx - effectiveMinX) / xSpan) * usableWidth;
              final double pixelY =
                  usableHeight - ((interpY - yLo) / ySpan) * usableHeight;
              onSmoothPositionPixel?.call(Offset(pixelX, pixelY));
            }
          }
        }
      }

      final LineBarSpot? spot = response?.lineBarSpots?.firstOrNull;
      if (spot != null) {
        // Event-kind discrimination (UAT regression): fl_chart fires
        // FlPointerHoverEvent through this callback on EVERY hover move
        // (render_base_chart.handleEvent), and re-fires it for a stationary
        // mouse whenever the chart rebuilds. Only FlTapDownEvent marks a
        // discrete tap — the caller applies its toggle-clear policy solely
        // to taps; hover/pan hits always carry isDiscreteTap=false.
        //
        // Gesture-END events (FlTapUpEvent / FlPanEndEvent / cancels)
        // carry no new positional intent and are NOT forwarded — a tap-up
        // forward would immediately re-select the point a tap-toggle just
        // cleared (the pointer is still over it at tap-up).
        final bool isSelectionIntent = event is FlTapDownEvent ||
            event is FlPointerHoverEvent ||
            event is FlPanDownEvent ||
            event is FlPanStartEvent ||
            event is FlPanUpdateEvent ||
            event is FlLongPressStart ||
            event is FlLongPressMoveUpdate;
        if (isSelectionIntent) {
          onSpotTouched?.call(spot.spotIndex, event is FlTapDownEvent);
        }
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
          // D-08: in smooth mode fl_chart's own dot is HIDDEN — it can only
          // paint at a snapped spot coordinate (line_chart_painter.dart
          // reads barData.spots[index]), while the smooth dot rides the
          // continuous pointer x. The widget-space Stack overlay paints
          // the interpolated dot instead. The vertical rule above is
          // unchanged (full-height crosshair still tracks the nearest
          // spot).
          onScrubPositionChanged != null
              ? const FlDotData(show: false)
              : FlDotData(
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
