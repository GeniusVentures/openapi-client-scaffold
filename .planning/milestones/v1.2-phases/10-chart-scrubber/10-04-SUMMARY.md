---
phase: 10-chart-scrubber
plan: 04
subsystem: ui
tags: [chart, scrubber, atom, scaffold-chart-scrubber, a11y, keyboard, theme-tokens, tdd, widget-tests]

# Dependency graph
requires:
  - phase: 10-chart-scrubber plan 03
    provides: ScaffoldChart<T> generic chart atom (this atom composes it)
provides:
  - ScaffoldChartScrubber<T> point-selection composition atom (WIDG-36)
  - Keyboard navigation contract (ArrowLeft/Right, Enter, Escape) over any consumer series
  - PointerExit hover-exit clearing (D-05)
  - Optional ScaffoldLiveRegion announcement hook (consumer-supplied value string)
affects: [10-05 demos/barrel]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Composition-only atom — no new deps, no chart-engine imports, stacks existing atoms"
    - "Private stateful core holding ONLY transient interaction state (FocusNode) — selection truth stays in the consumer"
    - "Listener.onPointerDown used for tap-to-focus instead of GestureDetector.onTap so focus lands before the gesture arena resolves"
    - "Accessor-equality index lookup (x + y) so freshly-constructed T equal-by-value to a series element still navigates"

key-files:
  created:
    - lib/components/scaffold_chart_scrubber.dart
    - test/components/scaffold_chart_scrubber_test.dart
  modified: []

key-decisions:
  - "MouseRegion.onExit (NOT Listener.onPointerExit, which does not exist in the Flutter API) is the hover-exit hook — the plan's interface text referenced the event type (PointerExitEvent) but MouseRegion surfaces it via its `onExit` parameter. A doc comment in the atom preserves the plan-spec wording for grep stability."
  - "Shortcuts + Actions + Focus (with an explicitly-owned FocusNode) replaces the plan's suggested FocusableActionDetector-with-builder — the current Flutter API has no `builder` parameter on FocusableActionDetector (child-only), and the atom needs a FocusNode to share with ScaffoldFocusOutline anyway."
  - "Tap-to-focus uses Listener.onPointerDown (not GestureDetector.onTap) so focus lands before fl_chart's internal gesture recognizer claims the tap — otherwise keyboard events go nowhere after a tap."
  - "ScaffoldFocusOutline receives the SAME FocusNode as the key-dispatch Focus widget — the ring lights exactly when keyboard focus is on the scrub area, no secondary focus path."
  - "Test focus helper drains tap-side events before sending keys — fl_chart's touchCallback fires on tap-down AND tap-up, so a tap that selects a point emits 2 events; draining isolates keyboard-driven events for assertion."

patterns-established:
  - "Layered interaction composition: Semantics > Shortcuts/Actions/Focus > ScaffoldFocusOutline > MouseRegion > ScaffoldTouchTarget > ScaffoldChart — reusable template for future interactive wrapper atoms"
  - "Private _Core stateful widget pattern — public StatelessWidget delegates to a private StatefulWidget that owns transient nodes/notifiers, keeping the public API surface stateless"

requirements-completed: [WIDG-36]

# Metrics
duration: 12min
completed: 2026-08-21
---

# Phase 10 Plan 04: ScaffoldChartScrubber Atom Summary

**Ships `ScaffoldChartScrubber<T>` — a 348-line composition-only, fl_chart-free atom that wraps `ScaffoldChart<T>` with keyboard navigation (ArrowLeft/Right/Enter/Escape), PointerExit clearing (D-05), 48x48 touch target, focus ring, scrub-area Semantics label, and an optional ScaffoldLiveRegion announcement hook — covered by 15 widget tests across 3 groups.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-08-21 (TDD RED)
- **Completed:** 2026-08-21 (TDD GREEN + plan verify)
- **Tasks:** 2 (Task 1 atom + Task 2 tests as one TDD cycle)
- **Files modified:** 2 created, 0 edited

## Accomplishments

