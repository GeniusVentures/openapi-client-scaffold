/// Pure chart geometry rules — top-level and pure so each one can be
/// tested on its own.
///
/// Ported from GeniusWallet's `lib/chart/chart_axis.dart` (logic only — no
/// money formatting, no chart-library imports). Neutral scaffold contract
/// (D-04): no domain types, no intl, no fl_chart. A chart-axis bug looks
/// like a working chart in every screenshot, which is exactly how the
/// y-window bug in GeniusWallet's `chartYBounds` shipped in the first
/// place — so every rule here is a top-level function with its own
/// degenerate-input tests.
library;

import 'dart:math';

/// Scaffold-neutral record replacing fl_chart's `FlSpot` at the geometry
/// layer.
///
/// The geometry file MUST NOT depend on fl_chart (D-02 support-part
/// isolation). Callers adapt their domain type or `FlSpot` into this
/// record at the boundary.
typedef ChartPoint = ({double x, double y});

/// At or above this many pixels of PLOT the framed chart earns its gutters;
/// below it the ticks crowd and the frame is dropped for the axis-free
/// fallback. This is a RUNTIME measurement, never a per-surface setting —
/// the same chart widget is composed under many different height regimes
/// and some call sites have no minimum height at all, so no configuration
/// value can express "does the frame fit here".
const double kChartFrameMinHeight = 220.0;

/// The right-hand gutter the framed chart reserves for its axis labels.
const double kChartAxisGutter = 62.0;

/// The bottom row the framed chart reserves for its time labels.
const double kChartTimeRowHeight = 22.0;

/// Axis-free chart's reserved label strip, top and bottom. The line is
/// drawn only in the middle `plotHeight - 2 * kChartLabelBand`, so no data
/// shape can ever reach a label — the fix that replaced a plate the line
/// could still run through (see [chartBandedBounds] below).
const double kChartLabelBand = 17.0;

/// Where the below-bar area fill reaches zero alpha, as a fraction of the
/// plot height measured over `belowBarLargestRect` (top of the highest spot
/// to the plot floor). Preserved verbatim from the GeniusWallet port so the
/// rendered gradient matches the design source 1:1.
const double kChartFillFadeStop = 0.62;

/// The "nice" tick ladder, so the axis reads `64,250` not `64,187.4413`.
///
/// The ladder deliberately includes the 2.5 rung: a plain 1-2-5-10 ladder
/// jumps from 200 to 500 at norm=2.01, and on a real window (span 1274)
/// that collapsed a 6-tick request into 2 labels — below the 2-to-8 band
/// the data-viz guides ask for.
///
/// Returns the candidate multiplier whose resulting tick count is closest
/// to [want], among candidates with at least 2 values. A zero or negative
/// span returns a single value at [lo] with a step of 1, so a flat or
/// degenerate window cannot divide by zero or loop.
(List<double>, double) chartTickStep(double lo, double hi, int want) {
  final double span = hi - lo;
  if (span <= 0) {
    return (<double>[lo], 1.0);
  }

  final double mag =
      pow(10, (log(span / want) / ln10).floorToDouble()).toDouble();
  const List<double> multipliers = <double>[
    1.0,
    1.5,
    2.0,
    2.5,
    3.0,
    4.0,
    5.0,
    10.0,
  ];

  List<double>? bestVals;
  double? bestStep;
  int? bestErr;

  for (final double m in multipliers) {
    final double step = m * mag;
    final List<double> vals = <double>[];
    double v = (lo / step).ceil() * step;
    for (; v <= hi + step * 1e-9; v += step) {
      vals.add(v);
    }
    if (vals.length < 2) {
      continue;
    }
    final int err = (vals.length - want).abs();
    if (bestErr == null || err < bestErr) {
      bestVals = vals;
      bestStep = step;
      bestErr = err;
    }
  }

  if (bestVals == null || bestStep == null) {
    return (<double>[lo, hi], span);
  }
  return (bestVals, bestStep);
}

/// The axis label for [value], with precision derived from the tick [step].
///
/// **Deriving precision from the value's magnitude — instead of the step —
/// is a real bug this rule exists to prevent, not a style choice**: it is
/// exactly how a stablecoin's axis printed `$1.00 / $1.00 / $1.00 / $1.00`
/// for four different prices in the GeniusWallet port source.
///
/// Neutral scaffold contract (D-04): no currency formatter, no currency
/// symbol — just `value.toStringAsFixed(decimals)`. Callers layer domain
/// formatting (currency, units, thousands separators) on top.
String chartAxisLabel(double value, double step) {
  final int decimals = step >= 1 ? 0 : min(8, (-log(step) / ln10).ceil() + 1);
  return value.toStringAsFixed(decimals);
}

/// How many bottom time labels fit, clamped to BOTH the plot width and the
/// number of samples actually on screen.
///
/// With 4 samples, 6 label slots printed the same label twice — caught by
/// the design sketch's "4 points" state. Floor of 2 keeps the axis legible
/// on a narrow plot.
int chartXLabelCount({required double plotWidth, required int sampleCount}) {
  return max(2, min(min(6, (plotWidth / 110).floor()), sampleCount));
}

