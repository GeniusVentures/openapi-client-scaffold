---
phase: 12-token-pipeline
plan: 02
subsystem: codegen
tags: [line-endings, gitattributes, drift-check, m3-tokens-css]
requires: []
provides:
  - "LF output from engine.render_template and m3_tokens_css.main on every OS"
  - ".gitattributes pinning LF (text=auto eol=lf, *.png binary)"
  - "python -m scaffold_codegen.m3_tokens_css ... --check (exit 1 on missing or differing output, never writes)"
  - "tools/tests/fixtures/m3_tokens.css snapshot generated from e67e00c"
affects: [12-03-ci-wiring, phase-13-theme-fields]
tech-stack:
  added: []
  patterns:
    - "AST guard test over tools/scaffold_codegen for newline=\"\\n\" on every text writer"
    - "byte comparison of generated CSS with a committed snapshot"
key-files:
  created:
    - .gitattributes
    - tools/tests/test_codegen_writes_lf.py
    - tools/tests/test_m3_tokens_css_drift.py
    - tools/tests/fixtures/m3_tokens.css
  modified:
    - tools/scaffold_codegen/engine.py
    - tools/scaffold_codegen/m3_tokens_css.py
    - .planning/workstreams/scaffold/research/FEATURES.md
key-decisions:
  - "The CSS snapshot is generated from e67e00c's design_tokens.json, so it predates the additive scaffold namespace and proves m3_tokens.css bytes are unchanged."
  - "--check is optional; --tokens and --output stay required and imports stay stdlib-only so the CMake bare-script call is unchanged."
metrics:
  duration: "about 20 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 3500
  tasks: 3
  commits: 3
---

# Phase 12 Plan 02: LF writers, .gitattributes, CSS drift check Summary

Every codegen writer now emits LF on Windows, git pins LF, and `m3_tokens_css --check` compares generated CSS against a committed snapshot.

## What was built

- `engine.render_template` and `m3_tokens_css.main` pass `newline="\n"`. A pytest walks every `.py` under `tools/scaffold_codegen` and fails any `write_text` or text-mode write `open` without it. It also covers 12-01's `theme_defaults.py`.
- Regenerating the five committed widget families on this Windows machine leaves `git diff --exit-code lib/components/` clean.
- `.gitattributes`: `* text=auto eol=lf` and `*.png binary`. The only CRLF index entry, `research/FEATURES.md`, was renormalized (line endings only, empty diff with `--ignore-cr-at-eol`). `git ls-files --eol` now shows 0 `i/crlf`, and all 82 PNGs remain `i/-text`.
- `--check` on `m3_tokens_css`: exit 1 with "out of date" on a missing or differing output, exit 0 when equal, no write in check mode.
- `tools/tests/fixtures/m3_tokens.css` generated from `git show e67e00c:design_tokens.json`. `--check` against both the e67e00c tokens and the current `design_tokens.json` exits 0, so the `scaffold` namespace leaves the CSS bytes unchanged.

## Verification

- Full `pytest`: 70 passed (3 LF tests, 6 drift tests, existing `test_m3_tokens_css.py` unmodified). `ruff check`: clean.
- Bare-script runs without PYTHONPATH pass for both write and `--check`, matching the CMake invocation.

## Deviations from Plan

None to the plan's behavior. Two execution notes:

- `git commit -- <paths>` re-read the CRLF working copy of `FEATURES.md` and left the renormalized blob staged. The commit was amended once so the LF blob is in `192f868`. `git status` is clean.
- The working copy of `FEATURES.md` still has CRLF bytes on disk. Git treats it as clean under `eol=lf`.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. T-12-06 to T-12-09 mitigations are implemented: stdlib-only imports, snapshot plus inertness test, AST guard plus `.gitattributes`, and a renormalize limited to the one listed path.

## Commits

- 65dd91a: fix(12-02): TOK-04 write LF from engine and m3_tokens_css
- 192f868: chore(12-02): TOK-04 pin LF with .gitattributes
- 24c2636: feat(12-02): TOK-03 add CSS snapshot and m3_tokens_css --check

## Self-Check: PASSED

All created files exist and all three commits are in `git log`.
