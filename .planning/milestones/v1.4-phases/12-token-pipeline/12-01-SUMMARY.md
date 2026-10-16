---
phase: 12-token-pipeline
plan: 01
subsystem: theme-codegen
tags: [design-tokens, jinja2, codegen, dart-theme, drift-check]
requires: []
provides:
  - "scaffold namespace in design_tokens.json (palette.dark, palette.light, dimens)"
  - "python -m scaffold_codegen.generators.theme_defaults [--check]"
  - "scaffold_codegen.LIB_THEME_DIR"
  - "GENERATED / END GENERATED marker regions in lib/theme/scaffold_palette.dart and scaffold_dimens.dart"
affects: [phase-13-theme-fields, phase-14-aa-fixes, phase-15-midnight-preset, 12-03-ci-wiring]
tech-stack:
  added: []
  patterns:
    - "marker-region splice into committed Dart"
    - "json parse_float=Decimal to keep literal digits"
    - "value + dartRef alias for colors the Dart source writes as ScaffoldColors references"
key-files:
  created:
    - tools/scaffold_codegen/generators/theme_defaults.py
    - templates/theme/const_args.dart.jinja2
    - tools/tests/test_theme_defaults.py
    - test/theme/scaffold_tokens_parity_test.dart
  modified:
    - design_tokens.json
    - tools/scaffold_codegen/__init__.py
    - lib/theme/scaffold_dimens.dart
    - lib/theme/scaffold_palette.dart
key-decisions:
  - "Byte-identical means every Dart value unchanged plus six added marker comment lines (two per region); no existing line is removed or altered."
  - "Literal encoders live in the driver (single owner) instead of a separate dart_literals.py."
  - "Generation reads only the repo design_tokens.json; the CLI has no token-path option (LD-06)."
metrics:
  duration: "about 25 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 7300
  tasks: 2
  commits: 2
---

# Phase 12 Plan 01: Token pipeline, Dart defaults Summary

design_tokens.json now feeds the default `ScaffoldPalette` (dark and light) and `ScaffoldDimens` values through a Jinja2 driver that splices between marker comments, with a `--check` drift mode and a Dart parity test.

## What was built

- Additive `scaffold` namespace (22 dark, 22 light, 21 dimens entries). The M3 keys `_comment`, `color`, `typography`, `shape`, `elevation` are value-identical to e67e00c and keep their order.
- `theme_defaults.py`: `load_tokens` (Decimal floats), `dart_double`, `dart_color`, `render_files`, `run`, `main`. LF-only writes. No CLI option for another token file.
- `templates/theme/const_args.dart.jinja2`: one `    name: literal,` line per entry.
- Six marker comment lines in lib/theme. Against e67e00c the numstat is `4 0` (palette) and `2 0` (dimens).
- 31 pytest cases in `tools/tests/test_theme_defaults.py`, plus 3 Dart parity tests.

## Byte-identity definition

"Byte-identical" here means values unchanged plus six marker comment lines. The two Dart files differ from e67e00c only by those six added lines; every const default value, and every pre-existing line, is untouched.

## Verification

- pytest: 31 passed. `--check` exits 0. ruff clean on this plan's files.
- `dart analyze --fatal-infos lib test/theme`: no issues.
- `flutter test test/theme`: 24 passed (21 pre-existing plus 3 new parity tests). Existing palette and dimens token tests are unmodified.
- M3 key equality against e67e00c: True.

## Deviations from Plan

None. The plan was executed as written. Task 1 (tracer) was committed and its automated verify passed before Task 2 began, per the orchestrator instruction to treat the tracer as auto.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. T-12-01 to T-12-05 mitigations are implemented: full-match validators, no path options on the CLI, fixed marker text.

## Commits

- ea592ce: refactor(12-01): TOK-02 generate ScaffoldDimens defaults from design_tokens.json
- 7fe0c54: refactor(12-01): TOK-01 generate ScaffoldPalette defaults from design_tokens.json

## Self-Check: PASSED

All created files exist and both commits are present in `git log`.
