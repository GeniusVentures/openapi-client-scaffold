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
  /// is consulted only when deciding whether to fire `onPointSelected`
  /// with the tapped point or with `null` (toggle behavior).
  final T? selectedPoint;

  /// Fires when the user touches a data point.
  final ValueChanged<T?>? onPointSelected;

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
                : (int spotIndex) {
                    if (spotIndex < 0 || spotIndex >= visibleItems.length) {
                      return;
                    }
                    final T tapped = visibleItems[spotIndex];
                    // Toggle: tapping the currently selected point clears
                    // the selection; tapping anything else selects it.
                    onPointSelected!(identical(tapped, selectedPoint) ? null : tapped);
                  },
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
