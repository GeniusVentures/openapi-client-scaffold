---
phase: 06-core-ui-foundation
plan: "04"
subsystem: ui
tags: [flutter, widget-atoms, accessibility, template-generated, selection-indicator, image-placeholder, animated-display, drag-handle, resize-handle, numeric-input, drift-gate]

# Dependency graph
requires:
  - phase: 06-core-ui-foundation
    plan: "03"
    provides: ScaffoldSkeleton, ScaffoldDisabledOverlay, ScaffoldPressable, barrel convention
provides:
  - ScaffoldSelectionIndicator (radio/checkbox/toggle, template-generated, 3 files)
  - ScaffoldImagePlaceholder (loading/missing/empty/failed, template-generated, 4 files)
  - ScaffoldAnimatedDisplay (fade/pulse/scale/slide/rotate/shake/bounce, template-generated, 7 files)
  - ScaffoldDragHandle, ScaffoldResizeHandle, ScaffoldNumericInput (plain Dart)
affects:
  - 06-05 and later Wave 2 composites (compose these primitives)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Jinja2 StrictUndefined template -> per-variant generated Dart (drift-gated, 3 generators)
    - Semantics boolean flags (checked/toggled/mixed/inMutuallyExclusiveGroup/button) instead of roles
    - reducedMotion zero-duration FadeTransition fallback via AlwaysStoppedAnimation

key-files:
  created:
    - lib/components/scaffold_selection_indicator_{radio,checkbox,toggle}.dart (generated)
    - lib/components/scaffold_image_placeholder_{loading,missing,empty,failed}.dart (generated)
    - lib/components/scaffold_animated_display_{fade,pulse,scale,slide,rotate,shake,bounce}.dart (generated)
    - lib/components/scaffold_drag_handle.dart
    - lib/components/scaffold_resize_handle.dart
    - lib/components/scaffold_numeric_input.dart
    - templates/components/selection_indicator.dart.jinja2 + selection_indicator_vars.json
    - templates/components/image_placeholder.dart.jinja2 + image_placeholder_vars.json
    - templates/components/animated_display.dart.jinja2 + animated_display_vars.json
    - scripts/generate_selection_indicator.py
    - scripts/generate_image_placeholder.py
    - scripts/generate_animated_display.py
    - test/components/scaffold_selection_indicator_test.dart
    - test/components/scaffold_image_placeholder_test.dart
    - test/components/scaffold_animated_display_test.dart
    - test/components/scaffold_drag_handle_test.dart
    - test/components/scaffold_resize_handle_test.dart
    - test/components/scaffold_numeric_input_test.dart
  modified:
    - lib/frontend_scaffold.dart

key-decisions:
  - Selection/checkbox/switch semantics use boolean flags (checked/mixed/toggled/inMutuallyExclusiveGroup), not SemanticsRole — Flutter 3.41.9 removed the radio/checkbox/switch roles in favor of flags (matching framework Checkbox/Switch)
  - Drag/Resize/Numeric handles use plain Semantics labels (no role): the closest roles (dragHandle/spinButton) are marked "unimplemented" in the SDK's debug role checks and throw in debug/test mode
  - Image placeholder "loaded" state is not a generated variant — the caller renders child directly (no wrapper)

requirements-completed: [WIDG-13, WIDG-14, WIDG-16, WIDG-19, WIDG-20, WIDG-21]

# Metrics
duration: 13min
completed: 2026-08-13
status: complete
---

# Phase 6 Plan 4: Core UI Foundation Summary

**Shipped the second Wave 1 batch — 3 template-generated display atoms (SelectionIndicator, ImagePlaceholder, AnimatedDisplay → 14 per-variant files) and 3 plain Dart interaction primitives (DragHandle, ResizeHandle, NumericInput) — with a clean drift gate and full analyze/test coverage.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-08-13T19:26:12Z
- **Completed:** 2026-08-13T19:38:58Z
- **Tasks:** 3 (all complete)
- **Files created/modified:** 33

## Accomplishments

