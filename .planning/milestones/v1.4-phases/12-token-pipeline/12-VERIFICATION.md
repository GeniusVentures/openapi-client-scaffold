---
phase: 12-token-pipeline
verified: 2026-10-16T00:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 12: Token Pipeline Verification Report

**Phase Goal:** A maintainer edits one token file and the default Dart palette and dimens regenerate from it, with no change to anything a consumer sees.
**Verified:** 2026-10-16
**Status:** passed
**Re-verification:** No, initial verification
**Baseline:** e67e00c (pre-phase). "Byte-identical" read as agreed: values unchanged plus six marker comment lines.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `design_tokens.json` has a `scaffold` namespace with every light/dark palette and every dimens value; M3 keys and `m3_tokens.css` bytes unchanged | VERIFIED | Namespace has palette.dark 22, palette.light 22, dimens 21; Dart classes have 22 Color and 21 double fields. `git diff e67e00c HEAD -- design_tokens.json`: 76 insertions, 0 deletions. CSS rendered from the e67e00c tokens and from current tokens is `cmp`-identical, with no CR bytes. |
| 2 | Generator reproduces default values; `git diff` on `lib/theme/` empty after regeneration | VERIFIED | `python -m scaffold_codegen.generators` exit 0, then `git diff --exit-code lib/` clean and `git status` clean. Against e67e00c, lib/theme numstat is `4 0` (palette) and `2 0` (dimens): only the six marker comment lines added, zero deletions or edits. Dart parity test passes. |
| 3 | Un-regenerated token change or hand-edited Dart makes pytest and `--check` fail; regenerating clears it | VERIFIED | Ran both negatives myself. Token edit (`horizontalPadding` 20 to 21): `theme_defaults --check` exit 1 ("drift: lib/theme/scaffold_dimens.dart"), pytest 4 failed. Hand edit of `textPrimary` inside the region: `--check` exit 1, pytest 3 failed. After regenerating, `--check` exit 0. Appending to the CSS snapshot: `m3_tokens_css --check` exit 1. Working tree restored. |
| 4 | Regeneration on Windows leaves LF in every generated file, no whole-file diff, `.gitattributes` pins LF | VERIFIED | Regenerated all families on Windows: no diff, no CR in lib/theme or lib/components generated files. `.gitattributes` = `* text=auto eol=lf` plus `*.png binary`. `git ls-files --eol`: 0 `i/crlf`, 471 `i/lf`, 82 `i/-text`. `newline="\n"` at the three writers (engine.py:146, m3_tokens_css.py:305, theme_defaults.py:177); AST guard test passes. |
| 5 | Capture harness leaves `images/` unchanged; GCS const extension list still compiles | VERIFIED (see note) | Rendered 52 PNGs at HEAD (via `SCAFFOLD_CAPTURE_DIR`) and 52 at e67e00c in a temp worktree on this machine: `cmp` shows zero differences. No change to `images/` between e67e00c and HEAD. `test/theme/consumer_contract_test.dart` has top-level `const` lists with `lightPalette`, `defaultPalette`, `defaultDimens`; `flutter test` 460 passed. |

**Score:** 5/5 truths verified.

Note on truth 5: a direct re-run on this machine rewrites the committed PNGs (font rasterization differs from the machine that produced them). That predates this phase, and the ROADMAP notes sanction baseline comparison through `SCAFFOLD_CAPTURE_DIR`. I used that route; HEAD and the pre-phase baseline are pixel-identical here.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `design_tokens.json` (`scaffold` ns) | VERIFIED | Additive only |
| `tools/scaffold_codegen/generators/theme_defaults.py` + `templates/theme/const_args.dart.jinja2` | VERIFIED | Substantive, wired into runner, CI, tests |
| `lib/theme/scaffold_{palette,dimens}.dart` marker regions | VERIFIED | Spliced output equals committed text |
| `generators/__main__.py`, `COMMITTED_GENERATORS` | VERIFIED | Runner exit 0; classified-list pytest passes |
| `.gitattributes` | VERIFIED | |
| `tools/tests/fixtures/m3_tokens.css` + `--check` | VERIFIED | |
| `.github/workflows/ci.yaml` "Generator drift check" | VERIFIED | Runs both `--check` commands, runner, `git diff --exit-code lib/`, untracked check |
| `test/theme/consumer_contract_test.dart`, `scaffold_tokens_parity_test.dart` | VERIFIED | Pass |
| `example/test/capture_images_test.dart` `SCAFFOLD_CAPTURE_DIR` | VERIFIED | Used to produce the HEAD render |

### Key Links

| From | To | Status |
|------|----|--------|
| `design_tokens.json` scaffold ns | `theme_defaults.py` to Dart regions | WIRED (token edit changes `--check` result) |
| `generators/__init__.py` list | runner, CI, docs | WIRED |
| CI step | `--check` commands + runner | WIRED |

### Behavioral Spot-Checks and Gates (run by me)

| Check | Result |
|-------|--------|
| `pytest` | 74 passed |
| `ruff check` | clean |
| `theme_defaults --check` | exit 0 |
| `m3_tokens_css ... --check` | exit 0 |
| Runner then `git diff --exit-code lib/` | clean |
| `dart analyze --fatal-infos` | no issues |
| `flutter test` | 460 passed |
| Capture baseline compare | 52/52 identical |

Python used the system interpreter (3.12.10, jinja2/pytest/ruff present), not a `.venv`; none exists in this checkout.

### Requirements Coverage

| Req | Status | Evidence |
|-----|--------|----------|
| TOK-01 | SATISFIED | Truth 1 |
| TOK-02 | SATISFIED | Truth 2 (with the agreed byte-identical definition) |
| TOK-03 | SATISFIED | Truth 3, CI step |
| TOK-04 | SATISFIED | Truth 4 |

No orphaned requirements.

### Anti-Patterns

No TBD/FIXME/XXX/TODO/HACK in added lines of any file changed since e67e00c. No stubs.

### Human Verification Required

None.

### Gaps Summary

No gaps. Housekeeping only, non-blocking: REQUIREMENTS.md TOK-01..04 and ROADMAP plan/phase checkboxes still read Pending/unchecked; CLAUDE.md and CONTRIBUTING.md still say "214 tests" (actual 460).

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
