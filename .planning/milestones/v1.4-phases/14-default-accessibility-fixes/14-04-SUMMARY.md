---
phase: 14-default-accessibility-fixes
plan: 04
subsystem: theme-roles
tags: [a11y, color-roles, refactor, design-tokens]
requires:
  - "14-03 light text field and drawer foreground (3ae320d)"
provides:
  - "ScaffoldColorRoles.accentSecondaryOnSurface and accentTextOnSurface (tokens, fields, copyWith, lerp, fallbackFor)"
  - "Every accent foreground and accent text site reads a color role"
  - "context.colorRoles fallback follows the palette surfaces (fallbackForPalette)"
affects: [14-05, 14-06]
tech-stack:
  added: []
  patterns:
    - "Fills keep palette.lightGreenPrimary; foregrounds read colorRoles"
key-files:
  modified:
    - design_tokens.json
    - lib/theme/scaffold_color_roles.dart
    - lib/theme/scaffold_theme.dart
    - lib/components/action_button.dart
    - lib/components/loading/loading.dart
    - lib/components/scaffold_badge.dart
    - lib/components/scaffold_chart.dart
    - lib/components/scaffold_chart_range_selector.dart
    - lib/components/scaffold_chip.dart
    - lib/components/scaffold_color_swatch.dart
    - lib/components/scaffold_disclosure.dart
    - lib/components/scaffold_drop_target.dart
    - lib/components/scaffold_numeric_input.dart
    - lib/components/scaffold_selectable_surface.dart
    - lib/components/scaffold_streaming_copy_button.dart
    - lib/components/scaffold_streaming_rich_text.dart
    - templates/components/search_bar.dart.jinja2
    - templates/components/selection_indicator.dart.jinja2
    - lib/components/scaffold_search_bar.dart
    - lib/components/scaffold_selection_indicator_checkbox.dart
    - lib/components/scaffold_selection_indicator_radio.dart
    - lib/components/scaffold_selection_indicator_toggle.dart
key-decisions:
  - "Unregistered color roles are chosen from the palette surfaces actually in use, not ThemeData.brightness."
  - "fallbackFor(palette, brightness) keeps its signature and meaning; a new fallbackForPalette(palette) is what context.colorRoles calls."
requirements-completed: [A11Y-01]
metrics:
  duration: "about 40 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 22000
  tasks: 2
  commits: 3
---

# Phase 14 Plan 04: Accent call sites read color roles Summary

Two new roles (accentSecondaryOnSurface, accentTextOnSurface) and 19 accent foreground sites moved onto color roles with no pixel change, plus a fix so unregistered roles follow the palette surfaces.

## Commit values (for 14-05 and 14-06)

| Name | SHA | Touches |
|---|---|---|
| UNREGISTERED_ROLES_FIX | 7c175ed | scaffold_color_roles.dart, scaffold_theme.dart, 4 tests; no PNG |
| ACCENT_REFACTOR | 4d813e1 | tokens, roles, 13 widgets, 2 templates, 4 generated files, tests; no PNG |

## Deviations from Plan

**1. [Rule 1 - Bug] Unregistered roles unreadable with a light ThemeData and no palette**
- Found during: pre-task fix requested by the orchestrator, from the 14-03 observation.
- Issue: `context.colorRoles` picked light or dark tokens from `ThemeData.brightness`. A light ThemeData with no registered ScaffoldPalette resolves to the dark default surfaces but got the dark text-field and drawer foregrounds on them.
- Fix: new `ScaffoldColorRoles.fallbackForPalette(palette)` chooses `inputForeground` by the luminance of `palette.grayPrimary` and the sheet roles by `palette.deepBlueTertiary`. `context.colorRoles` calls it. `fallbackFor(palette, brightness)` is unchanged and still public. The 'no extensions' widget test expectations (text field, bottom drawer) went back to the dark values.
- Tests: `fallbackForPalette` unit tests (dark, light, mixed surfaces) and a palette_contrast_test group that pumps four combinations (light ThemeData with no palette, dark with no palette, light with light palette, dark with dark palette) and asserts 4.5:1 for inputForeground and sheetForeground plus divider polarity.
- Captures: re-rendered, `git status --porcelain images/` empty, so no re-baseline commit was needed.
- Commit: 7c175ed
- Note for 14-05: the light accent branch should key off the same surface decision, not ThemeData.brightness.

**2. [Rule 3 - Blocking] selection_indicator template helper signatures**
- Issue: radio and checkbox builders had no BuildContext, which `context.colorRoles` needs.
- Fix: `_buildRadio` and `_buildCheckbox` take `BuildContext context` like `_buildToggle` already did. Generated files regenerated from the template.
- Commit: 4d813e1

Otherwise the plan ran as written. Task 1 (tracer) and Task 2 are in one commit as the plan specifies; the tracer slice verified before expansion (tokens, generator check, tests, analyze all green).

## Verification

- theme_defaults --check exit 0; all-families generator then `git diff --exit-code lib/` clean.
- dart analyze --fatal-infos clean; flutter test 688 passed; pytest 134 passed. consumer_contract_test.dart unchanged. ruff is not installed in this shell, so it was not run.
- Capture harness re-rendered into images/ after the fix commit and after the refactor: `git status --porcelain images/` empty, and neither commit touches a PNG.
- Residual use check prints exactly three fills: scaffold_badge.dart (count, text and icon default), scaffold_chart_range_selector.dart (12% band), scaffold_selectable_surface.dart (12% wash). `colorRoles.accentOnSurface` appears 26 times and `accentTextOnSurface` 4 times in lib/components and templates/components.
- Doc comments that named the old palette default were updated.

## Known Stubs

None.

## Self-Check: PASSED

Commits 7c175ed and 4d813e1 exist; working tree clean after the generator run.
