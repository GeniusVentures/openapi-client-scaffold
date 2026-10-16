---
phase: 11-verification-coverage-gate
plan: 03
subsystem: documentation
tags: [readme, gallery, coverage, WIDG-44, WIDG-45]
requires:
  - 11-02 (images/ populated with 26 PNGs)
provides:
  - "README.md: corrected counts (454 tests, 26 demos), 26-entry Component gallery, 19-row WIDG-45 Coverage table, images/ row in layout tree"
affects:
  - README.md (public package face)
tech-stack:
  added: []
  patterns:
    - "GitHub-flavored Markdown table with leading pipes and trailing ` |$` for every row"
    - "Package-root-relative image paths (`images/<name>.png`) so GitHub renders embeds"
key-files:
  created: []
  modified:
    - README.md
decisions:
  - "WIDG-45 table copied verbatim from 11-RESEARCH.md §WIDG-45 19-Component Coverage Proof; markdown bold (`**Compose**` etc.) stripped from the Coverage Tier cell so the plan's grep patterns (`Ready (7-ready)`, `Compose (8-thin)`, `Add primitive (4-primitive)`) match unambiguously. Tally and per-row content unchanged."
metrics:
  duration: "252s"
  completed: 2026-08-23
  tasks: 3
  files_modified: 1
---

# Phase 11 Plan 03: README Restructure — Demo, Gallery, Coverage Summary

README.md now tells the reader how to run the demo, embeds a 26-entry
component gallery backed by the Plan 11-02 PNGs, and proves the WIDG-45
19-component Beautiful UI coverage claim inline — with stale "214 tests" /
"one demo screen per widget family" claims replaced by 454 / 26 and the
repository layout tree updated to list `images/`.

## Tasks Completed

| # | Task | Commit | Line count after |
|---|------|--------|------------------|
| 1 | Correct stale counts + expand Demo app section + add `images/` to layout tree | `a1977e4` | 322 |
| 2 | Add Component gallery section (26 embedded images) | `5b4131b` | 428 |
| 3 | Add Coverage section with the 19-row WIDG-45 table | `a605b31` | 458 |

README.md went from **319 lines** (start) to **458 lines** (end): +3
(Task 1 edits + tree row), +106 (Task 2 gallery), +30 (Task 3 coverage).

## Phase-Gate Verification (all seven green)

Verbatim outputs captured from the worktree root:

```
$ dart analyze --fatal-infos
Analyzing agent-a47132bc3d3f447a2...
No issues found!

$ flutter test
00:07 +454: All tests passed!

$ grep -rn "skip: true" test/
(no output — empty)

$ ls images/ | wc -l
      26

$ grep -c '^!\[.*\](images/' README.md
26

$ grep -cE '^\| [0-9]+ \|' README.md
19

$ grep -c "214 tests\|one demo screen per widget family" README.md
0
```

## WIDG-45 Table Provenance

The 19-row Coverage table was copied **verbatim** from
`.planning/workstreams/scaffold/phases/11-verification-coverage-gate/11-RESEARCH.md`
§WIDG-45 19-Component Coverage Proof — no paraphrasing, no re-ordering.
Row order, atom names, backtick formatting, and the 7+8+4 = 19 tally all
match. The only mechanical change is stripping the `**...**` bold markers
around the Coverage Tier cell text (`**Compose** (8-thin)` →
`Compose (8-thin)`), because the plan's grep-based acceptance criteria
require the un-bolded literal substrings (`Ready (7-ready)`,
`Compose (8-thin)`, `Add primitive (4-primitive)`) to match. All 11 v1.2
atom names appear at least once in the final README.

## Acceptance Criteria Trace

**Task 1:**
- `grep -c "214 tests\|214 widget" README.md` → 0
- `grep -c "454 tests" README.md` → 1
- `grep -c "454 widget + token tests" README.md` → 1
- `grep -c "26 demo screens" README.md` → 1
- `grep -c "one demo screen per widget family" README.md` → 0
- `grep -c "^├── images/" README.md` → 1
- `grep -c "cd example && flutter run -d macos" README.md` → 1
- `grep -c "^## Demo app$" README.md` → 1
- `wc -l README.md` → 322 (within the 320–325 band)

**Task 2:**
- `grep -c "^## Component gallery$"` → 1
- `grep -c "^!\[.*\](images/"` → 26
- Spot-checked `images/action_button.png`, `images/chip.png`,
  `images/chart_range_selector.png`, `images/kitchen_sink.png`,
  `images/tracer.png` — all on disk
- `awk '/^## Demo app/,/^## Develop/' README.md | grep -c "^## Component gallery$"` → 1
- `grep -E '^!\[.*\]\((/|\./)' README.md` → 0 matches (no leading `/` or `./`)
- Order matches `example/lib/main.dart` `_DemoTile` registry:
  ActionButton (line 85) precedes Kitchen Sink (line 125) precedes
  Chart Range Selector (line 185)

**Task 3:**
- `grep -c "^## Coverage$"` → 1
- `grep -cE "^\| [0-9]+ \|"` → 19
- `grep -c "Ready (7-ready)"` → 7
- `grep -c "Compose (8-thin)"` → 8
- `grep -c "Add primitive (4-primitive)"` → 4
- All 11 v1.2 atom names (`ScaffoldChip`, `ScaffoldChipGroup`,
  `ScaffoldDisclosure`, `ScaffoldTraceList`, `ScaffoldComposer`,
  `ScaffoldStreamingRichText`, `ScaffoldCodeBlock`,
  `ScaffoldSelectionActions`, `ScaffoldChart`, `ScaffoldChartScrubber`,
  `ScaffoldChartRangeSelector`) present ≥1×
- `awk '/^## Component gallery/,/^## Develop/' README.md | grep -c "^## Coverage$"` → 1
- `grep -E "^\| " README.md | grep -vc " \|$"` → 0 (every table row ends
  with a trailing pipe)

## Deviations from Plan

**None — plan executed exactly as written.**

The only judgment call was the bold-strip in the WIDG-45 Coverage Tier
cells, which is *required by* the plan's own grep-based acceptance
criteria (the plan's <action> section already shows the un-bolded form
in its row listing). Documented above under "WIDG-45 Table Provenance"
for traceability; not a deviation.

## Self-Check

- `README.md` exists and is 458 lines: FOUND
- Commit `a1977e4` (Task 1): FOUND
- Commit `5b4131b` (Task 2): FOUND
- Commit `a605b31` (Task 3): FOUND
- All 7 phase-gate commands pass
- All 26 image embeds reference on-disk files

## Self-Check: PASSED
