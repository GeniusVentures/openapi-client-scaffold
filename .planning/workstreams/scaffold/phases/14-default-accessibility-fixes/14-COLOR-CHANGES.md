# Phase 14: Default color changes

Record of every default color the scaffold changed in Phase 14 (roadmap SC5), for the Phase 17
GCS notice (GATE-02) and the capture gate (GATE-01). PRE is `07a7808` (the Phase 13 head).
Values come from the 14-02, 14-03 and 14-05 SUMMARYs and were checked against
`git show <sha>:design_tokens.json`. Ratios are on the worst surface of the mode, from the same
math as `test/theme/wcag_contrast.dart`.

## Changed default colors

Token paths are in `design_tokens.json`. Each Dart field is a generated default in
`lib/theme/scaffold_palette.dart` or `lib/theme/scaffold_color_roles.dart`.

| Token path | Dart field | Mode | Old | New | Worst ratio before -> after | Commit |
|---|---|---|---|---|---|---|
| scaffold.palette.light.gray500 | `ScaffoldPalette.lightPalette.gray500` | light | 0xFF73788C | 0xFF65697B | 3.73 -> 4.63 | 0f79aaa |
| scaffold.palette.dark.gray500 | `ScaffoldPalette.defaultPalette.gray500` | dark | 0xFF73788C | 0xFF818698 | 3.84 -> 4.64 | 0f79aaa |
| scaffold.palette.light.statusSuccess | `ScaffoldPalette.lightPalette.statusSuccess` | light | 0xFF0AA06B | 0xFF087951 | 2.86 -> 4.62 | 0f79aaa |
| scaffold.palette.light.statusError | `ScaffoldPalette.lightPalette.statusError` | light | 0xFFD13438 | 0xFFC82D31 | 4.19 -> 4.61 | 0f79aaa |
| scaffold.palette.light.statusWarningText | `ScaffoldPalette.lightPalette.statusWarningText` | light | 0xFF9A6A00 | 0xFF8D6100 | 4.03 -> 4.65 | 0f79aaa |
| scaffold.palette.light.focusRingColor | `ScaffoldPalette.lightPalette.focusRingColor` | light | 0xFF00EAAE | 0xFF00956F | 1.33 -> 3.23 | 0f79aaa |
| scaffold.palette.light.borderGrey | `ScaffoldPalette.lightPalette.borderGrey` | light | 0x1F000000 | 0x73000000 | 1.31 -> 3.27 | 0f79aaa |
| scaffold.palette.dark.borderGrey | `ScaffoldPalette.defaultPalette.borderGrey` | dark | 0x4DFFFFFF | 0x5CFFFFFF | 2.59 -> 3.25 | 0f79aaa |
| scaffold.colorRoles.light.borderControl | `lightColorRoles.borderControl` | light | 0x1F000000 | 0x73000000 | equals light borderGrey (1.31 -> 3.27) | 0f79aaa |
| scaffold.colorRoles.dark.borderControl | `ScaffoldColorRoles.defaultColorRoles.borderControl` | dark | 0x4DFFFFFF | 0x5CFFFFFF | equals dark borderGrey (2.59 -> 3.25) | 0f79aaa |
| scaffold.colorRoles.light.inputForeground | `lightColorRoles.inputForeground` | light | 0xFFFFFFFF | 0xFF17191E | 1.11 -> 15.81 (on grayPrimary) | 3ae320d |
| scaffold.colorRoles.light.sheetForeground | `lightColorRoles.sheetForeground` | light | 0xFFFFFFFF | 0xFF17191E | 1.18 -> 14.96 (on deepBlueTertiary) | 3ae320d |
| scaffold.colorRoles.light.sheetDivider | `lightColorRoles.sheetDivider` | light | 0x1FFFFFFF | 0x1F000000 | decorative, see note | 3ae320d |
| scaffold.colorRoles.light.accentOnSurface | `lightColorRoles.accentOnSurface` | light | 0xFF00EAAE | 0xFF00956F | 1.33 -> 3.23 (white 1.57 -> 3.80) | b673be7 |
| scaffold.colorRoles.light.accentSecondaryOnSurface | `lightColorRoles.accentSecondaryOnSurface` | light | 0xFF01CC95 | 0xFF01956D | 1.77 -> 3.23 (white 2.08 -> 3.80) | b673be7 |
| scaffold.colorRoles.light.accentTextOnSurface | `lightColorRoles.accentTextOnSurface` | light | 0xFF00EAAE | 0xFF00795A | 1.33 -> 4.60 (white 1.57 -> 5.41) | b673be7 |
| ScaffoldColorRoles.fallbackFor (behavior) | `ScaffoldColorRoles.fallbackFor(palette, brightness)` | light | light foreground accents read the palette accent (lightGreenPrimary, lightGreenSecondary) | light foreground accents come from `lightColorRoles`; dark still reads the palette | follows the three accent rows above | b673be7 |
| ScaffoldColorRoles.fallbackForPalette (behavior) | `context.colorRoles` with no registered roles | both | chose light or dark role tokens from `ThemeData.brightness` | chooses by the palette surfaces in use: `inputForeground` by the luminance of `palette.grayPrimary`, sheet roles by `palette.deepBlueTertiary`, accents by the drawer surface | a light `ThemeData` with no palette keeps readable (dark-surface) foregrounds | 7c175ed |

The last row is an unplanned fix found during 14-03 and shipped in 14-04. `fallbackFor` keeps its
signature and meaning; `fallbackForPalette` is new and is what `context.colorRoles` calls. It
produced no capture commit because it changes no rendered image in the demos.

