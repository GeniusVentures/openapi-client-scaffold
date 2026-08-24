---
phase: 06-core-ui-foundation
plan: "01"
subsystem: ui
tags: [flutter, theme-extension, motion, accessibility, focus, touch-target, widget-atoms]

# Dependency graph
requires:
  - phase: 05-scaffold-submodule-consolidation
    provides: ScaffoldPalette/ScaffoldDimens ThemeExtension pattern, scaffoldThemeExtensions list, context.palette/context.dimens, barrel export convention
provides:
  - 7 new ScaffoldPalette color tokens + 6 new ScaffoldDimens tokens (full copyWith/lerp)
  - ScaffoldMotion InheritedWidget (reduced-motion) + ScaffoldMotionDurations/ScaffoldMotionCurves
  - ScaffoldSurface, ScaffoldTouchTarget, ScaffoldFocusOutline zero-dependency atoms
affects:
  - 06-02 and all later Wave 0-3 atoms (consume the tokens, motion, and composition primitives)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ThemeExtension copyWith/lerp token extension
    - InheritedWidget reduced-motion propagation via of(context)
    - context.palette/context.dimens token resolution with ?? fallback
    - Focus ring visibility gated on FocusHighlightMode.traditional OR accessibleNavigation

key-files:
  created:
    - lib/components/scaffold_motion.dart
    - lib/components/scaffold_surface.dart
    - lib/components/scaffold_touch_target.dart
    - lib/components/scaffold_focus_outline.dart
    - test/components/scaffold_motion_test.dart
    - test/components/scaffold_surface_test.dart
    - test/components/scaffold_touch_target_test.dart
    - test/components/scaffold_focus_outline_test.dart
    - test/components/scaffold_palette_token_test.dart
    - test/components/scaffold_dimens_token_test.dart
    - example/lib/demos/tracer_demo.dart
  modified:
    - lib/theme/scaffold_palette.dart
    - lib/theme/scaffold_dimens.dart
    - lib/frontend_scaffold.dart
    - example/lib/main.dart

key-decisions:
  - ScaffoldMotion.of(context) is non-nullable and throws FlutterError when no ancestor exists
  - "Keyboard focus active" maps to FocusManager.instance.highlightMode == FocusHighlightMode.traditional (keyboardFocus getter does not exist in Flutter 3.41)
  - Focus ring painter is public (ScaffoldFocusRingPainter) so tests can assert token color/width
  - ScaffoldFocusOutline listens to highlightMode changes to repaint the ring on keyboard focus

requirements-completed: [WIDG-01, WIDG-02, WIDG-03, WIDG-04]

coverage:
  - id: D1
    description: "Theme token expansion — 7 ScaffoldPalette color tokens + 6 ScaffoldDimens tokens with copyWith/lerp"
    verification:
      - kind: unit
        ref: "test/components/scaffold_palette_token_test.dart#ScaffoldPalette Wave 0 tokens"
        status: pass
      - kind: unit
        ref: "test/components/scaffold_dimens_token_test.dart#ScaffoldDimens Wave 0 tokens"
        status: pass
    human_judgment: false
  - id: D2
    description: "ScaffoldMotion InheritedWidget + ScaffoldMotionDurations/ScaffoldMotionCurves constants"
    requirement: WIDG-01
    verification:
      - kind: unit
        ref: "test/components/scaffold_motion_test.dart#ScaffoldMotion"
        status: pass
    human_judgment: false
  - id: D3
    description: "ScaffoldSurface — background/border/shape/elevation container"
    requirement: WIDG-02
    verification:
      - kind: unit
        ref: "test/components/scaffold_surface_test.dart#ScaffoldSurface"
        status: pass
    human_judgment: false
  - id: D4
    description: "ScaffoldTouchTarget — 48x48 min hit area + Semantics container"
    requirement: WIDG-03
    verification:
      - kind: unit
        ref: "test/components/scaffold_touch_target_test.dart#ScaffoldTouchTarget"
        status: pass
    human_judgment: false
  - id: D5
    description: "ScaffoldFocusOutline — accessibility-aware focus ring"
    requirement: WIDG-04
    verification:
      - kind: unit
        ref: "test/components/scaffold_focus_outline_test.dart#ScaffoldFocusOutline"
        status: pass
    human_judgment: false
  - id: D6
    description: "TracerDemo — end-to-end Motion→Surface→TouchTarget→FocusOutline composition in the example app"
    verification:
      - kind: other
        ref: "dart analyze example/lib (compiles clean); flutter run example not executed (no device)"
        status: unknown
    human_judgment: true
    rationale: "The demo compiles and each atom is unit-tested, but the plan's success criterion requires a visual flutter run on the example app to confirm no red-screen at runtime — not automatable in this environment."

