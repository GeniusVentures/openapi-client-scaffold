/// ScaffoldChartScrubber demo — selection + keyboard + PointerExit + live region.
///
/// Demonstrates the four interaction surfaces of `ScaffoldChartScrubber<T>`
/// (WIDG-36):
///   - Tap/drag scrubbing with external consumer-rendered readout (D-05).
///   - ArrowLeft / ArrowRight keyboard navigation over the series.
///   - Enter to confirm the current selection; Escape to clear.
///   - PointerExit (hover off the chart) clears the selection.
///   - Optional `ScaffoldLiveRegion` announcement of the selected value.
///
/// Theme tokens only — zero hardcoded colors.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Number of sample points in the demo series.
const int _kSampleCount = 24;

/// X-axis origin: epoch-second-style value (Aug 2023).
const double _kXOriginSeconds = 1692000000.0;

/// X-axis sample step (one hour between points).
const double _kXStepSeconds = 3600.0;

/// Demo series — same shape as the ScaffoldChart demo's, so the two demos
/// can be compared side-by-side.
final List<Offset> _kSampleSeries = List<Offset>.generate(
  _kSampleCount,
  (int i) {
    final double x = _kXOriginSeconds + i * _kXStepSeconds;
    final double phase = (i % 8) / 8.0;
    final double y = 100.0 + 50.0 * (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2) - 25.0;
    return Offset(x, y);
  },
  growable: false,
);

/// Demo for [ScaffoldChartScrubber] (WIDG-36).
class ChartScrubberDemo extends StatefulWidget {
  /// Creates the demo.
  const ChartScrubberDemo({super.key});

  @override
  State<ChartScrubberDemo> createState() => _ChartScrubberDemoState();
}

class _ChartScrubberDemoState extends State<ChartScrubberDemo> {
  /// The currently selected point — the demo (consumer) owns selection
  /// truth; the atom stays stateless-for-selection per the locked pattern.
  Offset? _selected;

  /// Formatted value string forwarded to the live region. Null when no
  /// selection — the atom skips the `ScaffoldLiveRegion` wrapper.
  String? _announce;

  void _onSelected(Offset? v) {
    setState(() {
      _selected = v;
      _announce = v == null ? null : 'Value ${v.dy.toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String readoutText = _selected == null
        ? 'No selection'
        : 'Value: ${_selected!.dy.toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldChartScrubber')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // External readout (D-05) — consumer-rendered; the atom does
            // NOT paint a tooltip or readout of its own.
            Text(
              readoutText,
              style: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space4),
            SizedBox(
              height: 280,
              child: ScaffoldChartScrubber<Offset>(
                series: _kSampleSeries,
                xAccessor: (Offset o) => o.dx,
                yAccessor: (Offset o) => o.dy,
                selectedPoint: _selected,
                onPointSelected: _onSelected,
                announceValue: _announce,
              ),
            ),
            SizedBox(height: dimens.space4),
            Text(
              'Tap or drag to scrub. Arrow keys navigate. Enter confirms. '
              'Escape or hover-exit clears.',
              style: textTheme.labelSmall?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
