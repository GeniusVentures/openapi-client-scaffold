---
phase: 10-chart-scrubber
plan: 05
subsystem: ui
tags: [chart, scrubber, barrel-export, demo, example-app, uat, theme-tokens]

# Dependency graph
requires:
  - phase: 10-chart-scrubber plan 03/04
    provides: ScaffoldChart<T> + ScaffoldChartScrubber<T> atoms to export and demo
provides:
  - Barrel exports for ScaffoldChart, ScaffoldChartScrubber, chart_geometry, scaffold_chart_renderer
  - ChartDemo + ChartScrubberDemo registered in the example app
  - Human UAT of chart + scrubber under dark and light palettes
affects: [10-06 smooth/range extension, 11 verification/coverage]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Barrel export in alphabetical position within lib/frontend_scaffold.dart"
    - "Demo files use theme tokens only (context.palette/dimens/textTheme) — zero hardcoded colors"

key-files:
  created:
    - example/lib/demos/chart_demo.dart
    - example/lib/demos/chart_scrubber_demo.dart
  modified:
    - lib/frontend_scaffold.dart
    - example/lib/main.dart

key-decisions:
  - "UAT surfaced three scrubber interaction regressions (hover must never toggle-clear; hover-exit must not clear during a drag; focus ring must not blink on selection) — fixed in 10-05 follow-ups and codified as regression tests."

patterns-established:
  - "Example-app demo registration via _DemoTile in main.dart; one demo per atom family"

requirements-completed: [WIDG-35, WIDG-36]

# Metrics
duration: ~1h (plus UAT)
completed: 2026-08-22
---

# Phase 10 (plan 05): Barrel Exports + Chart Demos Summary

**Exported the Phase 10 chart/scrubber atoms from the barrel and shipped ChartDemo + ChartScrubberDemo in the example app, closing WIDG-35/36 after a UAT pass that surfaced and fixed three scrubber interaction regressions.**

## Performance

- **Duration:** ~1h (plus human UAT)
- **Started:** 2026-08-21T18:28:25-07:00
- **Completed:** 2026-08-22 (UAT approved with the 10-06 UAT)
- **Tasks:** 3 (barrel export, demos, human UAT)
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- Barrel-exported ScaffoldChart, ScaffoldChartScrubber, chart_geometry, scaffold_chart_renderer
- Shipped ChartDemo (framed / axis-free / formatter / empty-state) and ChartScrubberDemo (scrub + keyboard + PointerExit + live region) and registered both in the example app
- Human UAT approved (chart + scrubber render and interact correctly under dark and light palettes)

## Task Commits

1. **Task 1: barrel-export the four Phase 10 files** — `10b1856` (feat)
2. **Task 2: ship ChartDemo + ChartScrubberDemo and register in example app** — `09abe71` (feat)
3. **Task 3: human UAT checkpoint** — approved by user (no commit; gate)

**UAT regression fixes (10-05):** `41de76e` `4b44f15` (hover-exit gating + tap-focus ring) · `a6633a7` `90bcb9d` (hover never toggle-clears) · `e78b147` `c6f80e3` (tap-toggle removal) · `70b8e4d` `73ded7e` (focus-ring tree-shape stability)

**Plan metadata:** plan file `10-05-PLAN.md`

_Note: TDD/UAT-fix tasks have multiple commits (test → feat/fix)._

## Files Created/Modified
- `lib/frontend_scaffold.dart` — barrel exports (chart, chart_scrubber, chart_geometry, scaffold_chart_renderer)
- `example/lib/demos/chart_demo.dart` — four canonical ScaffoldChart configurations
- `example/lib/demos/chart_scrubber_demo.dart` — scrub selection + keyboard + PointerExit + live region
- `example/lib/main.dart` — demo registration

## Decisions Made
See `key-decisions` in frontmatter — the three UAT regressions were root-caused and fixed at the source (gesture-event-kind discrimination at the fl_chart seam, hover-exit gating on active drag, stable tree shape above the scrubber core).

## Deviations from Plan
None — plan executed as specified. The UAT regression fixes were in-scope remediation of the shipped atoms, not plan changes.

## Issues Encountered
- UAT surfaced three scrubber interaction regressions (hover toggle-clear, hover-exit-during-drag clear, focus-ring blink); each was reproduced with a RED test, root-caused, and fixed (see fix commits above).

## User Setup Required
None.

## Next Phase Readiness
- WIDG-35 and WIDG-36 are closed; the chart + scrubber atoms are exported, demoed, and UAT-approved.
- Phase 10 extended by plan 10-06 (D-08 smooth scrub, D-09 range selector, D-10 gesture rule) — see `10-06-SUMMARY.md`.

---
*Phase: 10-chart-scrubber*
*Completed: 2026-08-22*
