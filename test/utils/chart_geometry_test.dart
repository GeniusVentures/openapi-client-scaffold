import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/utils/chart_geometry.dart';

void main() {
  group('chartTickStep', () {
    test('happy path — span 100, want 5, picks a ladder step', () {
      final (List<double> values, double step) = chartTickStep(0, 100, 5);
      // Step must be one of the 1/1.5/2/2.5/3/4/5/10 multiplier rungs.
      const List<double> ladder = <double>[
        10.0,
        15.0,
        20.0,
        25.0,
        30.0,
        40.0,
        50.0,
        100.0,
      ];
      expect(ladder.contains(step), isTrue);
      // Resulting tick count lands in the 2-to-8 band.
      expect(values.length, greaterThanOrEqualTo(2));
      expect(values.length, lessThanOrEqualTo(8));
      // Every value is a multiple of the chosen step.
      for (final double v in values) {
        final double ratio = v / step;
        expect((ratio - ratio.roundToDouble()).abs(), lessThan(1e-9));
      }
    });

    test('returns single value + step 1.0 when span is zero', () {
      final (List<double> values, double step) = chartTickStep(5, 5, 5);
      expect(values, <double>[5.0]);
      expect(step, 1.0);
    });

    test('returns single value + step 1.0 when span is negative', () {
      final (List<double> values, double step) = chartTickStep(10, 0, 5);
      expect(values, <double>[10.0]);
      expect(step, 1.0);
    });

    test('2.5 rung — span 1274 want 6 does not collapse to 2 labels', () {
      final (List<double> values, double _) = chartTickStep(0, 1274, 6);
      // Plain 1-2-5-10 ladder jumps from 200 to 500 at norm=2.01 and the
      // 6-tick request collapses to 2 labels; the 2.5 rung keeps it near 6.
      expect(values.length, greaterThan(2));
      // Closest-to-6 within the 2-to-8 band.
      expect(values.length, lessThanOrEqualTo(8));
    });

    test('falls back to ([lo, hi], span) when no candidate has >=2 values', () {
      // Pathological span that squeezes every ladder candidate to <2 values.
      // span = 1e-12 with want=8: mag = 10^(floor(log10(1e-12/8))) = 1e-13.
      // Even step = 1e-13 * 10 = 1e-12 yields at most one tick inside.
      final (List<double> values, double step) =
          chartTickStep(1.0, 1.0 + 1e-12, 8);
      expect(values.length, 2);
      expect(values[0], closeTo(1.0, 1e-9));
      expect(values[1], closeTo(1.0 + 1e-12, 1e-15));
      expect(step, closeTo(1e-12, 1e-15));
    });
  });

  group('chartAxisLabel', () {
    test('derives decimals from step, not magnitude — step 10 prints no decimals', () {
      expect(chartAxisLabel(64.187, 10.0), '64');
    });

    test('large value with step 5000 prints no decimals', () {
      expect(chartAxisLabel(64187.4413, 5000.0), '64187');
    });

    test('step 0.01 yields 2 decimals — 1.0042 prints "1.00"', () {
      expect(chartAxisLabel(1.0042, 0.01), '1.00');
    });

    test('decimals capped at 8 for tiny steps', () {
      final String label = chartAxisLabel(1.0, 1e-9);
      // 8 decimals: "1.00000000".
      expect(label, '1.00000000');
    });
  });

  group('chartXLabelCount', () {
    test('clamps to 6 on wide plot with many samples', () {
      expect(chartXLabelCount(plotWidth: 660, sampleCount: 100), 6);
    });

    test('clamps to sampleCount when samples are scarce', () {
      expect(chartXLabelCount(plotWidth: 660, sampleCount: 4), 4);
    });

    test('floors to minimum 2 on narrow plot', () {
      expect(chartXLabelCount(plotWidth: 50, sampleCount: 100), 2);
    });
  });

  group('chartYTickCount', () {
    test('clamps to 3 on small plot', () {
      expect(chartYTickCount(76), 3);
    });

    test('220px plot rounds to 3', () {
      expect(chartYTickCount(220), 3);
    });

    test('456px plot rounds to 6', () {
      expect(chartYTickCount(456), 6);
    });

    test('caps at 6 on very tall plot', () {
      expect(chartYTickCount(5000), 6);
    });
  });

  group('chartUsesFrame', () {
    test('returns false below 220px', () {
      expect(chartUsesFrame(219.9), isFalse);
    });

    test('returns true at exactly 220px', () {
      expect(chartUsesFrame(220.0), isTrue);
    });

    test('returns true on tall plots', () {
      expect(chartUsesFrame(500.0), isTrue);
    });
  });

  group('chartBandedBounds', () {
    test('widens (0, 100) so values land kChartLabelBand px inside each edge', () {
      final (double lo, double hi) = chartBandedBounds((0.0, 100.0), 220);
      // Available plot = 220 - 2*17 = 186 px for the 100-unit span.
      // unitsPerPx = 100 / 186; window widens by 17 * unitsPerPx on each side.
      const double expectedUnitsPerPx = 100.0 / 186.0;
      expect(lo, closeTo(0.0 - 17.0 * expectedUnitsPerPx, 1e-9));
      expect(hi, closeTo(100.0 + 17.0 * expectedUnitsPerPx, 1e-9));
      // Sanity: the original 100 lands ~17px from the top, 0 ~17px from the bottom.
      expect(hi, greaterThan(100.0));
      expect(lo, lessThan(0.0));
    });

    test('returns input unchanged when available == 0', () {
      final (double lo, double hi) = chartBandedBounds((0.0, 100.0), 34);
      expect(lo, 0.0);
      expect(hi, 100.0);
    });

    test('returns input unchanged when available < 0', () {
      final (double lo, double hi) = chartBandedBounds((0.0, 100.0), 30);
      expect(lo, 0.0);
      expect(hi, 100.0);
    });
  });

  group('chartVisibleExtremes', () {
    test('returns highest and lowest inside the view window', () {
      final List<ChartPoint> data = <ChartPoint>[
        (x: 0, y: 1),
        (x: 1, y: 5),
        (x: 2, y: 2),
        (x: 3, y: 9),
      ];
      final ({ChartPoint high, ChartPoint low})? result =
          chartVisibleExtremes(data, viewMinX: 1, viewMaxX: 2);
      expect(result, isNotNull);
      expect(result!.high.x, 1);
      expect(result.high.y, 5);
      expect(result.low.x, 2);
      expect(result.low.y, 2);
    });

    test('falls back to whole series when window selects nothing', () {
      final List<ChartPoint> data = <ChartPoint>[
        (x: 0, y: 1),
        (x: 1, y: 5),
        (x: 2, y: 2),
        (x: 3, y: 9),
      ];
      final ({ChartPoint high, ChartPoint low})? result =
          chartVisibleExtremes(data, viewMinX: 100, viewMaxX: 200);
      expect(result, isNotNull);
      expect(result!.high.y, 9);
      expect(result.low.y, 1);
    });

    test('returns null for flat series', () {
      final List<ChartPoint> data = <ChartPoint>[
        (x: 0, y: 7),
        (x: 1, y: 7),
        (x: 2, y: 7),
      ];
      expect(chartVisibleExtremes(data), isNull);
    });

    test('returns null for empty list', () {
      expect(chartVisibleExtremes(const <ChartPoint>[]), isNull);
    });
  });
}
