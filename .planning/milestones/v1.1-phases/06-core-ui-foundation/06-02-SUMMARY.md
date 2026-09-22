---
phase: 06-core-ui-foundation
plan: "02"
subsystem: ui
tags: [flutter, widget-atoms, accessibility, responsive, template-generated, color-swatch, formatted-value, drift-gate]

# Dependency graph
requires:
  - phase: 06-core-ui-foundation
    plan: "01"
    provides: ScaffoldPalette/ScaffoldDimens tokens, ScaffoldMotion, ScaffoldTouchTarget, barrel convention
provides:
  - ScaffoldLiveRegion, ScaffoldOverflowFade, ScaffoldScrollEdgeIndicator
  - ScaffoldResponsiveVisibility (breakpoint-aware show/hide/replace)
  - ScaffoldFormattedValue (template-generated, 6 per-variant files) + ScaffoldColorSwatch
affects:
  - 06-03 and later Wave 0-3 atoms (compose these primitives)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Jinja2 StrictUndefined template -> per-variant generated Dart (drift-gated)
    - Semantics(liveRegion) announcement via ScaffoldLiveRegion wrapper
    - dstOut ShaderMask edge-fade gradient (opaque edges / transparent center)
    - MediaQuery-driven breakpoint show/hide with ComparisonOperator

key-files:
  created:
    - lib/components/scaffold_live_region.dart
    - lib/components/scaffold_overflow_fade.dart
    - lib/components/scaffold_scroll_edge_indicator.dart
    - lib/components/scaffold_responsive_visibility.dart
    - lib/components/scaffold_color_swatch.dart
    - lib/components/scaffold_formatted_value_{number,money,percentage,date,time,duration}.dart
    - templates/components/formatted_value.dart.jinja2
    - templates/components/formatted_value_vars.json
    - scripts/generate_formatted_value.py
    - test/components/scaffold_live_region_test.dart
    - test/components/scaffold_overflow_fade_test.dart
    - test/components/scaffold_scroll_edge_indicator_test.dart
    - test/components/scaffold_responsive_visibility_test.dart
    - test/components/scaffold_formatted_value_test.dart
    - test/components/scaffold_color_swatch_test.dart
  modified:
    - lib/frontend_scaffold.dart

key-decisions:
  - ScaffoldFormattedValue is rendered once per variant via scripts/generate_formatted_value.py (imports engine.py public API), overriding variant + widget_class_name — no runtime enum/switch spans variants (per STATE.md template boundary)
  - ScaffoldOverflowFade uses BlendMode.dstOut with opaque-at-edges / transparent-at-center gradient so content fades at the edges (not the center)
  - ScaffoldColorSwatch composes dimens.minTouchTarget ConstrainedBox (not ScaffoldTouchTarget) for the 48px hit area
  - Generated files carry a bare `library;` directive (matching card.dart.jinja2), not `library frontend_scaffold;` which would collide with the barrel

requirements-completed: [WIDG-05, WIDG-06, WIDG-07, WIDG-08, WIDG-09, WIDG-10]

# Metrics
duration: 14min
completed: 2026-08-13
status: complete
---

# Phase 6 Plan 2: Core UI Foundation Summary

**Shipped the six remaining Wave 0 zero-dependency atoms — LiveRegion, OverflowFade, ScrollEdgeIndicator, ResponsiveVisibility, FormattedValue (template-generated, 6 variants), and ColorSwatch — completing the foundation layer with a clean drift gate and full analyze/test coverage.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-08-13T18:37:15Z
- **Completed:** 2026-08-13T18:51:16Z
- **Tasks:** 3 (all complete)
- **Files created/modified:** 21

## Accomplishments

