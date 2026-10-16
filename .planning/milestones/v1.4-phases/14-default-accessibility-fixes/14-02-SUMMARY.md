---
phase: 14-default-accessibility-fixes
plan: 02
subsystem: theme-tokens
tags: [a11y, wcag, contrast, design-tokens, captures]
requires:
  - "14-01 baseline captures (d9342ff, b9145a8)"
provides:
  - "test/theme/wcag_contrast.dart: contrastRatio, kWcagText, kWcagNonText, argbHex"
  - "palette_contrast_test.dart: classification of every palette and colorRoles token, per-pair checks on default dark and light"
  - "Default dark and light palettes pass WCAG AA (A11Y-01)"
affects: [14-03, 14-04, 14-05, 14-06, 15]
tech-stack:
  added: []
  patterns:
    - "Contrast test classifies every token; a new token without a classification fails the coverage test"
key-files:
  created:
    - test/theme/wcag_contrast.dart
    - test/theme/wcag_contrast_test.dart
    - test/theme/palette_contrast_test.dart
  modified:
    - design_tokens.json
    - lib/theme/scaffold_palette.dart
    - lib/theme/scaffold_color_roles.dart
    - test/theme/scaffold_palette_token_test.dart
    - images/*.png (10)
key-decisions:
  - "Five dartRef entries became plain ARGB strings; ScaffoldColors constants unchanged."
  - "Light focus ring is now its own AA value, so the 'shares brand accents' test no longer pins focusRingColor to the dark one."
requirements-completed: [A11Y-01]
metrics:
  duration: "about 25 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 14000
  tasks: 3
  commits: 3
---

# Phase 14 Plan 02: Default palettes pass WCAG AA Summary

Default dark and light palettes now pass 4.5:1 (text) and 3:1 (non-text) on all four surfaces, enforced by a token-classifying contrast test, with token-only changes and a separate capture commit.

## Commit values (for 14-06)

| Name | SHA | Touches |
|---|---|---|
| helper | 6cf6f83 | wcag_contrast.dart, wcag_contrast_test.dart, palette_contrast_test.dart (textPrimary rule) |
| A11Y01 | 0f79aaa | design_tokens.json, scaffold_palette.dart, scaffold_color_roles.dart, palette_contrast_test.dart, scaffold_palette_token_test.dart; no PNG |
| A11Y01_CAPTURES | f4207f7 | 10 PNGs only |

## Value changes (worst surface of the mode, ratios from the same math as the test helper)

| Token | Old | New | Ratio before -> after |
|---|---|---|---|
| palette.light.gray500 | 0xFF73788C | 0xFF65697B | 3.73 -> 4.63 |
| palette.dark.gray500 | 0xFF73788C | 0xFF818698 | 3.84 -> 4.64 |
| palette.light.statusSuccess | 0xFF0AA06B | 0xFF087951 | 2.86 -> 4.62 |
| palette.light.statusError | 0xFFD13438 | 0xFFC82D31 | 4.19 -> 4.61 |
| palette.light.statusWarningText | 0xFF9A6A00 | 0xFF8D6100 | 4.03 -> 4.65 |
| palette.light.focusRingColor | 0xFF00EAAE | 0xFF00956F | 1.33 -> 3.23 |
| palette.light.borderGrey | 0x1F000000 | 0x73000000 | 1.31 -> 3.27 |
| palette.dark.borderGrey | 0x4DFFFFFF | 0x5CFFFFFF | 2.59 -> 3.25 |
| colorRoles.light.borderControl | 0x1F000000 | 0x73000000 | equals light borderGrey |
| colorRoles.dark.borderControl | 0x4DFFFFFF | 0x5CFFFFFF | equals dark borderGrey |

## RED list (Task 2, before the token change)

Exactly 43 failing tests, matching the expected set: default light gray500 and statusSuccess on four surfaces (8); statusError and statusWarningText on grayPrimary and deepBlueTertiary (4); focusRingColor, borderGrey, borderControl (roles) and borderControl (fallback) on four surfaces (16); default dark gray500 on three surfaces (3) and borderGrey, borderControl (roles), borderControl (fallback) on four surfaces (12). The coverage test passed.

## Verification

- theme_defaults --check exit 0; pytest 134 passed; ruff clean; dart analyze --fatal-infos clean.
- flutter test: 669 passed (root). palette_contrast_test fully green.
- consumer_contract_test.dart and scaffold_colors.dart unchanged.
- All-families generator run leaves lib/ clean. Re-render after the capture commit leaves images/ clean. Two renders (scratch and images/) byte-identical.

## Capture explanations (10 PNGs, color change only; viewed text_entry_field_light and action_button_dark old vs new)

- action_button_dark, action_button_light: gray500 label.
- text_entry_field_dark, text_entry_field_light: gray500 hint, borderGrey enabled border (via colorRoles fallback).
- chart_range_selector_light, chart_scrubber_light, chart_scrubber_dark: borderGrey chart frame.
- toast_light: light status accents.
- chip_light, trace_list_light: ScaffoldStatusIndicator light status colors (statusSuccess, statusWarningText, statusError). These two demos are not in the plan's demo list but render ScaffoldStatusIndicator, which draws those tokens.

Dark captures moved only through gray500 or borderGrey.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Old-value pin] scaffold_palette_token_test 'shares brand accents with the dark palette'**
- Issue: pinned light focusRingColor to the dark value.
- Fix: split into the accent-sharing assertion (lightGreenPrimary) and a new test that light focusRingColor is 0xFF00956F and differs from dark. Expected by the plan.
- Commit: 0f79aaa

Otherwise none. The explicit coverage-test classification adds 'accent' and 'accentOnSurface' (colorRoles) as excluded, which the plan's excluded list named for the palette side.

## Known Stubs

None.

## Self-Check: PASSED

Commits 6cf6f83, 0f79aaa, f4207f7 exist with the expected path sets; the working tree was clean after the capture commit.
