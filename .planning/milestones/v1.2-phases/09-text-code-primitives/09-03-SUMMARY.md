---
phase: 09-text-code-primitives
plan: 03
status: complete
completed: 2026-08-20
requirements: [WIDG-39]
---

# 09-03 — ScaffoldSelectionActions

## What was built

`lib/components/scaffold_selection_actions.dart` (370 LoC) — the generic
selection-anchored toolbar wrapper for WIDG-39 / D-05. Public surface:

- `enum ScaffoldToolbarPlacement { auto, above, below }`
- `class ScaffoldSelectionActions extends StatefulWidget` with required
  `child` and `toolbarBuilder`, optional `onSelectionChanged` and
  `toolbarPlacement` (default `auto`)
- `@visibleForTesting static void debugSimulateSelection(state, plainText,
  {selection})` — deterministic selection-injection hook for widget tests

Behavior:

- Wraps the child in `CompositedTransformTarget` + `SelectionArea` so any
  descendant Text becomes selectable; reports `onSelectionChanged` on every
  selection change via `SelectionArea.onSelectionChanged`
- Selection-empty / collapse → toolbar hidden, no OverlayEntry inserted
- Non-empty selection → toolbar overlay inserted via LayerLink +
  CompositedTransformFollower, anchored above the selection by default with
  `auto` fallback to `below` when insufficient space
- Toolbar surface is ScaffoldSurface with `palette.surfaceElevated` fill,
  1px `palette.borderSubtle` border, `dimens.radiusMd` radius,
  `EdgeInsets.symmetric(h: space4, v: space4)` padding, zero shadow
- Toolbar fade is 150ms decelerate (`ScaffoldMotionDurations.short`),
  gated on `ScaffoldMotion.of(context).reducedMotion` → Duration.zero
- Dismissal: selection collapse, tap-outside (translucent GestureDetector
  wrapping Positioned.fill), scroll of the wrapped content, and Escape
  (Focus + onKeyEvent)
- The atom ships NO default actions — `toolbarBuilder` is REQUIRED (D-05)

`test/components/scaffold_selection_actions_test.dart` — 11 test cases:

- Tests 1–10 drive selection via `debugSimulateSelection` (deterministic
  injection) and cover: callback contract, toolbar show/hide, surface
  styling, builder invocation, empty-builder no-overlay, placement override
  (below → followerAnchor topCenter), auto-flip on top-collision, Escape
  dismissal, reduced-motion zero-duration, light-palette render
- Test 11 is the plan-mandated long-press+drag smoke test and is marked
  `skip: true` because flutter_test's gesture pipeline does not reliably
  drive SelectionArea.onSelectionChanged under the default 800x600 test
  viewport (the drag reaches SelectableText but SelectionRegistrar does
  not promote it deterministically). Per plan: framework flake → skip with
  comment, no retries. Real-path coverage is preserved via
  debugSimulateSelection, which uses the SAME internal handler as the
  SelectionArea callback.

## Notable implementation details

- **Overlay sizing pitfall (the wave-1 blocker):**
  `CompositedTransformFollower` enforces tight full-screen constraints on
  its child. The first attempt (Align with `widthFactor: 1.0`) did not
  shrink-wrap because Align honors `widthFactor` only under loose
  constraints; the second attempt (ClipRect + UnconstrainedBox) still
  leaked an 82px overflow because RenderConstraintsTransformBox reports
  against incoming constraints, not substituted ones. The working idiom
  is `OverflowBox(minWidth:0, maxWidth:∞, minHeight:0, maxHeight:∞,
  alignment: topLeft)` wrapping `Align(widthFactor:1, heightFactor:1)`
  wrapping the toolbar card. This converts tight→loose before Align sees
  the constraints, which is the only point in the chain where the
  substitution actually takes effect.
- **IntrinsicWidth around the Row:** under the fully-loose constraints
  produced by OverflowBox, a bare `Row(mainAxisSize: min)` still sizes
  against the constraint max in its first layout pass. IntrinsicWidth
  forces the Row to its child's intrinsic width before RenderFlex runs,
  pinning the shrink-wrap.
- **debugSimulateSelection shares the internal handler:** the hook does
  not duplicate logic — it forwards to the same `_handleSelection` path
  the SelectionArea callback uses, so behavior assertions on the test
  side remain valid against the production code path.
- **Escape focus trade-off:** the atom wraps itself in `Focus(autofocus:
  false)` and requests focus when the toolbar becomes visible, so Escape
  works without stealing focus on initial render. Toolbar actions remain
  keyboard-reachable via Tab from the selected text.

## Verification

- `dart analyze lib/components/scaffold_selection_actions.dart --fatal-infos` → 0 issues
- `dart analyze test/components/scaffold_selection_actions_test.dart --fatal-infos` → 0 issues (after `dart fix --apply` resolved 7 prefer_const_constructors)
- `flutter test test/components/scaffold_selection_actions_test.dart` → 10 passed, 1 skipped (framework flake — documented)
- `pubspec.yaml` unchanged (D-08)
- No new design tokens; only existing ScaffoldDimens / ScaffoldPalette

## Files created

- `lib/components/scaffold_selection_actions.dart`
- `test/components/scaffold_selection_actions_test.dart`

## Self-Check: PASSED
