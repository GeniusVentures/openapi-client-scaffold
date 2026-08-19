---
quick_id: 260818-oe8
type: execute
status: complete
date: 2026-08-18
commit: 7c598a7
files_modified:
  - src/scaffold/CMakeLists.txt
---

# Quick Task 260818-oe8: CMakeLists.txt Source A / Source B template_gen stamp dirs

## One-liner

Inserted `make_directory` for the nested `template_gen/{scaffold,shared}/base/` stamp directories into the two Source A / Source B `add_custom_command` blocks so `cmake -E touch` no longer fails on a fresh build tree.

## Outcome

`scaffold_generate_templates` now builds successfully on a clean configure with no manual `mkdir` step. The incremental-stamp contract still holds (re-running the target is a no-op), and `generate_all_components` continues to build (regression check passed).

## Changes

Exactly four lines added to `src/scaffold/CMakeLists.txt` — no other edits, no reordering, no refactoring:

1. **Source A** (scaffold's own `templates/base/*.jinja2`): inserted as the FIRST `COMMAND` inside the `add_custom_command`:
   ```cmake
   COMMAND ${CMAKE_COMMAND} -E make_directory
       "${CMAKE_CURRENT_BINARY_DIR}/template_gen/scaffold/base"
   ```

2. **Source B** (parent M3 templates from `TEMPLATES_DIR`): inserted as the FIRST `COMMAND` inside the `add_custom_command`:
   ```cmake
   COMMAND ${CMAKE_COMMAND} -E make_directory
       "${CMAKE_CURRENT_BINARY_DIR}/template_gen/shared/base"
   ```

Both match the existing component-target precedent (line 216) — same invocation shape, multi-line continuation, quoted path.

## Why only the stamp dirs

`tools/scaffold_codegen/engine.py` line 143 already does `out.parent.mkdir(parents=True, exist_ok=True)` for the *output* paths. Only the stamp paths (touched by CMake at the end of each custom command) needed CMake-side directory creation. No `make_directory` was added for `${GENERATED_DIR}/...` — that would have been redundant.

## Verification

All performed in a throwaway build tree `/tmp/fresh-build-260818-oe8`:

- Fresh configure succeeded: `cmake -B /tmp/fresh-build-260818-oe8 -S /Users/Shared/SSDevelopment/Development/GeniusVentures/GeniusNetwork/apps/genius-tube/src/scaffold -DPYTHON3_EXECUTABLE=$(which python3)`
- `cmake --build /tmp/fresh-build-260818-oe8 --target scaffold_generate_templates` succeeded — rendered `base/m3_base_layout.jinja2`
- Stamp file present: `/tmp/fresh-build-260818-oe8/template_gen/scaffold/base/m3_base_layout.stamp`
- `template_gen/shared/base/` correctly absent — `TEMPLATES_DIR` points back at the scaffold's own templates dir, so Source B is skipped per the existing `if(NOT TEMPLATES_DIR STREQUAL _scaffold_templates_dir)` guard. The Source B fix is structurally identical to Source A and only activates when a consumer points `TEMPLATES_DIR` at an external M3 tree.
- Incremental rebuild of `scaffold_generate_templates` was a no-op (`Built target` with no re-render) — stamp contract preserved.
- Regression check: `cmake --build /tmp/fresh-build-260818-oe8 --target generate_all_components` succeeded — all 18 widget/cubit/state files rendered.
- Diff confirmed exactly two inserted `make_directory` COMMAND blocks (4 added lines, 0 removals, 0 modifications).

## Commit

- `7c598a7` — `fix(cmake): create template_gen/{scaffold,shared}/base dirs before stamp touch in Source A/B`

## Deviations

None — plan executed exactly as written.

## Self-Check: PASSED

- CMakeLists.txt exists and contains both `make_directory` insertions (verified via `git diff` output above).
- Commit `7c598a7` exists on branch `gsd/phase-08-supporting-atoms-table-cells-light-palette`.
- Pre-existing uncommitted UAT work (`lib/components/scaffold_focus_outline.dart`, `example/lib/demos/composer_demo.dart`, `test/`, `.planning/`) untouched — only `CMakeLists.txt` was staged and committed.
