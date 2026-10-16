---
phase: 16-component-restyles
plan: 05
subsystem: theme-and-components
tags: [drawer, bottom-sheet, theme-extension, midnight, captures]
requires:
  - "16-04 (ScaffoldShapes, surfaceEdge role)"
provides:
  - "ResponsiveDrawerPanel, the public desktop side panel ResponsiveDrawer.show opens"
  - "ScaffoldShapes.sheetRadius (double?) and ScaffoldColorRoles.scrim (Color?), null by default, generated from design_tokens.json"
  - "Midnight drawer and sheet: card fill, surfaceEdge hairline, 24 px open-edge radius, 0x99000000 barrier"
affects: [16-06]
key-files:
  created: []
  modified:
    - lib/components/bottom_drawer/responsive_drawer.dart
    - lib/theme/scaffold_shapes.dart
    - lib/theme/scaffold_color_roles.dart
    - lib/theme/presets/midnight_tokens.dart
    - design_tokens.json
    - tokens/midnight.json
    - example/test/capture_images_test.dart
    - test/components/bottom_drawer_test.dart
    - test/theme/scaffold_shapes_test.dart
    - test/theme/scaffold_color_roles_test.dart
    - test/theme/midnight_token_map_test.dart
    - test/theme/palette_contrast_test.dart
    - test/theme/scaffold_tokens_parity_test.dart
    - tools/tests/test_theme_defaults.py
    - tools/tests/test_theme_presets.py
    - images/midnight/bottom_drawer_dark.png
    - images/midnight/bottom_drawer_light.png
    - images/midnight/wallet_connect_sheet_dark.png
    - images/midnight/wallet_connect_sheet_light.png
key-decisions:
  - "The refactor landed first and was proven byte-identical in both profiles before any behavior change (PD-07)."
  - "Null sheetRadius and surfaceEdge keep the exact old panel tree (no shape, no clip); the default mobile sheet keeps 16 px top corners."
  - "Midnight deepBlueTertiary moved from the menu fill to the card fill (0xFF0C0E14 / 0xFFFFFFFF), following the source drawer panel (PD-05)."
requirements-completed: [RST-01]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 14000
  tasks: 3
  commits: 3
---

# Phase 16 Plan 05: Sheets and drawers Summary

Midnight drawers and sheets take the source look (card fill, hairline, 24 px open-edge radius, 60% scrim) through a new public `ResponsiveDrawerPanel`, a generated `ScaffoldShapes.sheetRadius` and a generated `ScaffoldColorRoles.scrim`; the default theme renders exactly as before.

## Commits

| SHA | Content |
|---|---|
| 1df092e | refactor(16-05): desktop drawer panel as ResponsiveDrawerPanel, captures unchanged |
| 719b785 | feat(16-05): themed drawer and sheet edge, radius and barrier; midnight panel on the card fill (RST-01) |
| dfe9732 | chore(16-05): re-baseline midnight captures after the drawer restyle (RST-01); CHORE_16_05 |

## Verification

| Check | Result |
|---|---|
| theme_defaults, theme_presets `--check` | exit 0 |
| pytest tools/tests | 193 passed (unchanged count; three assertions updated for the new fields) |
| ruff check | All checks passed |
| flutter test (root) | 1353 passed (was 1337; +16) |
| dart analyze --fatal-infos, root and example | No issues found |
| Default scratch render vs images/*.png | byte-identical after the refactor and after the feature commit |
| Midnight scratch render after the refactor | byte-identical to images/midnight |
| scaffold_palette.dart vs d5ad4cb | empty diff |
| CHORE_16_05 stat | only images/midnight; `git log d5ad4cb..HEAD -- images ':!images/midnight'` empty |

## Midnight captures moved

bottom_drawer_dark, bottom_drawer_light, wallet_connect_sheet_dark, wallet_connect_sheet_light. The two bottom_drawer captures were opened: card-fill panel, hairline, rounded left corners. The wallet sheet moved because it also reads deepBlueTertiary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pinned tests for the generated regions and token key lists**
- **Found during:** Task 2 verification
- **Issue:** adding `scrim` and `sheetRadius` broke three pytest assertions (dark colorRoles key list, shapes region of theme_defaults, shapes region of theme_presets) and the dart tokens parity test, all of which pin the exact field lists.
- **Fix:** extended the expected lists with the new fields.
- **Files modified:** tools/tests/test_theme_defaults.py, tools/tests/test_theme_presets.py, test/theme/scaffold_tokens_parity_test.dart
- **Commit:** 719b785

**2. [Rule 3 - Blocking] Unused import in the harness**
- **Found during:** Task 1
- **Issue:** after the panel replaced the inline copy, `bottom_drawer.dart` was unused in capture_images_test.dart (`--fatal-infos` fails on it).
- **Fix:** swapped it for the `responsive_drawer.dart` import.
- **Commit:** 1df092e

The plan's palette_contrast_test note (classify scrim as excluded) needed one new row in the color-roles table; the preset table already had a `scrim` row.

## Known Stubs

None.

## Threat Flags

None. T-16-13 (default tree unchanged, pinned by widget tests and byte-identical renders), T-16-14 (palette_contrast_test passes on the new fill) and T-16-15 (CHORE_16_05 recorded) hold.

## Self-Check: PASSED

1df092e, 719b785 and dfe9732 exist on develop. `class ResponsiveDrawerPanel` appears once in responsive_drawer.dart, `ResponsiveDrawerPanel(` once in example/test/capture_images_test.dart, `sheetRadius` and `colorRoles.scrim` are used in responsive_drawer.dart, and both midnight `deepBlueTertiary` values appear once in midnight_tokens.dart.
