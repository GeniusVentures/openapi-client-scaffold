---
phase: 08-supporting-atoms-table-cells-light-palette
plan: 02
subsystem: components/data-table
tags: [codegen-template, cell-builder, widget-test, WIDG-43]
requirements: [WIDG-43]
requires:
  - templates/components/data_table.dart.jinja2 (pre-existing DataColumnConfig + cell render path)
  - lib/theme/scaffold_theme.dart (scaffoldThemeExtensions for pump helper)
provides:
  - DataColumnConfig.cellBuilder optional field (Widget Function(BuildContext, T item)?)
  - Jinja cell-render branch on cellBuilder presence (fallback preserves string-Text behavior)
  - Widget test proving the runtime cellBuilder contract end-to-end
affects:
  - Generated GeniusDataTable (and any future data-table consumer widgets) — now accepts
    per-column cellBuilder overrides without forking the table
tech-stack:
  added: []
  patterns:
    - Additive codegen-template extension (constructor + field + render branch)
    - Hand-written test double mirroring generated output for template-level contracts
    - D-09 fallback: runtime contract verified in widget test when the JSON fixture
      cannot express a function value
key-files:
  created:
    - test/components/data_table_cell_builder_test.dart
  modified:
    - templates/components/data_table.dart.jinja2
decisions:
  - D-08 (locked, implemented): cellBuilder is optional; null preserves existing string
    cell path; sort driven by accessor regardless of cellBuilder presence
  - D-09 (locked, fallback taken): data_table_vars.json NOT modified — fixture format
    cannot express a function value; runtime branch verified via widget test
metrics:
  duration-minutes: ~5
  completed: 2026-08-17
---

# Phase 08 Plan 02: DataColumnConfig cellBuilder Extension Summary

**One-liner:** Additive `cellBuilder` field on `DataColumnConfig` plus a Jinja `{% if %}` branch in the cell render path of `templates/components/data_table.dart.jinja2`, with the runtime contract verified by a hand-written widget test (per D-09 fallback — fixture not modified).

## What Was Built

### Task 1 — Widget test for the cellBuilder contract (TDD RED)

Created `test/components/data_table_cell_builder_test.dart` with:

- A hand-written `_SampleItem` test-double (mirrors the placeholder item class the template emits).
- A hand-written `_DataColumnConfig` test-double (mirrors the post-change template `DataColumnConfig` shape: `label`, `accessor`, `sortable = true`, `cellBuilder`).
- A `_CellHost` widget that mirrors the post-change template render branch exactly — `cellBuilder != null ? Builder(builder: cellBuilder!(ctx, item)) : Text(item.accessor?.toString() ?? '')`.
- Three widget tests:
  1. Null `cellBuilder` renders the string-fallback `Text(item.name)`.
  2. Non-null `cellBuilder` returning a `Key('custom-cell')` Container renders that widget and NOT the string fallback.
  3. Builder is invoked with the same `BuildContext` and item (captured via closure).

Pre-Task-2 state verified: `grep -c 'cellBuilder' templates/components/data_table.dart.jinja2` returned `0` (RED gate).

### Task 2 — Template extension (GREEN)

Additive change to `templates/components/data_table.dart.jinja2`:

- `DataColumnConfig` constructor gains `this.cellBuilder,` after `this.sortable = true,`.
- New field with doc contract:
  ```dart
  final Widget Function(BuildContext context, {{ data_type_name }} item)?
      cellBuilder;
  ```
  Doc specifies: no outer padding in custom builders (inherit `DataCell` default), sort driven by `accessor` regardless of `cellBuilder` presence.
- Cell render path branches:
  ```jinja2
  {% if col.cellBuilder is defined and col.cellBuilder %}
    Builder(builder: (BuildContext cellContext) =>
        widget.columns[{{ loop.index0 }}].cellBuilder!(cellContext, item)),
  {% else %}
    Text(item.{{ col.accessor }}?.toString() ?? ''),
  {% endif %}
  ```
- The `is defined` guard protects against `StrictUndefined` when the fixture does not declare `cellBuilder` on a column (current state of `data_table_vars.json`).
- Locked `labelLarge?.copyWith(fontWeight: FontWeight.w600)` column-header style is byte-identical (shifted from line 245 to lines 255-256 by the additive field block; the declaration itself is untouched).
- `templates/components/data_table_vars.json` is unchanged (D-09 fallback — JSON cannot express a function value).

## Commits

| Hash | Type | Message |
|------|------|---------|
| `88fe8a5` | test | test(08-02): add widget test for DataColumnConfig cellBuilder contract |
| `d8009b5` | feat | feat(08-02): extend DataColumnConfig with optional cellBuilder field |

## Verification

| Gate | Result |
|------|--------|
| `flutter test test/components/data_table_cell_builder_test.dart` | PASS (3/3 tests) |
| `dart analyze --fatal-infos test/components/data_table_cell_builder_test.dart` | PASS (no issues) |
| `grep -c 'cellBuilder' templates/components/data_table.dart.jinja2` | 6 (≥ 3 required) |
| `grep -c 'labelLarge' templates/components/data_table.dart.jinja2` | 1 (locked header preserved) |
| `git diff HEAD~2 HEAD -- templates/components/data_table_vars.json` | empty (fixture untouched) |
| Jinja `{% if %}`/`{% endif %}` balance | 2/2 (no orphan tags) |
| Jinja `{% for %}`/`{% endfor %}` balance | 5/5 (no orphan tags) |

## Deviations from Plan

None — plan executed exactly as written. The D-09 fallback was pre-specified in the plan ("the fixture format cannot express a function value, so the contract is verified in the widget test"), so not modifying `data_table_vars.json` is the sanctioned path, not a deviation.

## Threat Flags

None. The cellBuilder closure executes in the same isolate as consumer code; no new trust boundaries are introduced (T-08-02-01/02/03 all `accept` per the plan's threat model).

## Self-Check: PASSED

- `test/components/data_table_cell_builder_test.dart` exists on disk.
- `templates/components/data_table.dart.jinja2` modified; `data_table_vars.json` byte-identical to base.
- Both commits exist on branch `wt-08-02`:
  - `88fe8a5` — test(08-02) widget test (TDD RED commit; template unmodified at this commit).
  - `d8009b5` — feat(08-02) template extension (GREEN commit).