- Shipped 5 plain Dart widget atoms: `ScaffoldLiveRegion` (Semantics liveRegion announcement), `ScaffoldOverflowFade` (dstOut ShaderMask edge fade with `FadeDirection`), `ScaffoldScrollEdgeIndicator` (1px edge hairlines driven by a `ScrollController`), `ScaffoldResponsiveVisibility` (breakpoint-aware show/hide/replace via `ComparisonOperator`), and `ScaffoldColorSwatch` (selectable color dots in 48px touch targets with selection ring + disabled dim).
- Delivered `ScaffoldFormattedValue` as a Jinja2-template-generated atom: `formatted_value.dart.jinja2` + `formatted_value_vars.json` + `scripts/generate_formatted_value.py` (drives `engine.py` StrictUndefined) emit the 6 per-variant files (`Number`/`Money`/`Percentage`/`Date`/`Time`/`Duration`). Each wraps output in `ScaffoldLiveRegion`, uses `textTheme.bodyLarge`, `maxLines: 1` + ellipsis, and renders `nullPlaceholder` (`'--'`) on null. No runtime enum/switch spans variants.
- Full gate green: `dart analyze --fatal-infos lib/ test/` clean, `flutter test` 71/71 passing, `dart analyze example/lib` clean, and the drift gate regenerates all 6 variants with zero diff.

## Task Commits

Each task committed atomically (TDD: RED test commit → GREEN implementation commit):

1. **Task 1: LiveRegion + OverflowFade + ScrollEdgeIndicator** — `fd08262` (test) → `605ea55` (feat)
2. **Task 2: ScaffoldResponsiveVisibility** — `e721b21` (test) → `aadff8a` (feat)
3. **Task 3: FormattedValue (template-generated) + ColorSwatch** — `be46c78` (test) → `5175983` (feat)

## Files Created/Modified

- `lib/components/scaffold_live_region.dart` — Semantics(liveRegion) wrapper
- `lib/components/scaffold_overflow_fade.dart` — FadeDirection enum + ShaderMask edge fade (public `gradientFor` for testability)
- `lib/components/scaffold_scroll_edge_indicator.dart` — ScrollController-driven edge hairlines
- `lib/components/scaffold_responsive_visibility.dart` — ComparisonOperator + breakpoint show/hide/replace
- `lib/components/scaffold_color_swatch.dart` — selectable dots + ring + disabled dim
- `lib/components/scaffold_formatted_value_{number,money,percentage,date,time,duration}.dart` — 6 generated variant files (drift-gated)
- `templates/components/formatted_value.dart.jinja2` + `formatted_value_vars.json` — source of truth
- `scripts/generate_formatted_value.py` — per-variant generator (drives engine.py)
- `lib/frontend_scaffold.dart` — barrel exports for all 8 new component files
- 6 test files under `test/components/`

## Decisions Made