/// How many horizontal gridlines/ticks the framed chart asks for.
int chartYTickCount(double plotHeight) =>
    max(3, min(6, (plotHeight / 76).round()));

/// Whether the plot has room for the framed chart. This is a RUNTIME rule
/// measured off the box the chart was actually handed, never a per-surface
/// flag.
bool chartUsesFrame(double plotHeight) => plotHeight >= kChartFrameMinHeight;

/// The axis-free chart's reserved label gutters, expressed as a Y-window
/// transform.
///
/// `fl_chart` has no notion of a reserved label strip, so the gutters are
/// built by widening the Y window instead: given the plot is [plotHeight]
/// tall and the data must occupy only the middle `plotHeight - 2 * band`,
/// this expands the window so the original `lo`/`hi` land exactly [band] px
/// inside each edge.
///
/// **This is the SECOND attempt at this defect, and the first one was
/// wrong.** An opaque plate behind the H/L labels was tried and rejected,
/// because the line still ran through the plate — the plate merely hid that
/// stretch of the series. Hiding data behind a caption is not a fix.
/// Reserving the gutter in the Y window itself means no data shape can ever
/// reach a label, at any surface size.
(double, double) chartBandedBounds(
  (double, double) bounds,
  double plotHeight, {
  double band = kChartLabelBand,
}) {
  final (double lo, double hi) = bounds;
  final double available = plotHeight - 2 * band;
  if (available <= 0) {
    return bounds;
  }
  final double unitsPerPx = (hi - lo) / max(1, available);
  return (lo - band * unitsPerPx, hi + band * unitsPerPx);
}

/// The chart's vertical window, as `(minY, maxY)` — computed over the points
/// inside the CURRENT X view, never the whole fetched series.
///
/// Ported verbatim from GeniusWallet's `chartYBounds` — the site of the
/// y-window bug that motivated this whole module. The bug was computing the
/// window over the entire series while the X window showed only the last 50
/// points, so a coin sitting 98% below its all-time high rendered the visible
/// slice as a flat line pinned to the bottom of the card. The data was not
/// flat; the scale was wrong.
///
/// The old padding was `* 0.999` / `* 1.001` — effectively none, so the line
/// also ran edge to edge. 8% of the visible span on each side gives the curve
/// somewhere to move while still filling ~86% of the height.
///
/// A genuinely flat slice — one point, or a stablecoin that has not moved —
/// has zero span and cannot be scaled at all, so it falls back to ±1% of the
/// value (or ±0.01 when the value's magnitude is too small to produce a
/// positive 1% pad) and the line lands mid-card instead of dividing by zero.
/// That case is not hypothetical: it is every chart between the first paint
/// and the second live tick.
///
/// Empty series returns `(0.0, 1.0)` — a safe placeholder so callers never
/// divide by zero.
///
/// Pan/zoom cannot empty the visible window when the caller passes the same
/// `[viewMinX, viewMaxX]` pair it used to clip the spots, but a bad window
/// degrades to the whole series rather than throwing out of `reduce`.
(double, double) chartYBounds(
  List<ChartPoint> data, {
  double? viewMinX,
  double? viewMaxX,
}) {
  if (data.isEmpty) {
    return (0.0, 1.0);
  }

  final double lo = viewMinX ?? data.first.x;
  final double hi = viewMaxX ?? data.last.x;

  List<double> visible = data
      .where((ChartPoint s) => s.x >= lo && s.x <= hi)
      .map((ChartPoint s) => s.y)
      .toList();
  if (visible.isEmpty) {
    visible = data.map((ChartPoint s) => s.y).toList();
  }

  final double lowest = visible.reduce(min);
  final double highest = visible.reduce(max);
  final double span = highest - lowest;

  if (span <= 0) {
    final double pad = max(highest.abs() * 0.01, 0.01);
    return (lowest - pad, highest + pad);
  }
  return (lowest - span * 0.08, highest + span * 0.08);
}

/// The highest and lowest spot inside the visible `[viewMinX, viewMaxX]`
/// window — never the whole fetched series, which the chart's window is
/// only a slice of.
///
/// Falls back to the whole series if the window selects nothing, the same
/// way the Y-bounds rule does. Returns null for an empty list or a flat
/// series (`high.y == low.y`), so the caller can skip drawing the labels
/// entirely.
({ChartPoint high, ChartPoint low})? chartVisibleExtremes(
  List<ChartPoint> data, {
  double? viewMinX,
  double? viewMaxX,
}) {
  if (data.isEmpty) {
    return null;
  }

  final double lo = viewMinX ?? data.first.x;
  final double hi = viewMaxX ?? data.last.x;

  List<ChartPoint> visible =
      data.where((ChartPoint s) => s.x >= lo && s.x <= hi).toList();
  if (visible.isEmpty) {
    visible = data;
  }

  ChartPoint high = visible.first;
  ChartPoint low = visible.first;
  for (final ChartPoint s in visible) {
    if (s.y > high.y) {
      high = s;
    }
    if (s.y < low.y) {
      low = s;
    }
  }

  if (high.y == low.y) {
    return null;
  }
  return (high: high, low: low);
}
