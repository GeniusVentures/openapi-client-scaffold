---
phase: 13-theme-fields
plan: 02
subsystem: theme
tags: [theme-extension, codegen, design-tokens, color-roles, gradients, text-field, drawer]
requires:
  - "13-01 ScaffoldTypography, params regions, theme_defaults REGIONS style column"
provides:
  - "ScaffoldColorRoles (accent, accentOnSurface, borderControl, inputForeground, sheetForeground, sheetDivider) with fallbackFor(palette, brightness)"
  - "ScaffoldGradients with nullable edgeFade, none by default"
  - "context.colorRoles and context.gradients getters"
  - "ScaffoldOverflowFade.gradientFor ramp parameter"
  - "generator kind gradient (null only)"
affects: [13-03, 13-04, 13-05, phase-14-contrast, phase-15-midnight-preset, phase-16-call-sites]
tech-stack:
  added: []
  patterns:
    - "palette-derived fallback for color roles that replace palette reads"
    - "alpha-ramp gradient token scaled to the widget's own edge fraction"
key-files:
  created:
    - lib/theme/scaffold_color_roles.dart
    - lib/theme/scaffold_gradients.dart
    - test/theme/scaffold_color_roles_test.dart
    - test/theme/scaffold_gradients_test.dart
    - test/components/text_entry_field_widget_test.dart
    - test/components/bottom_drawer_test.dart
  modified:
    - design_tokens.json
    - tools/scaffold_codegen/generators/theme_defaults.py
    - tools/tests/test_theme_defaults.py
    - lib/theme/scaffold_theme.dart
    - lib/frontend_scaffold.dart
    - lib/components/scaffold_overflow_fade.dart
    - lib/components/text_entry_field_widget.dart
    - lib/components/bottom_drawer/bottom_drawer.dart
    - test/theme/scaffold_tokens_parity_test.dart
    - test/theme/consumer_contract_test.dart
    - test/components/scaffold_overflow_fade_test.dart
key-decisions:
  - "PC-06: unregistered colorRoles start from lightColorRoles or defaultColorRoles by brightness, then take accent, accentOnSurface and borderControl from the resolved palette."
  - "PC-07: edgeFade is a ramp (alphas and stops only) scaled into the widget's own edge fraction; null keeps the original code path."
  - "Light white tokens equal the dark ones (LD-13-05); Phase 14 changes the values."
metrics:
  duration: "about 40 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 14000
  tasks: 3
  commits: 3
---

# Phase 13 Plan 02: Color roles, gradients and widget migrations Summary

ScaffoldColorRoles and ScaffoldGradients exist as generated-default theme extensions, and the text field, drawer and overflow fade now read them while drawing the same pixels as before when nothing is registered.

## What was built

- Tokens: `scaffold.colorRoles.{dark,light}` (six roles, dartRef for the three that equal ScaffoldColors constants) and `scaffold.gradients.edgeFade` (null).
- Generator: two color-role rows (dark params, light args), one gradient row, and `dart_gradient`, which accepts only null so no unvalidated gradient text reaches Dart.
- `ScaffoldColorRoles`: no required parameters, `defaultColorRoles`, `lightColorRoles`, `fallbackFor`, `copyWith`, `lerp`. `context.colorRoles` falls back through `fallbackFor(palette, brightness)`.
- `ScaffoldGradients`: `edgeFade` nullable, `defaultGradients`, `copyWith`, `lerp`. `context.gradients` falls back to the default.
- `ScaffoldOverflowFade.gradientFor` takes an optional `ramp`; the two-stop black-to-transparent ramp reproduces all seven built-in gradients exactly (equality test). A pixel test shows a registered ramp changes the drawn fade.
- `TextEntryFieldWidget` uses `context.typography.inputStyle` plus `colorRoles.inputForeground`, `accentOnSurface` and `borderControl`. `BottomDrawer` uses `sheetForeground` and `sheetDivider`. No hard-coded white or font family remains in either file.
- Consumer contract: new cases check every new getter under the old light and dark registrations and a 22-parameter palette and 21-parameter dimens constructor call. Existing lines are untouched.

## Verification

- pytest tools/tests: 134 passed (91 in test_theme_defaults.py); ruff clean
- `theme_defaults --check`: exit 0
- `dart analyze --fatal-infos` (whole repo): no issues
- `flutter test`: 533 passed
- `git diff b618159` is empty for scaffold_palette.dart, scaffold_dimens.dart, scaffold_colors.dart and responsive_drawer.dart; the contract test diff has no removed lines

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing group-order test needed the new keys**
- **Found during:** Task 1
- **Issue:** `test_typography_group_order_and_m3_key_untouched` asserts the exact key order of `scaffold`, which grew by `colorRoles` and `gradients`.
- **Fix:** Extended the expected list in Tasks 1 and 2.
- **Files modified:** tools/tests/test_theme_defaults.py
- **Commits:** cb1740e, 6849792

**2. Acceptance greps adjusted for the 13-01 `const` prefix**
- Params regions emit `const Color(...)` defaults; the Python test asserts `this.inputForeground = const Color(0xFFFFFFFF),`. References such as `ScaffoldColors.lightGreenPrimary` get no prefix.

**3. Gradient generator test shape**
- The plan's single-row monkeypatch case was written as two tests: a non-null token naming `scaffold.gradients.edgeFade`, and an args-style region rejecting the null literal.

## Auth gates

None.

## Known Stubs

None. `edgeFade` is intentionally null by default.

## Threat Flags

None. T-13-05 is covered by `dart_gradient` rejection cases, T-13-06 by the extended Dart parity test, T-13-07 and T-13-08 by the default-equality widget tests and the constructor-shape contract test.

## Commits

- cb1740e: feat(13-02): THM-05 add ScaffoldColorRoles from scaffold.colorRoles tokens
- 6849792: feat(13-02): THM-04 add ScaffoldGradients with themeable overflow-fade ramp
- 877754c: feat(13-02): THM-07 move text field and drawer onto typography and color-role tokens

## Self-Check: PASSED

All created files exist and all three commits are in `git log`.