- ScaffoldOverflowFade's gradient is opaque at the edges / transparent in the center under `BlendMode.dstOut` (so content fades at the edges). The plan's prose "transparent stops at the edges" would have faded the center instead.
- The FormattedValue drift gate is reproducible via a committed `scripts/generate_formatted_value.py` (engine.py's CLI cannot override `variant` per render), so regeneration + diff is a one-liner for CI.
- `ScaffoldScrollEdgeIndicator` guards `position.hasContentDimensions` before reading `extentBefore/extentAfter` — the controller can be attached but not yet laid out during first build.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Semantics label/liveRegion are packed into SemanticsProperties**
- **Found during:** Task 1 (ScaffoldLiveRegion)
- **Issue:** Flutter 3.41's `Semantics` widget stores `label`/`value`/`liveRegion` on `SemanticsProperties`; there are no direct `semantics.label`/`semantics.liveRegion` getters.
- **Fix:** Tests read `semantics.properties.label` / `semantics.properties.liveRegion`.
- **Files modified:** `test/components/scaffold_live_region_test.dart`

**2. [Rule 1 - Bug] ScrollEdgeIndicator crashed on first build**
- **Found during:** Task 1
- **Issue:** `position.extentBefore/After` reads null `min/maxScrollExtent` when the controller is attached but not yet laid out (first build), throwing a null-check error.
- **Fix:** Guard on `position.hasContentDimensions` before reading extents.
- **Files modified:** `lib/components/scaffold_scroll_edge_indicator.dart`

**3. [Rule 1 - Bug] ResponsiveVisibility tests omitted the operator + used widget identity**
- **Found during:** Task 2
- **Issue:** The hideAt test helper did not pass `operator: lessThanOrEqual`, and `find.byWidget(const SizedBox.shrink())` does not match by identity.
- **Fix:** Added `operator` to the test helper; asserted the hidden SizedBox width/height == 0 instead.
- **Files modified:** `test/components/scaffold_responsive_visibility_test.dart`

**4. [Rule 1 - Bug] ColorSwatch disabled test over-counted IgnorePointer**
- **Found during:** Task 3
- **Issue:** `SingleChildScrollView` contributes its own internal `IgnorePointer(ignoring: false)`, so `find.byType(IgnorePointer)` found 3, not 2.
- **Fix:** Filter to `IgnorePointer.ignoring == true` before counting.
- **Files modified:** `test/components/scaffold_color_swatch_test.dart`

**5. [Rule 2 - Missing critical functionality] Added reproducible generator script**
- **Found during:** Task 3
- **Issue:** The plan requires regenerating/diffing "each variant", but `engine.py`'s CLI has no per-render `variant` override — only the representative `number` variant could be CLI-rendered.
- **Fix:** Added `scripts/generate_formatted_value.py` (imports `engine.py` `create_environment`/`render_template`) that renders all 6 variants; drift gate = regenerate + `git diff --exit-code`.
- **Files modified:** `scripts/generate_formatted_value.py` (new)

**6. [Rule 1 - Bug] Plan's "library frontend_scaffold;" directive would collide with the barrel**
- **Found during:** Task 1 (planning read-through)
- **Issue:** The barrel already declares `library frontend_scaffold;`; adding the same named library directive to each atom would be a duplicate-library-name error.
- **Fix:** Plain Dart atoms use no `library` directive (matching `scaffold_surface.dart`); generated files use a bare `library;` (matching `card.dart.jinja2`).
- **Files modified:** all new atom files

**Total deviations:** 6 auto-fixed (Rule 1 ×5, Rule 2 ×1)
**Impact on plan:** All fixes were correctness/testability necessary; no scope creep, no architectural changes, no package-manager installs (jinja2 was already provisioned in the project's `documentation/.venv`, used as-is).

## Issues Encountered

None beyond the auto-fixes above. The `jinja2` Python package was not on the system `python3` PATH; it was already available in the project's `documentation/.venv` (`jinja2 3.1.6`), which was used to drive `engine.py` — no new package was installed.

## Threat Model

- **T-06-03 (DoS, FormattedValue dynamic cast) — mitigated:** formatting guards null before casting; null (the only invalid value reachable under static typing) renders `nullPlaceholder`.
- **T-06-04 (Info disclosure, LiveRegion label) — accepted:** Semantics labels are by-design user-visible for screen readers; no secrets in atom labels.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Ready for 06-03 (next Wave 0 dependency-layer plan). All 28-atom foundation primitives for Wave 0 are now in place with a reproducible template drift gate. No blockers.

---
*Phase: 06-core-ui-foundation*
*Completed: 2026-08-13*

## Self-Check: PASSED

- All 20 created files + 1 modified file present on disk.
- All 6 task commits present in `git log` (fd08262, 605ea55, e721b21, aadff8a, be46c78, 5175983).
- `dart analyze --fatal-infos lib/ test/` → No issues found.
- `flutter test` → 71/71 passing.
- `dart analyze example/lib` → No issues found.
- Drift gate: `scripts/generate_formatted_value.py` regeneration → `git diff --exit-code` → zero difference.