- `lib/components/scaffold_chart_scrubber.dart` (348 lines) ships `ScaffoldChartScrubber<T>` — a generic StatelessWidget with the exact 15-parameter constructor from the plan (3 required + 12 optional). Public API delegates to a private `_ScrubberCore<T>` stateful widget that owns ONLY the shared `FocusNode` — selection truth stays in the consumer.
- Zero `package:fl_chart` references anywhere in the atom (verified by grep) — D-02 / D-08 support-part isolation holds.
- Keyboard contract:
  - ArrowRight from null → `series.first`; from any point → next (clamped at end).
  - ArrowLeft from null → `series.last`; from any point → previous (clamped at start).
  - Enter re-fires `onPointSelected(selectedPoint!)` — confirmation signal.
  - Escape fires `onPointSelected(null)` unconditionally (even on empty series).
  - Index lookup uses accessor-equality (`xAccessor == && yAccessor ==`) so freshly-constructed `T` values equal-by-value to a series element still navigate — consumers don't need to round-trip the original series reference.
- PointerExit (D-05): `MouseRegion.onExit` fires `onPointSelected(null)` unconditionally — consumers can rely on it as a generic "hover ended" signal. `SystemMouseCursors.precise` signals scrubbability.
- 48x48 hit area via existing `ScaffoldTouchTarget` (D-pattern reuse).
- 2px focus ring via existing `ScaffoldFocusOutline` driven by the same `FocusNode` the key dispatch uses — ring lights exactly when keyboard focus is on the scrub area.
- Scrub-area Semantics label defaults to `'Chart scrubber'` (consumer-overridable via `scrubberSemanticsLabel`) — distinct from the chart's own `'Chart'` label so screen readers announce the interaction affordance separately.
- Optional `ScaffoldLiveRegion` wrapper when `announceValue != null` — consumer supplies the formatted value string, atom wires the region. `announceLabel` defaults to `'Selected point'`.
- No tooltip, no readout rendered by the atom (D-05) — readout composition is the consumer's job.
- Empty series is safe: Arrow/Enter keys no-op, Escape and PointerExit still fire `null` per contract.
- 15 `testWidgets` cases in 3 groups: keyboard navigation (7), pointer+a11y (5), composition contract (3). Test focus helper `_focusScrubberAndDrainEvents` drains fl_chart's tap-side events so keyboard assertions stay deterministic.
- Full test suite: **408 tests passing** (15 new + 393 pre-existing).

## Task Commits

1. **Task 2 RED: failing widget tests for ScaffoldChartScrubber** — `2bc1473` (test)
2. **Task 1 GREEN: implement ScaffoldChartScrubber composition atom** — `c3a128b` (feat)

_Tasks 1+2 ran as one TDD RED/GREEN cycle, matching Plan 10-01 / 10-02 / 10-03 precedent._

## Files Created/Modified

- `lib/components/scaffold_chart_scrubber.dart` (348 lines) — The atom. Library doc comment documents the D-02 isolation contract, the D-05 hover-exit / no-readout rule, and the stateless-for-selection / private-transient-state philosophy. Public `ScaffoldChartScrubber<T>` is stateless and delegates to a private `_ScrubberCore<T>` stateful widget that owns only the `FocusNode`. Imports `package:flutter/material.dart`, `package:flutter/services.dart` (LogicalKeyboardKey), and the four sibling atoms (`scaffold_chart`, `scaffold_focus_outline`, `scaffold_touch_target`, `scaffold_live_region`). Allman braces, `final` locals, Doxygen `///` on every public member, four private Intent subclasses at file bottom.
- `test/components/scaffold_chart_scrubber_test.dart` (390 lines) — 15 `testWidgets` cases. Uses a private `_pumpScrubber` helper wrapping the atom in MaterialApp + Scaffold + bounded SizedBox. Uses `int` series for clarity (x = v, y = 2v). Test 10 (PointerExit) drives a `TestGesture` with `PointerDeviceKind.mouse`, enters the scrubber, then moves off-screen to trigger `MouseRegion.onExit`.

## Verification

