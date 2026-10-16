---
phase: 14-default-accessibility-fixes
plan: 01
subsystem: capture-harness
tags: [captures, determinism, a11y, harness]
requires:
  - "Phase 13 head 07a7808"
provides:
  - "images/ as a deterministic same-machine baseline of 52 PNGs"
  - "Text field capture with typed text; bottom drawer capture with the open panel"
  - "BottomDrawerDemo.drawerTitle, drawerItems(context), drawerFooter(context)"
affects: [14-02, 14-03, 14-04, 14-05, 14-06]
tech-stack:
  added: []
  patterns:
    - "Open-dialog captures are built inside the RepaintBoundary, mirroring the overlay layout"
key-files:
  created: []
  modified:
    - example/test/capture_images_test.dart
    - example/lib/demos/bottom_drawer_demo.dart
    - images/*.png
key-decisions:
  - "Drawer demo items use palette.textPrimary instead of Colors.white so they read on the light panel."
  - "Barrier scrim left out of the drawer capture: it is a hard-coded constant not under test."
metrics:
  duration: "about 15 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 6000
  tasks: 2
  commits: 3
---

# Phase 14 Plan 01: Capture harness baseline and coverage Summary

images/ is now this machine's deterministic render of the pre-phase head, and the harness shows the widgets A11Y-02 fixes, with the bug visible in the light captures.

## Commit values (for 14-06)

| Name | SHA | Touches |
|---|---|---|
| PRE | 07a7808d3ea11327b59610a81edf4c54507b2fdb | pre-phase head |
| BASELINE | d9342ff | 52 PNGs, no source |
| COVERAGE | 20762f7 | example/test/capture_images_test.dart, example/lib/demos/bottom_drawer_demo.dart, no PNG |
| COVERAGE_CAPTURES | b9145a8 | text_entry_field_{dark,light}, bottom_drawer_{dark,light} |

## Task 1: machine re-render

- Two scratch renders at PRE: 52 PNGs each, `diff -rq` empty (byte-identical).
- Render into images/ matched run1 exactly.
- All 52 of 52 PNGs changed (rasterization differs from the other machine); none added or deleted.
- Sanity check on toast_dark.png, old versus new: same layout and colors, glyph rasterization and sub-pixel text position only.

## Task 2: harness coverage

- Text field: a `prepare` step types 'Ada Lovelace' into the first TextFormField, then unfocuses and pumps once.
- Bottom drawer: a private `_OpenDrawerCapture` widget mirrors ResponsiveDrawer's desktop branch (demo page plus right-aligned 400-wide panel on deepBlueTertiary) inside the capture boundary.
- The demo exposes `drawerTitle`, `drawerItems(context)` and `drawerFooter(context)`; `_open` uses them.
- `dart analyze --fatal-infos` clean at repo root and in example/.
- Two scratch renders identical (52 PNGs). Only the four named PNGs moved relative to BASELINE. A render after the final commit equals images/ (52 PNGs, no diff).

What the four PNGs show:

- text_entry_field_dark: white typed text in the first field.
- text_entry_field_light: typed text is white on the light fill, nearly invisible. This is the A11Y-02 bug, expected until 14-03.
- bottom_drawer_dark: white title, close icon and items on the dark panel.
- bottom_drawer_light: white title and close icon on the light panel (the bug), dark item labels.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

The three commits exist with the expected path sets; working tree clean after the last task commit.
