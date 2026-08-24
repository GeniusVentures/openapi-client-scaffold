---
phase: 08-supporting-atoms-table-cells-light-palette
plan: 06
subsystem: barrel-export + demo-registration
tags: [phase-8, wave-2, exports, demos, final-gate]
requirements: [WIDG-40, WIDG-41, WIDG-42]
dependency_graph:
  requires: [08-01, 08-02, 08-03, 08-04, 08-05]
  provides:
    - "Public barrel surface for chip, chip_group, composer, disclosure, trace_list"
    - "Example-app registrations for the four new demos"
  affects:
    - lib/frontend_scaffold.dart
    - example/lib/main.dart
tech_stack:
  added: []
  patterns:
    - "Alphabetical export insertion in components/ block"
    - "_DemoTile registration pattern for example app"
key_files:
  created: []
  modified:
    - lib/frontend_scaffold.dart
    - example/lib/main.dart
decisions:
  - "Single-plan ownership of barrel + main.dart to avoid same-wave merge conflicts (per plan objective)"
  - "Demos appended after Wallet connect sheet — keeps Phase 8 additions grouped at the tail of the demo list"
metrics:
  duration: "~3 minutes"
  completed_date: 2026-08-17
  tasks: 3
  commits: 3
---

# Phase 08 Plan 06: Barrel Exports + Demo Registrations + Final Gate Summary

**One-liner:** Wired the five new Phase 8 atoms into the public barrel export and registered the four new demos in the example app, then ran the full v1.1 shipping gate (269 tests green, analyze clean, no hardcoded colors/dims).

## Objective

Close out Phase 8 by wiring the new atoms into the public surface: append the five barrel exports to `lib/frontend_scaffold.dart` in alphabetical position and register the four new demos in `example/lib/main.dart`, then run the full test + analyze gate to prove the v1.1 shipping bar holds across the package.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Append five new exports to lib/frontend_scaffold.dart in alphabetical position | c41fa3a | lib/frontend_scaffold.dart |
| 2 | Register the four new demos in example/lib/main.dart | c65ba47 | example/lib/main.dart |
| 3 | Run the full Phase 8 verification gate | (this commit) | (gate only — no file changes) |

## Verification Results

### Task 1 — Barrel exports
- 5 new export lines present in alphabetical position within the existing `components/` block:
  - `scaffold_chip.dart`, `scaffold_chip_group.dart` — between `scaffold_card_state.dart` and `scaffold_color_swatch.dart`
  - `scaffold_composer.dart` — between `scaffold_color_swatch.dart` and `scaffold_dashed_border.dart`
  - `scaffold_disclosure.dart` — between `scaffold_disabled_overlay.dart` and `scaffold_drag_handle.dart`
  - `scaffold_trace_list.dart` — between `scaffold_touch_target.dart` and `wallet_connect_sheet.dart`
- `dart analyze --fatal-infos lib/frontend_scaffold.dart` → "No issues found!"
- Export count grep: 5 matches confirmed
- Library doc header and existing exports untouched

### Task 2 — Demo registrations
- 4 new imports appended after `kitchen_sink_demo.dart`:
  `chip_demo.dart`, `composer_demo.dart`, `disclosure_demo.dart`, `trace_list_demo.dart`
- 4 new `_DemoTile` entries appended after the Wallet connect sheet tile, in this order:
  - **Chip / ChipGroup** → `ScaffoldChipDemo()` — "Pill pressable atom + selection group"
  - **Composer** → `ScaffoldComposerDemo()` — "Text composition area with badge/action slots"
  - **Disclosure** → `ScaffoldDisclosureDemo()` — "Expand/collapse row with AnimatedSize + reduced-motion"
  - **Trace list** → `ScaffoldTraceListDemo()` — "Ordered disclosure items + optional group header"
- `dart analyze --fatal-infos example/lib/main.dart` → "No issues found!"
- Demo-class grep: 4 matches confirmed

### Task 3 — Final Phase 8 gate (all four checks pass)

1. **`flutter test` (full suite)** — **269/269 passed**. Suite includes the new tests added by 08-01..08-05 (badge light palette, chip, chip group, composer, disclosure, trace list).
2. **`dart analyze --fatal-infos` (package root)** — "No issues found!" across `lib/`, `test/`, `example/`.
3. **`grep -n "Colors.white" lib/components/scaffold_badge.dart`** — no matches (WIDG-46 remediation holds).
4. **`example/` package analyze** — after `flutter pub get`, `dart analyze --fatal-infos` → "No issues found!"

Additional plan-level checks (also green):
- No `Colors.white|black|grey` in any of `scaffold_chip.dart`, `scaffold_chip_group.dart`, `scaffold_composer.dart`, `scaffold_disclosure.dart`, `scaffold_trace_list.dart`, `scaffold_badge.dart`.
- No hardcoded `EdgeInsets.all|symmetric|only(<numeric>)` in any of the five new atom files (all spacing flows through `ScaffoldDimens`).

## Deviations from Plan

None — plan executed exactly as written. Both target files matched the documented anchors, so the edits landed without remediation.

## Authentication Gates

None.

## Known Stubs

None — no placeholder data flows into the new exports or demo tiles. Demo screens consume placeholder strings internally (acceptable per threat model T-08-06-02), but the barrel and registration changes themselves contain no stubs.

## Threat Flags

None. The plan's `<threat_model>` register already covers the barrel widening (T-08-06-01, accept) and demo placeholder data (T-08-06-02, accept). No new trust boundaries introduced.

## Self-Check: PASSED

- `lib/frontend_scaffold.dart` — modified, contains all 5 new export lines (verified via grep + analyzer)
- `example/lib/main.dart` — modified, contains 4 new imports + 4 new `_DemoTile` entries (verified via grep + analyzer)
- Commit `c41fa3a` — present (`git log --oneline` confirms)
- Commit `c65ba47` — present (`git log --oneline` confirms)
- Full test suite green: 269/269
- Full analyzer clean (package + example)
