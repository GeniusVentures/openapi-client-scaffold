---
phase: 08-supporting-atoms-table-cells-light-palette
plan: 01
subsystem: scaffold-theme-and-atoms
tags: [widg-46, light-palette, wcag-aa, badge, theme-extension]
requires:
  - lib/theme/scaffold_palette.dart (defaultPalette + lightPalette)
  - lib/theme/scaffold_dimens.dart (defaultDimens)
  - lib/theme/scaffold_theme.dart (context.palette extension)
provides:
  - ScaffoldBadge._resolveOnStatusColor — WCAG-AA on-status color resolver used by label-style and icon-glyph sites
  - lightPalette token-coverage contract locked in CI via test
affects:
  - Wave 1-3 plans that compose ScaffoldBadge (chip status dot, composer badge slots, disclosure status slot) — all inherit the WCAG-AA on-status fix
tech-stack:
  added: []
  patterns:
    - "Luminance-threshold on-status resolution (fill.computeLuminance() > 0.40 → dark text, else light text) — keeps resolution inside the atom (D-10)"
    - "Per-palette pump helper pattern (_pumpLight) for verifying widget rendering under ThemeData.light() + ScaffoldPalette.lightPalette"
key-files:
  created: []
  modified:
    - lib/components/scaffold_badge.dart
    - test/components/scaffold_badge_test.dart
    - test/theme/scaffold_palette_token_test.dart
decisions:
  - "D-10 implemented: on-status color resolution lives inside ScaffoldBadge via _resolveOnStatusColor, not in consumers"
  - "On-status dark = #17191E (matches lightPalette.textPrimary); on-status light = #FFFFFFFF; luminance threshold = 0.40"
metrics:
  duration: "5m 30s"
  completed: 2026-08-17
  tasks: 3
  files_modified: 3
  tests_added: 7
  tests_updated: 1
---

# Phase 8 Plan 01: Light Palette & Badge On-Status Remediation Summary

Implemented WIDG-46 by adding `_resolveOnStatusColor` to `ScaffoldBadge` and replacing both hardcoded `Colors.white` sites (label style + icon glyph) with a luminance-driven resolver, locking the light-palette token-coverage contract in a new test.

## One-Liner

