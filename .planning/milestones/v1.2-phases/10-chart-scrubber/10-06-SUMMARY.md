---
phase: 10-chart-scrubber
plan: 06
subsystem: ui
tags: [chart, scrubber, range-selector, smooth-scrub, gesture-arena, scaffold-chart, a11y, theme-tokens, tdd, widget-tests]

# Dependency graph
requires:
  - phase: 10-chart-scrubber plan 03/04
    provides: ScaffoldChart<T> + ScaffoldChartScrubber<T> atoms this plan extends (D-08) and composes (D-09)
provides:
  - Renderer D-08 smooth seam — continuous-position plumbing + interpolated-dot overlay (scaffold_chart_renderer.dart)
  - ScaffoldChartScrubber smooth mode + onPositionChanged continuous callback (D-08)
  - ScaffoldChartRangeSelector<T> drag-band composed atom reporting (T start, T end)? via onRangeSelected (D-09); report-only
  - D-10 gesture-conflict rule — band drag suppresses inner pan-scrub; tap/hover pass through to point-scrub
affects: [11 verification/coverage]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Report-only composition atom — the range selector NEVER rescales/zooms/filters itself; the consumer applies the range via the onRangeSelected callback (sets viewMinX/viewMaxX on next build)"
    - "Always-present translucent GestureDetector + IgnorePointer(CustomPaint) overlay: horizontal-drag recognizer joins the arena first (suppresses pan-scrub) while tap/hover pass through — the D-10 mechanism"
    - "Raw pointer-down position captured via Listener.onPointerDown anchors the band's left edge (DragStartDetails.localPosition is slop-shifted under DragStartBehavior.start)"
    - "Pixel↔chart-x mapping accounts for the surface's space8 inset AND the framed chart's kChartAxisGutter right gutter (fl_chart chartVirtualRect)"

key-files:
  created:
    - lib/components/scaffold_chart_range_selector.dart
    - test/components/scaffold_chart_range_selector_test.dart
    - example/lib/demos/chart_range_selector_demo.dart
  modified:
    - lib/utils/scaffold_chart_renderer.dart
    - lib/components/scaffold_chart.dart
    - lib/components/scaffold_chart_scrubber.dart
    - lib/utils/chart_geometry.dart
    - lib/frontend_scaffold.dart
    - example/lib/demos/chart_scrubber_demo.dart
    - example/lib/main.dart

key-decisions:
  - "D-10 deviation (Rule 1 — plan bug): the plan's overlay used HitTestBehavior.opaque + a conditional Positioned.fill. opaque starves the chart of tap/hover (violating D-10's own pass-through contract) and a conditional overlay can never capture the FIRST drag (chicken-and-egg). Implemented instead: always-present translucent GestureDetector + IgnorePointer on the CustomPaint."
  - "Tap-vs-drag discrimination uses a _sawDragUpdate bool (set in _onDragUpdate), not start.dx == current.dx float equality — a drag that returns to its start pixel is a real drag and must fire."
  - "A failed band drag (degenerate window / empty series / collapsed layout) does NOT fire onRangeSelected(null) — null is reserved for explicit clear (Escape). Prevents a failed drag from silently wiping a valid selection."
  - "dimens.space8 resolved once per build into a State field; gesture handlers read the cached value (no inherited-widget dependency at gesture time)."
  - "In-flight band drag is cancelled when LayoutBuilder constraints materially change (resize mid-drag) so the band never maps against mismatched geometries."

patterns-established:
  - "Gesture-arena precedence via Stack ordering + HitTestBehavior (translucent, NOT opaque) + IgnorePointer on the paint layer — reusable template for overlay-vs-chart gesture conflicts"
  - "Calibration-by-hover-sweep in tests: empirically map value→pixel by sweeping a mouse pointer and recording first-selection pixel, because framed-chart pixel mapping is non-obvious (gutter shifts data points)"

requirements-completed: [WIDG-36]

# Metrics
duration: ~4h (incl. UAT + code-review fix pass)
completed: 2026-08-22
---

# Phase 10 (plan 06): Smooth Scrub + Range Selector Summary

**Shipped D-08 smooth scrub (continuous dot riding the line) and the D-09/D-10 ScaffoldChartRangeSelector drag-band atom — report-only range selection with gesture-arena-correct suppression of inner pan-scrub.**

## Performance

- **Duration:** ~4h (implementation + human UAT + 12-finding code-review fix pass)
- **Started:** 2026-08-22T15:26:32-07:00
- **Completed:** 2026-08-22
- **Tasks:** 5 (4 implementation + 1 human-verify checkpoint)
- **Files modified:** 11 (3 created, 8 modified)

## Accomplishments
- Renderer seam extended with continuous-position plumbing + interpolated-dot overlay (D-08); `ScaffoldChartScrubber` smooth mode with `onPositionChanged` continuous callback
- `ScaffoldChartRangeSelector<T>` composed atom — drag-band overlay reporting `(T, T)?` via `onRangeSelected`, report-only (never rescales itself), band visuals per 10-UI-SPEC accent item 5 (12% alpha fill + 1px accent edge rules)
- D-10 gesture-conflict rule: band drag suppresses inner pan-scrub via Stack-overlay arena precedence; tap/hover/keyboard point-scrub unchanged
- Barrel export + new range-selector demo + smooth-mode scrubber section registered in the example app
- Human UAT approved (smooth scrub + range selection + consumer-policy zoom, dark AND light palettes)
- Code review (deep, 14 files): 0 Critical / 7 Warning / 5 Info — all 12 findings fixed and re-verified

