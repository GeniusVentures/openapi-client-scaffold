---
phase: 17-release-gates
plan: 02
subsystem: tooling
tags: [consumer-check, gcs, harness, notice]
requires:
  - phase: 17-release-gates
    provides: 17-01 capture gate (plan dependency)
  - phase: 14-default-accessibility-fixes
    provides: 14-COLOR-CHANGES.md
provides:
  - tools/consumer_check/gcs_check.sh, a portable GCS consumer harness
  - tools/tests/test_consumer_check.py, a portability guard
  - 17-GCS-NOTICE.md, an unsent draft notice for the GCS team
affects: [17-03]
tech-stack:
  added: []
  patterns: [harness restores the consumer submodule on exit]
key-files:
  created:
    - tools/consumer_check/gcs_check.sh
    - tools/tests/test_consumer_check.py
    - .planning/workstreams/scaffold/phases/17-release-gates/17-GCS-NOTICE.md
  modified: []
key-decisions:
  - "Harness is a close bash port of the session harness; only machine knowledge removed and fail-early guards added (PD-09)"
  - "The notice is a draft file only; sending stays with the owner (UN-04)"
requirements-completed: [GATE-02]
status: complete
actuals:
  tokens: 14000
  tasks: 2
  commits: 3
---

# Phase 17 Plan 02: GCS Harness and Notice Summary

The GCS consumer check now lives in the repo with no machine paths, reproduces the session harness at develop, and the v1.4 color notice is drafted (not sent).

## Harness result at develop (scaffold 9840f09)

Session harness and `tools/consumer_check/gcs_check.sh "$GCS/src/app" develop` printed the same summary. The only difference is the analyze run time (2.5s vs 2.0s).

```
== scaffold at 9840f09
== SUMMARY ref=local-scaffold/develop
codegen failures (of 12): 0
pub get exit: 0
analyze:      57 error  | 57 issues found.
analyze issues in scaffold/example (baseline noise): 57
analyze issues in app code (lib/test): 0
test: 00:01 +60 ~1: All tests passed!
submodule restored to 8ada743
```

- The 57 issues are all under `scaffold/example` (same kind as the 50 baseline plus 7 from demos added to the example test file). No new kind.
- After both runs the GCS submodule HEAD was 8ada743fbb61aecf727dbb78acc9cf29cbc54ff5 (as recorded before) and `git status --porcelain` in GCS was empty.
- Guard check: an empty temp dir as app dir exits 2 ("is not a git work tree") and changes nothing.
- Nothing was committed, pushed or filed in GCS.

## Notice

`17-GCS-NOTICE.md` starts with a "DRAFT, NOT SENT" marker. It lists all 21 distinct color values from 14-COLOR-CHANGES.md (verified by script), the two fallback behavior changes with the GCS consequence (GCS's light theme registers the light palette, so the role choice is unchanged for it), what did not change, midnight opt-in, the keep-the-old-look snippet, and the harness numbers. The snippet was compiled and asserted in a scratch test under `test/theme/` (passed, `dart analyze --fatal-infos` clean), then deleted; `git status --porcelain -- test` is empty.

## Commits

- 9840f09 feat(17-02): in-repo GCS consumer check harness (GATE-02)
- d893751 chore(17-02): mark the consumer check harness executable (GATE-02)
- 0212661 docs(17-02): draft GCS notice for the v1.4 default color changes (GATE-02)

## Deviations from Plan

**1. [Rule 1 - Bug] Executable bit lost in the first commit**
- `git commit -- <paths>` takes file mode from the working tree (644 on Windows), overriding `git update-index --chmod=+x`.
- Fixed in a separate mode-only commit, d893751. The script content (blob a3b8390) is identical, so the harness runs at 9840f09 still apply.

**2. Minor**
- The notice's keep-the-old-look section registers roles for both themes (light roles and a dark `borderControl` override), since each `ThemeData` takes one roles extension and the dark `borderControl` also changed.
- The tracer/human-verify gates did not apply. The "Tested against" line cites 9840f09, the commit the harness ran at; 17-03 updates it.
- The matcher test checks that each pattern name is among the hits for its sample, which tolerates a sample matching more than one pattern.

## Known Stubs

None.

## Threat Flags

None. T-17-06 to T-17-09 mitigated as planned (restore trap and guards, portability test, draft-only notice, value cross-check and compiled snippet).

## Self-Check: PASSED

Harness, test and notice files exist; commits 9840f09, d893751 and 0212661 exist; harness file mode is 100755 in HEAD; ruff and 229 pytest tests pass after the last commit.