WCAG-AA badge on-status colors via luminance threshold — `ScaffoldBadge` now resolves dark text (#17191E) on bright fills (lightGreenPrimary, statusSuccess, statusWarningText) and light text (#FFFFFFFF) on dark fills (statusError, blue500) under both `defaultPalette` and `lightPalette`, with no consumer overrides.

## What Was Built

### Task 1 — Failing on-status-color tests (RED, commit `7cfde75`)

Extended `test/components/scaffold_badge_test.dart` with a `_pumpLight` companion helper that wraps children in `ThemeData.light().copyWith(extensions: [ScaffoldPalette.lightPalette, ScaffoldDimens.defaultDimens])`, plus six new tests under a `on-status color resolution (WIDG-46)` group:

1. `lightGreenPrimary` fill renders dark label under `defaultPalette`
2. `lightGreenPrimary` fill renders dark label under `lightPalette`
3. `statusError` fill renders light label under `defaultPalette`
4. `statusError` fill renders light label under `lightPalette`
5. Icon-only badge on `lightGreenPrimary` renders dark icon glyph
6. Icon-only badge on `statusError` renders light icon glyph

Initial run: 3 tests fail (the three dark-on-bright assertions), 3 pass coincidentally (white-on-dark), 12 pre-existing tests still pass — RED state confirmed.

### Task 2 — `_resolveOnStatusColor` implementation (GREEN, commit `f2a8f75`)

In `lib/components/scaffold_badge.dart`:

- Added three `static const` members on `ScaffoldBadge`:
  - `_kOnStatusLuminanceThreshold = 0.40`
  - `_kOnStatusDark = Color(0xFF17191E)` (matches `lightPalette.textPrimary`)
  - `_kOnStatusLight = Color(0xFFFFFFFF)`
- Added `static Color _resolveOnStatusColor(Color fill)` returning dark when `fill.computeLuminance() > _kOnStatusLuminanceThreshold`, else light.
- Replaced `Colors.white` at the label-style site (was line 105) with `_resolveOnStatusColor(resolvedBadgeColor)`.
- Replaced `Colors.white` at the icon-glyph site (was line 140) with the same helper call.
- No new palette tokens; `lib/theme/scaffold_palette.dart` untouched.

Result: all 18 badge tests pass; `dart analyze --fatal-infos` clean; `grep -n "Colors\.white" lib/components/scaffold_badge.dart` returns no matches.

### Task 3 — Light-palette token coverage contract (commit `5fdc85a`)

Added `lightPalette covers all tokens consumed by shipped widgets` test to `test/theme/scaffold_palette_token_test.dart`. Asserts `isNotNull` for each of the 11 tokens consumed by shipped scaffold widgets per the 08-UI-SPEC "Color" section:

`surfaceElevated`, `deepBlueCardColor`, `lightGreenPrimary`, `textPrimary`, `textSecondary`, `borderSubtle`, `focusRingColor`, `statusSuccess`, `statusError`, `statusWarningText`, `blue500`

Plus the surface-flip contract: `lightPalette.surfaceElevated != defaultPalette.surfaceElevated` and `lightPalette.textPrimary != defaultPalette.textPrimary`.

Result: all 13 palette tests pass; `dart analyze --fatal-infos` clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-existing `count variant` test codified the hardcoded-white bug**
- **Found during:** Task 2 (GREEN step)
- **Issue:** The existing test `'count variant renders pill with labelSmall white text'` asserted `text.style?.color == Colors.white` against the default fill `lightGreenPrimary` (#00EAAE, luminance ≈ 0.71). Under the new resolver, that fill correctly resolves to dark on-status text — so the test failed. The test was asserting the WIDG-46 bug as the spec.
- **Fix:** Updated the test name to `count variant renders pill with labelSmall dark text on bright fill` and the assertion to `Color(0xFF17191E)`, with a comment explaining that the bright default fill resolves to dark on-status color per the WIDG-46 remediation. This is the test's correct specification going forward.
- **Files modified:** `test/components/scaffold_badge_test.dart`
- **Commit:** `f2a8f75`

**2. [Rule 3 - Blocking] Plan-referenced path `test/components/scaffold_palette_token_test.dart` does not exist**
- **Found during:** Task 3
- **Issue:** The plan's `<files>`, `read_first`, and acceptance criteria all reference `test/components/scaffold_palette_token_test.dart`, but the file actually lives at `test/theme/scaffold_palette_token_test.dart` (it's a theme-extension test, co-located with other theme tests).
- **Fix:** Extended the existing file at its actual location. The test intent (lightPalette token coverage) is identical; the path correction is a no-op for behavior. All grep-based acceptance criteria (`grep -c "lightPalette"`, etc.) were run against the actual path and pass.
- **Files modified:** `test/theme/scaffold_palette_token_test.dart` (actual path, not the plan's stated path)
- **Commit:** `5fdc85a`

## Authentication Gates

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. The change is purely visual styling resolution inside an atom.

## Verification Results

| Gate | Result |
|------|--------|
| `flutter test test/components/scaffold_badge_test.dart` | PASS — 18 tests green |
| `flutter test test/theme/scaffold_palette_token_test.dart` | PASS — 13 tests green |
| `flutter test test/components/scaffold_badge_test.dart test/theme/scaffold_palette_token_test.dart` (combined) | PASS — 31 tests green |
| `dart analyze --fatal-infos lib/components/scaffold_badge.dart test/components/scaffold_badge_test.dart test/theme/scaffold_palette_token_test.dart` | PASS — no issues |
| `grep -n "Colors\.white" lib/components/scaffold_badge.dart` | PASS — no matches (exit 1) |

## TDD Gate Compliance

- [x] RED gate commit exists: `7cfde75 test(08-01): add failing on-status-color tests for ScaffoldBadge`
- [x] GREEN gate commit follows RED: `f2a8f75 feat(08-01): add _resolveOnStatusColor and replace hardcoded Colors.white in ScaffoldBadge`
- [x] RED state was confirmed before GREEN: 3 of the 6 new tests failed (dark-on-bright assertions) prior to the implementation
- [ ] REFACTOR gate commit: not applicable — the GREEN implementation was already minimal; no cleanup needed

## Self-Check: PASSED

- [x] `lib/components/scaffold_badge.dart` exists and contains `_resolveOnStatusColor`
- [x] `test/components/scaffold_badge_test.dart` exists and contains `_pumpLight` + 6 new on-status tests
- [x] `test/theme/scaffold_palette_token_test.dart` exists and contains `lightPalette covers all tokens consumed by shipped widgets`
- [x] Commit `7cfde75` found in `git log` (Task 1 RED)
- [x] Commit `f2a8f75` found in `git log` (Task 2 GREEN)
- [x] Commit `5fdc85a` found in `git log` (Task 3)
- [x] `grep -n "Colors\.white" lib/components/scaffold_badge.dart` returns no matches
