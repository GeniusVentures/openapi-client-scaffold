---
phase: 08-supporting-atoms-table-cells-light-palette
plan: 04
subsystem: components
tags: [widgets, atoms, chip, chip-group, selection, wids-40]
requires:
  - lib/components/scaffold_pressable.dart
  - lib/components/scaffold_surface.dart
  - lib/components/scaffold_touch_target.dart
  - lib/components/scaffold_status_indicator.dart
  - lib/components/scaffold_disabled_overlay.dart
  - lib/theme/scaffold_palette.dart
  - lib/theme/scaffold_dimens.dart
  - lib/theme/scaffold_theme.dart
provides:
  - ScaffoldChip atom (pill pressable, optional icon/label/status slots)
  - ScaffoldChipGroup atom (Wrap layout + consumer-owned selection dispatch)
affects:
  - Unblocks "Tool Chips" consumer pattern
  - Unblocks "Filter Table → chip/group" consumer pattern
tech-stack:
  added: []
  patterns:
    - "Pill surface + pressable + touch-target (48px min via pressable, not padding arithmetic)"
    - "Selected state = 2px accent BORDER, fill unchanged (60/30/10 contract)"
    - "Typed slots joined by space2 separators (icon → label → status)"
    - "Consumer-owned selection truth + ValueChanged<Set<int>> callback out (D-02)"
    - "Constructor assert for a11y contract — icon-only requires semanticLabel (D-03)"
    - "Semantics(role: radioGroup|list) for selection-mode containers"
key-files:
  created:
    - lib/components/scaffold_chip.dart
    - lib/components/scaffold_chip_group.dart
    - test/components/scaffold_chip_test.dart
    - test/components/scaffold_chip_group_test.dart
    - example/lib/demos/chip_demo.dart
  modified: []
decisions:
  - "Selected chip uses 2px lightGreenPrimary BORDER (not fill change) — preserves 60/30/10"
  - "48px min hit area comes from ScaffoldPressable's internal ScaffoldTouchTarget — not padding arithmetic"
  - "ChipGroup holds NO selection truth — consumer supplies Set<int> and receives next via onSelectionChanged"
  - "Icon-only chips REQUIRE semanticLabel enforced via constructor assert (WCAG 4.1.2)"
  - "Multi-select Semantics uses SemanticsRole.list (Flutter SDK has no generic 'group' role); single-select uses SemanticsRole.radioGroup"
metrics:
  duration: "~10 minutes"
  completed: 2026-08-17
  tasks: 4
  files-created: 5
  files-modified: 0
  commits: 4
  tests-added: 18
  tests-passing: 18
---

# Phase 8 Plan 04: ScaffoldChip + ScaffoldChipGroup Summary

Pill-shaped pressable token atom and consumer-owned selection-management group layout, both shipped with widget tests across dark + light palettes and a demo file (registration deferred to plan 08-06).

## What Was Built

### ScaffoldChip (`lib/components/scaffold_chip.dart`)

- **Pill pressable atom** composing `ScaffoldSurface` (radiusPill=48, deepBlueCardColor fill, 8h×8v padding) + `ScaffoldPressable` (which internally supplies `ScaffoldTouchTarget` 48×48 hit area, hover/press state layers, focus outline, disabled overlay).
- **Selected state** = 2px `palette.lightGreenPrimary` BORDER on top of the unchanged `palette.deepBlueCardColor` fill — preserving the 60/30/10 contract (D-01).
- **Typed slots**: optional 16px leading `Icon`, `Text(label, labelMedium)`, trailing 8px `ScaffoldStatusIndicator` — joined by `dimens.space2` (4px) separators.
- **A11y (D-03)**: constructor `assert(label != null || semanticLabel != null)` enforces WCAG 4.1.2 for icon-only chips; `Semantics(selected:)` wraps the pressable (which adds `button: true`).
- No hardcoded colors or dims — all visual values resolve via `context.palette` / `context.dimens`.

### ScaffoldChipGroup (`lib/components/scaffold_chip_group.dart`)

- **Wrap layout** with `dimens.space8` (16px) spacing and `dimens.space4` (8px) runSpacing.
- **Consumer-owned selection** (D-02): takes `selected: Set<int>` and dispatches the next set via `onSelectionChanged`. Single-select mode replaces the set with the tapped index; multi-select toggles membership. Tapping an already-selected chip in single-select emits the same set (consumer decides whether to no-op).
- **Empty state**: renders `SizedBox.shrink()` when `chips.isEmpty`.
- **Semantics role**: `SemanticsRole.radioGroup` for single-select, `SemanticsRole.list` for multi-select (Flutter SDK lacks a generic `group` role; `list` is the closest container role).
- Per-index wrap: each consumer-supplied `ScaffoldChip` is re-created with `selected: selected.contains(i)` and a forwarding `onPressed` that calls `_handleChipTap(i)`; chip's slots (`label`/`icon`/`status`/`disabled`/`semanticLabel`) forward unchanged.

### Tests (`test/components/scaffold_chip_test.dart`, `scaffold_chip_group_test.dart`)

