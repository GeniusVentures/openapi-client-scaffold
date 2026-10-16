---
phase: 14-default-accessibility-fixes
plan: 05
subsystem: theme-roles
tags: [a11y, color-roles, design-tokens, light-mode, captures]
requires:
  - "14-04 accent call sites read color roles (4d813e1)"
provides:
  - "scaffold.colorRoles.light accentOnSurface 0xFF00956F, accentSecondaryOnSurface 0xFF01956D, accentTextOnSurface 0xFF00795A"
  - "fallbackFor keeps the light accent foregrounds in light mode and reads the palette in dark mode"
  - "palette_contrast_test checks the three accent roles in both themes"
affects: [14-06]
key-files:
  modified:
    - design_tokens.json
    - lib/theme/scaffold_color_roles.dart
    - test/theme/palette_contrast_test.dart
    - test/theme/scaffold_color_roles_test.dart
    - test/theme/consumer_contract_test.dart
    - test/components/text_entry_field_widget_test.dart
    - images/*_light.png (9 files)
key-decisions:
  - "Light accent foreground values keep the old hue and move only lightness, to the first step above the threshold on the worst light surface."
  - "fallbackFor light branch keeps lightColorRoles accents; dark branch still reads the palette. fallbackForPalette is unchanged and picks the branch from the drawer surface, so a light ThemeData with no palette keeps the dark accents."
requirements-completed: [A11Y-01]
metrics:
  duration: "about 25 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 12000
  tasks: 2
  commits: 2
---

# Phase 14 Plan 05: Light accent foregrounds meet AA Summary

Light-mode accent icons, borders, dots and the focused text-field border now meet 3:1, and accent text meets 4.5:1, from three token values; dark is unchanged.

## Commit values (for 14-06)

| Name | SHA | Touches |
|---|---|---|
| ACCENT_FIX | b673be7 | design_tokens.json, scaffold_color_roles.dart, 5 tests; no PNG |
| ACCENT_CAPTURES | 4b406e5 | 9 `_light.png` files only |

## Value changes (consumer-visible, light only)

Ratios on white / F1F3F5 / E9EDF2.

| Token | Old | New | Ratio old -> new |
|---|---|---|---|
| scaffold.colorRoles.light.accentOnSurface | 0xFF00EAAE | 0xFF00956F | 1.57/1.41/1.33 -> 3.80/3.41/3.23 |
| scaffold.colorRoles.light.accentSecondaryOnSurface | 0xFF01CC95 | 0xFF01956D | 2.08/1.87/1.77 -> 3.80/3.42/3.23 |
| scaffold.colorRoles.light.accentTextOnSurface | 0xFF00EAAE | 0xFF00795A | 1.57/1.41/1.33 -> 5.41/4.86/4.60 |

The three light entries are now plain strings with no dartRef, so the generated `lightColorRoles` uses `Color(...)` literals for them. Dark entries are untouched.

Contract-test change in consumer_contract_test.dart: only the light-registration `accentOnSurface` expectation, now `Color(0xFF00956F)`. The dark expectation is unchanged.

## Deviations from Plan

**1. [Rule 1 - Bug] text_entry_field_widget_test pinned the old light focused border**
- Found during: Task 1 full-suite run.
- Issue: "defaults equal the values drawn before the tokens / light" expected `palette.lightGreenPrimary` for the focused border. The border reads `accentOnSurface`, so the light value is now 0xFF00956F, as UD-08 intends.
- Fix: the expectation is 0xFF00956F when the palette is the light palette and `palette.lightGreenPrimary` otherwise. The "no extensions" case (light ThemeData, dark default surfaces) keeps the dark accent via `fallbackForPalette`, as it should.
- Commit: b673be7 (listed in the commit body).

Otherwise the plan ran as written. RED failed in light only (27 tests) before the token and fallback change. The human-verify gate for the tracer was handled by the automated verify.

## Captures (ACCENT_CAPTURES)

Two harness runs (images/ and a scratch dir) were byte-identical for all moved files. No `_dark.png` moved. Nine light captures moved, all from the listed demos:

| PNG | Widget and role |
|---|---|
| action_button_light | ActionButton icon, accentSecondaryOnSurface |
| chart_light | ScaffoldChart line, accentOnSurface |
| chart_range_selector_light | range selector edge rule, accentOnSurface |
| chart_scrubber_light | scrubber demo chart accent, accentOnSurface |
| chip_light | selected ScaffoldChip 2px border, accentOnSurface |
| disclosure_light | expanded chevron, accentOnSurface |
| loading_light | left loading dot, accentOnSurface |
| markdown_to_spans_light | citation marker and link text, accentTextOnSurface |
| streaming_rich_text_light | citation marker text, accentTextOnSurface |

action_button_light and streaming_rich_text_light were viewed next to their `HEAD` versions: the bright mint became a darker green, and layout is identical. kitchen_sink, tracer, trace_list, selection_actions, code_block and text_entry_field did not move, which the plan allows.

## Verification

- theme_defaults --check exit 0; all-families generator then `git diff --exit-code lib/` clean; working tree clean after the capture commit.
- pytest 134 passed; ruff check passed; dart analyze --fatal-infos clean; flutter test 736 passed.
- palette_contrast_test checks accentOnSurface and accentSecondaryOnSurface at 3:1 and accentTextOnSurface at 4.5:1 on all four surfaces, for both themes, on the static roles and on fallbackFor.
- A re-render after the capture commit leaves images/ clean.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Commits b673be7 and 4b406e5 exist, 4b406e5 directly follows b673be7, and the fix commit touches no file under images/.