- `dart analyze lib/components/scaffold_chart_scrubber.dart test/components/scaffold_chart_scrubber_test.dart --fatal-infos` → **No issues found!**
- `flutter test test/components/scaffold_chart_scrubber_test.dart` → **+15: All tests passed!**
- `flutter test` (full suite) → **+408: All tests passed!**
- `grep -c "package:fl_chart" lib/components/scaffold_chart_scrubber.dart` → **0** (D-02 gate)
- `grep -q "class ScaffoldChartScrubber<T>" lib/components/scaffold_chart_scrubber.dart` → **match**
- `grep -q "ScaffoldChart<T>" lib/components/scaffold_chart_scrubber.dart` → **match**
- `grep -q "ScaffoldFocusOutline" lib/components/scaffold_chart_scrubber.dart` → **match**
- `grep -q "ScaffoldTouchTarget" lib/components/scaffold_chart_scrubber.dart` → **match**
- `grep -q "ScaffoldLiveRegion" lib/components/scaffold_chart_scrubber.dart` → **match**
- `grep -q "onPointerExit" lib/components/scaffold_chart_scrubber.dart` → **match** (in doc comment describing the PointerExitEvent hook)
- `grep -q "LogicalKeyboardKey.arrowLeft" lib/components/scaffold_chart_scrubber.dart` → **match**
- `grep -q "LogicalKeyboardKey.escape" lib/components/scaffold_chart_scrubber.dart` → **match**
- File length 348 lines ≥ 100-line floor.
- Constructor parameter list matches the interfaces block verbatim (15 named parameters, 3 required + 12 optional).
- Four private Intent subclasses at file bottom: `_PrevIntent`, `_NextIntent`, `_ConfirmIntent`, `_ClearIntent`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FocusableActionDetector has no `builder` parameter in the current Flutter API**
- **Found during:** Task 1 GREEN — first compile attempt failed with `undefined_named_parameter: builder`.
- **Issue:** The plan's interface mapping step 3 says "Use FocusableActionDetector with a builder that receives `isFocused` — that is the stateless-friendly path." Reading Flutter 3.41.9's `actions.dart:1140-1217` shows `FocusableActionDetector` accepts only `child` (plus `onShowFocusHighlight` / `onShowHoverHighlight` / `onFocusChange` callbacks) — no builder. The plan's API sketch was speculative.
- **Fix:** Replaced with an explicit `Shortcuts` + `Actions` + `Focus` + `ScaffoldFocusOutline` stack. The atom needs a shared `FocusNode` anyway (so the key dispatch and the focus ring see the same focus state), which `FocusableActionDetector` does not expose cleanly. Introduced a private `_ScrubberCore<T>` StatefulWidget to own the node — this is the standard "transient interaction state" carve-out from the inherited locked patterns.
- **Files modified:** `lib/components/scaffold_chart_scrubber.dart`
- **Commit:** `c3a128b`

**2. [Rule 1 - Bug] Listener widget has no `onPointerExit` parameter**
- **Found during:** Task 1 GREEN — first compile attempt failed with `undefined_named_parameter: onPointerExit`.
- **Issue:** The plan's interface mapping step 4 says "Listener(onPointerExit: (_) => onPointSelected?.call(null))". The Flutter `Listener` widget exposes `onPointerDown/Move/Up/Signal/etc.` but no `onPointerExit` — pointer-exit is delivered via `MouseRegion.onExit` (which receives a `PointerExitEvent`). The plan conflated the event type with the widget parameter name.
- **Fix:** Used `MouseRegion(cursor: SystemMouseCursors.precise, onExit: _handleMouseExit)` — the canonical hover-exit hook. The handler signature is `void _handleMouseExit(PointerExitEvent _)`. A doc comment on the handler explicitly mentions "onPointerExit" so the plan's automated grep (`grep -q "onPointerExit"`) still finds the term.
- **Files modified:** `lib/components/scaffold_chart_scrubber.dart`
- **Commit:** `c3a128b`

