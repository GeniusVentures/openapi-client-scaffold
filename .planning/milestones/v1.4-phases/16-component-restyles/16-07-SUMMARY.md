---
phase: 16-component-restyles
plan: 07
subsystem: theme-and-components
tags: [action-button, tabular-figures, formatted-value, theme-extension, midnight, codegen, captures]
requires:
  - "16-06 (accent fills, checkbox roles)"
provides:
  - "ScaffoldColorRoles.actionIcon / actionDisabledFill / actionDisabledForeground (Color?), null by default, generated from design_tokens.json"
  - "ScaffoldTypography.numericStyle (TextStyle?), null by default"
  - "Midnight ActionButton: on-surface accent glyph, sunken disabled tile, 54% disabled glyph and caption"
  - "Midnight formatted values render with tabular figures, merged in the formatted_value template"
affects: []
key-files:
  created:
    - test/components/action_button_test.dart
  modified:
    - design_tokens.json
    - tokens/midnight.json
    - lib/theme/scaffold_color_roles.dart
    - lib/theme/scaffold_typography.dart
    - lib/theme/presets/midnight_tokens.dart
    - lib/components/action_button.dart
    - templates/components/formatted_value.dart.jinja2
    - lib/components/scaffold_formatted_value_date.dart
    - lib/components/scaffold_formatted_value_duration.dart
    - lib/components/scaffold_formatted_value_money.dart
    - lib/components/scaffold_formatted_value_number.dart
    - lib/components/scaffold_formatted_value_percentage.dart
    - lib/components/scaffold_formatted_value_time.dart
    - test/components/scaffold_formatted_value_test.dart
    - test/theme/scaffold_color_roles_test.dart
    - test/theme/scaffold_typography_test.dart
    - test/theme/midnight_token_map_test.dart
    - test/theme/palette_contrast_test.dart
    - test/theme/scaffold_tokens_parity_test.dart
    - tools/tests/test_theme_defaults.py
    - images/midnight/action_button_dark.png
    - images/midnight/action_button_light.png
    - images/midnight/restyles_dark.png
    - images/midnight/restyles_light.png
key-decisions:
  - "A set actionDisabledForeground wins over a caller iconColor and textColor when the button is disabled; caller overrides still win for the enabled state (UD-02)."
  - "The tabular figures change was made only in formatted_value.dart.jinja2 and the six variants regenerated; formatted_value --check exits 0 (UD-04)."
  - "ActionButton glyph size ratio (0.38 vs the source 0.45) and padding are layout, not style values, and stay as they are."
  - "StringButton is unchanged (PD-08)."
requirements-completed: [RST-01]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 36000
  tasks: 2
  commits: 4
---

# Phase 16 Plan 07: ActionButton roles and tabular figures Summary

Midnight ActionButtons take the source glyph (on-surface accent) and disabled look (sunken tile, 54% glyph and caption) through three generated nullable color roles, and midnight formatted values render with tabular figures through `ScaffoldTypography.numericStyle` merged in the formatted value template. Default theme output is unchanged.

## Commits

| SHA | Content |
|---|---|
| 7645aed | feat(16-07): themed ActionButton glyph and disabled state (RST-01) |
| 75f7a04 | chore(16-07): re-baseline midnight captures after the ActionButton restyle (RST-01); CHORE_16_07A |
| 0eddc59 | feat(16-07): tabular figures on formatted values from ScaffoldTypography (RST-01) |
| 5d783f3 | chore(16-07): re-baseline midnight captures after tabular figures (RST-01); CHORE_16_07B |

## Verification

| Check | Result |
|---|---|
| formatted_value, theme_defaults, theme_presets `--check` | exit 0 |
| pytest tools/tests | 193 passed |
| ruff check | All checks passed |
| flutter test (root) | 1464 passed (was 1391; +73) |
| dart analyze --fatal-infos, root and example | No issues found |
| Default scratch render vs images/*.png (both features) | 52 files, byte-identical |
| CHORE_16_07A / CHORE_16_07B stat | only images/midnight; `git log d5ad4cb..HEAD -- images ':!images/midnight'` empty |

## Midnight captures moved

- After the ActionButton restyle: action_button_dark and action_button_light. Both opened: cyan glyphs on the enabled and rotating tiles, sunken disabled tile with a dimmed glyph and caption.
- After tabular figures: restyles_dark and restyles_light (the formatted number row). The plan expected possibly no movement because the harness uses Roboto files; Roboto's default digits are proportional, so the pixels did move and CHORE_16_07B was made. No other midnight capture moved.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pinned key lists**
- **Found during:** Task 1
- **Issue:** scaffold_tokens_parity_test and tools/tests/test_theme_defaults.py pin the exact nullable colorRoles field lists.
- **Fix:** extended both with the three new fields.
- **Files modified:** test/theme/scaffold_tokens_parity_test.dart, tools/tests/test_theme_defaults.py
- **Commit:** 7645aed

None otherwise. The plan listed action_button_test.dart as possibly missing; it was created.

## Known Stubs

None.

## Threat Flags

None. T-16-19 (template-only edit, `--check` exit 0), T-16-20 (actionIcon classified nonText 3:1 and passing on every midnight surface in palette_contrast_test; the two disabled roles are excluded as exempt) and T-16-21 (CHORE_16_07A and CHORE_16_07B recorded) hold.

## Self-Check: PASSED

7645aed, 75f7a04, 0eddc59 and 5d783f3 exist on develop. `colorRoles.actionIcon` and `actionDisabledFill` appear in lib/components/action_button.dart; `numericStyle` appears in the template and in lib/theme/presets/midnight_tokens.dart.
