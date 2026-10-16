---
phase: 15-midnight-preset
plan: 05
subsystem: example-app-and-brand-hygiene
tags: [example, preset-switch, brand-scan, templates, midnight]
requires:
  - "15-04 (midnightTheme(Brightness) full ThemeData)"
provides:
  - "Example app 'Midnight preset' switch: default or midnight, dark or light, composing with 'Theme overrides'"
  - "example/test/preset_switcher_test.dart: four-combination palette test plus the override case"
  - "tools/tests/test_no_brand_names.py: automated brand-name scan of lib/, example/, tokens/"
affects: [15-07]
key-files:
  created:
    - example/test/preset_switcher_test.dart
    - tools/tests/test_no_brand_names.py
  modified:
    - example/lib/main.dart
    - templates/components/card.dart.jinja2
    - templates/components/search_bar.dart.jinja2
    - templates/components/state.dart.jinja2
    - lib/components/scaffold_card.dart
    - lib/components/scaffold_search_bar.dart
    - lib/components/scaffold_state_view.dart
    - lib/components/media_card.dart
    - lib/utils/chart_geometry.dart
    - lib/utils/scaffold_chart_renderer.dart
key-decisions:
  - "The orange override is one private helper (_applyOverride) used by the default and midnight paths."
  - "With midnight and overrides both on, only the registered ScaffoldPalette is replaced; every other midnight extension is kept."
requirements-completed: [PRE-02, PRE-03]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 14000
  tasks: 3
  commits: 3
---

# Phase 15 Plan 05: Example preset switch and brand scan Summary

The example app can show default or midnight in both modes, and a pytest now enforces that lib/, example/ and tokens/ carry no brand names.

## Commits

| Task | SHA | Content |
|---|---|---|
| 1 (tracer) | df5194b | 'Midnight preset' switch after 'Light mode'; midnightTheme via deep import; shared override helper; widget test |
| 2 | 7cdfa3e | Header wording changed in the three composite templates and regenerated (one line in each generated file) |
| 3 | 739556e | Comment-only rewording in media_card, chart_geometry, scaffold_chart_renderer; test_no_brand_names |

## Verification

- preset_switcher_test: 2 tests pass (four combinations in one, override case in the other). Example `dart analyze --fatal-infos` clean.
- Root: flutter test 1225 passed, pytest 182 passed (178 plus 4 new), ruff clean, `dart analyze --fatal-infos` clean.
- Drift check after task 2 and after the final commit: regenerating leaves lib/ clean. The task 2 commit changes exactly three lib files, one line each.
- Task 3 changes no non-comment line in lib/ (checked with a diff filter).
- Scan negative check: adding "Genius" to a comment in lib/theme/presets/midnight_theme.dart made the scan fail with file and line; reverted.
- lib/frontend_scaffold.dart and example/test/capture_images_test.dart are unchanged since 0fe6608.

## Deviations from Plan

None - plan executed as written. The scan test was written after the comment edits rather than before, so the failing-first step was shown by the temporary injection instead.

## Known Stubs

None.

## Self-Check: PASSED

df5194b, 7cdfa3e and 739556e exist on develop; all created and modified files exist.
