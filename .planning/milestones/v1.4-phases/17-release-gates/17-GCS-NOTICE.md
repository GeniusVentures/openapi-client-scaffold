DRAFT, NOT SENT. The owner sends this to the GeniusCognitiveSystem team. Nothing has been posted, filed or committed in that repository.

# Notice for the GeniusCognitiveSystem team: scaffold v1.4 default color changes

Suggested subject: frontend_scaffold v1.4: some default colors changed to pass WCAG AA, no API changes

To: GeniusCognitiveSystem team

Tested against: scaffold `develop` at `f6b99d3`, 2026-10-16: 0 of 12 codegen failures, pub get exit 0, 0 app-code analyze issues, 60 tests passing.

## Summary

Scaffold v1.4 changes some default colors so the default light and dark palettes pass WCAG AA
(text 4.5:1, controls and focus indicators 3:1). No public API changed. Your light and dark themes
pick up every change below without a code change.

We built and tested GCS against the scaffold at `f6b99d3` with the consumer check harness
(`tools/consumer_check/gcs_check.sh`):

- Codegen of the chat components: 0 failures of 12.
- `flutter pub get`: exit 0.
- `flutter analyze`: 0 issues in GCS app code (lib and test).
- `flutter test`: 60 passed, 1 skipped, all tests passed.
- The submodule was put back on its original commit afterwards.

No GCS test expects the old colors.

## What changed

GCS registers `ScaffoldPalette.lightPalette` on its light theme and `ScaffoldPalette.defaultPalette`
on its dark theme, and registers no `ScaffoldColorRoles`. So GCS gets every palette change below, and
it gets the roles from `ScaffoldColorRoles.fallbackForPalette`, which is where the role changes reach it.

Light theme

| Token path | Dart field | Old | New | What you see |
|---|---|---|---|---|
| scaffold.palette.light.gray500 | `ScaffoldPalette.lightPalette.gray500` | 0xFF73788C | 0xFF65697B | Darker secondary gray text and icons (3.73 to 4.63) |
| scaffold.palette.light.statusSuccess | `ScaffoldPalette.lightPalette.statusSuccess` | 0xFF0AA06B | 0xFF087951 | Darker success green (2.86 to 4.62) |
| scaffold.palette.light.statusError | `ScaffoldPalette.lightPalette.statusError` | 0xFFD13438 | 0xFFC82D31 | Slightly darker error red (4.19 to 4.61) |
| scaffold.palette.light.statusWarningText | `ScaffoldPalette.lightPalette.statusWarningText` | 0xFF9A6A00 | 0xFF8D6100 | Slightly darker warning text (4.03 to 4.65) |
| scaffold.palette.light.focusRingColor | `ScaffoldPalette.lightPalette.focusRingColor` | 0xFF00EAAE | 0xFF00956F | Visible focus ring on light surfaces (1.33 to 3.23) |
| scaffold.palette.light.borderGrey | `ScaffoldPalette.lightPalette.borderGrey` | 0x1F000000 | 0x73000000 | Control borders are visible on light surfaces (1.31 to 3.27) |
| scaffold.colorRoles.light.borderControl | `lightColorRoles.borderControl` | 0x1F000000 | 0x73000000 | Same as light borderGrey |
| scaffold.colorRoles.light.inputForeground | `lightColorRoles.inputForeground` | 0xFFFFFFFF | 0xFF17191E | Typed text in light text fields is now dark, not white (1.11 to 15.81) |
| scaffold.colorRoles.light.sheetForeground | `lightColorRoles.sheetForeground` | 0xFFFFFFFF | 0xFF17191E | Text and icons on a light bottom drawer are dark (1.18 to 14.96) |
| scaffold.colorRoles.light.sheetDivider | `lightColorRoles.sheetDivider` | 0x1FFFFFFF | 0x1F000000 | Divider on a light drawer is a dark hairline, not invisible white |
| scaffold.colorRoles.light.accentOnSurface | `lightColorRoles.accentOnSurface` | 0xFF00EAAE | 0xFF00956F | Green icons, lines and borders are darker on light surfaces (1.33 to 3.23) |
| scaffold.colorRoles.light.accentSecondaryOnSurface | `lightColorRoles.accentSecondaryOnSurface` | 0xFF01CC95 | 0xFF01956D | Secondary green accents are darker on light surfaces (1.77 to 3.23) |
| scaffold.colorRoles.light.accentTextOnSurface | `lightColorRoles.accentTextOnSurface` | 0xFF00EAAE | 0xFF00795A | Green accent text (links, citation marker, group label) is darker on light surfaces (1.33 to 4.60) |

Dark theme

| Token path | Dart field | Old | New | What you see |
|---|---|---|---|---|
| scaffold.palette.dark.gray500 | `ScaffoldPalette.defaultPalette.gray500` | 0xFF73788C | 0xFF818698 | Lighter secondary gray text and icons (3.84 to 4.64) |
| scaffold.palette.dark.borderGrey | `ScaffoldPalette.defaultPalette.borderGrey` | 0x4DFFFFFF | 0x5CFFFFFF | Slightly stronger control borders (2.59 to 3.25) |
| scaffold.colorRoles.dark.borderControl | `ScaffoldColorRoles.defaultColorRoles.borderControl` | 0x4DFFFFFF | 0x5CFFFFFF | Same as dark borderGrey |

