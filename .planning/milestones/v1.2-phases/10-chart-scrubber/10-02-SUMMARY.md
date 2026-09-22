---
phase: 10-chart-scrubber
plan: 02
subsystem: ui
tags: [chart, fl_chart, renderer, support-part, isolation, widget-tests]

# Dependency graph
requires:
  - phase: 10-chart-scrubber plan 01
    provides: chart_geometry helpers (chartTickStep/chartUsesFrame/chartYTickCount/chartAxisLabel/chartBandedBounds) + ChartPoint typedef + kChart* constants
provides:
  - fl_chart-backed LineChart builder behind a scaffold-neutral interface (D-02 / D-08)
  - buildScaffoldLineChart public entry point returning LineChart with framed/axis-free variants
  - Tooltip-suppressed + border-hidden + reduced-motion-pass-through contract locked by 12 widget tests
affects: [10-03 ScaffoldChart, 10-04 ScaffoldChartScrubber]

# Tech tracking
tech-stack:
  added:
    - fl_chart: ^1.2.0
  patterns:
    - "D-02 single-file isolation of fl_chart — base atoms stay fl_chart-free"
    - "Pass-through reducedMotion contract: parameter required at the API, documented as no-op for fl_chart static data"
    - "Palette pieces passed individually (Color/TextStyle), not as ScaffoldPalette — keeps renderer unit-testable without Theme"

key-files:
  created:
    - lib/utils/scaffold_chart_renderer.dart
    - test/utils/scaffold_chart_renderer_test.dart
  modified:
    - pubspec.yaml

key-decisions:
  - "yBounds passed as precomputed (double, double) tuple — renderer never recomputes (atom owns visible-window rule)"
  - "reducedMotion documented as pass-through contract because fl_chart 1.2.0 does not animate static data"
  - "plotWidth/viewMinX/viewMaxX accepted and asserted for contract completeness even though renderer currently hands minX/maxX directly to fl_chart"
  - "LineTouchResponse requires touchLocation+touchChartCoordinate named params in fl_chart 1.2.0; TouchLineBarSpot needs (bar, barIndex, spot, distance) positional — test constructs the full chain"

patterns-established:
  - "Single-seam chart engine isolation: any future chart-library swap touches exactly one file"
  - "framed/axis-free selection is runtime-driven via chartUsesFrame(plotHeight) — never a per-surface setting"

requirements-completed: [WIDG-35, WIDG-36]

# Metrics
duration: 18min
completed: 2026-08-21
---

# Phase 10 Plan 02: fl_chart Renderer Support Part Summary

**Locks the fl_chart dependency into a single 301-line seam (`lib/utils/scaffold_chart_renderer.dart`) behind a scaffold-neutral `buildScaffoldLineChart()` API, covered by 12 widget tests, with zero fl_chart leakage into base atoms (D-02 verified by grep).**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-08-21 (TDD RED)
- **Completed:** 2026-08-21 (TDD GREEN + verify)
- **Tasks:** 3 (Task 1 pubspec, Task 2+3 combined TDD RED/GREEN)
- **Files modified:** 2 created, 1 edited

## Accomplishments

