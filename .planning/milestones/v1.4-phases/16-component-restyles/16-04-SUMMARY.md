---
phase: 16-component-restyles
plan: 04
subsystem: theme-and-components
tags: [theme-extension, shapes, text-field, midnight, captures]
requires:
  - "16-03 (hover treatment, restyles capture)"
provides:
  - "ScaffoldShapes theme extension (inputFocusedBorderWidth, double?, null by default) generated from design_tokens.json scaffold.shapes"
  - "context.shapes getter falling back to ScaffoldShapes.defaultShapes"
  - "Midnight.shapes (inputFocusedBorderWidth 2.0), registered in both modes"
affects: [16-05, 16-06]
key-files:
  created:
    - lib/theme/scaffold_shapes.dart
    - test/theme/scaffold_shapes_test.dart
  modified:
    - design_tokens.json
    - tokens/midnight.json
    - tools/scaffold_codegen/generators/theme_defaults.py
    - tools/scaffold_codegen/generators/theme_presets.py
    - tools/tests/test_theme_defaults.py
    - tools/tests/test_theme_presets.py
    - lib/theme/scaffold_theme.dart
    - lib/frontend_scaffold.dart
    - lib/theme/presets/midnight_tokens.dart
    - lib/theme/presets/midnight_theme.dart
    - lib/components/text_entry_field_widget.dart
    - test/theme/consumer_contract_test.dart
    - test/theme/midnight_token_map_test.dart
    - test/theme/midnight_theme_test.dart
    - test/components/text_entry_field_widget_test.dart
    - images/midnight/restyles_dark.png
    - images/midnight/restyles_light.png
key-decisions:
  - "ScaffoldShapes has one instance shared by both modes, like ScaffoldDimens; it is not added to scaffoldThemeExtensions."
  - "Midnight keeps accentOnSurface as the focused border color and takes only the 2 px width (PD-05)."
requirements-completed: [RST-01]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 5400
  tasks: 3
  commits: 3
---

# Phase 16 Plan 04: ScaffoldShapes and the focused field border Summary

Component geometry is now themeable through a generated `ScaffoldShapes` extension with null defaults, and the midnight preset draws the focused text field border at 2 px in `accentOnSurface`. The default theme still draws 1 px.

## Commits

| SHA | Content |
|---|---|
| d02e839 | feat(16-04): ScaffoldShapes theme extension for component geometry (RST-01) |
| 332cf56 | feat(16-04): focused text field border width from ScaffoldShapes (RST-01) |
| 2e59178 | chore(16-04): re-baseline midnight captures after the focused field border (RST-01); CHORE_16_04 |

## Verification

| Check | Result |
|---|---|
| theme_defaults, theme_presets `--check`; composites runner then `git status --porcelain -- lib/` | exit 0; only the intended files changed |
| pytest tools/tests | 193 passed (was 191; +2) |
| ruff check | All checks passed |
| flutter test (root) | 1337 passed (was 1322; +15) |
| dart analyze --fatal-infos | No issues found |
| Default scratch render vs images/*.png | 52 files, byte-identical after both feature commits |
| Midnight scratch render | 54 files; after the widget commit only restyles_dark.png and restyles_light.png changed |
| scaffold_palette.dart, scaffold_dimens.dart vs d5ad4cb | empty diff; scaffoldThemeExtensions still two entries |
| CHORE_16_04 stat | only the two restyles PNGs; `git log d5ad4cb..HEAD -- images ':!images/midnight'` empty |

## Midnight captures moved

Only `restyles_dark.png` and `restyles_light.png`. Both opened: the focused "Enter a name" field shows a 2 px border, accent blue in dark and the darker accentOnSurface teal in light.

## Deviations from Plan

None. The plan ran as written.

Environment notes: `theme_defaults.py` and a few test files have CRLF line endings in the working copy (git normalizes them to LF through `.gitattributes`), so scripted edits there matched on CRLF. ruff was missing from the first shell check but version 0.6.8 was already installed in this one.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust boundary. T-16-10, T-16-11 and T-16-12 mitigations hold: frozen palette, dimens and extension list are unchanged, the new regions are covered by both `--check` runs and pytest, and CHORE_16_04 is recorded.

## Self-Check: PASSED

d02e839, 332cf56 and 2e59178 exist on develop. `export 'theme/scaffold_shapes.dart';` appears once in lib/frontend_scaffold.dart, `this.inputFocusedBorderWidth,` once in lib/theme/scaffold_shapes.dart, `inputFocusedBorderWidth: 2.0,` once in lib/theme/presets/midnight_tokens.dart, and `shapes.inputFocusedBorderWidth` once in lib/components/text_entry_field_widget.dart.
