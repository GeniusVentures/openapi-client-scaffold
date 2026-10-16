---
phase: 17-release-gates
plan: 03
subsystem: release-gates
tags: [docs, capture-gate, consumer-check, milestone-wrap]
requires:
  - phase: 17-release-gates
    provides: 17-01 capture gate, 17-02 GCS harness and notice
provides:
  - CONTRIBUTING.md capture gate and consumer check sections
  - 17-GATES.md, the v1.4 release gate record at one head
  - REQUIREMENTS, ROADMAP and STATE closed for v1.4
affects: [complete-milestone]
tech-stack:
  added: []
  patterns: [gate record pinned to one SHA, later commits touch only .planning]
key-files:
  created:
    - .planning/workstreams/scaffold/phases/17-release-gates/17-GATES.md
  modified:
    - CONTRIBUTING.md
    - CLAUDE.md
    - README.md
    - .planning/workstreams/scaffold/phases/17-release-gates/17-GCS-NOTICE.md
    - .planning/workstreams/scaffold/REQUIREMENTS.md
    - .planning/workstreams/scaffold/ROADMAP.md
    - .planning/workstreams/scaffold/STATE.md
key-decisions:
  - "Gate head is f6b99d3, the docs commit; every later commit touches only .planning/"
requirements-completed: [GATE-01, GATE-02]
status: complete
actuals:
  tokens: 20000
  tasks: 3
  commits: 3
---

# Phase 17 Plan 03: Release Gates Summary

Both gates are documented, every release gate passed at head f6b99d3, and v1.4 reads 20 of 20 requirements complete.

## Gate results at f6b99d3

- dart analyze --fatal-infos clean in root and example/; flutter test 1464 passed; example preset switcher test 2 passed.
- ruff clean; pytest 229 passed (includes the history gate); the three --check commands exit 0; the runner leaves lib/ clean.
- Capture history: 14 capture commits, 14 sanctioned, 0 violations. Render: 52 default and 54 midnight PNGs, 0 differences. Default captures moved only in the five 14-COLOR-CHANGES.md commits.
- GCS harness: 0 of 12 codegen failures, pub get 0, 0 app-code issues, +60 tests. GCS submodule HEAD (8ada743) and status unchanged.
- M3 keys (color, typography, shape, elevation) equal to e67e00c; consumer_contract_test passed.
- Full record: 17-GATES.md.

## Commits

- f6b99d3 docs(17-03): capture gate and consumer check docs (GATE-01, GATE-02)
- c33f32e docs(17-03): v1.4 release gate record (GATE-01, GATE-02)
- 7b9a67c docs(17-03): v1.4 milestone wrap, 20 of 20 requirements complete

## Deviations from Plan

**1. [Rule 1 - Plan check error] CSS snapshot freeze check**
- The plan's `git diff --quiet e67e00c -- tools/tests/fixtures/m3_tokens.css` cannot pass: the fixture did not exist at e67e00c (added in 24c2636, Phase 12).
- Replaced with an equivalent, stronger check: CSS generated from e67e00c's design_tokens.json is byte-identical to the committed snapshot, and no commit changed the snapshot after 24c2636. Recorded in 17-GATES.md. The plan's final combined verify command fails on that one clause for the same reason.

**2. Minor**
- 17-GATES.md needed `git add` before the path-limited commit, since it was a new file.
- The CI `fetch-depth: 0` was already in place from 17-01; CONTRIBUTING.md now states it.
- Docs state that a manifest entry's `follows` is the capture commit's first parent and `subject` must match exactly, as the gate code enforces.

## Owner next steps

Send 17-GCS-NOTICE.md to the GCS team; merge develop to main with a merge commit; run `/gsd-complete-milestone --ws scaffold`; then v1.3 kickoff. Nothing was sent, pushed or filed.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

17-GATES.md exists; commits f6b99d3, c33f32e and 7b9a67c exist; wrap verify script printed "wrap ok"; no code file changed after f6b99d3.
