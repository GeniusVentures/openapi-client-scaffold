---
phase: 13-theme-fields
plan: 01
subsystem: theme
tags: [theme-extension, codegen, design-tokens, shadows, motion, typography]
requires:
  - "12-01 theme_defaults generator and --check"
provides:
  - "ScaffoldShadows, ScaffoldMotionTheme, ScaffoldTypography theme extensions with generated defaults"
  - "context.shadows, context.motion, context.typography getters with fallbacks"
  - "theme_defaults params-style regions and five new encoders"
affects: [13-02, 13-03, 13-04, phase-15-midnight-preset]
tech-stack:
  added: []
  patterns:
    - "params-style GENERATED regions inside a constructor parameter list"
    - "dark tokens as constructor defaults, light as an args region (mirrors palette)"
key-files:
  created:
    - templates/theme/const_params.dart.jinja2
    - lib/theme/scaffold_shadows.dart
    - lib/theme/scaffold_motion_theme.dart
    - lib/theme/scaffold_typography.dart
    - test/theme/scaffold_shadows_test.dart
    - test/theme/scaffold_motion_theme_test.dart
    - test/theme/scaffold_typography_test.dart
  modified:
    - design_tokens.json
    - tools/scaffold_codegen/generators/theme_defaults.py
    - tools/tests/test_theme_defaults.py
    - lib/theme/scaffold_theme.dart
    - lib/theme/scaffold_elevation.dart
    - lib/frontend_scaffold.dart
    - lib/components/toast/toast_widget.dart
key-decisions:
  - "Params regions prefix `const` on list and constructor-call literals in the generator, because Dart default values need it."
  - "ScaffoldPalette, ScaffoldDimens and scaffoldThemeExtensions are unchanged; getters fall back instead."
metrics:
  duration: "about 35 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 30000
  tasks: 3
  commits: 3
---

# Phase 13 Plan 01: Shadows, motion and typography extensions Summary

Three new theme extensions, each with defaults generated from the `scaffold` token namespace and a `context.<name>` getter that falls back to the default, with the toast moved onto `context.shadows`.

## What was built

- Generator: REGIONS rows have a fourth column (style `args` or `params`); `TEMPLATE_NAMES` picks the template; encoders `dart_shadows`, `dart_duration`, `dart_curve`, `dart_text_style`, `dart_font_family`; an args region rejects a None literal.
- Tokens: `scaffold.shadows.{dark,light}`, `scaffold.motion.{durations,curves}`, `scaffold.typography.{textStyles,fontFamilies}`. The M3 top-level keys and the CSS snapshot are unchanged.
- Dart: `ScaffoldShadows` (dark default, `lightShadows`, `BoxShadow.lerpList`), `ScaffoldMotionTheme` (duration lerp in microseconds, curves snap at 0.5), `ScaffoldTypography` (`TextStyle.lerp`, family snaps at 0.5). No required parameters. Barrel exports added.
- Toast: both densities draw `context.shadows.card`. `ScaffoldElevation` keeps its value; only its doc comment changed.

## Verification

- pytest: 123 passed (63 in test_theme_defaults.py); ruff clean
- `theme_defaults --check` and `m3_tokens_css --check`: exit 0
- `dart analyze --fatal-infos` (whole repo): no issues
- `flutter test`: 494 passed (test/theme: 61)
- `git diff b618159` is empty for scaffold_palette.dart, scaffold_dimens.dart, scaffold_colors.dart, consumer_contract_test.dart, toast_test.dart, scaffold_motion.dart and the CSS snapshot
- Tracer gate: toast tests with a registered shadow and with none passed before Tasks 2 and 3 started

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Params-region defaults need an explicit `const`**
- **Found during:** Task 1 (dart analyze: non_constant_default_value)
- **Issue:** The plan's encoders emit `[BoxShadow(...)]`, `Duration(...)`, `Cubic(...)` and `TextStyle(...)`. As constructor parameter defaults these are not constant without `const`.
- **Fix:** `render_files` prefixes `const ` on a params-region literal that starts with `[` or `Name(`. Encoder output is unchanged, so args regions (already a const context) stay free of `unnecessary_const`.
- **Consequence:** generated lines read `this.card = const [BoxShadow(`, `this.emphasized = const Cubic(0.2, 0.0, 0.0, 1.2),` and `this.inputStyle = const TextStyle(...)`. The plan's literal greps for these strings (without `const`) would print 0; the pytest and acceptance checks were adjusted to the `const` form.
- **Files modified:** tools/scaffold_codegen/generators/theme_defaults.py, tools/tests/test_theme_defaults.py
- **Commit:** a3108fd

Fixed text field family: the plan said "the family the text field hard-codes"; that is `'Roboto'`, used in the typography token.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. T-13-01 mitigations are in the encoders (full-match regexes, fixed key sets, fixed font weights) with rejection cases in pytest; T-13-02 held by the empty diff on Palette, Dimens and `scaffoldThemeExtensions`.

## Commits

- a3108fd: feat(13-01): THM-01 add ScaffoldShadows from scaffold.shadows tokens to toast
- 841adba: feat(13-01): THM-03 add ScaffoldMotionTheme from scaffold.motion tokens
- ef32c21: feat(13-01): THM-02 add ScaffoldTypography from scaffold.typography tokens

## Self-Check: PASSED

All created files exist and all three commits are in `git log`.
