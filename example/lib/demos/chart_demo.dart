/// ScaffoldChart demo — framed + axis-free + formatter + empty state.
///
/// Demonstrates the four canonical configurations of `ScaffoldChart<T>`
/// (WIDG-35):
///   1. Framed chart (plotHeight 280) — right Y-axis + bottom X-axis Row.
///   2. Axis-free chart (plotHeight 96) — no axes, no grid, banded bounds.
///   3. Custom xLabelFormatter + lineColor override.
///   4. Empty series state — Semantics label survives, no phantom axes.
///
/// Theme tokens only (`context.palette` / `context.dimens` /
/// `context.textTheme`) — zero hardcoded colors. Renders correctly under
/// both `defaultPalette` (dark) and `lightPalette` (light) with no consumer
/// overrides.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Number of sample points in the demo series.
const int _kSampleCount = 24;

/// X-axis origin: epoch-second-style value (Aug 2023).
const double _kXOriginSeconds = 1692000000.0;

/// X-axis sample step (one hour between points).
const double _kXStepSeconds = 3600.0;

/// Demo series — oscillating values in a 50..150 range, x as epoch-second-
/// style timestamps. Built once at startup; identical across all four chart
/// configurations so the visual difference is purely the chart's own layout.
final List<Offset> _kSampleSeries = List<Offset>.generate(
  _kSampleCount,
  (int i) {
    final double x = _kXOriginSeconds + i * _kXStepSeconds;
    // Oscillate y in a 50..150 range using a simple deterministic wave.
    final double phase = (i % 8) / 8.0;
    final double y = 100.0 + 50.0 * (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2) - 25.0;
    return Offset(x, y);
  },
  growable: false,
);

/// Demo for [ScaffoldChart] (WIDG-35).
class ChartDemo extends StatelessWidget {
  /// Creates the demo.
  const ChartDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldChart')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Framed chart (plotHeight 280) ---
            Text(
              'Framed chart (plotHeight 280)',
              style: textTheme.titleSmall?.copyWith(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            SizedBox(
              height: 280,
              child: ScaffoldChart<Offset>(
                series: _kSampleSeries,
                xAccessor: (Offset o) => o.dx,
                yAccessor: (Offset o) => o.dy,
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. Axis-free chart (plotHeight 96) ---
            Text(
              'Axis-free chart (plotHeight 96)',
              style: textTheme.titleSmall?.copyWith(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            SizedBox(
              height: 96,
              child: ScaffoldChart<Offset>(
                series: _kSampleSeries,
                xAccessor: (Offset o) => o.dx,
                yAccessor: (Offset o) => o.dy,
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. Custom formatter + line color ---
            Text(
              'Custom formatter + line color (plotHeight 220)',
              style: textTheme.titleSmall?.copyWith(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            SizedBox(
              height: 220,
              child: ScaffoldChart<Offset>(
                series: _kSampleSeries,
                xAccessor: (Offset o) => o.dx,
                yAccessor: (Offset o) => o.dy,
                xLabelFormatter: (double x) {
                  final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                    (x.toInt() * 1000),
                    isUtc: true,
                  );
                  // HH:mm
                  final String iso = dt.toIso8601String();
                  return iso.substring(11, 16);
                },
                lineColor: palette.statusSuccess,
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 4. Empty state ---
            Text(
              'Empty state',
              style: textTheme.titleSmall?.copyWith(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            SizedBox(
              height: 220,
              child: ScaffoldChart<Offset>(
                series: const <Offset>[],
                xAccessor: (Offset o) => o.dx,
                yAccessor: (Offset o) => o.dy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
