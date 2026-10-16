---
phase: 15-midnight-preset
plan: 02
subsystem: theme-presets
tags: [preset, codegen, contrast, midnight]
requires:
  - "15-01 (theme_presets driver, Midnight palette, midnightTheme)"
provides:
  - "Midnight.darkColorRoles, lightColorRoles, dimens, darkShadows, lightShadows, motion, typography"
  - "MidnightColors class with Midnight.darkColors and lightColors (18 fields)"
  - "midnightExtensions registers palette, dimens, colorRoles, shadows, motion, typography per mode"
  - "palette_contrast_test covers midnight dark and light on six surfaces, with key coverage tied to tokens/midnight.json"
affects: [15-03, 15-04]
key-files:
  modified:
    - tokens/midnight.json
    - tools/scaffold_codegen/generators/theme_presets.py
    - lib/theme/presets/midnight_tokens.dart
    - lib/theme/presets/midnight_theme.dart
    - test/theme/palette_contrast_test.dart
    - test/theme/midnight_token_map_test.dart
    - test/theme/midnight_theme_test.dart
key-decisions:
  - "Generated preset regions are not run through dart format, because the codegen output is the canonical text and --check would report drift."
  - "Midnight _Theme entries in the contrast test are non-const because they read fields of const instances."
requirements-completed: [PRE-01, PRE-02, A11Y-03]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 26000
  tasks: 3
  commits: 3
---

# Phase 15 Plan 02: Midnight groups and contrast Summary

Midnight now has every scaffold extension group generated from tokens/midnight.json, plus a MidnightColors class for the source colors with no scaffold field. The Phase 14 contrast test runs over midnight dark and light and passes without any value changes.

## Commits

| Task | SHA | Content |
|---|---|---|
| 1 (tracer) | 110fe30 | colorRoles tokens, regions and instances; contrast test with `checksFallback` and `extraSurfaces`; registration test |
| 2 | fcb7c1a | dimens, shadows, motion, typography, preset.colors; MidnightColors; surfaceBase and surfaceSheet as extra surfaces; preset color classification |
| 3 | ace884a | source-map rows for roles (8) and MidnightColors (18), dimens, shadows, motion, typography; context registration test |

## Verification

- theme_presets and theme_defaults `--check` exit 0. pytest 145 passed. ruff clean. `dart analyze --fatal-infos` clean.
- flutter test: 1044 passed (full run).
- Defaults diff against 0fe6608 (design_tokens.json, barrel, scaffold_*.dart) is empty.
- Generated marker count in midnight_tokens.dart is 13; `appBarHeight: 68.0` appears once.
- Dummy key in scaffold.colorRoles.dark made the coverage test fail; reverted.
- No AA failures on any of the six midnight surfaces, so no token values were adjusted.

## Deviations from Plan

**1. [Minor] `extraSurfaces: {}` passed explicitly in Task 1**
- The analyzer flagged an unused optional parameter after Task 1, so the midnight entries set it to an empty map until Task 2 filled it. Commit 110fe30 was amended once for an unnecessary `const`.

**2. [Minor] Own mistake during the dummy-key check**
- Restoring tokens/midnight.json with `git checkout` dropped the uncommitted colorRoles edit. It was restored from a backup copy before any commit; nothing was lost.

Otherwise the plan ran as written.

## Known Stubs

None.

## Self-Check: PASSED

110fe30, fcb7c1a and ace884a exist on develop; all modified files exist.
