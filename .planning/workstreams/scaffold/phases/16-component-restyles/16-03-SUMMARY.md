---
phase: 16-component-restyles
plan: 03
subsystem: theme-and-components
tags: [theme-extension, pressable, hover, midnight, captures]
requires:
  - "16-02 (surface edge, sheen, restyles capture)"
provides:
  - "ScaffoldColorRoles.hoverFill and hoverEdge (Color?, null by default)"
  - "ScaffoldPressable.borderRadius (optional, additive)"
  - "Midnight hoverFill 0x1414C8FF and hoverEdge 0x3D14C8FF in both modes"
affects: [16-05]
key-files:
  modified:
    - design_tokens.json
    - tokens/midnight.json
    - lib/theme/scaffold_color_roles.dart
    - lib/theme/presets/midnight_tokens.dart
    - lib/components/scaffold_pressable.dart
    - templates/components/card.dart.jinja2
    - lib/components/scaffold_card.dart
    - lib/components/media_card.dart
    - lib/components/scaffold_chip.dart
    - lib/components/scaffold_selectable_surface.dart
    - tools/tests/test_theme_defaults.py
    - test/theme/scaffold_color_roles_test.dart
    - test/theme/midnight_token_map_test.dart
    - test/theme/palette_contrast_test.dart
    - test/theme/scaffold_tokens_parity_test.dart
    - test/components/scaffold_pressable_test.dart
    - test/components/scaffold_card_test.dart
    - test/components/media_card_test.dart
    - test/components/scaffold_chip_test.dart
    - test/components/scaffold_selectable_surface_test.dart
    - images/midnight/restyles_dark.png
    - images/midnight/restyles_light.png
key-decisions:
  - "Hover is value-driven: when colorRoles.hoverFill is null the pressable keeps today's 8% textPrimary layer; when set it paints hoverFill plus an optional 1 px hoverEdge border clipped to borderRadius, and pressed still adds the 12% textPrimary layer."
  - "Midnight hoverFill is 8% accent (0x14), not the 12% (0x1F) in the value table: 12% pushed textSecondary below 4.5:1 on midnight surfaces."
requirements-completed: [RST-01]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 36000
  tasks: 3
  commits: 4
---

# Phase 16 Plan 03: Pressable hover treatment Summary

Under midnight a hovered pressable now paints the accent tint and a 1 px accent hairline with no geometry change; the four rounded consumers clip it to their own corner radius. Default theme rendering is unchanged.

## Commits

| SHA | Content |
|---|---|
| 22fa3a8 | feat(16-03): themed hover tint and edge on pressables (RST-01) |
| 98498eb | feat(16-03): rounded pressables clip the hover treatment (RST-01) |
| 8edd140 | chore(16-03): re-baseline midnight captures after the hover treatment (RST-01); CHORE_16_03 |

## Verification

| Check | Result |
|---|---|
| theme_defaults, theme_presets, composites generators `--check` | exit 0 |
| pytest tools/tests | 191 passed (unchanged) |
| flutter test (root) | 1322 passed (was 1280; +42) |
| dart analyze --fatal-infos | No issues found |
| ruff | not run: not installed in this shell |
| Default scratch render vs images/*.png | 52 files, byte-identical after each feature commit |
| CHORE_16_03 stat | only images/midnight/restyles_dark.png and restyles_light.png; `git log d5ad4cb..HEAD -- images ':!images/midnight'` empty |

## Midnight captures moved

Only `restyles_dark.png` and `restyles_light.png`. Both opened: the hovered "Tappable card" shows the accent tint with a rounded accent edge that follows the card outline, in dark and in light.

## Pressable call sites left square

These keep a rectangular hover edge under midnight (no radius passed): scaffold_disclosure, scaffold_code_block, scaffold_state_view (generated from state.dart.jinja2), the copy buttons, media_controls and wallet_connect_sheet.

## Deviations from Plan

**1. [Rule 1 - Bug] hoverFill value lowered from 0x1F to 0x14.** The plan table value 0x1F14C8FF (12%) failed the plan's own contrast gate: textSecondary fell to 4.30:1 on midnight dark surfaces and 4.46:1 on midnight light surfaceBase. 0x1A (10%) still failed at 4.48:1 on dark. 0x14 (8%) passes both modes at 4.5:1. Per the plan, the value changed, the threshold did not. The acceptance grep for `hoverFill: Color(0x1F14C8FF)` therefore matches `0x1414C8FF` instead (2 occurrences). hoverEdge keeps 0x3D14C8FF.

**2. [Rule 1 - Bug] Existing tests tied to the old token shape.** `test_color_roles_tokens_are_a_dark_light_pair` and `scaffold_tokens_parity_test.dart` now expect `hoverFill` and `hoverEdge` as null keys after `surfaceEdge` in the dark region. The midnight token-map test gained two rows and field readers.

**3. Formatting.** `dart format` on `scaffold_color_roles_test.dart` and `palette_contrast_test.dart` reflowed some pre-existing lines. For `media_card_test`, `scaffold_chip_test`, `media_card.dart` and `scaffold_chip.dart` the reflow was undone so only the intended lines changed.

Otherwise the plan ran as written.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust boundary.

## Self-Check: PASSED

22fa3a8, 98498eb, 8edd140 and f486985 (refactor, reads roles via context.colorRoles) exist on develop. `this.hoverFill,` and `this.hoverEdge,` are in the generated region of lib/theme/scaffold_color_roles.dart; `hoverFill: Color(0x1414C8FF)` appears twice in lib/theme/presets/midnight_tokens.dart; ``context.colorRoles.hoverFill` is read in lib/components/scaffold_pressable.dart; card.dart.jinja2 passes `borderRadius: radius`.
