---
phase: 06-core-ui-foundation
fixed_at: 2026-08-14T21:49:23Z
review_path: .planning/workstreams/scaffold/phases/06-core-ui-foundation/06-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 06-core-ui-foundation: Code Review Fix Report

**Fixed at:** 2026-08-14T21:49:23Z
**Source review:** 06-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (CR-01, WR-01 .. WR-07; 13 Info findings out of scope)
- Fixed: 8
- Skipped: 0

## Fixed Issues

### CR-01: `ScaffoldMotion.of` throws with no ancestor, crashing the library's own composites

**Files modified:** `lib/components/scaffold_motion.dart`, `test/components/scaffold_motion_test.dart`
**Commit:** 5695355
**Applied fix:** `ScaffoldMotion.of` now falls back to
`const ScaffoldMotion(reducedMotion: false, child: SizedBox.shrink())` instead of
throwing, mirroring the `context.palette`/`context.dimens` `??` default pattern.
The old "throws FlutterError without an ancestor" test was replaced with a
fallback assertion (`reducedMotion` is false).

### WR-01: `ScaffoldTouchTarget` unconditionally inflates every child by 24px

**Files modified:** `lib/components/scaffold_touch_target.dart`
**Commit:** af54b9a
**Applied fix:** Dropped the unconditional `Padding(all: touchTargetPadding)`;
the minimum is now enforced by `ConstrainedBox(minWidth/minHeight)` alone, so
children that already meet the minimum keep their intrinsic size.

### WR-02: `ScaffoldBadge` renders every variant in a fixed 48x48 box

**Files modified:** `lib/components/scaffold_badge.dart`, `test/components/scaffold_badge_test.dart`
**Commit:** 32af136
**Applied fix:** Removed the `SizedBox(minTouchTarget)` wrapper so each variant
renders at its intrinsic size (dot 8px, count pill min 20px, icon 24px, text
pill). The "hit-tests at a 48x48 touch target" test was replaced with an
intrinsic-size assertion (dot is 8x8).

### WR-03: `ScaffoldSearchBar._handleQueryChanged` emits on a closed cubit

**Files modified:** `templates/components/search_bar.dart.jinja2`, `lib/components/scaffold_search_bar.dart`
**Commit:** 25d8e42
**Applied fix:** The post-`await` catch block is now guarded with
`if (mounted && !cubit.isClosed)` before calling `cubit.failSearch(...)`.
Fixed in the source template and regenerated (drift gate clean).

### WR-04: Composites create their Cubit inside `build`, making params non-reactive and the cubit un-drivable

**Files modified:** `templates/components/card.dart.jinja2`, `templates/components/state.dart.jinja2`, `lib/components/scaffold_card.dart`, `lib/components/scaffold_state_view.dart`
**Commit:** 829eee8
**Applied fix:** `ScaffoldCard` and `ScaffoldStateView` are now StatefulWidgets
that (1) accept an optional parent-owned `cubit` (used via `BlocProvider.value`,
so parents can `context.read<...>()` and drive `showLoading()`/`showError(...)`
etc.), and (2) own an internal cubit created in `initState` (not `build`) that
is re-seeded in `didUpdateWidget` when `variant`/`state`/`instanceId` change.
Fixed in the source templates and regenerated.

### WR-05: Templates hardcode import filenames while parameterizing class names

**Files modified:** `templates/components/card.dart.jinja2`, `templates/components/card_cubit.dart.jinja2`, `templates/components/state.dart.jinja2`, `templates/components/state_cubit.dart.jinja2`, `templates/components/search_bar.dart.jinja2`, `templates/components/search_bar_cubit.dart.jinja2`, `templates/components/card_vars.json`, `templates/components/state_vars.json`, `templates/components/search_bar_vars.json`
**Commit:** c7375fb
**Applied fix:** Added a `file_stem` fixture variable to each `_vars.json` and
replaced the hardcoded `import 'scaffold_*_cubit/state.dart'` literals with
`import '{{ file_stem }}_cubit.dart'` / `import '{{ file_stem }}_state.dart'`.
Verified by rendering with a non-`Scaffold*` name (produces correct imports);
regeneration of the default fixtures is byte-identical (drift gate clean).

### WR-06: `ScaffoldNumericInput` focus state is dead and buttons are not keyboard-accessible

**Files modified:** `lib/components/scaffold_numeric_input.dart`
**Commit:** 80bc01a (focus node + keyboard buttons), e18fcf1 (spinButton semantics)
**Applied fix:** Wired a real `FocusNode` through a `Focus` wrapper into
`ScaffoldFocusOutline`; wrapped the +/- buttons in `Focus` with Enter/Space
`onKeyEvent` handling; added `Semantics(textField: true, value: ...,
increasedValue: ..., decreasedValue: ..., onIncrease: ..., onDecrease: ...)`.
Note: `SemanticsRole.spinButton` is marked `_unimplemented` in this Flutter
version (3.41.9) and throws a debug assertion, so the spin-button semantics are
expressed via the supported `textField` + value + increase/decrease fields and
`SemanticsAction.increase`/`decrease` callbacks instead.

### WR-07: `ScaffoldPressable._enabled` requires `onPressed`, silently disabling long-press-only and drag sources

**Files modified:** `lib/components/scaffold_pressable.dart`, `lib/components/scaffold_draggable.dart`
**Commit:** ead68b6
**Applied fix:** Split the `_enabled` gate to
`!disabled && (onPressed != null || onLongPress != null)`, and changed the
keyboard handler to `onPressed?.call()` (no forced unwrap). `ScaffoldDraggable`
now wraps its `LongPressDraggable` in `ScaffoldTouchTarget` + explicit
`Semantics(button: true, enabled: true)` instead of a `ScaffoldPressable` with
null handlers that announced "disabled".

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-08-14T21:49:23Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
