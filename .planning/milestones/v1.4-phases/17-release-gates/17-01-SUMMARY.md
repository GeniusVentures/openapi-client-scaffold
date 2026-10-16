---
phase: 17-release-gates
plan: 01
subsystem: tooling
tags: [capture-gate, git-history, ci, pytest]
requires:
  - phase: 14-default-accessibility-fixes
    provides: sanctioned default capture commits (14-COLOR-CHANGES.md)
  - phase: 16-component-restyles
    provides: sanctioned midnight capture commits (16-RESTYLES.md)
provides:
  - tools/capture_gate.py with history and render subcommands
  - tools/capture_rebaselines.json (base plus 14 sanctioned v1.4 capture commits)
  - history gate in pytest and full-history checkout in the CI python job
affects: [17-03]
tech-stack:
  added: []
  patterns: [manifest-sanctioned changes to committed binary fixtures]
key-files:
  created:
    - tools/capture_gate.py
    - tools/capture_rebaselines.json
    - tools/tests/test_capture_gate.py
  modified:
    - .github/workflows/ci.yaml
key-decisions:
  - "The manifest is the only sanction mechanism (PD-02)"
  - "Render check is local only; CI runs the history check through pytest (PD-06)"
requirements-completed: [GATE-01]
status: complete
actuals:
  tokens: 22000
  tasks: 3
  commits: 4
---

# Phase 17 Plan 01: Capture Gate Summary

A stdlib-only capture gate that fails when an existing capture changes outside a manifest-listed commit, plus a render check that re-runs the harness and diffs images/ byte for byte.

## Results

- `python tools/capture_gate.py history` exits 0 on develop: 14 capture commits, 14 sanctioned, 0 violations.
- Removing the d9342ff entry makes it exit 1 and name that commit. A malformed manifest exits 2.
- `python tools/capture_gate.py render` exits 0: 52 default and 54 midnight PNGs rendered, 0 differences, nothing written into images/. `--flutter does-not-exist` exits 2.
- Rules R1 to R6, manifest validation and the unreachable-base message (names `fetch-depth: 0`) are covered by tests.
- Full suite: 225 pytest tests pass; `ruff check` clean.
- The manifest was generated from git, then checked against 14-COLOR-CHANGES.md (5 default SHAs) and 16-RESTYLES.md plus bc8d692 (9 midnight SHAs).

## Commits

- 61ca748 feat(17-01): capture history gate with the v1.4 re-baseline manifest (GATE-01)
- 1b7ea32 test(17-01): failing tests for capture gate isolation and manifest rules (GATE-01)
- 0d4f597 feat(17-01): enforce PNG-only, scope and manifest integrity in the capture gate (GATE-01)
- 43c4cc6 feat(17-01): capture render check against a fresh harness run (GATE-01)

## Deviations from Plan

**1. [Rule 3 - Blocking] New files needed tracking before `git commit -- <paths>`**
- Used `git add -N` on the three new files only, then committed by path. No other paths staged.

**2. [Rule 1 - Bug] `git merge-base --is-ancestor` returns 128 for an unknown base**
- `_git` now takes an allowed-exit-code tuple so an unreachable base raises the `fetch-depth: 0` message instead of a raw git error. Done in Task 1, before commit.

**3. Minor additions beyond the plan text**
- The render subcommand removes its scratch dir when the harness itself fails.
- The tracer's human-verify gate was handled by running the automated verify, per the orchestrator.

## Known Stubs

None.

## Threat Flags

None. T-17-01 to T-17-03 and T-17-05 are mitigated as planned (T-17-04 accepted).

## Self-Check: PASSED

Files and the four commits above exist; history, render, pytest and ruff were all run after the final commit.