- Delivered 3 Jinja2 StrictUndefined templates (`selection_indicator.dart.jinja2`, `image_placeholder.dart.jinja2`, `animated_display.dart.jinja2`) with matching `_vars.json` fixtures and reproducible `scripts/generate_*.py` generators (driving `engine.py`). Each renders per-variant files with the source-schema + generator-version header; no generated file contains a cross-variant runtime enum/switch.
- `ScaffoldSelectionIndicator` → 3 generated files (Radio: 20px circle outline + 12px `lightGreenPrimary` dot; Checkbox: 20px rounded-rect with check/dash icon; Toggle: 40x24 pill with `AnimatedPositioned` thumb), each in a 48px `ScaffoldTouchTarget` with `checked`/`mixed`/`toggled` semantics and 0.4-opacity disabled dim.
- `ScaffoldImagePlaceholder` → 4 generated files (Loading → `ScaffoldSkeleton`; Missing → `Icons.image_not_supported` + surface; Empty → `Icons.photo_outlined`; Failed → `Icons.broken_image` in `statusError` + optional retry), each with consumer-overridable screen-reader label; loaded state renders child directly.
- `ScaffoldAnimatedDisplay` → 7 generated files (fade/pulse/scale/slide/rotate/shake/bounce), each a `SingleTickerProviderStateMixin` StatefulWidget reading `ScaffoldMotion.of(context).reducedMotion` and substituting a zero-duration fade under reduced motion; `trigger` change replays; `ExcludeSemantics` while animating.
- `ScaffoldDragHandle` (3-line grip, 48px TouchTarget, "Drag to reorder" label) and `ScaffoldResizeHandle` (`ResizeDirection` enum: horizontal/vertical/both, corner painter, "Drag to resize" label).
- `ScaffoldNumericInput` (decrement/value/increment with min/max/step/decimalPlaces bounds, FocusOutline, DisabledOverlay, LiveRegion value announcement, labeled buttons, error tint + border).
- Full gate green: `dart analyze --fatal-infos lib/ test/` clean, `flutter test` 124/124 passing, drift gate regenerates all 14 variants with zero diff, no hardcoded hex values.

## Task Commits

Each task committed atomically (TDD: RED test commit → GREEN implementation commit):

1. **Task 1: SelectionIndicator + ImagePlaceholder + AnimatedDisplay (3 templates → 14 files)** — `6aeca6c` (test) → `8a0db04` (feat)
2. **Task 2: ScaffoldDragHandle + ScaffoldResizeHandle** — `870d0c9` (test) → `53e66b4` (feat)
3. **Task 3: ScaffoldNumericInput** — `82c2095` (test) → `6a5ad99` (feat)

## Files Created/Modified

- `templates/components/{selection_indicator,image_placeholder,animated_display}.dart.jinja2` + 3 `_vars.json` — source of truth
- `scripts/generate_{selection_indicator,image_placeholder,animated_display}.py` — per-variant generators (drift-gated)
- `lib/components/scaffold_selection_indicator_{radio,checkbox,toggle}.dart` — 3 generated files
- `lib/components/scaffold_image_placeholder_{loading,missing,empty,failed}.dart` — 4 generated files
- `lib/components/scaffold_animated_display_{fade,pulse,scale,slide,rotate,shake,bounce}.dart` — 7 generated files
- `lib/components/scaffold_drag_handle.dart`, `scaffold_resize_handle.dart`, `scaffold_numeric_input.dart` — plain Dart atoms
- `lib/frontend_scaffold.dart` — 17 new barrel exports
- 6 test files under `test/components/`

## Decisions Made

- Selection indicator semantics use boolean flags (`checked`/`mixed`/`toggled`/`inMutuallyExclusiveGroup`) rather than a `SemanticsRole`, mirroring this SDK's own `Checkbox`/`Switch` widgets.
- Drag/resize/numeric handles use plain `Semantics` labels (no role). See Deviations for why the planned roles are unavailable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Flutter 3.41.9 redesigned `SemanticsRole` — `radio`/`checkbox`/`switch` roles removed**
- **Found during:** Task 1 (planning read-through + first analyze)
- **Issue:** The plan/UI-SPEC call for `SemanticsRole.radio`/`.checkbox`/`.switch`, but this Flutter SDK's redesigned `dart:ui` `SemanticsRole` enum dropped those values in favor of boolean semantics flags (the framework's own `Checkbox` uses `checked:`/`mixed:`, `Switch` uses `toggled:`).
- **Fix:** Selection indicators use `Semantics(checked:/mixed:/toggled:/inMutuallyExclusiveGroup:)` flags; no role.
- **Files modified:** `templates/components/selection_indicator.dart.jinja2` (+ its 3 generated files)