- 10 chip tests covering: default rendering (labelMedium + fill), selected border, tap-once callback, disabled overlay + tap-block, icon+label gap, icon+label+status gaps, icon-only assert, icon-only semantics label, button+selected semantics flags, lightPalette rendering.
- 8 chip-group tests covering: empty shrink, single-select replace, multi-select toggle, single re-tap emits same set, selected propagation to wrapped chips, Wrap spacing tokens, semantics roles (radioGroup vs list), lightPalette rendering.
- All 18 tests pass under `flutter test`.

### Demo (`example/lib/demos/chip_demo.dart`)

- 6 single-chip sections: Default, Selected, Disabled, Leading icon, Status, Icon-only.
- 3 group sections: Single-select (via `_SingleSelectGroup` StatefulWidget holding `Set<int>`), Multi-select (`_MultiSelectGroup`), Empty group.
- Imports direct component paths (not the barrel); NOT registered in `example/lib/main.dart` — plan 08-06 owns registration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Flutter SDK `SemanticsRole` enum mismatch**
- **Found during:** Task 3 (ScaffoldChipGroup implementation)
- **Issue:** The plan's literal text referenced `SemanticsRole.radiogroup` (lowercase 'g') and `SemanticsRole.group`. Neither exists in the pinned Flutter SDK (`thirdparty/flutter`). Compile error: `Member not found: 'radiogroup'` and `Member not found: 'group'`.
- **Fix:** Mapped the plan's intent onto the actual SDK enum. Single-select uses `SemanticsRole.radioGroup` (camelCase — exact match to the plan's intent). Multi-select uses `SemanticsRole.list` — the Flutter SDK exposes no generic "group" role; `list` is the closest container role that satisfies the "group of related controls" semantics contract.
- **Files modified:** `lib/components/scaffold_chip_group.dart`, `test/components/scaffold_chip_group_test.dart` (updated Test 17 expectations).
- **Commit:** 25d2814 (amended during task; deviation captured in the commit message body)

No other deviations. Plan executed as written for Tasks 1, 2, and 4.

## Auth Gates

None — fully autonomous local execution.

## Threat Register Compliance

- **T-08-04-03 (Information Disclosure / a11y spoofing) — MITIGATED:** D-03 constructor assert on `ScaffoldChip` enforces `semanticLabel` non-null whenever `label == null && icon != null`. Test 7 verifies `throwsAssertionError`; Test 8 verifies the label is registered on the semantics tree.
- **T-08-04-01 (Tampering — consumer-owned selection Set):** Accepted per plan. The group copies `selected` into a new `Set<int>` before mutation, so consumer state is never mutated in place.
- **T-08-04-02 (DoS — huge chips list):** Accepted per plan. `Wrap` is unbounded; virtualization deferred to consumers.
- **T-08-04-04 (Elevation of Privilege):** Accepted per plan. Both atoms are stateless render-only; hold no secrets or persistent state.

## Verification Results

```
flutter test test/components/scaffold_chip_test.dart test/components/scaffold_chip_group_test.dart
  → 18/18 tests passing

dart analyze --fatal-infos \
  lib/components/scaffold_chip.dart \
  lib/components/scaffold_chip_group.dart \
  test/components/scaffold_chip_test.dart \
  test/components/scaffold_chip_group_test.dart \
  example/lib/demos/chip_demo.dart
  → No issues found!

grep -nE "Colors\.(white|black|grey|blue|red)" lib/components/scaffold_chip*.dart
  → No matches

grep -nE "EdgeInsets\.(all|symmetric|only)\([0-9]" lib/components/scaffold_chip*.dart
  → No matches

grep -c "chip_demo" example/lib/main.dart
  → 0 (registration deferred to plan 08-06 as planned)
```

## Commits

| Hash | Type | Subject |
|------|------|---------|
| c17ee63 | test | add failing widget tests for ScaffoldChip + ScaffoldChipGroup |
| 445defa | feat | implement ScaffoldChip pill atom |
| 25d2814 | feat | implement ScaffoldChipGroup selection-management layout |
| f5b3420 | feat | author chip_demo.dart for ScaffoldChip + ScaffoldChipGroup |

## Self-Check: PASSED

- FOUND: lib/components/scaffold_chip.dart
- FOUND: lib/components/scaffold_chip_group.dart
- FOUND: test/components/scaffold_chip_test.dart
- FOUND: test/components/scaffold_chip_group_test.dart
- FOUND: example/lib/demos/chip_demo.dart
- FOUND: commit c17ee63 (Task 1 RED)
- FOUND: commit 445defa (Task 2 GREEN)
- FOUND: commit 25d2814 (Task 3 GREEN)
- FOUND: commit f5b3420 (Task 4 demo)
- VERIFIED: 18/18 plan-gate tests pass on the final tree
- VERIFIED: `dart analyze --fatal-infos` clean across all five files
- VERIFIED: No hardcoded colors or dims in either component file
- VERIFIED: `example/lib/main.dart` does NOT reference `chip_demo` (deferred to plan 08-06)
- VERIFIED: `lib/frontend_scaffold.dart` NOT modified (barrel export deferred to plan 08-06)
- VERIFIED: STATE.md / ROADMAP.md NOT modified (orchestrator owns those writes)
