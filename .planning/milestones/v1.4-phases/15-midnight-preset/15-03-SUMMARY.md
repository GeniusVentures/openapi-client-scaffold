---
phase: 15-midnight-preset
plan: 03
subsystem: theme-presets
tags: [preset, codegen, gradients, typography, midnight]
requires:
  - "15-02 (Midnight groups, MidnightColors, preset region table)"
provides:
  - "dart_gradient encodes linear and radial gradients, fully validated"
  - "dart_text_style accepts lineHeight (emitted as height: lineHeight / fontSize) and tabularFigures"
  - "Midnight.darkGradients, lightGradients (MidnightGradients), darkElevation, lightElevation (MidnightElevation)"
  - "Midnight.textTheme (ten slots), Midnight.typeScale (MidnightTypeScale), Midnight.scale (MidnightScale)"
affects: [15-04, 15-07]
key-files:
  modified:
    - tools/scaffold_codegen/generators/theme_defaults.py
    - tools/scaffold_codegen/generators/theme_presets.py
    - tools/tests/test_theme_defaults.py
    - tokens/midnight.json
    - lib/theme/presets/midnight_tokens.dart
    - test/theme/midnight_token_map_test.dart
key-decisions:
  - "Gradient stops must be non-decreasing and within 0.0..1.0; they need not start at 0.0 or end at 1.0, because the glow stops are [0.0, 0.6]."
  - "lineHeight without fontSize is a token error, since the height multiplier has nothing to divide by."
requirements-completed: [PRE-02]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 30000
  tasks: 3
  commits: 3
---

# Phase 15 Plan 03: Gradients, shadows, type scale and spacing ladder Summary

The shared codegen now encodes gradients and text styles with line height and tabular figures, and the midnight preset carries every remaining token group from the source map: gradients, dialog and glow shadows, text theme, numeric styles and the spacing and radius steps with no ScaffoldDimens field. design_tokens.json output is byte-identical.

## Commits

| Task | SHA | Content |
|---|---|---|
| 1 (tracer) | 423afe7 | linear and radial gradient encoder with reject tests; preset.shadows and preset.gradients; MidnightElevation, MidnightGradients |
| 2 | 4e0cc60 | lineHeight and tabularFigures in the text-style encoder; preset.textTheme, typeScale, scale; MidnightTypeScale, MidnightScale |
| 3 | c92ebf6 | source-map rows for gradients, elevation, text theme, numeric styles, scale, plus a key coverage test |

## Verification

- theme_defaults and theme_presets `--check` exit 0. pytest 178 passed. ruff clean. `dart analyze --fatal-infos` clean.
- flutter test: 1090 passed (full run).
- design_tokens.json, scaffold_gradients.dart and scaffold_typography.dart are unchanged since 0fe6608.
- Acceptance greps: 1 RadialGradient, 2 canvas stop lists, 2 `height: 40.0 / 32.0`, 3 tabularFigures, 21 generated markers.
- Changing the dark canvas stop in tokens/midnight.json and regenerating failed the map test; restored from a backup copy.

## Deviations from Plan

None - plan executed as written. The encoder reject cases beyond the listed ones (missing begin, end, radius or colors, a list as the type) were added to the parametrized test.

## Known Stubs

None.

## Self-Check: PASSED

423afe7, 4e0cc60 and c92ebf6 exist on develop; all modified files exist.
