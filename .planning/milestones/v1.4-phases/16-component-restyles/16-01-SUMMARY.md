---
phase: 16-component-restyles
plan: 01
subsystem: theme-and-components
tags: [theme-extension, generator, midnight, captures]
requires:
  - "15 (midnight preset, theme generators)"
provides:
  - "Theme generators accept null in a params region"
  - "ScaffoldShadows.elevated (List<BoxShadow>?, null by default, midnight value from tokens/midnight.json)"
  - "ScaffoldSurface token path: themed shadow when set, Material elevation otherwise"
  - "Midnight-only restyles capture (_RestylesCapture) and images/midnight/restyles_{dark,light}.png"
affects: [16-02, 16-03, 16-04, 16-05, 16-06, 16-07, 16-08]
key-files:
  created:
    - images/midnight/restyles_dark.png
    - images/midnight/restyles_light.png
  modified:
    - tools/scaffold_codegen/generators/theme_defaults.py
    - tools/tests/test_theme_defaults.py
    - design_tokens.json
    - tokens/midnight.json
    - lib/theme/scaffold_shadows.dart
    - lib/theme/presets/midnight_tokens.dart
    - lib/components/scaffold_surface.dart
    - test/theme/scaffold_shadows_test.dart
    - test/theme/midnight_token_map_test.dart
    - test/components/scaffold_surface_test.dart
    - test/components/scaffold_card_test.dart
    - example/test/capture_images_test.dart
key-decisions:
  - "Null handling lives in render_regions, before the encoders: every literal kind yields None, params regions render `this.name,`, args regions still raise naming <region>.<name>."
  - "ScaffoldSurface switches on context.shadows.elevated, never on the preset. A registered ScaffoldShadows(elevated: ...) on any theme gets the BoxShadow path."
requirements-completed: [RST-01]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 14000
  tasks: 3
  commits: 3
---

# Phase 16 Plan 01: Elevated surface shadow tracer Summary

One themed value, the elevated shadow, now flows from the token files through the generators and ScaffoldShadows into ScaffoldSurface and ScaffoldCard; default rendering is untouched, and the midnight-only restyles capture exists as the baseline for later plans.

## Commits

| SHA | Content |
|---|---|
| b1c05f1 | feat(16-01): elevated surfaces draw the themed shadow when set (RST-01) |
| 0d71055 | test(16-01): midnight-only restyles capture (RST-01) |
| 8ba7e91 | chore(16-01): re-baseline midnight captures after the elevated shadow (RST-01); CHORE_16_01 |

## Verification

| Check | Result |
|---|---|
| theme_defaults --check, theme_presets --check, generators runner | exit 0, lib/ clean after regeneration |
| pytest tools/tests | 190 passed (was 182; +8 null-handling cases) |
| ruff check | passed |
| flutter test (root) | 1236 passed (was 1225; +11) |
| dart analyze --fatal-infos, root and example/ | No issues found |
| Default scratch render vs images/*.png | 52 files, byte-identical, no DIFF |
| Midnight scratch render | 54 PNGs |
| CHORE_16_01 stat | only images/midnight/ (2 new files); `git log d5ad4cb..HEAD -- images ':!images/midnight'` empty |

## Midnight captures moved by the shadow change

None. No existing midnight demo capture shows an elevated card or surface in the visible frame, so only the two new restyles PNGs are in CHORE_16_01. The new captures were opened and checked: real glyphs, hovered tappable card, focused field with the accent border, checked/unchecked/indeterminate checkboxes, radio, toggle and the formatted number all sit inside the frame. In the midnight dark capture the elevated card fill equals the page color, so its shadow is the visible edge.

## Deviations from Plan

**1. [Rule 3 - Blocking] _RestylesCapture wraps itself in a Scaffold.** The first render had a white page and Ahem boxes for card text, because the capture harness does not supply the page color or Material text style the demos get from their own Scaffold. Added a Scaffold inside the widget, as each demo has. Commit 0d71055.

**2. [Rule 3 - Blocking] `ui.PointerDeviceKind`.** The harness imports dart:ui with a prefix, so the mouse kind is `ui.PointerDeviceKind.mouse`.

**3. Existing pytest updated.** `test_scaffold_group_order_keeps_existing_keys_first` asserted dark shadows equal light shadows; it now compares `card` and asserts `elevated` is null in dark and absent in light (PD-01). Same commit as the feature.

Otherwise the plan ran as written.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust boundary.

## Self-Check: PASSED

b1c05f1, 0d71055 and 8ba7e91 exist on develop; images/midnight/restyles_dark.png and restyles_light.png are tracked; the generated region of lib/theme/scaffold_shadows.dart holds `this.elevated,` (the grep count is 2 because copyWith also reads `this.elevated,`), `elevated: [BoxShadow` twice in lib/theme/presets/midnight_tokens.dart, `shadows.elevated` in lib/components/scaffold_surface.dart.
