---
phase: 12-token-pipeline
plan: 03
subsystem: codegen
tags: [ci, drift-check, generators-runner, consumer-contract, capture-harness]
requires:
  - "12-01 theme_defaults generator and --check"
  - "12-02 m3_tokens_css --check and CSS snapshot"
provides:
  - "python -m scaffold_codegen.generators runner over COMMITTED_GENERATORS"
  - "CI step 'Generator drift check' in the python job"
  - "test/theme/consumer_contract_test.dart (GCS const extension lists)"
  - "SCAFFOLD_CAPTURE_DIR override in the capture harness"
affects: [phase-13-theme-fields]
tech-stack:
  added: []
  patterns:
    - "single classified tuple of generator modules, enforced by a pkgutil test"
    - "subprocess-per-generator runner that stops on first failure"
key-files:
  created:
    - tools/scaffold_codegen/generators/__main__.py
    - tools/tests/test_generators_runner.py
    - test/theme/consumer_contract_test.dart
  modified:
    - tools/scaffold_codegen/generators/__init__.py
    - .github/workflows/ci.yaml
    - CONTRIBUTING.md
    - README.md
    - templates/README.md
    - CLAUDE.md
    - example/test/capture_images_test.dart
key-decisions:
  - "COMMITTED_GENERATORS and CONSUMER_GENERATORS in generators/__init__.py are the only list of families; CI and docs call the runner."
  - "The runner uses a subprocess per module so each driver keeps its documented argv handling."
metrics:
  duration: "about 25 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 9000
  tasks: 3
  commits: 3
---

# Phase 12 Plan 03: Drift gate in CI, docs, consumer contract Summary

CI now regenerates every committed family and fails on any diff, the theme token family is documented, and a consumer-contract test plus a capture re-run show nothing a consumer sees moved.

## What was built

- Runner: `python -m scaffold_codegen.generators` runs the six committed generators in order and stops on the first non-zero exit. A pytest fails when a generator module is not classified as committed or consumer-space.
- CI: python-job step `Generator drift check` runs `theme_defaults --check`, `m3_tokens_css ... --check`, the runner, `git diff --exit-code lib/` and an untracked-file check on `lib/`. The dart job is unchanged.
- Docs: CONTRIBUTING (Theme tokens, Drift check, Line endings, family row, check line), README table row, templates/README `theme/` bullet, CLAUDE.md generated-regions sentence and the corrected CI note.
- `consumer_contract_test.dart`: top-level `const List<ThemeExtension<dynamic>>` lists matching GeniusCognitiveSystem (lightPalette, defaultPalette, defaultDimens) with identity assertions: 3 tests.
- `capture_images_test.dart`: `_captureDir()` reads `SCAFFOLD_CAPTURE_DIR`, default `../images`; all three write sites use it.

## Capture gate

Baseline comparison, not direct. A direct re-run changed 52 PNGs (committed images were rasterized on another machine), so `images/` was restored with `git checkout -- images/`. HEAD was rendered to a scratch directory with `SCAFFOLD_CAPTURE_DIR` and `e67e00c` was rendered in a temporary worktree on this machine. `diff -rq` over the 52 harness PNGs printed nothing, so no nondeterministic captures. The worktree was removed and `git status --porcelain images/` is empty.

## Phase gate at head (all ran)

- `dart analyze --fatal-infos`: no issues
- `flutter test`: 460 passed
- `ruff check`: clean
- `pytest`: 74 passed
- `theme_defaults --check`: exit 0
- `m3_tokens_css ... --check`: exit 0
- runner then `git diff --exit-code lib/`: clean
- GeniusCognitiveSystem harness (`gcs-check.sh develop`): 0 codegen failures, pub get 0, 60 tests pass, 50 analyze errors all in scaffold/example (baseline), 0 in app code. Submodule restored to 8ada743; nothing committed in GCS.

## Deviations from Plan

None to behavior. Execution notes:

- CLAUDE.md's "the manual drift check" wording (line 31) was left untouched because the plan limits CLAUDE.md to two edits. It is now slightly stale and can be fixed in a later pass.
- The docs commit was amended twice before moving on (a mis-escaped `newline="\n"` in CONTRIBUTING and trimming the CLAUDE.md edit to 4 changed lines). Final hash below.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. T-12-10 to T-12-12 mitigations are implemented: CI drift step plus classification test, consumer contract test, and a runner that takes no options and uses a fixed tuple with `sys.executable`.

## Commits

- b6d4e2a: ci(12-03): TOK-03 run generator drift check in CI
- 7428dbe: docs(12-03): TOK-03 document theme token family and CI drift check
- e4422c3: test(12-03): TOK-02 add consumer contract test and SCAFFOLD_CAPTURE_DIR override

## Self-Check: PASSED

All created files exist and all three commits are in `git log`.
