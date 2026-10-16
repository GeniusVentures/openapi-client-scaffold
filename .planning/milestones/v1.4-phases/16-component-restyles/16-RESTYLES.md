# Phase 16: Component restyle record

Disposition of every candidate R1-R15 from `research/FEATURES.md` section 5, the deviations from the
source and from FEATURES, every theme field this phase added, and the commits allowed to touch
`images/midnight/` (input for Phase 17 GATE-01).

## Candidate dispositions

| Cand | Candidate | Disposition | Where | Theme fields used | Captures that show it |
|---|---|---|---|---|---|
| R1 | Card: fill, 1 px hairline, custom BoxShadow instead of Material elevation | Shipped in this phase | 16-01 b1c05f1 (shadow path), 16-02 f1b2611 (sheen and hairline) | `ScaffoldShadows.elevated`, `ScaffoldGradients.surfaceSheen`, `ScaffoldColorRoles.surfaceEdge` | `restyles_dark`, `restyles_light` |
| R2 | Hover: brand tint fill and 1 px edge, no geometry change | Shipped in this phase | 16-03 22fa3a8 (pressable), 98498eb (rounded consumers clip it) | `ScaffoldColorRoles.hoverFill`, `hoverEdge` | `restyles_dark`, `restyles_light` |
| R3 | Outlined primary button (ActionButton) | Shipped in this phase, ActionButton only | 16-07 7645aed | `ScaffoldColorRoles.actionIcon`, `actionDisabledFill`, `actionDisabledForeground` | `action_button_dark`, `action_button_light` |
| R4 | Gradient CTA fill and glow | Not built (PD-08) | none | none | none |
| R5 | Input: focused border | Shipped in this phase for the focused border; the rest of R5 shipped by Phases 13-15 tokens | 16-04 d02e839, 332cf56 | `ScaffoldShapes.inputFocusedBorderWidth` (color stays `accentOnSurface`) | `restyles_dark`, `restyles_light` |
| R6 | Sheets and drawers: fill, radius, scrim | Shipped in this phase | 16-05 1df092e (panel refactor), 719b785 | `ScaffoldShapes.sheetRadius`, `ScaffoldColorRoles.scrim`, `surfaceEdge`, midnight `deepBlueTertiary` | `bottom_drawer_{dark,light}`, `wallet_connect_sheet_{dark,light}` |
| R7 | Dividers | Shipped earlier | Phase 15 (preset `dividerTheme`) | none | n/a |
| R8 | Selection and focus use the accent role, not green | Shipped in this phase for the fill sites; foreground sites shipped in Phase 14-04 | 16-06 5c48dad | `ScaffoldColorRoles.accent` | none moved (refactor, byte-identical) |
| R9 | Tabular figures on numbers | Shipped in this phase | 16-07 0eddc59 | `ScaffoldTypography.numericStyle` | `restyles_dark`, `restyles_light` |
| R10 | Mono family token | Shipped earlier | Phase 13 `monoFontFamily`, Phase 15 value | `ScaffoldTypography.monoFontFamily` | n/a |
| R11 | Selection checkbox | Shipped in this phase, checkbox only | 16-06 fbb7b68 | `ScaffoldColorRoles.checkboxFill`, `checkboxMark`, `checkboxEdge`, `ScaffoldShapes.checkboxRadius`, `checkboxBorderWidth` | `restyles_dark`, `restyles_light` |
| R12 | Page canvas: wash, radial glow, noise | Not built (PD-08) | none | none | none |
| R13 | Themed toast and dialog shadow | Shipped earlier | Phase 13 toast reads `context.shadows`, Phase 15 values; the toast already equals the source recipe | `ScaffoldShadows.card` | n/a |
| R14 | `ThemeData` assembly | Shipped earlier | Phase 15 `midnightTheme` | none | all midnight captures |
| R15 | Wallet `ColorScheme` outline and error | Shipped earlier | Phase 15 | none | all midnight captures |

### Not built, with reasons (PD-08)

- R4 gradient CTA: no scaffold component carries that look. The source keeps ActionButton and
  StringButton flat, so it would be a new widget, not a restyle.
- R12 page canvas: no scaffold component paints the page, and `midnightTheme` already sets
  `scaffoldBackgroundColor`.

### Partial notes

- StringButton (R3): unchanged; the source button is identical to the scaffold one.
- Radio and toggle (R11): unchanged; the source styles no radio or toggle, and the toggle track is
  already a pill. The radio and toggle files are empty diffs against d5ad4cb.
- ActionButton glyph size and padding (R3): layout values, not style values. The scaffold glyph ratio
  stays 0.38 (source 0.45) and the padding is unchanged.
- Pressables left with square hover edges (16-03): `scaffold_disclosure`, `scaffold_code_block`,
  `scaffold_state_view` (generated from `state.dart.jinja2`), the copy buttons, `media_controls` and
  `wallet_connect_sheet`. They pass no `borderRadius`, so the midnight hover edge is rectangular.
- R8: a search of `lib/components` and `templates/components` found no reads of `lightGreenPrimary`
  or `lightGreenSecondary` beyond the three fill sites (badge, chart range band, selectable-surface
  tint).

## Deviations from the source and from FEATURES (PD-05)

- Drawer fill: the midnight drawer panel uses the card fill, as the source does. FEATURES R6 named
  `surfaceMenu`. Midnight `deepBlueTertiary` moved from `0xFF171A21` to `0xFF0C0E14` (dark) and from
  `0xFFEFF2F6` to `0xFFFFFFFF` (light). The wallet connect sheet moved with it.