Note on `sheetDivider`: the light divider is decorative. A divider identifies no component or
state, so it is exempt from WCAG 1.4.11. Instead of a ratio the record keeps its polarity: a dark
hairline on the light panel instead of an invisible white one. `palette_contrast_test.dart`
asserts this (darker than the panel in light, lighter in dark).

New tokens (additions, not changes): `scaffold.colorRoles.dark.accentSecondaryOnSurface`
(0xFF01CC95) and `scaffold.colorRoles.dark.accentTextOnSurface` (0xFF00EAAE) were added in
4d813e1. Both equal the colors the sites drew before. The light counterparts are the 14-05 rows
above, which were added in 4d813e1 at the old accent values and changed in b673be7.

## What did not change

- The `ScaffoldColors` constants (`gray500`, `borderGrey`, `lightGreenPrimary` and the rest) keep
  their values. Code that references them directly sees no change.
- Constructor and field names of `ScaffoldPalette` and `ScaffoldColorRoles`, and
  `lib/theme/scaffold_colors.dart` itself (no diff since PRE).
- Dark input, sheet and accent roles. The dark `accentSecondaryOnSurface` and
  `accentTextOnSurface` equal the colors those sites drew before.
- Accent fills: palette `lightGreenPrimary` and `lightGreenSecondary`. The only widget reads left
  are the badge count and text fill, the chart range selector 12% band, and the selectable
  surface 12% wash.
- The M3 keys in `design_tokens.json` (`color`, `typography`, `shape`, `elevation`) and the
  `tools/tests/fixtures/m3_tokens.css` snapshot. Everything outside `scaffold` equals PRE.
- Widget and template code, except the pixel-neutral 4d813e1 refactor that moved accent
  foregrounds onto color roles.

## Sanctioned capture commits

`git log PRE..HEAD -- images/` lists exactly these five commits, oldest first. Each holds only
PNGs under `images/`. No other Phase 14 commit touches `images/`. Each one except BASELINE has as
its parent the code or token commit it reflects. 14-04 (7c175ed, 4d813e1) produced no capture
commit because neither changed a rendered pixel.

| Name | SHA | Subject | Parent (follows) | PNGs moved |
|---|---|---|---|---|
| BASELINE | d9342ff | chore(14-01): re-render captures on this machine, no code change | PRE 07a7808 | all 52 (machine re-render, rasterization differs from the old machine) |
| COVERAGE_CAPTURES | b9145a8 | chore(14-01): re-baseline text field and drawer captures for the harness change | COVERAGE 20762f7 | text_entry_field_{dark,light}, bottom_drawer_{dark,light} |
| A11Y01_CAPTURES | f4207f7 | chore(14-02): re-baseline captures for A11Y-01 | A11Y01 0f79aaa | action_button_{dark,light}, text_entry_field_{dark,light}, chart_range_selector_light, chart_scrubber_{dark,light}, chip_light, toast_light, trace_list_light |
| A11Y02_CAPTURES | 015d521 | chore(14-03): re-baseline light text field and drawer captures for A11Y-02 | A11Y02 3ae320d | text_entry_field_light, bottom_drawer_light |
| ACCENT_CAPTURES | 4b406e5 | chore(14-05): re-baseline light captures for the accent fix | ACCENT_FIX b673be7 | action_button_light, chart_light, chart_range_selector_light, chart_scrubber_light, chip_light, disclosure_light, loading_light, markdown_to_spans_light, streaming_rich_text_light |

Other commits that Phase 17 may see between PRE and HEAD (none touches `images/`):
COVERAGE 20762f7, helper 6cf6f83, A11Y01 0f79aaa, A11Y02 3ae320d, UNREGISTERED_ROLES_FIX 7c175ed,
ACCENT_REFACTOR 4d813e1, ACCENT_FIX b673be7, plus the docs commits.

## Accent coverage

No accent contrast item is left open. 14-04 and 14-05 route non-text accent uses (icons, borders,
lines, dots, the focused text-field border) to the 3:1 roles `accentOnSurface` and
`accentSecondaryOnSurface`, and route accent text to the 4.5:1 role `accentTextOnSurface`. The
three text sites are the streaming rich text link, the streaming rich text citation marker, and
the search bar group label. Accent fills are unchanged.

In light mode the three roles are 0xFF00956F, 0xFF01956D and 0xFF00795A. `palette_contrast_test`
checks them on all four surfaces in both themes, on the static roles and through `fallbackFor`.

## GCS harness

Run at the phase head `d985ab36c7a00a36afc3c314e18365c1d9a0e003` with `gcs-check.sh`. Summary
lines, verbatim:

```
== scaffold at d985ab3
== SUMMARY ref=d985ab36c7a00a36afc3c314e18365c1d9a0e003
codegen failures (of 12): 0
pub get exit: 0
analyze:      53 error  | 53 issues found. (ran in 14.5s)
analyze issues in scaffold/example (baseline noise): 53
analyze issues in app code (lib/test): 0
test: 00:01 +60 ~1: All tests passed!
00:01 +60 ~1: All tests passed!
submodule restored to 8ada743
```

Result: codegen failures 0, pub get exit 0, 60 tests pass (1 skipped), 0 app-code analyze issues,
submodule restored. No GCS test fails, so there are no "GCS tests expecting old colors" and no
notice items from tests.

The scaffold/example issue count is 53, not the baseline 50. All 53 are in
`scaffold/example/test/capture_images_test.dart`. The 50 baseline issues are 25
`uri_does_not_exist` (example-package imports) and 25 `creation_with_non_type`. The 3 added
issues are `undefined_identifier` on `BottomDrawerDemo` at lines 749, 750 and 751, which are the
three uses 14-01 added to that file. They have the same cause as the baseline noise: the
`frontend_scaffold_example` package does not resolve inside GCS. They are accepted as the same
kind, in a file 14-01 changed.

GCS tests expecting old colors: none.
