---
phase: 15-midnight-preset
plan: 06
subsystem: capture-harness
tags: [captures, midnight, harness, fonts]
requires:
  - "15-04 (midnightTheme(Brightness))"
  - "15-05 (example preset switch)"
provides:
  - "_CaptureProfile with default and midnight profiles in the capture harness"
  - "images/midnight/: 52 midnight captures (26 demos, light and dark)"
affects: [16, 17]
key-files:
  modified:
    - example/test/capture_images_test.dart
    - lib/theme/presets/midnight_theme.dart
  created:
    - images/midnight/*.png
key-decisions:
  - "Inter and JetBrainsMono render from the harness's Roboto files; no font file is added."
  - "The midnight text theme now carries the sans family itself, so appBarTheme and tabBarTheme styles use Inter."
requirements-completed: [PRE-03]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 16000
  tasks: 2
  commits: 4
---

# Phase 15 Plan 06: Midnight captures Summary

The capture harness is now profile-driven, and 52 midnight captures sit in images/midnight/ as new files; the 52 default captures are unchanged.

## Commits

| Name | SHA | Touches |
|---|---|---|
| Harness refactor | 4cc5457 | example/test/capture_images_test.dart, no PNG |
| Midnight font family fix | 9b367e9 | lib/theme/presets/midnight_theme.dart |
| Midnight profile | 1049be8 | example/test/capture_images_test.dart, no PNG |
| MIDNIGHT_CAPTURES | bc8d692 | 52 files under images/midnight/ only |

## Verification

- After 4cc5457 and after 1049be8, a scratch render equals images/*.png byte for byte (52 files, no DIFF). Midnight scratch render: 52 PNGs, none under 3 KB.
- `git log 0fe6608..HEAD -- images ':!images/midnight'` is empty; `git show --stat bc8d692` lists only images/midnight/ paths (52 files).
- Root: `dart analyze --fatal-infos` clean, flutter test 1225 passed. Example analyze clean.

## What the captures show

- action_button_dark: near-black page, mint accent icons, grey labels, white Inter-stand-in title.
- text_entry_field_light: light grey-blue page, white app bar, pale fields with a grey border, legible dark typed text.
- toast_light, chip_light (selected chip has a dark teal 2px border), bottom_drawer_dark (dark panel, white text, blue outlined buttons): all legible with real glyphs.
- toast_light shows toast cards overlapping the demo controls; that is the same layout the default capture uses.

## Deviations from Plan

**1. [Rule 1 - Bug] Midnight app bar titles and tab labels had no font family**
- **Found during:** Task 1, viewing the first midnight render (app bar title and button labels were solid Ahem blocks).
- **Issue:** `ThemeData(fontFamily:)` applies only to its own default text theme. `appBarTheme.titleTextStyle` and `tabBarTheme` labels reuse the preset's text styles, which carried no family, so they ignored Inter (a consumer app would show the platform font). `bodySmall` was also rebuilt from the un-applied scale.
- **Fix:** apply `Midnight.typeScale.sansFontFamily` to the scale once and derive `bodySmall` from that.
- **Files modified:** lib/theme/presets/midnight_theme.dart
- **Commit:** 9b367e9 (its own commit, before the midnight capture commits; default captures verified unchanged afterward)

## Known Stubs

None.

## Self-Check: PASSED

4cc5457, 9b367e9, 1049be8 and bc8d692 exist on develop; images/midnight/ holds 52 tracked PNGs; the working tree is clean.
