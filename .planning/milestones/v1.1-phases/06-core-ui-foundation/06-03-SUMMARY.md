---
phase: 06-core-ui-foundation
plan: "03"
subsystem: ui
tags: [flutter, widget-atoms, accessibility, animation, interaction, badge, skeleton, pressable, status]

# Dependency graph
requires:
  - phase: 06-core-ui-foundation
    plan: "01"
    provides: ScaffoldMotion, ScaffoldTouchTarget, ScaffoldFocusOutline, palette/dimens tokens
provides:
  - ScaffoldSkeleton, ScaffoldDisabledOverlay
  - ScaffoldBadge, ScaffoldStatusIndicator
  - ScaffoldPressable
affects:
  - 06-04 and later Wave 1/2 atoms (compose these single-dependency primitives)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - SingleTickerProviderStateMixin shimmer sweep (LinearGradient) with reduced-motion static pulse fallback
    - M3 state layers (textPrimary at 8%/12% opacity) via AnimatedOpacity over a TouchTarget
    - Semantics(button: true) + Focus.onKeyEvent Enter/Space activation (Flutter 3.41 has no SemanticsRole.button)
    - Focus.includeSemantics inserts a focusable Semantics node (test targets the button node explicitly)

key-files:
  created:
    - lib/components/scaffold_skeleton.dart
    - lib/components/scaffold_disabled_overlay.dart
    - lib/components/scaffold_badge.dart
    - lib/components/scaffold_status_indicator.dart
    - lib/components/scaffold_pressable.dart
    - test/components/scaffold_skeleton_test.dart
    - test/components/scaffold_disabled_overlay_test.dart
    - test/components/scaffold_badge_test.dart
    - test/components/scaffold_status_indicator_test.dart
    - test/components/scaffold_pressable_test.dart
  modified:
    - lib/frontend_scaffold.dart

key-decisions:
  - ScaffoldDisabledOverlay uses the ColorSwatch-established dim pattern (`disabledOverlayColor.withValues(alpha: disabledOverlayOpacity)` ColoredBox over the full child + IgnorePointer) rather than the plan's child-opacity prose — matches the truth statement and the shipped 06-02 atom
  - ScaffoldPressable button semantics use `Semantics(button: true, enabled: ...)` (Flutter 3.41.9 removed `SemanticsRole.button` in favor of ARIA roles)
  - ScaffoldSkeleton uses one `repeat(reverse: true)` controller for both the shimmer sweep and the reduced-motion pulse (0.6 -> 1.0)

requirements-completed: [WIDG-11, WIDG-12, WIDG-15, WIDG-17, WIDG-18]

# Metrics
duration: 12min
completed: 2026-08-13
status: complete
---

# Phase 6 Plan 3: Core UI Foundation Summary

**Shipped the first five Wave 1 single-dependency atoms — ScaffoldSkeleton (animated shimmer placeholder), ScaffoldDisabledOverlay (interaction blocker), ScaffoldBadge (dot/count/icon/text indicator), ScaffoldStatusIndicator (5-variant color dot), and ScaffoldPressable (M3 state-layer interaction wrapper) — each composing exactly one Wave 0 atom, with full a11y and a clean analyze/test gate.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-08-13T13:56:59-05:00
- **Completed:** 2026-08-13T14:08:56-05:00
- **Tasks:** 3 (all complete)
- **Files created/modified:** 11

## Accomplishments

- Shipped 5 plain Dart widget atoms (not template-generated — the 4 template candidates and 3 composites are later waves):
  - `ScaffoldSkeleton` — `SingleTickerProviderStateMixin` shimmer sweep (`LinearGradient` of `skeletonBaseColor`/`skeletonShimmerColor`/`skeletonBaseColor`) with a reduced-motion static pulse (opacity 0.6→1.0) when `ScaffoldMotion.reducedMotion` is true; `ExcludeSemantics`; width/height/borderRadius override defaults.
  - `ScaffoldDisabledOverlay` — `IgnorePointer` + `disabledOverlayColor` dim at `disabledOverlayOpacity` with optional `Semantics(tooltip: reason)`; enabled state returns the child with zero-opacity cost.
  - `ScaffoldBadge` — `BadgeVariant` (dot/count/icon/text), count truncating to "99+", count=0/empty-text → `SizedBox.shrink`, `Semantics(role: status)` with "{count} items" label, 48x48 touch target, disabled 0.4 opacity, no positioning (pure composability).
  - `ScaffoldStatusIndicator` — `StatusVariant` (success/warning/error/info/neutral) mapped to palette tokens, configurable dot size, `Semantics(role: status)` with configured label.
  - `ScaffoldPressable` — composes `ScaffoldTouchTarget` + `ScaffoldFocusOutline` + M3 state layers (textPrimary 8% hover / 12% pressed) + `Focus.onKeyEvent` Enter/Space activation + `ScaffoldDisabledOverlay` when disabled; `Semantics(button: true)`.
- Full gate green: `dart analyze --fatal-infos lib/ test/` clean; `flutter test` 98/98 passing (27 new tests).

## Task Commits

