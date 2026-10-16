---
phase: 15-midnight-preset
verified: 2026-10-16T00:00:00Z
status: passed
score: 4/4 roadmap success criteria verified
behavior_unverified: 0
overrides_applied: 0
gaps: []
warnings:
  - "SC2 literal wording: 'no brand names in example/' is not literally true. example/macos has ai.gnus bundle ids and a copyright line, and example/web/icons/Icon-512.png matches a binary grep. Pre-existing runner metadata, excluded by tools/tests/test_no_brand_names.py. lib/ and the Dart/JSON/yaml content of example/ are clean."
  - "Midnight light statusSuccess/statusError (0xFF065F46 / 0xFF991B1B) differ from the wallet map light values (0xFF07875F / 0xFFD92D2D). Deliberate AA departure (PD-03), documented in 15-01-PLAN, the token-map test, and README. The wallet values are 3.42:1 and 3.63:1 on the page."
stale_docs:
  - ".planning/workstreams/scaffold/ROADMAP.md: Phase 15 line 59 and the seven plan lines 150-156 still '[ ]'; Progress table row 228 says '15. Midnight Preset | 0/TBD | Not started' (rows 225-227 for Phases 12-14 are also stale: 'Planned' / 'Not started')"
  - ".planning/workstreams/scaffold/REQUIREMENTS.md: PRE-01, PRE-02, PRE-03, A11Y-03 checkboxes (lines 29-31, 41) unchecked; traceability rows 75-78 say 'Pending'"
  - ".planning/workstreams/scaffold/STATE.md: status 'executing', Phase 15 'Plan: 1 of 7', 'Progress 0% (0/6 phases)', stopped_at 'v1.4 roadmap created ... nothing planned or executed yet', last_activity_desc 'Phase 12 execution started'"
  - "CLAUDE.md line 20 and CONTRIBUTING.md line 15 say 'flutter test # 214 tests'; README.md line 289 says '454 tests'. Actual root run is 1225 (acknowledged in 15-07-SUMMARY, left alone)"
  - "No SUMMARY frontmatter lists requirements-completed for all four IDs in one place: 15-01 lists [], 15-02/04/07 list PRE-01/02/A11Y-03 variants. Informational only"
---

# Phase 15: Midnight Preset Verification Report

**Phase Goal:** An app can switch to the midnight look, light and dark, with one call, and the example app shows it, while apps that do not opt in see no change.
**Verified:** 2026-10-16, head 0407673 (develop), clean tree
**Status:** passed (with two warnings and a stale-docs list)
**Re-verification:** No, initial verification

All checks below were run by the verifier, not read from SUMMARY.md.

## Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | One deep-import call returns midnight ThemeData and extensions for light or dark, generated from its own token file, and `--check` covers it | VERIFIED | `lib/theme/presets/midnight_theme.dart` exports `midnightTheme(Brightness)` (line 16, `extensions: midnightExtensions(brightness)` line 81) and `midnightExtensions`. `grep -i "preset\|midnight" lib/frontend_scaffold.dart` is empty, so not in the barrel. `tokens/midnight.json` (own file, no M3 keys) feeds `tools/scaffold_codegen/generators/theme_presets.py` into `lib/theme/presets/midnight_tokens.dart`. `python -m scaffold_codegen.generators.theme_presets --check` exit 0. Drift tests in `tools/tests/test_theme_presets.py` (token edit drifts, hand edit fails, check writes nothing). CI line 58 of `.github/workflows/ci.yaml` runs it. `python -m scaffold_codegen.generators` then `git status --porcelain` is clean. Both brightness values covered by `test/theme` (737 tests pass). |
| 2 | Preset reproduces the wallet token map (accents, surface ladder, spacing, radius, type, motion, shadows, gradients); no brand names in lib/ or example/ | VERIFIED (2 warnings) | Compared `tokens/midnight.json` against FEATURES.md sections 1-4: cyan `#14C8FF`/`#0AAEE6`, mint `#2BF5B4`, purple `#C28FFF`; surfaces `#0B0D12/#0C0E14/#171A21/#06080C` dark and `#DCE0E6/#FFFFFF/#EFF2F6/#CFD4DB` light; appBarHeight 68 and the space/radius ladder; motion 120/200/320 ms with easeOutCubic/easeOutExpo; card, dialog, glow, glow-pair shadows; accentFill, accentBorder, heroWash, canvas (3 stops), surfaceSheen, radial canvasGlow; full 10-slot text theme, numeric styles with tabular figures, Inter/JetBrainsMono. Source map pinned by `test/theme/midnight_token_map_test.dart` (863 lines). Brand grep over tracked `lib/`, `tokens/`, `templates/`: zero hits for genius/gnus/GW prefixes; `wallet_connect_sheet.dart` is pre-existing generic Reown code, not the source brand. Warnings: see frontmatter (example/macos bundle id; light status colors deliberately AA-adjusted). |
| 3 | Example app switches default/midnight in both modes; default captures unchanged | VERIFIED | `example/lib/main.dart` has the "Midnight preset" SwitchListTile (line 198), `_useMidnight` state, deep import of `midnight_theme.dart`, composes with "Theme overrides". `example/test/preset_switcher_test.dart` (2 tests, four combinations plus override) passes. Re-ran the capture harness into a scratch dir: 52 default PNGs byte-identical to `images/`, 52 midnight PNGs byte-identical to `images/midnight/`, 0 diffs. `git log 0fe6608..HEAD -- images ':!images/midnight'` is empty. `git diff 0fe6608..HEAD` on `design_tokens.json`, `lib/frontend_scaffold.dart`, `lib/theme/scaffold_*.dart`, `tools/tests/fixtures` is empty. |
| 4 | Automated contrast test passes for default and midnight palettes, light and dark, covering text, status, control-border, focus-ring | VERIFIED | `test/theme/palette_contrast_test.dart` defines `default dark/light` and `midnight dark/light` themes; per-field classification covers textPrimary/Secondary/gray500 (text), statusSuccess/Error/WarningText (text), borderControl (3:1, roles and fallback), focusRingColor (3:1); key coverage is tied to `tokens/midnight.json`. `test/theme/midnight_theme_contrast_test.dart` adds ColorScheme and component-theme pairs. Passes (flutter test test/theme, 737 passed). Independent Python recomputation of WCAG ratios for midnight on elevated, base, sheet and input surfaces: all text/status/accent pairs at least 4.75:1, borderControl at least 3.08:1 (light base), focus ring at least 4.76:1. No FAIL. |

**Score:** 4/4 truths verified. No behavior-dependent truths left unexercised.

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| PRE-01 | SATISFIED | Truth 1 |
| PRE-02 | SATISFIED | Truth 2 (warnings noted) |
| PRE-03 | SATISFIED | Truth 3 |
| A11Y-03 | SATISFIED | Truth 4 |

No orphaned requirements: REQUIREMENTS.md maps exactly these four IDs to Phase 15 and all seven plans claim them between them.

## Gate Commands (run by verifier at head 0407673)

| Check | Result |
|-------|--------|
| `theme_defaults --check`, `theme_presets --check`, `m3_tokens_css --check` (as CI runs them, repo root, PYTHONPATH=tools) | all exit 0 |
| `python -m scaffold_codegen.generators` + `git status --porcelain` | clean |
| pytest (tools) | 182 passed |
| ruff check | All checks passed |
| `dart analyze --fatal-infos` root and example | No issues found |
| `flutter test` root | 1225 passed |
| example capture + preset switcher tests | 4 passed, 104 PNGs byte-identical |

## Anti-Patterns

No TBD/FIXME/XXX gate check was run beyond the brand scan; generated preset regions pass `--check` and no stub or hollow data path was found: palette, color roles, dimens, shadows, motion, typography, gradients all flow from `tokens/midnight.json` through the generator into registered extensions.

## Stale Documentation (not fixed, per instruction)

See `stale_docs` in the frontmatter: ROADMAP.md checkboxes and Progress table, REQUIREMENTS.md checkboxes and traceability, STATE.md position fields, and the test counts in CLAUDE.md, CONTRIBUTING.md and README.md.

## Human Verification

None required for goal achievement. Optional: eyeball `images/midnight/` for taste; captures use stand-in Roboto for Inter/JetBrainsMono by design.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