# Metrics
duration: 16min
completed: 2026-08-13
status: complete
---

# Phase 6 Plan 1: Core UI Foundation Summary

**Expanded theme tokens (7 palette + 6 dimens) and shipped ScaffoldMotion + Surface/TouchTarget/FocusOutline zero-dependency foundation atoms with reduced-motion support and an accessibility-aware focus ring.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-08-13T18:09:53Z
- **Completed:** 2026-08-13T18:25:34Z
- **Tasks:** 3 (all complete)
- **Files modified/created:** 15

## Accomplishments

- Expanded `ScaffoldPalette` to 22 color tokens and `ScaffoldDimens` to 21 dimension tokens, each with full `copyWith`/`lerp` ThemeExtension coverage — the token contract every later atom consumes.
- Shipped `ScaffoldMotion` (InheritedWidget) with `ScaffoldMotionDurations`/`ScaffoldMotionCurves`, establishing the reduced-motion and animation-constant propagation mechanism.
- Delivered three zero-dependency atoms (`ScaffoldSurface`, `ScaffoldTouchTarget`, `ScaffoldFocusOutline`) plus a `TracerDemo` proving the composition slice end-to-end.
- Full gate green: `dart analyze --fatal-infos lib/ test/` clean, `flutter test` 48/48 passing, `dart analyze example/lib` clean.

## Task Commits

Each task was committed atomically (TDD: RED test commit → GREEN implementation commit):

1. **Task 1: Expand theme tokens (D-03)** — `e464bc1` (test) → `07503e1` (feat)
2. **Task 2: ScaffoldMotion (D-01)** — `e1cb8fd` (test) → `705f1b8` (feat)
3. **Task 3: Surface + TouchTarget + FocusOutline + tracer demo** — `c7c4600` (test) → `70ba67a` (feat)

## Files Created/Modified

- `lib/theme/scaffold_palette.dart` — +7 color tokens (focusRingColor, skeletonBaseColor, skeletonShimmerColor, disabledOverlayColor, dragFeedbackBackground, dropZoneHighlight, dropZoneRejected)
- `lib/theme/scaffold_dimens.dart` — +6 tokens (focusRingWidth, skeletonCornerRadius, disabledOverlayOpacity, dragHandleSize, minTouchTarget, touchTargetPadding)
- `lib/components/scaffold_motion.dart` — ScaffoldMotion InheritedWidget + durations/curves
- `lib/components/scaffold_surface.dart` — ScaffoldSurface
- `lib/components/scaffold_touch_target.dart` — ScaffoldTouchTarget
- `lib/components/scaffold_focus_outline.dart` — ScaffoldFocusOutline + ScaffoldFocusRingPainter
- `lib/frontend_scaffold.dart` — barrel exports for the 4 new component files
- `example/lib/demos/tracer_demo.dart` + `example/lib/main.dart` — registered tracer demo
- 6 test files under `test/components/`

## Decisions Made