- Scrim value: `0x99000000` (`MidnightColors.scrim`), carried by `ScaffoldColorRoles.scrim`; the
  default theme keeps `Colors.black87`.
- Checkbox mark: `textOnAccent` `0xFF000B18` (7.74:1 on the fill), not the source's white tick
  (2.56:1). The indeterminate state is filled too when `checkboxFill` is set, so the dark dash stays
  visible in midnight dark.
- Focused field border: the width is 2 px from `ScaffoldShapes`; the color stays `accentOnSurface`
  rather than the source's brand primary, which fails 3:1 on the light surfaces.
- Hover fill: 8% accent (`0x1414C8FF`), not the 12% (`0x1F`) of the value table. 12% and 10% pushed
  `textSecondary` below 4.5:1 on midnight surfaces (4.30:1 and 4.48:1). The threshold held; the value
  changed.
- Dark sheen: left unset. The source dark sheen is two equal stops, which is flat on purpose.

## Theme fields added

Defaults come from `design_tokens.json` (`null` means the widget keeps its built-in look); midnight
values come from `tokens/midnight.json`.

| Field | Default | Midnight dark | Midnight light | Plan |
|---|---|---|---|---|
| `ScaffoldShadows.elevated` | null | `0x59000000`, blur 16.0, offset (0.0, 4.0) | `0x1F000000`, blur 16.0, offset (0.0, 4.0) | 16-01 |
| `ScaffoldGradients.surfaceSheen` | null | unset (null) | linear topCenter to bottomCenter, `0xFFFFFFFF` to `0xFFF5F7FA` | 16-02 |
| `ScaffoldColorRoles.surfaceEdge` | null | `0x1FFFFFFF` | `0x1F10131A` | 16-02 |
| `ScaffoldColorRoles.hoverFill` | null | `0x1414C8FF` | `0x1414C8FF` | 16-03 |
| `ScaffoldColorRoles.hoverEdge` | null | `0x3D14C8FF` | `0x3D14C8FF` | 16-03 |
| `ScaffoldShapes.inputFocusedBorderWidth` | null | 2.0 | 2.0 | 16-04 |
| `ScaffoldShapes.sheetRadius` | null | 24.0 | 24.0 | 16-05 |
| `ScaffoldColorRoles.scrim` | null | `0x99000000` | `0x99000000` | 16-05 |
| `ScaffoldPalette.deepBlueTertiary` (midnight value change only) | unchanged | `0xFF0C0E14` (was `0xFF171A21`) | `0xFFFFFFFF` (was `0xFFEFF2F6`) | 16-05 |
| `ScaffoldColorRoles.checkboxFill` | null | `0xFF0AAEE6` | `0xFF0AAEE6` | 16-06 |
| `ScaffoldColorRoles.checkboxMark` | null | `0xFF000B18` | `0xFF000B18` | 16-06 |
| `ScaffoldColorRoles.checkboxEdge` | null | `0xFF0AAEE6` | `0xFF0A6885` | 16-06 |
| `ScaffoldShapes.checkboxRadius` | null | 4.0 | 4.0 | 16-06 |
| `ScaffoldShapes.checkboxBorderWidth` | null | 1.5 | 1.5 | 16-06 |
| `ScaffoldColorRoles.actionIcon` | null | `0xFF0AAEE6` | `0xFF0A6885` | 16-07 |
| `ScaffoldColorRoles.actionDisabledFill` | null | `0xFF06080C` | `0xFFCFD4DB` | 16-07 |
| `ScaffoldColorRoles.actionDisabledForeground` | null | `0x8AFFFFFF` | `0x8A10131A` | 16-07 |
| `ScaffoldTypography.numericStyle` | null | `{"tabularFigures": true}` | same instance | 16-07 |

New generated extension: `ScaffoldShapes` (`lib/theme/scaffold_shapes.dart`), fed by `scaffold.shapes`,
reached through `context.shapes`, exported from the barrel, not listed in `scaffoldThemeExtensions`.
New generated midnight consts: `Midnight.darkScaffoldGradients`, `Midnight.lightScaffoldGradients`
and `Midnight.shapes`, all registered by `midnightExtensions`. New public widget:
`ResponsiveDrawerPanel`. New optional parameter: `ScaffoldPressable.borderRadius`.

## Commits that touched images/midnight/

Output of `git log --format='%h %s' d5ad4cb..HEAD -- images/midnight` at the 16-07 head. Each is an
isolated `chore(16-NN)` commit touching only `images/midnight/`. These are the commits Phase 17
GATE-01 may allow to move midnight captures.

| SHA | Subject |
|---|---|
| 8ba7e91 | chore(16-01): re-baseline midnight captures after the elevated shadow (RST-01) |
| d878e80 | chore(16-02): re-baseline midnight captures after the card sheen and hairline (RST-01) |
| 8edd140 | chore(16-03): re-baseline midnight captures after the hover treatment (RST-01) |
| 2e59178 | chore(16-04): re-baseline midnight captures after the focused field border (RST-01) |
| dfe9732 | chore(16-05): re-baseline midnight captures after the drawer restyle (RST-01) |
| 292d5ba | chore(16-06): re-baseline midnight captures after the checkbox restyle (RST-01) |
| 75f7a04 | chore(16-07): re-baseline midnight captures after the ActionButton restyle (RST-01) |
| 5d783f3 | chore(16-07): re-baseline midnight captures after tabular figures (RST-01) |

Plan 16-07 made two chore commits, so a gate that expects one chore commit per plan must allow both.
Midnight capture count: 54 PNGs (the 52 demo captures plus `restyles_dark.png` and
`restyles_light.png`, added by 8ba7e91). Default captures under `images/`: 52, none changed since
d5ad4cb.