- `pubspec.yaml` gains exactly ONE new dependency: `fl_chart: ^1.2.0` (D-01 — matches GeniusWallet `pubspec.yaml:36`). All existing dependencies unchanged. `flutter pub get` resolved successfully (added `fl_chart 1.2.0` + transitive `equatable 2.1.0`).
- `lib/utils/scaffold_chart_renderer.dart` (301 lines) is the ONLY scaffold file importing `package:fl_chart` — verified by `grep -rln "package:fl_chart" lib/` returning exactly one path. Base atoms in `lib/components/` are fl_chart-free (D-02 / D-08).
- `buildScaffoldLineChart()` exposes a single public entry point with the full contract signature: spots, plotHeight, plotWidth, lineColor, borderControl, borderSubtle, textSecondary, axisLabelStyle, reducedMotion, yBounds, onSpotTouched, viewMinX, viewMaxX, minX, maxX.
- Framed variant (plotHeight ≥ `kChartFrameMinHeight`) renders right-side titles at `reservedSize: kChartAxisGutter` with nice-number tick ladder (`chartTickStep` + `chartAxisLabel`); axis-free variant hides grid and all four title sides.
- Tooltip suppressed per D-05 (transparent color, `BorderSide.none`, `EdgeInsets.zero` padding, `getTooltipItems` returns nulls).
- Touch indicator matches D-05 exactly: `FlDotCirclePainter(radius: 5, strokeWidth: 4, strokeColor: lineColor at 26% alpha)` over a `FlLine(color: borderControl, strokeWidth: 1)` crosshair spanning `yBounds.$1` to `yBounds.$2`.
- Below-bar gradient ports the GeniusWallet pattern 1:1: `LinearGradient` from `lineColor` at 26% alpha to 0% alpha, `begin: topCenter`, `end: bottomCenter`, `stops: [0.0, kChartFillFadeStop]`.
- Empty `spots` returns `SizedBox.shrink()` — never constructs a `LineChart` with empty data.
- `reducedMotion` parameter documented as a pass-through contract: fl_chart 1.2.0 does not animate static data, so the parameter exists at the boundary but is not consumed inside the renderer. Library doc comment explains the contract for future variants.
- 12 widget tests cover all 9 behavior cases from the plan plus empty-spots guard and touch-enabled/disabled polarity: framed grid+titles, axis-free grid/titles suppression, border hidden on both variants, tooltip suppression, touch indicator shape/color, spotIndex callback forwarding, gradient stops+alpha, dots hidden, `isCurved: false`, `barWidth: 2`.

## Task Commits

Each task was committed atomically; Tasks 2+3 ran as one TDD RED/GREEN cycle (matching Plan 01's precedent):

1. **Task 1: pubspec fl_chart dependency** — `3477812` (chore)
2. **Tasks 2+3 RED: failing widget tests for scaffold_chart_renderer** — `6273316` (test)
3. **Tasks 2+3 GREEN: implement scaffold_chart_renderer + fix fl_chart API call signatures in test** — `c1568ff` (feat)

## Files Created/Modified

- `pubspec.yaml` — added `fl_chart: ^1.2.0` (alphabetical placement between `flutter` sdk and `flutter_bloc`).
- `lib/utils/scaffold_chart_renderer.dart` (301 lines) — single fl_chart seam. Library doc comment documents the D-02/D-08 isolation contract and the `reducedMotion` pass-through rule. Imports only `package:fl_chart`, `package:flutter/material.dart`, and the sibling `chart_geometry.dart`. Defines 9 `_k*` constants (no magic numbers). Allman bracing, `final` locals, Doxygen `///` doc comments on the public function.
- `test/utils/scaffold_chart_renderer_test.dart` (228 lines) — 12 widget tests in 3 groups (`framed`, `axis-free`, `touch`). Uses synchronous assertions against the returned `LineChart.data` — no `pumpWidget` needed because fl_chart's `LineChart` is a pure-data container at construction time. Test 6 (touch callback) constructs a `TouchLineBarSpot` + `LineTouchResponse` manually to drive `touchCallback` synchronously.

## Verification

- `dart analyze lib/utils/scaffold_chart_renderer.dart test/utils/scaffold_chart_renderer_test.dart --fatal-infos` → **No issues found!**
- `flutter test test/utils/scaffold_chart_renderer_test.dart` → **+12: All tests passed!**
- `flutter test` (full suite) → **+378: All tests passed!**
- `grep -rln "package:fl_chart" lib/components/` → **empty** (D-02 gate verified)
- `grep -rln "package:fl_chart" lib/utils/` → **exactly one file**: `lib/utils/scaffold_chart_renderer.dart`
- All plan-level grep gates pass: `import 'package:fl_chart/fl_chart.dart'`, `buildScaffoldLineChart`, `FlBorderData(show: false)`, `getTooltipItems`, `kChartFillFadeStop`, `FlDotCirclePainter` all present in source.
- File length 301 lines ≥ 150-line floor.
- pubspec grep `^  fl_chart: \^1\.2\.0$` matches with exactly 2 leading spaces.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] fl_chart 1.2.0 constructor signatures differ from plan assumptions**
- **Found during:** Task 3 GREEN (analyzer)
- **Issue:** The plan's Test 6 sketch called `LineTouchResponse(<LineBarSpot>[spot])` and `FlTapDownEvent()` positionally. fl_chart 1.2.0 actually requires `LineTouchResponse({required touchLocation, required touchChartCoordinate, lineBarSpots})` with named params, and `FlTapDownEvent(this.details)` requires a positional `TapDownDetails`. Additionally `TouchLineBarSpot` (the runtime element type of `lineBarSpots`) requires `(bar, barIndex, spot, distance)` positionally — not the `LineBarSpot` shape.
- **Fix:** Test now constructs the full chain: `barData.spots[3]` (must be an actual entry — `spotIndex` is derived via `bar.spots.indexOf(spot)`), then `TouchLineBarSpot(barData, 0, flSpot, 0.0)`, then `LineTouchResponse(touchLocation: Offset.zero, touchChartCoordinate: Offset.zero, lineBarSpots: [touchSpot])`. Semantics preserved: the callback still receives a response whose `lineBarSpots.first.spotIndex == 3`.
- **Files modified:** `test/utils/scaffold_chart_renderer_test.dart`
- **Commit:** `c1568ff`