Each task committed atomically (TDD: RED test commit → GREEN implementation commit):

1. **Task 1: ScaffoldSkeleton + ScaffoldDisabledOverlay** — `e67d066` (test) → `d26fe0b` (feat)
2. **Task 2: ScaffoldBadge** — `bef8a23` (test) → `26c1c78` (feat)
3. **Task 3: ScaffoldStatusIndicator + ScaffoldPressable** — `fafa862` (test) → `4e66650` (feat)

## Files Created/Modified

- `lib/components/scaffold_skeleton.dart` — animated shimmer placeholder (reduced-motion pulse fallback)
- `lib/components/scaffold_disabled_overlay.dart` — IgnorePointer dim overlay + tooltip semantics
- `lib/components/scaffold_badge.dart` — BadgeVariant enum + dot/count/icon/text indicator
- `lib/components/scaffold_status_indicator.dart` — StatusVariant enum + 5-color status dot
- `lib/components/scaffold_pressable.dart` — TouchTarget + FocusOutline + state layers + keyboard activation
- `lib/frontend_scaffold.dart` — barrel exports for all 5 new atoms
- 5 test files under `test/components/`

## Decisions Made

- `ScaffoldDisabledOverlay` dim is a single `ColoredBox(disabledOverlayColor.withValues(alpha: disabledOverlayOpacity))` over the full child, matching the truth statement and the already-shipped `ScaffoldColorSwatch` disabled pattern (the plan's prose suggested a child-opacity variant).
- `ScaffoldPressable` expresses button semantics via `Semantics(button: true)` because Flutter 3.41.9 removed `SemanticsRole.button` (the enum is now ARIA-aligned); the `Focus` widget's own `includeSemantics: true` focusable node coexists.
- `ScaffoldSkeleton` drives both shimmer and pulse from one `repeat(reverse: true)` controller; the shimmer sweeps back-and-forth and the pulse oscillates 0.6↔1.0.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `SemanticsRole.button` does not exist in Flutter 3.41.9**
- **Found during:** Task 3 (ScaffoldPressable)
- **Issue:** The plan/UI-SPEC specify `Semantics(role: SemanticsRole.button)`, but Flutter 3.41.9's `dart:ui` `SemanticsRole` enum was reworked to ARIA roles and has no `button` member.
- **Fix:** Use `Semantics(button: true, enabled: ...)`, the canonical Flutter button flag (`SemanticsProperties.button`).
- **Files modified:** `lib/components/scaffold_pressable.dart`, `test/components/scaffold_pressable_test.dart`

**2. [Rule 1 - Bug] Token/role types not re-exported by the convenience imports**
- **Found during:** Tasks 2 and 3
- **Issue:** `SemanticsRole` lives in `dart:ui` and is not re-exported by `material.dart`; `ScaffoldPalette`/`ScaffoldDimens` are imported (not re-exported) by `scaffold_theme.dart`, so naming them in method signatures failed to compile.
- **Fix:** Added explicit `import 'dart:ui' show SemanticsRole;` and `import 'package:frontend_scaffold/theme/scaffold_{palette,dimens}.dart';` where those types are named.
- **Files modified:** `lib/components/scaffold_badge.dart`, `lib/components/scaffold_status_indicator.dart`, `lib/components/scaffold_pressable.dart`, and matching test files.

**3. [Rule 1 - Bug] Pressable button-semantics test grabbed the wrong node**
- **Found during:** Task 3
- **Issue:** `Focus` (default `includeSemantics: true`) inserts a focusable `Semantics` node above the button `Semantics`, so `find.descendant(...).first` returned that node (`button == null`).
- **Fix:** Target the button node explicitly via `firstWhere((s) => s.properties.button == true)`; also silenced the disabled-tap `warnIfMissed` warning.
- **Files modified:** `test/components/scaffold_pressable_test.dart`

**Total deviations:** 3 auto-fixed (all Rule 1). No scope creep, no architectural changes, no package installs.

## Threat Model

- **T-06-05 (DoS, Skeleton AnimationController leak) — mitigated:** controller is disposed in `dispose()`, `SingleTickerProviderStateMixin` guarantees a single ticker, `repeat(reverse: true)` stops on disposal. Tests pump-and-dispose without a leak.
- **T-06-06 (DoS, Pressable callback after disposal) — mitigated:** `onPressed`/`onLongPress`/`onHoverChanged` fire only from live gesture/key/hover handlers that cannot run after disposal; the internally-created `FocusNode` is disposed in `dispose()`.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Ready for 06-04 (remaining Wave 1 atoms). The interaction/feedback/animation/affordance patterns are now established and available for Wave 2 multi-dependency composites. No blockers.

---

*Phase: 06-core-ui-foundation*
*Completed: 2026-08-13*

## Self-Check: PASSED

- All 11 created/modified files present on disk.
- All 6 task commits present in `git log` (e67d066, d26fe0b, bef8a23, 26c1c78, fafa862, 4e66650).
- `dart analyze --fatal-infos lib/ test/` → No issues found.
- `flutter test` → 98/98 passing.
- Barrel exports all 5 atoms (grep confirmed).
