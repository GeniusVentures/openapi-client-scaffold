/// `ScaffoldChart<T>` — neutral chart atom (WIDG-35).
///
/// Maps a consumer-supplied `series` to `ChartPoint` records via the typed
/// `xAccessor` / `yAccessor` pair, resolves theme tokens from
/// `context.palette` / `context.dimens` / `context.textTheme`, picks framed
/// vs axis-free layout from the measured plot height, and delegates
/// rendering to `buildScaffoldLineChart` (D-02 support-part isolation).
///
/// This file contains ZERO chart-library imports and zero domain knowledge.
/// The X-axis label row on framed charts is a plain `Row` of `Text` widgets
/// (D-06) — never chart-engine bottom titles, whose anchoring cannot line
/// up with epoch-second sample positions.
///
/// Atom is stateless for render: holds no mutable state. `selectedPoint`
/// and `onPointSelected` flow through constructor parameters — the consumer
/// owns truth. The atom does NOT paint a persistent selection dot; visual
/// selection state is composed on top via `ScaffoldChartScrubber` (Plan 04).
library;

import 'package:flutter/material.dart';

import '../theme/scaffold_dimens.dart';
import '../theme/scaffold_palette.dart';
import '../theme/scaffold_theme.dart';
import '../utils/chart_geometry.dart';
import '../utils/scaffold_chart_renderer.dart';
import 'scaffold_motion.dart';
import 'scaffold_surface.dart';

/// Scrub behavior mode for [ScaffoldChart] and `ScaffoldChartScrubber`
/// (D-08).
enum ScrubMode {
  /// The touched indicator dot snaps to the nearest data-point index
  /// (WIDG-36 default).
  snap,

  /// The dot rides the line continuously at the pointer's chart-x; its y
  /// is the linear interpolation between the bracketing samples.
  smooth,
}

/// Neutral chart atom — generic over the consumer's series element type.
///
/// The atom maps `List<T>` to `List<ChartPoint>` via the accessors, picks
/// framed vs axis-free layout at runtime via `chartUsesFrame(plotHeight)`,
/// and delegates all chart-engine rendering to the support part.
class ScaffoldChart<T> extends StatelessWidget {
  /// Creates a chart over [series].
  const ScaffoldChart({
    super.key,
    required this.series,
    required this.xAccessor,
    required this.yAccessor,
    this.selectedPoint,
    this.onPointSelected,
    this.onScrubGestureStart,
    this.onScrubGestureEnd,
    this.scrubMode = ScrubMode.snap,
    this.onPositionChanged,
    this.plotHeight,
    this.lineColor,
    this.semanticsLabel,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.viewMinX,
    this.viewMaxX,
  });

  /// The data series to plot.
  final List<T> series;

  /// Maps an element of [series] to its X coordinate.
  final double Function(T) xAccessor;

  /// Maps an element of [series] to its Y coordinate.
  final double Function(T) yAccessor;

  /// The currently selected point, owned by the consumer.
  ///
  /// The atom does NOT paint a persistent selection dot — visual selection
  /// is composed externally (Plan 04's ScaffoldChartScrubber). This value
  /// is consulted by the enclosing scrubber's keyboard navigation; pointer
  /// hits always SELECT — they never clear (D-05: clearing happens only
  /// via Escape or pointer-exit).
  final T? selectedPoint;

  /// Fires when the user touches a data point.
  final ValueChanged<T?>? onPointSelected;

  /// Optional gesture-lifecycle callback fired when a scrub gesture starts
  /// (pan-start or tap-down inside the chart's touch area). Scaffold-neutral
  /// — consumers never see the chart engine's event types.
  ///
  /// Pairs with [onScrubGestureEnd]; the scrubber uses these to gate
  /// hover-exit clearing while a drag is active.
  final VoidCallback? onScrubGestureStart;

  /// Optional gesture-lifecycle callback fired when a scrub gesture ends
  /// (pan-end, pan-cancel, tap-up, or tap-cancel). See [onScrubGestureStart].
  final VoidCallback? onScrubGestureEnd;

