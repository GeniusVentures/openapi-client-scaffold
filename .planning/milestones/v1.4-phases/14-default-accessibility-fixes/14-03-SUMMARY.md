---
phase: 14-default-accessibility-fixes
plan: 03
subsystem: theme-tokens
tags: [a11y, wcag, contrast, design-tokens, captures]
requires:
  - "14-02 palette_contrast_test and wcag_contrast helper (0f79aaa, f4207f7)"
provides:
  - "Light text field and drawer foregrounds are dark by default (A11Y-02)"
  - "palette_contrast_test has no deferred entries"
affects: [14-04, 14-05, 14-06]
tech-stack:
  added: []
  patterns:
    - "Decorative colorRoles tokens are checked by luminance polarity, not ratio"
key-files:
  modified:
    - design_tokens.json
    - lib/theme/scaffold_color_roles.dart
    - test/theme/palette_contrast_test.dart
    - test/theme/scaffold_color_roles_test.dart
    - test/components/text_entry_field_widget_test.dart
    - test/components/bottom_drawer_test.dart
    - tools/tests/test_theme_defaults.py
    - images/text_entry_field_light.png
    - images/bottom_drawer_light.png
key-decisions:
  - "Token-value change only; no widget or generator code touched (UD-04)."
requirements-completed: [A11Y-02]
metrics:
  duration: "about 20 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
---

# Phase 14 Plan 03: Light text field and drawer foreground Summary

Light-mode TextEntryFieldWidget typed text and BottomDrawer title, close icon and divider now default to dark values via three scaffold.colorRoles.light token changes, in a fix commit separate from the two-PNG capture commit.

## Commit values (for 14-06)

| Name | SHA | Touches |
|---|---|---|
| A11Y02 | 3ae320d | design_tokens.json, scaffold_color_roles.dart, 4 Dart tests, test_theme_defaults.py; no PNG |
| A11Y02_CAPTURES | 015d521 | images/text_entry_field_light.png, images/bottom_drawer_light.png only |

## Value changes (scaffold.colorRoles.light; dark unchanged)

| Token | Old | New | Ratio old -> new |
|---|---|---|---|
| inputForeground | 0xFFFFFFFF | 0xFF17191E | 1.11 -> 15.81 on grayPrimary |
| sheetForeground | 0xFFFFFFFF | 0xFF17191E | 1.18 -> 14.96 on deepBlueTertiary |
| sheetDivider | 0x1FFFFFFF | 0x1F000000 | invisible white hairline -> dark hairline (decorative) |

## Tests

- palette_contrast_test: inputForeground and sheetForeground are text (4.5:1) on roles and fallbackFor in both modes; sheetDivider checked by polarity (darker than the panel in light, lighter in dark). The `deferred` role is removed; `grep -c "plan 14-03"` is 0.
- RED confirmed light-only failures before the token edit. Widget, role and Python tests updated to the new light values.
- theme_defaults --check exit 0; pytest 134 passed; ruff clean; dart analyze --fatal-infos clean; flutter test 681 passed. consumer_contract_test.dart unchanged.

## Capture review (old via git show HEAD: vs new)

- Typed "Ada Lovelace" is dark on the light fill (was white, near invisible).
- Drawer title and close icon are dark.
- Divider is a visible dark hairline under the header (was invisible).
- Nothing else changed. `git status --porcelain images/` listed exactly the two light PNGs; scratch and images renders byte-identical (52 PNGs). After the capture commit a re-render left images/ clean and the all-families generator left lib/ clean.

## Deviations from Plan

**1. [Rule 1 - Old-value pin] 'no extensions' widget test expectations**
- Issue: `ThemeData()` defaults to light brightness, so the 'no extensions' case resolves light color roles through fallbackFor and now draws the dark foreground and dark hairline. The tests pinned white.
- Fix: expectations for 'no extensions' in text_entry_field_widget_test.dart and bottom_drawer_test.dart now use the light values.
- Commit: 3ae320d

## Observations

- A host that registers no ScaffoldPalette and no ScaffoldColorRoles but uses a light (default) ThemeData gets the dark default palette surfaces with the light role foregrounds, so input text and drawer title are dark on dark surfaces in that unregistered edge. The plan mandates `fallbackFor(palette, brightness)` and a token-only change, so this was not altered. The same pairing already applied to borderControl before this plan. Worth a decision in a later plan if bare ThemeData() consumers matter.

## Known Stubs

None.

## Self-Check: PASSED

Commits 3ae320d and 015d521 exist with the expected path sets; working tree clean.
