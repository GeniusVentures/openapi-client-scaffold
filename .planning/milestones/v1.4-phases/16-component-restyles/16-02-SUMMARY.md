---
phase: 16-component-restyles
plan: 02
subsystem: theme-and-components
tags: [theme-extension, generator, midnight, captures, card]
requires:
  - "16-01 (null-capable params regions, elevated shadow, restyles capture)"
provides:
  - "ScaffoldGradients.surfaceSheen (LinearGradient?, null by default)"
  - "ScaffoldColorRoles.surfaceEdge (Color?, null by default)"
  - "Midnight.darkScaffoldGradients / lightScaffoldGradients, registered by midnightExtensions"
  - "ScaffoldSurface: elevated surfaces paint the sheen (no caller color) and a 1 px foreground hairline (no caller border)"
affects: [16-05]
key-files:
  modified:
    - design_tokens.json
    - tokens/midnight.json
    - tools/scaffold_codegen/generators/theme_presets.py
    - tools/tests/test_theme_presets.py
    - tools/tests/test_theme_defaults.py
    - lib/theme/scaffold_gradients.dart
    - lib/theme/scaffold_color_roles.dart
    - lib/theme/presets/midnight_tokens.dart
    - lib/theme/presets/midnight_theme.dart
    - lib/components/scaffold_surface.dart
    - templates/components/card.dart.jinja2
    - lib/components/scaffold_card.dart
    - test/theme/scaffold_gradients_test.dart
    - test/theme/scaffold_color_roles_test.dart
    - test/theme/midnight_token_map_test.dart
    - test/theme/midnight_theme_test.dart
    - test/theme/palette_contrast_test.dart
    - test/theme/scaffold_tokens_parity_test.dart
    - test/components/scaffold_surface_test.dart
    - test/components/scaffold_card_test.dart
    - images/midnight/restyles_dark.png
    - images/midnight/restyles_light.png
key-decisions:
  - "surfaceEdge is null in the dark default region only; the light args region omits it (PD-01). The contrast and parity tests derive the light key set as the class keys minus the keys null in dark."
  - "The hairline is a foregroundDecoration, so it adds no layout size and works in both the BoxShadow and the Material elevation branch."
  - "Sheen applies only when the caller passed no color; ScaffoldCard's elevated variant stopped passing its color so it qualifies."
requirements-completed: [RST-01]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 40000
  tasks: 3
  commits: 4
---

# Phase 16 Plan 02: Card sheen and hairline Summary

Under midnight, an elevated card or surface now draws the source card recipe: the top-lit sheen in light mode (white to 0xFFF5F7FA), a 1 px `surfaceEdge` hairline in both modes, and the themed shadow from 16-01. Default theme rendering is unchanged.

## Commits

| SHA | Content |
|---|---|
| 22633f6 | feat(16-02): surface sheen and surface edge theme values, midnight instances (RST-01) |
| 1db98c5 | refactor(16-02): elevated card relies on the surface default color |
| f1b2611 | feat(16-02): raised surfaces take the themed sheen and hairline (RST-01) |
| d878e80 | chore(16-02): re-baseline midnight captures after the card sheen and hairline (RST-01); CHORE_16_02 |

## Verification

| Check | Result |
|---|---|
| theme_defaults, theme_presets, composites generators; full runner leaves `lib/` clean | exit 0; only the hand-edited scaffold_surface.dart differed |
| pytest tools/tests | 191 passed (was 190; +1 preset region test) |
| ruff check | passed |
| flutter test (root) | 1280 passed (was 1236; +44) |
| dart analyze --fatal-infos | No issues found |
| Default scratch render vs images/*.png | 52 files, byte-identical after the values commit, the refactor commit and the feature commit |
| Refactor commit, midnight scratch render | no changed capture (both profiles byte-identical, PD-07) |
| CHORE_16_02 stat | only images/midnight/; `git log d5ad4cb..HEAD -- images ':!images/midnight'` empty |

## Midnight captures moved by the sheen and hairline

Only `restyles_dark.png` and `restyles_light.png` (CHORE_16_02, d878e80). Both opened and checked: in light the elevated card and the plain surface show the white to off-white sheen with the shadow and a faint hairline; in dark the elevated card and surface show the hairline on the flat card color. No other midnight demo capture shows an elevated surface.

## Deviations from Plan

**1. [Rule 1 - Bug] Existing tests tied to the old token shape.** Adding the two keys broke `test_color_roles_tokens_are_a_dark_light_pair`, `test_committed_gradients_region_is_one_line` (renamed `..._lists_every_gradient`) and `scaffold_tokens_parity_test.dart` (dark colorRoles region now ends with a null `surfaceEdge`). Updated them in the values commit.

**2. [Rule 1 - Bug] `scaffold_card_test` asserted the widget parameter.** The elevated-variant test read `surface.color` equal to the card color; after the refactor the parameter is null by design. It now asserts `surface.color` is null and checks the rendered decoration color. Updated in the refactor commit.

**3. [Rule 3 - Blocking] palette_contrast_test key coverage.** The test required the classified role keys to equal both the dark and light token regions; the light default region cannot hold a null key. Light keys are now the class keys minus the keys null in dark (`_nullableKeys`).

**4. Extra tests beyond the list.** A pytest case for the empty dark and one-entry light gradients preset regions; a surfaceEdge polarity test in palette_contrast_test; a layout-size test for the hairline and the sheen; a Material-elevation-branch sheen test. `dart format` reflowed a few pre-existing lines in the touched test files.

Otherwise the plan ran as written.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust boundary.

## Self-Check: PASSED

22633f6, 1db98c5, f1b2611 and d878e80 exist on develop. `this.surfaceSheen,` and `this.surfaceEdge,` are in the generated regions; `lightScaffoldGradients` is in lib/theme/presets/midnight_tokens.dart; `surfaceSheen` and `surfaceEdge` are read in lib/components/scaffold_surface.dart; the elevated variant in templates/components/card.dart.jinja2 no longer passes a color.
