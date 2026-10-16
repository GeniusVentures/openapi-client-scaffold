---
phase: 15-midnight-preset
plan: 07
subsystem: docs-and-gate
tags: [docs, gate, gcs, midnight]
requires:
  - "15-06 (midnight captures)"
provides:
  - "README midnight preset section, CONTRIBUTING preset token docs, CLAUDE.md generated-files clause"
  - "Phase 15 gate results at one head"
affects: [16, 17]
key-files:
  modified:
    - README.md
    - CONTRIBUTING.md
    - CLAUDE.md
key-decisions:
  - "No CI change: the generator --check steps already work from the repo root; a test pins that."
requirements-completed: [PRE-01, PRE-02, PRE-03, A11Y-03]
metrics:
  completed: 2026-10-16
status: complete
actuals:
  tokens: 9000
  tasks: 2
  commits: 1
---

# Phase 15 Plan 07: Docs and phase gate Summary

The midnight preset is documented for consumers and maintainers, and every phase gate passes at head b9b5413.

## Commits

| SHA | Content |
|---|---|
| b9b5413 | docs(15-07): README, CONTRIBUTING, CLAUDE.md |

CLAUDE.md differs by one edited sentence. The stale test count was left alone.

## Gate results (head b9b5413, clean tree)

| Check | Result |
|---|---|
| dart analyze --fatal-infos, root and example/ | No issues found (both) |
| flutter test, root | 1225 passed |
| flutter test test/preset_switcher_test.dart, example/ | 2 passed |
| ruff check | All checks passed |
| pytest | 182 passed (includes brand scan, 4 tests) |
| theme_defaults --check | exit 0 |
| theme_presets --check | exit 0 |
| m3_tokens_css --check | exit 0 |
| generators, then git diff --exit-code lib/ and git status --porcelain -- lib/ | clean |
| Defaults frozen since 0fe6608 (design_tokens.json, barrel, lib/theme/scaffold_*.dart, CSS snapshot) | unchanged |
| lib/components and lib/utils since 0fe6608 | 0 non-comment changed lines |
| Captures: fresh render vs images/ | 52 + 52 files byte-identical, no DIFF |
| git log 0fe6608..HEAD -- images ':!images/midnight' | empty |
| git log 0fe6608..HEAD -- images/midnight | bc8d692 only (MIDNIGHT_CAPTURES) |

## CI working directory (gate item 1)

The "exit 1 from repo root" seen in 15-04 came from running `python -m scaffold_codegen...` with no `PYTHONPATH` and no install: `scaffold_codegen` lives in `tools/`, so from the root the module is not found (`ModuleNotFoundError`). It is an import path problem, not a cwd problem. Checked at this head:

- With `PYTHONPATH=tools` from the repo root, `theme_defaults --check`, `theme_presets --check` and `m3_tokens_css --check` all exit 0. The generators locate files through `REPO_ROOT` in `scaffold_codegen/__init__.py`, so they do not depend on cwd.
- `.github/workflows/ci.yaml` runs from the repo root after `python -m pip install -e ".[dev]"` (setuptools `where = ["tools"]`), which makes the package importable. The drift step is correct as written, so no workflow change.
- Already tested: `test_theme_presets.py`, `test_theme_defaults.py` and `test_m3_tokens_css_drift.py` run the CLIs as subprocesses with `cwd=REPO_ROOT` and `PYTHONPATH=tools`. No new test needed.

## GCS harness (gcs-check.sh develop, head b9b5413)

```
== scaffold at b9b5413
== SUMMARY ref=local-scaffold/develop
codegen failures (of 12): 0
pub get exit: 0
analyze:      57 error  | 57 issues found. (ran in 10.0s)
analyze issues in scaffold/example (baseline noise): 57
analyze issues in app code (lib/test): 0
test: 00:01 +60 ~1: All tests passed!
submodule restored to 8ada743
```

Noise is 57, 4 above the baseline of 53. The 4 new issues are all in `scaffold/example/test/preset_switcher_test.dart` (the file this phase added). Same kinds as the baseline, because the example package does not resolve in GCS:

| Line | Kind |
|---|---|
| 6:8 | uri_does_not_exist (`package:frontend_scaffold_example/main.dart`) |
| 9:41 | undefined_identifier (`HomePage`) |
| 21:35 | creation_with_non_type (`ScaffoldExampleApp`) |
| 42:35 | creation_with_non_type (`ScaffoldExampleApp`) |

The other 53 are the unchanged capture_images_test.dart baseline. 0 app-code issues, so nothing is new in kind.

## Requirement closure

| Req | Evidence |
|---|---|
| PRE-01 | midnightTheme / midnightExtensions in `lib/theme/presets/`, deep import only (barrel byte-identical to 0fe6608); 1225 root tests pass; README documents the opt-in |
| PRE-02 | Brand scan passes (pytest 182); preset tokens in `tokens/midnight.json` drift-checked by `theme_presets --check`; README and CONTRIBUTING use neutral wording |
| PRE-03 | Example preset switch (preset_switcher_test, 2 passed); 52 captures in images/midnight/ equal a fresh render; default captures untouched |
| A11Y-03 | palette_contrast_test and midnight_theme_contrast_test pass in the full run; README lists the AA adjustments |

## Deviations from Plan

**1. Plan 15-06 unplanned fix commit 9b367e9 (accounted for)**
- `fix(15-06)` applied the sans font family to the midnight text styles reused by appBarTheme and tabBarTheme (lib/theme/presets/midnight_theme.dart). It is inside the checked range, changes only the opt-in preset, and sits before the midnight capture commit. The gate above ran at a head that includes it: lib/theme/scaffold_*.dart, the barrel and the default captures are unchanged, and the midnight captures equal a fresh render.

**2. CONTRIBUTING gradient format** follows the actual token file: radial `center` is an `[x, y]` list, not an alignment name as the plan text said.

No other deviations.

## Known Stubs

None.

## Self-Check: PASSED

b9b5413 exists on develop; README.md, CONTRIBUTING.md and CLAUDE.md contain the expected strings (midnightTheme 3, generators.theme_presets 2, tokens/midnight.json 1, tabularFigures 1); working tree was clean before this file.