  /// Scrub behavior mode (D-08). Defaults to [ScrubMode.snap] — the WIDG-36
  /// contract. [ScrubMode.smooth] makes the touched dot ride the line
  /// continuously while `onPointSelected` still fires the nearest point.
  final ScrubMode scrubMode;

  /// Continuous scrub-position callback (D-08). Fires on hover/pan-move
  /// with the pointer's continuous chart-x and the linearly interpolated y
  /// between the bracketing samples. Only wired to the renderer when
  /// [scrubMode] is [ScrubMode.smooth] AND this callback is non-null.
  final void Function(double x, double y)? onPositionChanged;

  /// Optional explicit plot height. When null, the atom measures its
  /// LayoutBuilder's `maxHeight` and asserts it is bounded.
  final double? plotHeight;

  /// Optional line color override. Defaults to `palette.lightGreenPrimary`.
  final Color? lineColor;

  /// Optional semantics label override. Defaults to `'Chart'`.
  final String? semanticsLabel;

  /// Optional X-axis label formatter. Defaults to `x.toStringAsFixed(0)`.
  final String Function(double)? xLabelFormatter;

  /// Optional Y-axis label formatter. Defaults to `chartAxisLabel`.
  final String Function(double value, double step)? yLabelFormatter;

  /// Optional visible-window override; defaults to the series' first X.
  final double? viewMinX;

  /// Optional visible-window override; defaults to the series' last X.
  final double? viewMaxX;