**2. [Rule 1 - Bug] `SemanticsRole.dragHandle`/`.spinButton` are "unimplemented" in debug role checks**
- **Found during:** Task 2 (first test run threw `Missing checks for role SemanticsRole.dragHandle`)
- **Issue:** `_DebugSemanticsRoleChecks` maps `dragHandle`/`spinButton`/`comboBox`/`tooltip`/`hotKey` to `_unimplemented`, which throws an assertion in debug/test mode (the plan's `moveHandle`/`adjustHandle`/`spinButton` roles are therefore unusable).
- **Fix:** DragHandle/ResizeHandle use a plain `Semantics(label:)`; NumericInput uses `ScaffoldLiveRegion` (value announcement) + `Semantics(button: true, label:)` buttons. Tests assert labels/values instead of roles.
- **Files modified:** `scaffold_drag_handle.dart`, `scaffold_resize_handle.dart`, `scaffold_numeric_input.dart`, 3 test files

**3. [Rule 1 - Bug] image_placeholder template emitted unused import/local**
- **Found during:** Task 1 `dart analyze --fatal-infos`
- **Issue:** `scaffold_palette.dart` was imported but never referenced by name (only `context.palette`), and `labelStyle` was declared for loading/failed where it is unused.
- **Fix:** Made each variant's build fully self-contained; dropped the unused palette import (only `scaffold_theme.dart` is needed for `context.palette`).
- **Files modified:** `templates/components/image_placeholder.dart.jinja2`

**4. [Rule 1 - Bug] image_placeholder loading test lacked a ScaffoldMotion ancestor**
- **Found during:** Task 1 (loading test crashed — `ScaffoldSkeleton` requires `ScaffoldMotion.of`)
- **Issue:** The loading placeholder renders `ScaffoldSkeleton`, which throws without a `ScaffoldMotion` ancestor.
- **Fix:** Wrapped the image_placeholder test harness in `ScaffoldMotion`.
- **Files modified:** `test/components/scaffold_image_placeholder_test.dart`

**Total deviations:** 4 auto-fixed (Rule 1 ×4)
**Impact on plan:** All fixes were API-adaptation/testability corrections required by the Flutter 3.41.9 SDK; no scope creep, no architectural changes, no package-manager installs (jinja2 was already provisioned in `documentation/.venv`, used as-is).

## Issues Encountered

None beyond the auto-fixes above. The `jinja2` Python package is not on the system `python3` PATH; it was already available in the project's `documentation/.venv` (`jinja2 3.1.6`), which was used to drive `engine.py` — no new package was installed.

## Threat Model

- **T-06-07 (DoS, AnimatedDisplay rapid trigger replay) — mitigated:** `_replay` guards via controller `reset()` before `forward()`/`repeat`; `dispose` cancels the controller.
- **T-06-08 (DoS, NumericInput bounds arithmetic) — mitigated:** `num` arithmetic is clamped via `_canIncrement`/`_canDecrement` before `onChanged` fires; no out-of-bounds callback.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Ready for 06-05 (Wave 2 composites). All Wave 1 single-dependency atoms are now in place with reproducible template drift gates. No blockers.

---
*Phase: 06-core-ui-foundation*
*Completed: 2026-08-13*

## Self-Check: PASSED

- All 32 created files + 1 modified file present on disk.
- All 6 task commits present in `git log` (6aeca6c, 8a0db04, 870d0c9, 53e66b4, 82c2095, 6a5ad99).
- `dart analyze --fatal-infos lib/ test/` → No issues found.
- `flutter test` → 124/124 passing (26 new tests).
- Drift gate: regenerate all 3 templates → `git diff --exit-code` → zero difference.
- Grep checks: selection indicators use checked/toggled/mixed; loading imports ScaffoldSkeleton; 7 animated files read reducedMotion; no cross-variant enum/switch; no hardcoded hex values; 17 barrel exports.