- `ScaffoldMotion.of(context)` is non-nullable and throws `FlutterError` on a missing ancestor (reconciled against the plan's contradictory `ScaffoldMotionData?` prose; the must_haves and tests require the non-null read).
- "Keyboard focus active" is implemented as `FocusManager.instance.highlightMode == FocusHighlightMode.traditional`, since `FocusManager.instance.keyboardFocus` (referenced by the plan/UI-SPEC) does not exist in Flutter 3.41.9.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `ringColor`/`ringWidth` referenced without `widget.` prefix**
- **Found during:** Task 3 (ScaffoldFocusOutline)
- **Issue:** Build method referenced the constructor fields as bare identifiers, which do not resolve inside the State class.
- **Fix:** Prefixed with `widget.` (`widget.ringColor`, `widget.ringWidth`).
- **Files modified:** `lib/components/scaffold_focus_outline.dart`

**2. [Rule 1 - Bug] Plan referenced non-existent `FocusManager.instance.keyboardFocus`**
- **Found during:** Task 3
- **Issue:** The plan/UI-SPEC condition "keyboard focus active" used `FocusManager.instance.keyboardFocus`, which does not exist in Flutter 3.41.9 (compile error).
- **Fix:** Implemented as `FocusManager.instance.highlightMode == FocusHighlightMode.traditional` (the canonical equivalent).
- **Files modified:** `lib/components/scaffold_focus_outline.dart`, `test/components/scaffold_focus_outline_test.dart`

**3. [Rule 1 - Bug] Focus ring did not appear on keyboard focus**
- **Found during:** Task 3
- **Issue:** `showRing` depends on highlight mode, but the widget only rebuilt on focus-node changes; a keyboard-focus transition (touch→traditional) left the ring hidden.
- **Fix:** Subscribed to `FocusManager.addHighlightModeListener` and rebuild on mode change.
- **Files modified:** `lib/components/scaffold_focus_outline.dart`

**4. [Rule 1 - Bug] Detached focus node never receives focus**
- **Found during:** Task 3 test setup
- **Issue:** A standalone `FocusNode` does not gain `hasFocus` via `requestFocus()` unless attached to a `Focus` widget (verified empirically).
- **Fix:** Attached the node via a `Focus` widget wrapping the test child, matching real usage where the focusable child owns the node.
- **Files modified:** `test/components/scaffold_focus_outline_test.dart`

**5. [Rule 1 - Bug] Test import/API corrections**
- **Found during:** Task 3
- **Issue:** `LogicalKeyboardKey` needs `flutter/services.dart`; `SemanticsFlag.isContainer` does not exist.
- **Fix:** Added the services import; asserted the public `Semantics.container` field directly instead of the nonexistent flag.
- **Files modified:** `test/components/scaffold_focus_outline_test.dart`, `test/components/scaffold_touch_target_test.dart`

**6. [Rule 2 - Missing testability] Public focus-ring painter**
- **Found during:** Task 3
- **Issue:** Plan listed `_FocusRingPainter` (private), but tests 11/12 require inspecting the painter's color/width; a private class in `lib/` is invisible to `test/`.
- **Fix:** Named the painter public (`ScaffoldFocusRingPainter`) with public `color`/`strokeWidth`/`borderRadius` fields.
- **Files modified:** `lib/components/scaffold_focus_outline.dart`

**7. [Rule 2 - Missing critical functionality] Registered tracer demo in example menu**
- **Found during:** Task 3
- **Issue:** The plan's `files_modified` listed only `example/lib/demos/tracer_demo.dart`; without a `main.dart` entry the demo is unreachable and cannot satisfy "tracer demo loads in the example app".
- **Fix:** Added the import and a `_DemoTile` entry in `example/lib/main.dart`.
- **Files modified:** `example/lib/main.dart`

**Total deviations:** 7 auto-fixed (Rule 1 ×5, Rule 2 ×2)
**Impact on plan:** All auto-fixes were necessary for correctness or testability; no scope creep, no architectural changes, no package-manager installs.

## Issues Encountered

None beyond the auto-fixes above. The tracer feedback gate (Task 1 verify re-run end-to-end) passed: 17/17 token tests green and theme files analyze-clean before expanding to Tasks 2-3.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Ready for 06-02 (next Wave 0 dependency-layer plan). The token contract, reduced-motion mechanism, and the three composition primitives (Surface/TouchTarget/FocusOutline) are in place for every subsequent atom. No blockers.

---
*Phase: 06-core-ui-foundation*
*Completed: 2026-08-13*

## Self-Check: PASSED

- All 13 created files present on disk.
- All 6 task commits present in `git log` (e464bc1, 07503e1, e1cb8fd, 705f1b8, c7c4600, 70ba67a).
- `dart analyze --fatal-infos lib/ test/` → No issues found.
- `flutter test` → 48/48 passing.
- `dart analyze --fatal-infos example/lib/` → No issues found.