Ratios are on the worst surface of the mode.

Two behavior changes in how roles are chosen when an app registers no `ScaffoldColorRoles`:

- `ScaffoldColorRoles.fallbackFor(palette, brightness)`: in light mode the foreground accent roles
  now come from `lightColorRoles` (the three darker greens above). Before, they read the palette's
  bright green fill, which does not contrast with a light surface. In dark mode they still read the
  palette. The signature and meaning are unchanged.
- `ScaffoldColorRoles.fallbackForPalette(palette)` is new, and `context.colorRoles` calls it when no
  roles are registered. It chooses light or dark role tokens from the surfaces of the palette in
  use (input text by `grayPrimary`, sheet roles by `deepBlueTertiary`), not from
  `ThemeData.brightness`. A light `ThemeData` that registers no palette keeps readable foregrounds.
  For GCS the choice is the same as before, because its light theme registers the light palette and
  its dark theme registers the dark palette. GCS gets the new light roles in light mode and the
  dark roles, with the new `borderControl`, in dark mode.

## What did not change

- The `ScaffoldColors` constants (`gray500`, `borderGrey`, `lightGreenPrimary` and the rest). Code
  that references them directly sees no change.
- Constructor and field names of `ScaffoldPalette` and `ScaffoldColorRoles`, and `scaffoldThemeExtensions`.
- The M3 keys of `design_tokens.json` (`color`, `typography`, `shape`, `elevation`) and the CSS
  output the GCS templates read. The chat component codegen renders without change.
- Dark input, sheet and accent roles. The dark `accentSecondaryOnSurface` and
  `accentTextOnSurface` equal the colors those places drew before.
- Accent fills: palette `lightGreenPrimary` and `lightGreenSecondary`.

## New and opt-in: the midnight preset

The package ships a dark and light preset. It is not in the barrel, so an app that does not import
it sees no change. GCS does not import it, so nothing changes for GCS. To try it, deep-import it:

```dart
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';

MaterialApp(
  theme: midnightTheme(Brightness.light),
  darkTheme: midnightTheme(Brightness.dark),
);
```

`midnightTheme(brightness)` returns a full `ThemeData`. An app that builds its own `ThemeData`
can take only the scaffold extensions with `midnightExtensions(brightness)`. The preset's fonts
are not bundled; the app supplies them.

## Keeping the old look (not recommended)

The old values fail WCAG AA: for example light `gray500` was 3.73:1 and light `statusSuccess` was
2.86:1, both below the 4.5:1 minimum for text. If you still need the old look, register the old
values in `gcs_theme.dart`:

```dart
final lightPaletteOld = ScaffoldPalette.lightPalette.copyWith(
  gray500: const Color(0xFF73788C),
  statusSuccess: const Color(0xFF0AA06B),
  statusError: const Color(0xFFD13438),
  statusWarningText: const Color(0xFF9A6A00),
  focusRingColor: const Color(0xFF00EAAE),
  borderGrey: const Color(0x1F000000),
);

final darkPaletteOld = ScaffoldPalette.defaultPalette.copyWith(
  gray500: const Color(0xFF73788C),
  borderGrey: const Color(0x4DFFFFFF),
);

final lightRolesOld = ScaffoldColorRoles.lightColorRoles.copyWith(
  accentOnSurface: const Color(0xFF00EAAE),
  accentSecondaryOnSurface: const Color(0xFF01CC95),
  accentTextOnSurface: const Color(0xFF00EAAE),
  borderControl: const Color(0x1F000000),
  inputForeground: const Color(0xFFFFFFFF),
  sheetForeground: const Color(0xFFFFFFFF),
  sheetDivider: const Color(0x1FFFFFFF),
);

final darkRolesOld = ScaffoldColorRoles.defaultColorRoles.copyWith(
  borderControl: const Color(0x4DFFFFFF),
);
```

Then put `lightPaletteOld` and `lightRolesOld` in the `extensions` list of `GcsTheme.light`, and
`darkPaletteOld` and `darkRolesOld` in the list of `GcsTheme.dark`. Import
`package:frontend_scaffold/theme/scaffold_color_roles.dart` next to the palette import.

Registering roles also replaces the fallback. Pixel parity with pre-v1.4 is close, but not
guaranteed for cases that relied on the old unregistered-role fallback.

We compiled this snippet against the scaffold at `f6b99d3` and checked each overridden field
against the old value in a scratch test.

## Notes

- To take the change, bump the `src/app/scaffold` submodule. Pin it to the tested commit
  `f6b99d3`, or to `main` after the v1.4 merge.
- `flutter analyze` in GCS reports 57 errors under `scaffold/example`. They come from the example
  package not resolving inside GCS (missing imports and undefined types in
  `scaffold/example/test/capture_images_test.dart`), they are the same kind of issue as the 50 that
  existed before v1.4 (the extra 7 come from new demos in that example test file), and none is in
  GCS code. Excluding `scaffold/example` from GCS analysis removes them.
