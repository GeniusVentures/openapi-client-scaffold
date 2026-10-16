---
phase: 16-component-restyles
verified: 2026-10-16T00:00:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 16: Component Restyles Verification Report

**Phase Goal:** Under the midnight preset, components that tokens alone cannot restyle show the wallet look, and under the defaults they look exactly as they do today.
**Verified:** 2026-10-16
**Status:** passed
**Re-verification:** No, initial verification
**Base for comparisons:** d5ad4cb (Phase 15 close)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Midnight (light and dark) shows the chosen restyles in captures | VERIFIED | `images/midnight/restyles_{dark,light}.png` viewed: shadowed cards with hairline (and light sheen), tinted hover card with accent edge, 2 px accent focused field, accent checkbox with dark mark and 4 px corners, tabular figures. `bottom_drawer_dark.png` shows 24 px open-edge radius, hairline, card fill. `action_button_dark.png` shows accent glyph and sunken disabled state. Toast reads `context.shadows.card` (toast_widget.dart:137,187). |
| 2 | Defaults: harness re-run leaves every existing capture unchanged; restyles driven by extension values, no preset check in widgets | VERIFIED | Fresh render to an out-of-repo `SCAFFOLD_CAPTURE_DIR`: 0 byte diffs across 52 default and 54 midnight PNGs. `git log d5ad4cb..HEAD -- images ':!images/midnight'` empty. `grep -i midnight\|preset` over `lib/components`, `lib/utils`, `templates/components` finds nothing. Widgets branch on nullable roles (`hoverFill == null`, `colorRoles.scrim ?? Colors.black87`, `checkboxMark ?? Colors.white`). Default token values for all new fields are null. `scaffold_palette.dart`, `scaffold_dimens.dart`, `m3_tokens.css` have empty diff vs d5ad4cb. |
| 3 | Template families restyled in `templates/components/*.jinja2` and regenerated; drift clean | VERIFIED | `card`, `formatted_value`, `selection_indicator` templates changed alongside their generated `.dart` files. `python -m scaffold_codegen.generators` reports every file unchanged; `git diff --exit-code lib/` exit 0; `git status --porcelain` empty. `theme_defaults --check`, `theme_presets --check`, `m3_tokens_css --check` all exit 0. |
| 4 | Phase 15 contrast test passes for midnight, both modes | VERIFIED | `flutter test`: 1464 passed. `palette_contrast_test.dart` and `midnight_theme_contrast_test.dart` classify every new role (hoverFill blended on surfaces at 4.5:1, checkboxMark/Fill, checkboxEdge, actionIcon at 3:1, scrim and disabled roles explicitly excluded with reasons). |

**Score:** 4/4 truths verified

### Candidate disposition (RST-01, R1-R15)

| Cand | Disposition | Check |
|------|-------------|-------|
| R1, R2, R5, R6, R8, R9, R11 | Shipped | Code diff and captures confirmed. R8 sweep: only a doc comment still names `lightGreenPrimary` in `lib/components` and `templates/components`. |
| R3 | ActionButton shipped; StringButton skipped | Skip rests on "source button identical", which is a claim about the wallet source and cannot be checked from this repo. Recorded in 16-RESTYLES.md; non-blocking. |
| R4, R12 | Not built (PD-08) | Reasons hold: no gradient-CTA widget exists, no page-painting widget exists, `midnightTheme` sets `scaffoldBackgroundColor` (midnight_theme.dart:78). Both are NTH in FEATURES.md. |
| R7, R10, R13, R14, R15 | Shipped earlier | Confirmed in Phase 13/15 code (toast shadow, preset theme, mono family). |
| Radio and toggle | Unchanged | Justified in record (no source styling; toggle already a pill). |

All 15 candidates have a recorded disposition; every skip has a stated reason.

### Public API

Additive only. Removed lines in `lib/` are internal implementation, plus `copyWith` signatures that gained named optional parameters. New: `ScaffoldShapes` (exported), `ResponsiveDrawerPanel`, `ScaffoldPressable.borderRadius`, nullable fields with optional constructor parameters. `scaffoldThemeExtensions` still holds two entries. `consumer_contract_test` passes within the 1464.

### Behavioral Spot-Checks and Gates (run by verifier)

| Check | Result |
|-------|--------|
| `dart analyze --fatal-infos` | No issues found |
| `flutter test` (root) | 1464 passed |
| `example` capture test and preset switcher test | pass; render byte-identical to committed images |
| `ruff check` | All checks passed |
| `pytest tools/tests` | 193 passed |
| Generator `--check` modes and full regeneration | clean, no `lib/` diff |

The GeniusCognitiveSystem harness run reported in 16-08-SUMMARY.md was not re-run; Phase 17 (GATE-02) owns that gate.

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| RST-01 | SATISFIED | Truths 1-4 and the candidate table above. |

### Anti-Patterns

No TBD, FIXME, XXX, TODO or HACK markers added in `lib/`, `templates/`, `test/`, `tokens/`, `tools/` or `design_tokens.json` since d5ad4cb. No stubs found.

### Human Verification

None required. Fidelity to the external wallet source is not checkable in this repo; the deviations from it are recorded in 16-RESTYLES.md.

## Stale Documentation (not fixed)

1. `.planning/workstreams/scaffold/ROADMAP.md`: Phase 16 line 60 and plan lines 175-182 are still unchecked `[ ]`; the progress table row for Phase 16 is not marked complete.
2. `.planning/workstreams/scaffold/REQUIREMENTS.md`: RST-01 (line 35) unchecked and traceability row (line 79) says Pending.
3. `.planning/workstreams/scaffold/STATE.md`: `stopped_at` still "roadmap created, nothing planned or executed"; `last_activity_desc` says Phase 12 execution started; position says "Plan 1 of 8", progress 0% (0/6), frontmatter shows 4/6 phases and 21/29 plans.
4. `README.md` line ~102: "Captures of all 26 demos are in `images/midnight/`" omits the two `restyles_*` captures (54 files, not 52). Minor.
5. Root `.planning/STATE.md` is stale per CLAUDE.md (known).

## Gaps Summary

No gaps. The phase goal is achieved: restyles are active under midnight, default captures and generated default files are byte-identical, midnight contrast holds, the public API is additive, and skipped restyles are justified.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