  @override
  Widget build(BuildContext context) {
    final String label = semanticsLabel ?? 'Chart';

    // Empty state: SizedBox.shrink() inside the outer Semantics so a11y
    // consumers still see the labelled container (UI-Spec Copywriting
    // Contract — "Empty state: SizedBox.shrink() when series is empty").
    if (series.isEmpty) {
      return Semantics(
        label: label,
        child: const SizedBox.shrink(),
      );
    }

    return Semantics(
      label: label,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double resolvedPlotHeight = plotHeight ?? constraints.maxHeight;
          if (!resolvedPlotHeight.isFinite) {
            throw FlutterError(
              'ScaffoldChart requires either an explicit plotHeight or a '
              'bounded height constraint. Wrap in SizedBox(height: ...) or '
              'pass plotHeight:.',
            );
          }

          final ScaffoldPalette palette = context.palette;
          final ScaffoldDimens dimens = context.dimens;
          final TextTheme textTheme = Theme.of(context).textTheme;
          final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;

          // Map series → parallel visible lists (spots + items) so the
          // chart-engine touchCallback's spotIndex maps directly back to T
          // in O(1) — no firstWhere lookup at touch time.
          final List<ChartPoint> allSpots = <ChartPoint>[
            for (final T item in series)
              (x: xAccessor(item), y: yAccessor(item)),
          ];

          final double lo = viewMinX ?? allSpots.first.x;
          final double hi = viewMaxX ?? allSpots.last.x;

          final List<ChartPoint> visibleSpots = <ChartPoint>[];
          final List<T> visibleItems = <T>[];
          for (int i = 0; i < series.length; i++) {
            final ChartPoint p = allSpots[i];
            if (p.x >= lo && p.x <= hi) {
              visibleSpots.add(p);
              visibleItems.add(series[i]);
            }
          }
          // Bad-window degradation: a window selecting nothing falls back
          // to the whole series rather than handing the renderer an empty
          // spots list (mirrors chartYBounds' fallback rule).
          if (visibleSpots.isEmpty) {
            visibleSpots.addAll(allSpots);
            visibleItems.addAll(series);
          }

          // Y-bounds via chartYBounds — the single site for the visible-
          // window + 8% padding + flat-series fallback rule (D-04).
          (double, double) yBounds = chartYBounds(
            visibleSpots,
            viewMinX: lo,
            viewMaxX: hi,
          );

          final bool useFrame = chartUsesFrame(resolvedPlotHeight);
          if (!useFrame) {
            // Axis-free: widen the Y window to reserve the top/bottom
            // label bands so no data shape can ever reach a label.
            yBounds = chartBandedBounds(yBounds, resolvedPlotHeight);
          }

          // Theme token resolution (D-07): every color and style flows
          // from context.palette / context.dimens / context.textTheme —
          // zero hardcoded colors, zero hardcoded dimens.
          final Color resolvedLineColor = lineColor ?? palette.lightGreenPrimary;
          final Color borderControl = palette.borderGrey;
          final Color borderSubtle = palette.borderSubtle;
          final Color textSecondary = palette.textSecondary;
          final TextStyle axisLabelStyle = textTheme.labelSmall!.copyWith(
            color: textSecondary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          );

          final Widget lineChart = buildScaffoldLineChart(
            spots: visibleSpots,
            plotHeight: resolvedPlotHeight,
            plotWidth: constraints.maxWidth,
            lineColor: resolvedLineColor,
            borderControl: borderControl,
            borderSubtle: borderSubtle,
            textSecondary: textSecondary,
            axisLabelStyle: axisLabelStyle,
            reducedMotion: reducedMotion,
            yBounds: yBounds,
            viewMinX: lo,
            viewMaxX: hi,
            minX: lo,
            maxX: hi,
            onSpotTouched: onPointSelected == null
                ? null
                : (int spotIndex, bool isDiscreteTap) {
                    if (spotIndex < 0 || spotIndex >= visibleItems.length) {
                      return;
                    }
                    // Tap/hover/drag ALWAYS select (D-05 contract): the
                    // 10-UI-SPEC never specified tap-to-clear — clearing
                    // happens ONLY via Escape or pointer-exit. The UAT
                    // verdict on the former discrete-tap toggle was that it
                    // reads as a bug ("If I click, it goes to no
                    // selection"), so a discrete tap on the already-selected
                    // point is a no-op re-select. The renderer's
                    // isDiscreteTap discrimination is retained at the seam
                    // (correct plumbing) but the atom no longer uses it to
                    // clear.
                    onPointSelected!(visibleItems[spotIndex]);
                  },
            onScrubGestureStart: onScrubGestureStart,
            onScrubGestureEnd: onScrubGestureEnd,
            onScrubPositionChanged:
                scrubMode == ScrubMode.smooth && onPositionChanged != null
                    ? onPositionChanged
                    : null,
            smoothSpots: scrubMode == ScrubMode.smooth ? visibleSpots : null,
          );

          // Framed charts get the plain-Row-of-Texts X-axis below the plot
          // (D-06) — chart-engine bottom-titles anchoring cannot express
          // epoch-second sample positions.
          final List<Widget> columnChildren = <Widget>[
            Expanded(child: lineChart),
          ];
          if (useFrame) {
            columnChildren.add(SizedBox(height: dimens.space4));
            columnChildren.add(
              SizedBox(
                height: kChartTimeRowHeight,
                child: Padding(
                  padding: const EdgeInsets.only(right: kChartAxisGutter),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints rowConstraints) {
                      final int count = chartXLabelCount(
                        plotWidth: rowConstraints.maxWidth,
                        sampleCount: visibleSpots.length,
                      );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List<Widget>.generate(count, (int b) {
                          final int ix = count > 1
                              ? ((b / (count - 1)) *
                                      (visibleSpots.length - 1))
                                  .round()
                              : 0;
                          final double xValue = visibleSpots[ix].x;
                          final String text = xLabelFormatter?.call(xValue) ??
                              xValue.toStringAsFixed(0);
                          return Text(text, style: axisLabelStyle);
                        }),
                      );
                    },
                  ),
                ),
              ),
            );
          }

          return ScaffoldSurface(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(dimens.radiusMd),
            padding: EdgeInsets.all(dimens.space8),
            child: Column(children: columnChildren),
          );
        },
      ),
    );
  }
}