## Task Commits

Each task was committed atomically (TDD: RED → GREEN):

1. **Task 1: renderer D-08 smooth seam + interpolated-dot overlay** — `d294b8b` (test/RED) → `0a83b2b` (feat/GREEN)
2. **Task 2: smooth-mode surface on ScaffoldChart + ScaffoldChartScrubber (D-08)** — `2ba0844` (test/RED) → `ecd26cb` (feat/GREEN)
3. **Task 3: ScaffoldChartRangeSelector<T> drag-band composed atom (D-09/D-10)** — `be9d7e3` (test/RED) → `41022b6` (feat/GREEN, deviation documented)
4. **Task 4: barrel export + demos + final gates** — `28ad09b` (barrel) + `7671120` (demos + registration)
5. **Task 5: human UAT checkpoint** — approved by user (no commit; gate)

**Code review:** `92d3630` (docs: add 10-REVIEW.md)
**Code-review fixes (12):** `b4fee5c` `f2db97b` `a6f706d` `807c22c` `60e3c2a` `75a43ed` `b49472d` `e24cdbb` `eac7937` `266e9d9` `496ae30` `934a8f9`

**Plan metadata:** `4ad6808` (docs: create gap-extension plan 10-06)

## Files Created/Modified
- `lib/components/scaffold_chart_range_selector.dart` — D-09 drag-band composed atom (report-only; D-10 suppression; keyboard + focus + a11y)
- `test/components/scaffold_chart_range_selector_test.dart` — Tests 15-28 (+ regression Tests 29-30 from the review fixes)
- `example/lib/demos/chart_range_selector_demo.dart` — drag-range + consumer-policy zoom demo
- `lib/utils/scaffold_chart_renderer.dart` — D-08 smooth seam + interpolated-dot overlay
- `lib/components/scaffold_chart.dart` / `scaffold_chart_scrubber.dart` — smooth-mode surface + `onPositionChanged`
- `lib/utils/chart_geometry.dart` — dead-clamp removal (WR-05)
- `lib/frontend_scaffold.dart` — barrel export
- `example/lib/demos/chart_scrubber_demo.dart` / `example/lib/main.dart` — smooth-mode section + registration

## Decisions Made
See `key-decisions` in frontmatter — most importantly the D-10 `opaque`→`translucent`+`IgnorePointer` correction and the three gesture-robustness rules (update-flag discrimination, no null-fire on failed drag, resize-cancels-band).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] D-10 overlay HitTestBehavior (opaque → translucent + IgnorePointer)**
- **Found during:** Task 3 (range selector implementation)
- **Issue:** The plan specified `HitTestBehavior.opaque` on the band overlay + a conditional `Positioned.fill`. opaque starves the chart of tap/hover (breaking D-10's own pass-through contract, plan line 29), and a conditional overlay can never capture the first drag.
- **Fix:** Always-present `translucent` GestureDetector + `IgnorePointer` on the CustomPaint; horizontal-drag recognizer joins the arena first (suppressing pan-scrub) while tap/hover pass through.
- **Files modified:** lib/components/scaffold_chart_range_selector.dart
- **Verification:** Tests 18 (drag suppression) + 19 (tap/hover pass-through) both pass; the plan's `grep -q "HitTestBehavior.opaque"` gate is expected to fail on the correct implementation.
- **Committed in:** `41022b6` (Task 3 GREEN commit)

**2. [Rule 1 - Bug] Framed-chart center-tap test bug (Test 19)**
- **Found during:** Task 3 test bring-up
- **Issue:** Test 19 originally tapped the widget's geometric center, but framed charts inset the plot by the 62px right gutter (fl_chart `chartVirtualRect`), so center ≠ over the center data point → tap selected nothing (>10px threshold).
- **Fix:** Rewrote Test 19 to calibrate point 30's real pixel location (hover-sweep) and tap/hover there — mirroring the drag tests.
- **Files modified:** test/components/scaffold_chart_range_selector_test.dart
- **Verification:** Test 19 passes.
- **Committed in:** `be9d7e3` (Task 3 RED commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — plan/test bugs). The 12 code-review findings (WR-01..07, IN-01..05) are recorded in `10-REVIEW.md` and fixed in their own commits — they are review remediation, not plan deviations.
**Impact on plan:** Both deviations necessary for correctness (one was a plan-internal contradiction). No scope creep.

## Issues Encountered
- MouseTracker assertion when the calibration helper left its mouse pointer active and a later test added a second pointer — fixed by `await mouse.removePointer()` at the end of the calibration helper.
- Gesture-arena zero-width-band edge case: a force-accepted tap fires `onHorizontalDragStart/End` with `start.dx == current.dx`; guarded so a tap is not reported as a range drag (superseded by the WR-02 update-flag fix).

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Phase 10 plans 10-01..10-04 and 10-06 are complete; 10-05 (barrel exports + chart demos + UAT) shipped its code and passed UAT — its SUMMARY is written alongside this one.
- All gates green: `dart analyze --fatal-infos` clean; `flutter test` 451 passed / 1 skipped; D-02 seam intact (fl_chart only in the renderer).
- Ready for Phase 11 (Verification & Coverage Gate) once the phase is marked complete and the PR ships.

---
*Phase: 10-chart-scrubber*
*Completed: 2026-08-22*
