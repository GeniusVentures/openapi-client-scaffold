---
phase: 15-midnight-preset
plan: 04
subsystem: theme-presets
tags: [preset, theme, colorscheme, component-themes, wcag, midnight]
requires:
  - "15-03 (Midnight gradients, text theme, type scale, spacing ladder)"
provides:
  - "midnightTheme(Brightness) returns the full ThemeData: midnight ColorScheme, page background, Inter text theme, 21 component themes, six extensions"
  - "test/theme/midnight_theme_contrast_test.dart: ColorScheme and component-theme contrast checks in light and dark"
affects: [15-07]
key-files:
  created:
    - test/theme/midnight_theme_contrast_test.dart
  modified:
    - lib/theme/presets/midnight_theme.dart
    - test/theme/midnight_theme_test.dart
key-decisions:
  - "Accent foregrounds (outline, borders, indicators, cursor, icons) read colorRoles.accentOnSurface; raw accent fills stay fills."
  - "onTertiary, onError, error and outline depart from the source for AA, each commented with its ratio."
  - "Dividers and the menu use colorScheme.surfaceContainerHighest, which is the sheet surface."
requirements-completed: [PRE-01, PRE-02, A11Y-03]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 40000
  tasks: 2
  commits: 2
---

# Phase 15 Plan 04: Midnight ThemeData assembly Summary

`midnightTheme(brightness)` now returns the complete midnight Material theme in one call, ported from the source theme with neutral names and AA-safe foregrounds, and a contrast test proves every foreground and fill pair the theme introduces.

## Commits

| Task | SHA | Content |
|---|---|---|
| 1 (tracer) | 35131bf | ColorScheme, page background, Inter colored text theme; scheme contrast test; page and type assertions |
| 2 | 9b10344 | 21 component themes, dividers and menu on the sheet surface; component contrast checks; widget smoke tests |

## Verification

- flutter test: 1225 passed (full run). The two theme test files alone: 144 passed.
- `dart analyze --fatal-infos` clean. pytest 178 passed. ruff clean. theme_defaults and theme_presets `--check` exit 0 (run from `tools/`).
- Acceptance grep for the component themes prints 21.
- lib/frontend_scaffold.dart, design_tokens.json and the default scaffold_palette, scaffold_color_roles and scaffold_theme files are unchanged since 0fe6608.
- Contrast: ColorScheme pairs (on/fill, onSurface, onSurfaceVariant, error as text, outline) and component foregrounds pass on surface, surfaceContainerHighest and the page, in light and dark. The excluded fills (primary, secondary, tertiary) are listed with reasons and the list is asserted non-empty.
- Smoke: a Scaffold with the listed Material widgets and a DatePickerDialog pump without exceptions in both modes.

## Deviations from Plan

None - plan executed as written.

## Known Stubs

None.

## Self-Check: PASSED

35131bf and 9b10344 exist on develop; all created and modified files exist.
