---
phase: 16-component-restyles
plan: 06
subsystem: theme-and-components
tags: [checkbox, accent-role, theme-extension, midnight, codegen, captures]
requires:
  - "16-05 (ScaffoldShapes, scrim and surfaceEdge roles)"
provides:
  - "Accent fills (badge, chart range band, selectable-surface tint) read colorRoles.accent"
  - "ScaffoldColorRoles.checkboxFill / checkboxMark / checkboxEdge (Color?) and ScaffoldShapes.checkboxRadius / checkboxBorderWidth (double?), null by default, generated from design_tokens.json"
  - "Midnight checked checkbox: strong accent fill, near-black mark, accentOnSurface 1.5 px edge, 4 px corners"
affects: [16-07]
key-files:
  created: []
  modified:
    - lib/components/scaffold_badge.dart
    - lib/components/scaffold_chart_range_selector.dart
    - lib/components/scaffold_selectable_surface.dart
    - templates/components/selection_indicator.dart.jinja2
    - lib/components/scaffold_selection_indicator_checkbox.dart
    - lib/theme/scaffold_color_roles.dart
    - lib/theme/scaffold_shapes.dart
    - lib/theme/presets/midnight_tokens.dart
    - design_tokens.json
    - tokens/midnight.json
    - test/components/scaffold_badge_test.dart
    - test/components/scaffold_chart_range_selector_test.dart
    - test/components/scaffold_selectable_surface_test.dart
    - test/components/scaffold_selection_indicator_test.dart
    - test/theme/scaffold_color_roles_test.dart
    - test/theme/scaffold_shapes_test.dart
    - test/theme/midnight_token_map_test.dart
    - test/theme/palette_contrast_test.dart
    - test/theme/scaffold_tokens_parity_test.dart
    - tools/tests/test_theme_defaults.py
    - tools/tests/test_theme_presets.py
    - images/midnight/restyles_dark.png
    - images/midnight/restyles_light.png
key-decisions:
  - "The refactor landed first and was proven byte-identical in both profiles before any behavior change (PD-07)."
  - "The checkbox change was made only in the checkbox branch of selection_indicator.dart.jinja2; radio and toggle files are unchanged against d5ad4cb (UD-04)."
  - "Midnight mark is textOnAccent (7.74:1 on the fill), not the source's white tick (2.56:1) (PD-05)."
  - "When checkboxFill is set, the indeterminate state is filled too, so the dark mark stays visible in midnight dark."
requirements-completed: [RST-01]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 24000
  tasks: 3
  commits: 3
---

# Phase 16 Plan 06: Accent fills and checkbox Summary

The badge fill, chart range band and selectable-surface tint now read `colorRoles.accent` with no pixel change, and midnight checkboxes take the source checked look (strong accent fill, near-black mark, accent edge, 4 px corners) through five new generated nullable fields and the selection-indicator template.

## Commits

| SHA | Content |
|---|---|
| 5c48dad | refactor(16-06): accent fills read colorRoles.accent, captures unchanged (RST-01) |
| fbb7b68 | feat(16-06): themed checkbox fill, mark, edge and geometry (RST-01) |
| 292d5ba | chore(16-06): re-baseline midnight captures after the checkbox restyle (RST-01); CHORE_16_06 |

## Verification

| Check | Result |
|---|---|
| selection_indicator, theme_defaults, theme_presets `--check` | exit 0 |
| radio and toggle files vs d5ad4cb | empty diff |
| pytest tools/tests | 193 passed (unchanged count; two pinned lists and one key list extended) |
| ruff check | All checks passed |
| flutter test (root) | 1391 passed (was 1353; +38) |
| dart analyze --fatal-infos, root and example | No issues found |
| Default scratch render vs images/*.png | byte-identical after the refactor and after the feature commit |
| Midnight scratch render after the refactor | byte-identical to images/midnight |
| CHORE_16_06 stat | only images/midnight; `git log d5ad4cb..HEAD -- images ':!images/midnight'` empty |

## Midnight captures moved

restyles_dark and restyles_light (the checkbox row). Both were opened: checked checkbox shows the 0xFF0AAEE6 fill with a dark check, unchecked shows only the edge, indeterminate shows the fill with a dark dash.

## Other accent fill sites

A search of lib/components and templates/components found no further reads of `lightGreenPrimary` or `lightGreenSecondary`; the three listed sites were the only ones.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Indeterminate dash invisible under midnight dark**
- **Found during:** Task 2
- **Issue:** the plan has the indeterminate state use the same mark color as checked, but the indeterminate state has no fill. A near-black dash on the unfilled dark surface would be invisible in midnight dark.
- **Fix:** the template fills the indeterminate state with `checkboxFill` when that role is set. With the role null (default theme) the indeterminate state stays unfilled with a white dash, as before; a test pins both.
- **Files modified:** templates/components/selection_indicator.dart.jinja2, lib/components/scaffold_selection_indicator_checkbox.dart, test/components/scaffold_selection_indicator_test.dart
- **Commit:** fbb7b68

**2. [Rule 3 - Blocking] Pinned lists for the generated regions and token key lists**
- **Found during:** Task 2
- **Issue:** the pytest key list for colorRoles.dark, the shapes regions of theme_defaults and theme_presets, and the dart tokens parity test pin the exact field lists.
- **Fix:** extended them with the five new fields.
- **Files modified:** tools/tests/test_theme_defaults.py, tools/tests/test_theme_presets.py, test/theme/scaffold_tokens_parity_test.dart
- **Commit:** fbb7b68

**3. Process slip, no effect on the result.** A stray `git stash` was run once during Task 2 (the stash list was empty beforehand). It was popped immediately; `git status` matched the pre-stash state and the stash list is empty. No work was lost.

## Known Stubs

None.

## Threat Flags

None. T-16-16 (template-only edit, `--check` exit 0, radio and toggle files pinned unchanged), T-16-17 (checkboxEdge 3:1 on every midnight surface and checkboxMark 3:1 on checkboxFill, both in palette_contrast_test and passing) and T-16-18 (CHORE_16_06 recorded) hold.

## Self-Check: PASSED

5c48dad, fbb7b68 and 292d5ba exist on develop. `colorRoles.checkboxMark` appears in lib/components/scaffold_selection_indicator_checkbox.dart, `checkboxMark` appears in the template, and `colorRoles.accent` is read in the three fill sites.
