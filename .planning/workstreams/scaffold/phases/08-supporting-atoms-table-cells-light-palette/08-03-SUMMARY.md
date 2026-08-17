---
phase: 08-supporting-atoms-table-cells-light-palette
plan: 03
subsystem: components
tags: [atoms, disclosure, trace-list, expand-collapse, WIDG-41, D-04, D-05]
dependency_graph:
  requires:
    - lib/components/scaffold_pressable.dart
    - lib/components/scaffold_motion.dart
    - lib/components/scaffold_status_indicator.dart
    - lib/theme/scaffold_theme.dart
    - lib/theme/scaffold_palette.dart
    - lib/theme/scaffold_dimens.dart
  provides:
    - lib/components/scaffold_disclosure.dart (ScaffoldDisclosure)
    - lib/components/scaffold_trace_list.dart (ScaffoldTraceList, TraceItem)
    - example/lib/demos/disclosure_demo.dart (ScaffoldDisclosureDemo)
    - example/lib/demos/trace_list_demo.dart (ScaffoldTraceListDemo)
  affects:
    - plan 08-06 (owns barrel export of the two new atoms + demo registration)
tech_stack:
  added: []
  patterns:
    - Flutter controlled/uncontrolled idiom (expanded + onExpandedChanged vs initiallyExpanded)
    - AnimatedSize + AnimatedRotation gated by ScaffoldMotion.reducedMotion
    - Leading-status composition outside the disclosure title (keeps atom API minimal)
key_files:
  created:
    - lib/components/scaffold_disclosure.dart
    - lib/components/scaffold_trace_list.dart
    - test/components/scaffold_disclosure_test.dart
    - test/components/scaffold_trace_list_test.dart
    - example/lib/demos/disclosure_demo.dart
    - example/lib/demos/trace_list_demo.dart
  modified: []
decisions:
  - "D-04 (locked): Disclosure = header row + AnimatedSize body, medium duration, reduced-motion gated"
  - "D-05 (locked): Controlled (expanded + onExpandedChanged) + uncontrolled (initiallyExpanded) — Flutter idiom"
  - "Status slot composition: ScaffoldStatusIndicator rendered OUTSIDE ScaffoldDisclosure.title via a Row wrapper — keeps the atom's `title: String` API minimal (UI-SPEC 'Status slot' row)"
metrics:
  duration_minutes: ~15
  completed_date: 2026-08-17
  tasks_completed: 4
  tasks_total: 4
  files_created: 6
  files_modified: 0
  tests_added: 15
---

# Phase 08 Plan 03: ScaffoldDisclosure + ScaffoldTraceList Summary

**One-liner:** Shipped `ScaffoldDisclosure` (controlled/uncontrolled expand/collapse row with reduced-motion-gated `AnimatedSize` body and rotating chevron) and `ScaffoldTraceList` (ordered `List<TraceItem>` of disclosure rows with optional `groupHeader` and leading status slot), each with full widget-test coverage across both palettes and a demo file — unlocking "Thinking traces" and any consumer needing an accessible expand/collapse pattern without forking `ExpansionTile`.

## Objective

Implement D-04 / D-05 from `08-CONTEXT.md` and WIDG-41: two new generic atoms in `lib/components/`, two test files, two demo files. Barrel export and demo registration deferred to plan 08-06 to avoid same-wave file conflicts.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Failing widget tests (RED) | `c319738` | `test/components/scaffold_disclosure_test.dart`, `test/components/scaffold_trace_list_test.dart` |
| 2 | Implement `ScaffoldDisclosure` | `419212a` | `lib/components/scaffold_disclosure.dart`, `test/components/scaffold_disclosure_test.dart` (key-fix) |
| 3 | Implement `ScaffoldTraceList` | `f08f17e` | `lib/components/scaffold_trace_list.dart` |
| 4 | Author demos | `325c1ea` | `example/lib/demos/disclosure_demo.dart`, `example/lib/demos/trace_list_demo.dart` |

## Verification Results

- `flutter test test/components/scaffold_disclosure_test.dart test/components/scaffold_trace_list_test.dart` → **15/15 passed**.
- `dart analyze --fatal-infos` on all six new files → **clean**.
- No hardcoded colors or dims in either component file (grep audit clean).
- `example/lib/main.dart` has zero references to the new demos (registration deferred to plan 08-06 as required).
- `lib/frontend_scaffold.dart` untouched (barrel export deferred to plan 08-06).

## Acceptance Criteria — All Met

**Task 1:**
- Both test files exist; disclosure has 9 `testWidgets` (≥ 8 required); trace-list has 6 `testWidgets` (≥ 5 required); initial run exited non-zero (RED confirmed — `ScaffoldDisclosure` / `ScaffoldTraceList` / `TraceItem` constructors missing).

**Task 2:**
- `lib/components/scaffold_disclosure.dart` exists; `ScaffoldMotion.of(context).reducedMotion` consumed (≥ 1); `AnimatedSize` (4 occurrences); `AnimatedRotation` (2); `ScaffoldPressable` (3); zero hardcoded `Colors.white|black|grey|blue|red`; zero hardcoded `EdgeInsets.(all|symmetric|only)([0-9]`; 9/9 disclosure tests pass; analyze clean.

