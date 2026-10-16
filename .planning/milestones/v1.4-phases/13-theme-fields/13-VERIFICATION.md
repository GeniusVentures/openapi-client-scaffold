---
phase: 13-theme-fields
verified: 2026-10-16T00:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 13: Theme Fields Verification Report

**Phase Goal:** An app can theme shadows, typography, motion, gradients and the accent, border-control and on-surface brand colors, and an app that registers none of them sees exactly today's output.
**Verified:** 2026-10-16
**Status:** passed
**Re-verification:** No, initial verification

## Observable Truths

| # | Truth (ROADMAP success criterion) | Status | Evidence |
|---|---|---|---|
| 1 | Registered shadow, typography, motion and gradient extensions are picked up by widgets (toast shadow, motion, overflow fade, text-field font) | VERIFIED | `lib/theme/scaffold_theme.dart` has `context.shadows/motion/typography/colorRoles/gradients`. Toast uses `context.shadows.card`; text field uses `typography.inputStyle`; overflow fade takes the gradient ramp. Registered-vs-default tests exist and pass (scaffold_shadows_test, scaffold_overflow_fade_test, text_entry_field_widget_test, motion_theme_* tests). Full `flutter test`: 574 passed. |
| 2 | With nothing registered, output equals today's: shadow = `ScaffoldElevation.card`, motion = old statics, text styles, gradients none, accent / borderControl / on-surface = today's colors | VERIFIED | Generated defaults read in source: card shadow `0x59000000/16/(0,4)` equals `ScaffoldElevation.card`; 150/300/500 ms and easeInOut/easeOut/Cubic(0.2,0,0,1.2) equal the b618159 statics; `inputStyle` Roboto 14/w400/ls0 matches the old inline style; `monoFontFamily` 'monospace' matches the old code block; `edgeFade` null. `colorRoles` fallback is derived from the resolved palette (`lightGreenPrimary`, `borderGrey`), so unregistered apps read the same palette fields as before. |
| 3 | `ScaffoldPalette` / `ScaffoldDimens` constructors and public fields unchanged; consumer contract test compiling the GCS const list passes | VERIFIED | `git diff b618159` over scaffold_palette.dart, scaffold_dimens.dart, scaffold_colors.dart, m3_tokens.css: empty. `consumer_contract_test.dart`: 126 added lines, 0 removed. `scaffoldThemeExtensions` still holds only palette and dimens. Test passes. |
| 4 | Text field and drawers read former hard-coded white from tokens; default light and dark captures pixel-identical | VERIFIED | `Colors.white` and `'Roboto'` no longer appear in text_entry_field_widget.dart or bottom_drawer/. They read `inputForeground`, `sheetForeground`, `sheetDivider` (defaults 0xFFFFFFFF / 0xFFFFFFFF / 0x1FFFFFFF = white / white12). I re-rendered all 52 captures at HEAD and at b618159 (worktree, same machine, outside the repo): `diff -rq` empty. The committed `images/` differ from a fresh render on this machine (cross-machine rendering), so the same-machine comparison is the valid test. |
| 5 | Template-generated families changed via `templates/components/*.jinja2` and regenerated; drift check clean | VERIFIED | Edited: selection_indicator, search_bar, animated_display templates. `python -m scaffold_codegen.generators` run from `tools/` reported all files unchanged; `git status --porcelain` empty and `git diff --exit-code lib/` exit 0. `theme_defaults --check` exit 0. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

## Requirements Coverage

| Req | Status | Evidence |
|---|---|---|
| THM-01 shadows | SATISFIED | `ScaffoldShadows` + `context.shadows`, toast migrated |
| THM-02 typography | SATISFIED | `ScaffoldTypography` + `context.typography`, text field and mono sites migrated |
| THM-03 motion | SATISFIED | `ScaffoldMotionTheme`; grep for `ScaffoldMotion(Durations\|Curves).` outside scaffold_motion.dart in `lib` and `templates`: 0 matches |
| THM-04 gradients | SATISFIED | `ScaffoldGradients` (edgeFade null by default) |
| THM-05 accent / borderControl / on-surface | SATISFIED | `ScaffoldColorRoles` |
| THM-06 constructors unchanged, fallbacks | SATISFIED | see truth 3; all six getters fall back when unregistered |
| THM-07 hard-coded white replaced | SATISFIED | see truth 4 |

No orphaned requirements.

## Behavioral Spot-Checks

| Check | Command | Result |
|---|---|---|
| Static analysis | `dart analyze --fatal-infos` | No issues found |
| Dart tests | `flutter test` | 574 passed |
| Python codegen tests | `python -m pytest` (tools) | 134 passed |
| Lint | `python -m ruff check` | All checks passed |
| Theme drift | `python -m scaffold_codegen.generators.theme_defaults --check` | exit 0 |
| All-family drift | `python -m scaffold_codegen.generators` then `git diff --exit-code lib/` | clean |
| CSS snapshot | `git diff b618159 -- tools/tests/fixtures/m3_tokens.css` | empty |
| Captures | HEAD vs b618159, 52 PNGs, same machine | identical |

## Anti-Patterns

No TBD, FIXME, XXX, TODO or HACK markers in files changed under `lib/`, `templates/`, `tools/` since b618159.

## Notes (non-blocking)

- 13-03-PLAN.md frontmatter lists THM-02 for a motion plan; the SUMMARY already notes this mislabel. No effect on coverage.
- `lightColorRoles.borderControl` (0x1F000000) differs from the dark default by design. It matches `ScaffoldPalette.lightPalette.borderGrey`, and an unregistered app does not hit it because the fallback reads the palette.
- ROADMAP.md and REQUIREMENTS.md still show Phase 13 and THM-01..07 as unchecked/Pending. The orchestrator should update them.
- The GCS harness result in 13-05-SUMMARY (60 tests pass, 0 app-code analyze issues) was not re-run here.

## Human Verification Required

None.

## Gaps Summary

No gaps. The phase goal is achieved.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
