/// ScaffoldChartRangeSelector demo — drag-range selection + consumer-policy
/// zoom (D-09/D-10).
///
/// Demonstrates the report-only contract of `ScaffoldChartRangeSelector<T>`:
/// the atom reports a `(Offset, Offset)?` range via `onRangeSelected` and
/// never rescales itself — the demo (consumer) applies the range by setting
/// `viewMinX`/`viewMaxX` on the next build. The "Reset zoom" button clears
/// only the window, proving the consumer owns the zoom policy.
///
/// Theme tokens only (`context.palette` / `context.dimens` /
/// `context.textTheme`) — zero hardcoded colors.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Number of sample points in the demo series.
const int _kSampleCount = 24;

/// X-axis origin: epoch-second-style value (Aug 2023).
const double _kXOriginSeconds = 1692000000.0;

/// X-axis sample step (one hour between points).
const double _kXStepSeconds = 3600.0;

/// Y-wave base value (the value the wave oscillates around before the
/// offset is applied).
const double _kYBaseValue = 100.0;

/// Y-wave peak-to-mid amplitude.
const double _kYAmplitude = 50.0;

/// Y-wave offset applied after the triangle wave, shifting the visible
/// range downward so the line sits in the lower half of the plot.
const double _kYOffset = 25.0;

/// Demo series — same shape as the ScaffoldChart/Scrubber demos'.
final List<Offset> _kSampleSeries = List<Offset>.generate(
  _kSampleCount,
  (int i) {
    final double x = _kXOriginSeconds + i * _kXStepSeconds;
    final double phase = (i % 8) / 8.0;
    final double y = _kYBaseValue +
        _kYAmplitude * (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2) -
        _kYOffset;
    return Offset(x, y);
  },
  growable: false,
);

/// Demo for [ScaffoldChartRangeSelector] (D-09/D-10).
class ChartRangeSelectorDemo extends StatefulWidget {
  /// Creates the demo.
  const ChartRangeSelectorDemo({super.key});

  @override
  State<ChartRangeSelectorDemo> createState() => _ChartRangeSelectorDemoState();
}

class _ChartRangeSelectorDemoState extends State<ChartRangeSelectorDemo> {
  /// The selected range (start, end), owned by the demo (consumer).
  (Offset, Offset)? _range;

  /// Visible-window bounds applied by the consumer (zoom policy). Null until
  /// a range is selected; cleared by "Reset zoom".
  double? _viewMinX;
  double? _viewMaxX;

  /// Applies the reported range as the consumer's zoom window. This is the
  /// report-only contract in action: the atom reports; the consumer decides.
  void _onRangeSelected((Offset, Offset)? range) {
    setState(() {
      _range = range;
      if (range != null) {
        _viewMinX = range.$1.dx;
        _viewMaxX = range.$2.dx;
      } else {
        _viewMinX = null;
        _viewMaxX = null;
      }
    });
  }

  /// Resets only the zoom window, leaving the range (and band) intact —
  /// proving the consumer owns the zoom policy independent of the band.
  void _resetZoom() {
    setState(() {
      _viewMinX = null;
      _viewMaxX = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String readoutText = _range == null
        ? 'No range selected'
        : 'Range: ${_range!.$1.dy.toStringAsFixed(2)} – '
            '${_range!.$2.dy.toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldChartRangeSelector')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              readoutText,
              style: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space4),
            SizedBox(
              height: 280,
              child: ScaffoldChartRangeSelector<Offset>(
                series: _kSampleSeries,
                xAccessor: (Offset o) => o.dx,
                yAccessor: (Offset o) => o.dy,
                selectedRange: _range,
                onRangeSelected: _onRangeSelected,
                viewMinX: _viewMinX,
                viewMaxX: _viewMaxX,
              ),
            ),
            SizedBox(height: dimens.space4),
            TextButton(
              onPressed: _resetZoom,
              child: const Text('Reset zoom'),
            ),
            SizedBox(height: dimens.space4),
            Text(
              'Drag to select a range. The demo zooms to the selection '
              '(consumer policy). Escape clears. Shift+Arrow adjusts the '
              'range end.',
              style: textTheme.labelSmall?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