**Task 3:**
- `lib/components/scaffold_trace_list.dart` exists; `class TraceItem` (1); `class ScaffoldTraceList` (1); `ScaffoldDisclosure(` (1); `SizedBox.shrink` (1); zero hardcoded colors; 6/6 trace-list tests pass; analyze clean.

**Task 4:**
- Both demo files exist; `ScaffoldDisclosureDemo` (1); `ScaffoldTraceListDemo` (1); `ScaffoldDisclosure(` in disclosure_demo (4 ≥ 4); `ScaffoldTraceList(` in trace_list_demo (3 ≥ 3); analyze clean; `example/lib/main.dart` has zero references to the new demos.

## Contract Highlights (per UI-SPEC + D-04/D-05)

- **Body indent:** `EdgeInsets.only(left: dimens.space6, top: dimens.space4)` — 12px left, 8px top (verified by Test 8).
- **Chevron:** `Icons.chevron_right` 24px, `AnimatedRotation` 0.0 → 0.25 turns (90°) with `ScaffoldMotionDurations.short` + `ScaffoldMotionCurves.standard`.
- **Chevron tint:** `palette.textSecondary` default; `palette.lightGreenPrimary` only when expanded AND `highlightWhenExpanded: true` (UI-SPEC "Accent reserved for" rule #3).
- **Body animation:** `AnimatedSize` with `ScaffoldMotionDurations.medium`; collapses to `Duration.zero` under reduced-motion (verified by reduced-motion test).
- **Semantics:** `Semantics(expanded: bool, label: title)` announced by screen readers (verified by Test 7).
- **Empty state:** `ScaffoldTraceList(items: [])` renders `SizedBox.shrink()` with zero size (verified by Test 9).
- **Status slot:** `ScaffoldStatusIndicator(status: item.status!, dotSize: 8)` rendered as a leading slot OUTSIDE the disclosure title via a `Row` wrapper — `ScaffoldDisclosure` API stays minimal (per plan task 3 action).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added per-case Keys in Test 6 to force new state across `pumpWidget` calls**
- **Found during:** Task 2 (GREEN run of `scaffold_disclosure_test.dart`)
- **Issue:** Test 6 pumps three different `ScaffoldDisclosure` configurations sequentially in a single `testWidgets` block. Without keys, the second `pumpWidget` call reused the existing `_ScaffoldDisclosureState` (same widget type + same position), so `_internalExpanded` from Case A (false) persisted into Case B, making the chevron-tint assertion fail with `textSecondary` instead of the expected `lightGreenPrimary`.
- **Fix:** Added `Key('caseA')` / `Key('caseB')` / `Key('caseC')` to force new state per case. This is a test-code fix — the production code was correct.
- **Files modified:** `test/components/scaffold_disclosure_test.dart`
- **Commit:** `419212a` (folded into the Task 2 commit since it was discovered during the GREEN run)

No other deviations. The plan executed exactly as written otherwise.

## Auth Gates

None.

## TDD Gate Compliance

Plan-level TDD gate sequence verified:

1. **RED commit** — `c319738` `test(08-03): add failing widget tests for ScaffoldDisclosure + ScaffoldTraceList` — initial `flutter test` run reported `Error: Couldn't find constructor 'ScaffoldDisclosure'` / `'ScaffoldTraceList'` / `'TraceItem'` (exit non-zero). No tests passed unexpectedly during RED.
2. **GREEN commits** — `419212a` (ScaffoldDisclosure) and `f08f17e` (ScaffoldTraceList) — both `feat(08-03):` commits land after the RED commit. All 15 tests flip from RED to GREEN.
3. **REFACTOR** — none required; initial implementation matched the locked UI-SPEC contract.

## Self-Check: PASSED

- `lib/components/scaffold_disclosure.dart` — FOUND
- `lib/components/scaffold_trace_list.dart` — FOUND
- `test/components/scaffold_disclosure_test.dart` — FOUND
- `test/components/scaffold_trace_list_test.dart` — FOUND
- `example/lib/demos/disclosure_demo.dart` — FOUND
- `example/lib/demos/trace_list_demo.dart` — FOUND
- Commit `c319738` — FOUND
- Commit `419212a` — FOUND
- Commit `f08f17e` — FOUND
- Commit `325c1ea` — FOUND
- `lib/frontend_scaffold.dart` — NOT modified (verified via `git diff 2c7f9c7..HEAD -- lib/frontend_scaffold.dart` returning empty)
- `example/lib/main.dart` — NOT modified (verified via `git diff 2c7f9c7..HEAD -- example/lib/main.dart` returning empty)
- `.planning/STATE.md` / `ROADMAP.md` — NOT modified (orchestrator owns those writes)

## Notes for Plan 08-06 (Barrel + Demo Registration)

- Append `export 'components/scaffold_disclosure.dart';` between `scaffold_disabled_overlay.dart` and `scaffold_drag_handle.dart` (alphabetical).
- Append `export 'components/scaffold_trace_list.dart';` between `scaffold_touch_target.dart` and `wallet_connect_sheet.dart` (alphabetical).
- Register `ScaffoldDisclosureDemo` and `ScaffoldTraceListDemo` in `example/lib/main.dart`'s demo list (mirror `MediaCardDemo` registration).
