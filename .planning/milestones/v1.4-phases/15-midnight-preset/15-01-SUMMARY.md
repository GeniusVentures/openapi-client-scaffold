---
phase: 15-midnight-preset
plan: 01
subsystem: theme-presets
tags: [preset, codegen, palette, midnight]
requires:
  - "0fe6608 (phase 14 head)"
provides:
  - "theme_defaults.render_regions and write_rendered (shared region rendering)"
  - "tokens/midnight.json with scaffold.palette dark and light"
  - "scaffold_codegen.generators.theme_presets driver (--check, no token-path option)"
  - "lib/theme/presets/midnight_tokens.dart (Midnight.darkPalette, Midnight.lightPalette)"
  - "lib/theme/presets/midnight_theme.dart (midnightTheme, midnightExtensions)"
  - "CI drift line and palette source-map test"
affects: [15-02, 15-03, 15-04]
key-files:
  created:
    - tokens/midnight.json
    - tools/scaffold_codegen/generators/theme_presets.py
    - lib/theme/presets/midnight_tokens.dart
    - lib/theme/presets/midnight_theme.dart
    - test/theme/midnight_theme_test.dart
    - test/theme/midnight_token_map_test.dart
    - tools/tests/test_theme_presets.py
  modified:
    - tools/scaffold_codegen/generators/theme_defaults.py
    - tools/scaffold_codegen/generators/__init__.py
    - tools/scaffold_codegen/__init__.py
    - .github/workflows/ci.yaml
key-decisions:
  - "Marker text takes a {source} placeholder so one splice serves both token files."
  - "Library doc comment on midnight_theme.dart uses a `library;` directive to avoid a dangling doc comment."
requirements-completed: []
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 14000
  tasks: 2
  commits: 3
---

# Phase 15 Plan 01: Midnight palette tracer Summary

The midnight palette (dark and light) flows from tokens/midnight.json through the existing codegen into generated Dart, and `midnightTheme(Brightness)` returns a ThemeData carrying it. Defaults and the barrel are untouched.

## Commits

| Name | SHA | Touches |
|---|---|---|
| REFACTOR | b1e979e | theme_defaults.py only (render_regions, write_rendered, `{source}` marker) |
| TRACER | e252e13 | token file, theme_presets driver, two preset Dart files, theme test, package init constants |
| DRIFT | cc4841b | test_theme_presets.py, ci.yaml drift line, midnight_token_map_test.dart |

## Verification

- After REFACTOR: theme_defaults --check exit 0, pytest 134 passed, ruff clean, `lib/` unchanged.
- Final: pytest 145 passed (11 new in test_theme_presets.py), flutter test 788 passed (45 token-map tests, 7 theme tests), `dart analyze --fatal-infos` clean, ruff clean, both `--check` runs exit 0.
- design_tokens.json, lib/frontend_scaffold.dart and every lib/theme/scaffold_*.dart are byte-identical to 0fe6608.
- ci.yaml has one `theme_presets --check` line in the python job.

## Deviations from Plan

**1. [Minor] dart format applied to test/theme/midnight_theme_test.dart**
- Found during: Task 2. Formatting the new token-map test also reformatted the TRACER test file, so that file is included in the DRIFT commit (cc4841b). No behavior change.

**2. [Minor] write_rendered prints with _display**
- The refactor prints `rendered <repo-relative path>` through `_display` instead of `lib/theme/{name}`. Output for repo files is identical; a preset in a subdirectory shows its full path.

Otherwise the plan ran as written.

## Known Stubs

None.

## Self-Check: PASSED

All created files exist; b1e979e, e252e13 and cc4841b exist on develop.