**2. [Rule 1 - Bug] TouchedSpotIndicatorData field name is `touchedSpotDotData`, not `touchedDotData`**
- **Found during:** Task 3 RED (analyzer)
- **Issue:** Plan sketch referenced `indicator.touchedDotData`; the actual fl_chart 1.2.0 field is `touchedSpotDotData`.
- **Fix:** Renamed in test; semantics unchanged.
- **Files modified:** `test/utils/scaffold_chart_renderer_test.dart`
- **Commit:** `6273316` (RED) then folded into `c1568ff` (GREEN)

**3. [Rule 1 - Bug] `FlBorderData` constructor is not `const` in fl_chart 1.2.0**
- **Found during:** Task 2 GREEN (analyzer)
- **Issue:** Plan sketch implied a `const FlBorderData(show: false)`; the constructor uses default-value assignment (`show = show ?? true`) so it cannot be `const`. The `const` keyword fails compilation.
- **Fix:** Declared as `final FlBorderData borderData = FlBorderData(show: false);` — runtime field, same semantics.
- **Files modified:** `lib/utils/scaffold_chart_renderer.dart`
- **Commit:** `c1568ff`

## Authentication Gates

None.

## Known Stubs

None — every behavior is fully implemented and widget-tested.

## Threat Flags

None — pure presentation-layer code, no I/O, no network, no auth, no schema, no user-input handling beyond the `onSpotTouched` callback (which forwards an `int` index to the consumer; no data crosses the boundary).

## Self-Check: PASSED

- [x] `lib/utils/scaffold_chart_renderer.dart` exists (301 lines)
- [x] `test/utils/scaffold_chart_renderer_test.dart` exists (228 lines)
- [x] `pubspec.yaml` contains `fl_chart: ^1.2.0` (exactly one new dependency)
- [x] Commit `3477812` (chore pubspec) found in `git log`
- [x] Commit `6273316` (test RED) found in `git log`
- [x] Commit `c1568ff` (feat GREEN) found in `git log`
- [x] All 12 renderer tests pass; full suite +378 passing
- [x] `dart analyze --fatal-infos` clean on both files
- [x] `grep -rln "package:fl_chart" lib/components/` returns empty (D-02 gate)
- [x] `grep -rln "package:fl_chart" lib/utils/` returns exactly one file
