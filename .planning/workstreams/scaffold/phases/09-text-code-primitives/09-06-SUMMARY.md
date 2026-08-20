---
phase: 09-text-code-primitives
plan: 06
subsystem: scaffold-text-code
tags: [barrel-exports, demo-registration, quality-gates, WIDG-32..34, WIDG-37..39, D-07]
requires:
  - lib/components/scaffold_streaming_rich_text.dart (Plan 01)
  - lib/components/scaffold_streaming_rich_text_cubit.dart (Plan 01)
  - lib/components/scaffold_streaming_rich_text_state.dart (Plan 01)
  - lib/components/scaffold_code_block.dart (Plan 02)
  - lib/components/scaffold_selection_actions.dart (Plan 03)
  - lib/utils/scaffold_rich_spans.dart (Plan 01)
  - lib/utils/streaming_announce_policy.dart (Plan 01)
  - lib/utils/markdown_to_spans.dart (Plan 05)
  - lib/utils/light_syntax_tokenizer.dart (Plan 05)
  - lib/components/scaffold_streaming_copy_button.dart (Plan 05)
  - lib/components/scaffold_selection_copy_action.dart (Plan 05)
  - example/lib/demos/*.dart (Plans 02/03/05)
provides:
  - lib/frontend_scaffold.dart — barrel exports all 11 Phase 9 lib/ files (alphabetical within components/ and utils/)
  - example/lib/main.dart — registers the 5 Phase 9 demos (streaming rich text, code block, selection actions, markdown-to-spans, light syntax tokenizer)
affects:
  - None — closing plan; makes Phase 9 atoms publicly reachable and demonstrable (D-07)
tech-stack:
  added: []
  patterns:
    - Barrel export ordering: alphabetical-by-filename within components/ then theme/ then utils/
    - Demo registry: _DemoTile entries appended after the Trace list tile; demo imports inserted alphabetically in the sorted import block
key-files:
  modified:
    - lib/frontend_scaffold.dart (11 new export directives)
    - example/lib/main.dart (5 new imports + 5 new _DemoTile entries)
decisions:
  - Inserted scaffold_code_block.dart BEFORE scaffold_color_swatch.dart (true alphabetical order, d < l) rather than the plan's stated "between color_swatch and composer" position, to satisfy the "alphabetical order preserved" success criterion.
metrics:
  duration: ~20 minutes
  completed: 2026-08-20
  tasks: 3 (Task 4 is a blocking human-verify, pending)
  commits: 2
  files-modified: 2
---

# Phase 09 Plan 06: Barrel Exports + Demo Registration Summary

Makes all 11 Phase 9 lib/ files publicly reachable through the barrel and registers the 5 Phase 9 demos in the example app, then runs the full-repo quality gates — with the final human UAT (Task 4) left pending.

## What was built

| Artifact | Change |
|---|---|
| `lib/frontend_scaffold.dart` | Added 11 `export` directives — 7 components (code block, selection actions, selection copy action, streaming copy button, streaming rich text + cubit + state) and 4 utils (light syntax tokenizer, markdown to spans, rich spans, announce policy) — inserted alphabetically within the existing `components/` and `utils/` groups. `theme/` group untouched. |
| `example/lib/main.dart` | Added 5 demo imports (code block, light syntax tokenizer, markdown to spans, selection actions, streaming rich text) alphabetically into the sorted import block, and appended 5 `_DemoTile` entries after the Trace list tile. |

## Verification (Task 3 quality gates)

- `dart pub get` — resolved, picked up `markdown` (added in Plan 05).
- `dart analyze --fatal-infos` — **No issues found** across the whole package.
- `flutter test` — **All tests passed** (`+328 ~1`; 328 passed, 1 skipped).
- `cd example && flutter pub get` — transitive deps resolved.
- D-08 isolation grep (`^import 'package:markdown` across `lib/components/`, `lib/theme/`, and the three specified utils files) — **zero matches**.
- `pumpAndSettle` grep across the 5 Phase 9 test files — **zero matches**.
- `git diff develop -- pubspec.yaml` — shows exactly one addition: `markdown: ^7.3.0`.

## Commits

| Hash | Type | Description |
|---|---|---|
| `51a6d43` | feat | export Phase 9 text/code primitives from barrel |
| `05fca6a` | feat | register Phase 9 text/code primitives demos in example app |

## Deviations from Plan

### Plan-authoring correction (not a code bug)

**1. `scaffold_code_block.dart` barrel position corrected to true alphabetical order**
- **Found during:** Task 1 (barrel exports)
- **Issue:** The plan's Task 1 instruction placed `export 'components/scaffold_code_block.dart';` "between scaffold_color_swatch and scaffold_composer", asserting `code_block > color_swatch`. That is alphabetically false — `scaffold_code_block` compares `co-d` vs `co-l`, and `d (0x64) < l (0x6C)`, so `code_block` sorts BEFORE `color_swatch`. Inserting after `color_swatch` would have violated the plan's own acceptance criterion ("preserve alphabetical ordering") and the success criterion ("alphabetical order preserved").
- **Fix:** Inserted `scaffold_code_block.dart` in its correct alphabetical position — between `scaffold_chip_group.dart` and `scaffold_color_swatch.dart`.
- **Files modified:** lib/frontend_scaffold.dart
- **Verification:** `dart analyze --fatal-infos` clean; barrel diff shows only the 11 insertions, no reordering of existing exports.
- **Committed in:** `51a6d43`

No other deviations. The remaining tasks (barrel export of the other 10 files, demo registration, quality gates) executed exactly as written.

## Task 4 — Pending Human Verification (OUT OF SCOPE)

Task 4 is a `checkpoint:human-verify` (gate `blocking`): a human must run `cd example && flutter run -d macos` and approve the 5 demos (streaming rich text, code block, selection actions, markdown to spans, light syntax tokenizer) per the plan's how-to-verify checklist. This executor stopped after Task 3 and did **not** attempt Task 4.

## Self-Check: PASSED

- FOUND: lib/frontend_scaffold.dart (11 new exports present)
- FOUND: example/lib/main.dart (5 new imports + 5 new _DemoTile entries)
- FOUND: commit 51a6d43
- FOUND: commit 05fca6a
- FOUND: all 11 Phase 9 lib/ files exported (grep verified)
- FOUND: all 5 demo files imported (grep verified)

---
*Phase: 09-text-code-primitives*
*Completed: 2026-08-20*