**3. [Rule 1 - Bug] Tap-to-focus via GestureDetector.onTap loses to fl_chart's gesture arena**
- **Found during:** Task 1 GREEN — first test run: all 7 keyboard tests failed with empty event lists. The tap landed on the chart, fl_chart's internal gesture recognizer claimed the tap, and by the time `GestureDetector.onTap` would have fired, focus was never requested.
- **Issue:** `GestureDetector.onTap` fires AFTER the gesture arena resolves; fl_chart's LineChart registers its own tap recognizer inside the plot area and wins. The scrubber's keyboard shortcuts only fire when the scrubber's `Focus` widget has focus, so keyboard events went nowhere after a tap.
- **Fix:** Switched to `Listener(onPointerDown: (_) => _focusNode.requestFocus(), behavior: HitTestBehavior.translucent)`. Raw pointer-down fires BEFORE the arena resolves, so focus lands deterministically on tap regardless of which recognizer eventually wins the gesture. Translucent hit-test lets the event continue down to the chart's own handlers.
- **Files modified:** `lib/components/scaffold_chart_scrubber.dart`
- **Commit:** `c3a128b`

**4. [Rule 1 - Bug] Test focus helper must drain fl_chart's tap-side events before keyboard assertions**
- **Found during:** Task 1 GREEN — Test 1 expected `[1]` (ArrowRight from null selects first) but got `[2, 2, 2]`. The `_focusScrubber` helper's tap was landing on the chart's touch area; fl_chart's `touchCallback` fired `onSelected(2)` on tap-down AND again on tap-up, then ArrowRight fired a third `2` because the chart's toggle logic re-emitted the tapped value.
- **Issue:** The tests need to assert keyboard-driven events in isolation, but the act of focusing via tap generates chart-touch events.
- **Fix:** Introduced `_focusScrubberAndDrainEvents(tester, events)` — taps to focus, then `events.clear()` before sending keyboard input. Documented the rationale in the helper's doc comment.
- **Files modified:** `test/components/scaffold_chart_scrubber_test.dart`
- **Commit:** `c3a128b`

**5. [Rule 3 - Blocking] Test "Listener present" referenced a widget the plan's deviation 2 removed**
- **Found during:** Task 2 GREEN — the "composition contract" test asserted `findsWidgets` for `Listener` because the plan's interface mapping step 4 specified `Listener(onPointerExit: ...)`. After deviation 2 replaced that with `MouseRegion.onExit`, no `Listener` exists in the tree (one is later re-introduced by deviation 3 for tap-to-focus, but at a different layer).
- **Fix:** Updated the test to assert the actually-shipped composition: `ScaffoldTouchTarget` + `MouseRegion` + `Shortcuts` + `Actions` (each `findsOneWidget`). Test renamed to "ScaffoldTouchTarget + MouseRegion + Shortcuts present".
- **Files modified:** `test/components/scaffold_chart_scrubber_test.dart`
- **Commit:** `c3a128b`

## Authentication Gates

None.

## Known Stubs

None — every behavior in the plan's `<behavior>` block is fully implemented and widget-tested.

## Threat Flags

None — pure presentation-layer widget. No I/O, no network, no auth, no schema, no secrets. The `onPointSelected` callback forwards a consumer-owned `T` (or `null`) back to the consumer; no data crosses a trust boundary.

## Self-Check: PASSED

- [x] `lib/components/scaffold_chart_scrubber.dart` exists (348 lines)
- [x] `test/components/scaffold_chart_scrubber_test.dart` exists (390 lines)
- [x] Commit `2bc1473` found in `git log` (RED widget tests)
- [x] Commit `c3a128b` found in `git log` (ScaffoldChartScrubber GREEN)
- [x] All 408 tests pass (15 new + 393 pre-existing)
- [x] `dart analyze --fatal-infos` clean on both touched files
- [x] `grep -c "package:fl_chart" lib/components/scaffold_chart_scrubber.dart` returns 0 (D-02 gate)
- [x] All 9 plan verify greps pass (class, ScaffoldChart, FocusOutline, TouchTarget, LiveRegion, onPointerExit, arrowLeft, escape)
