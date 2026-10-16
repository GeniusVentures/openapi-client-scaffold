---
status: complete
phase: 08-supporting-atoms-table-cells-light-palette
source:
  - 08-01-SUMMARY.md
  - 08-02-SUMMARY.md
  - 08-03-SUMMARY.md
  - 08-04-SUMMARY.md
  - 08-05-SUMMARY.md
  - 08-06-SUMMARY.md
started: 2026-08-17T00:00:00.000Z
updated: 2026-08-19T00:00:00.000Z
completed: 2026-08-19T00:00:00.000Z
---

# Phase 8 UAT — Supporting Atoms, Table Cells & Light Palette

These tests require running the example app and visually confirming each
widget. Run from the scaffold example:

```
cd src/scaffold/example
flutter run -d macos     # macOS desktop
flutter run -d chrome    # Chrome (web)
```

Then open each demo from the example app's home list. The home list also has
two toggles used by tests 6 and 7: **Light mode** and **Theme overrides**.

## Current Test
<!-- OVERWRITE each test - shows where we are -->

(complete — all 7 tests passed on macOS)

## Tests

### 1. Example app launches and lists the four Phase 8 demos
expected: The example app builds and boots without errors on both macOS and Chrome. The home list contains four entries — "Chip / ChipGroup", "Composer", "Disclosure", "Trace list" — and tapping any entry opens its demo page without a crash.
result: pass
note: Verified on macOS 2026-08-19. All four entries present and open cleanly.

### 2. ScaffoldChip states + ScaffoldChipGroup selection
expected: The Chip demo shows six single-chip states — default, selected (accent border), disabled (dimmed), leading icon, trailing status dot, icon-only. Below them, the single-select group moves the accent border to the tapped chip; the multi-select group toggles each chip's border independently; the empty group renders as zero-size (no visible widget). Per-chip taps print to the debug console.
result: pass
note: Verified on macOS 2026-08-19.

### 3. ScaffoldComposer slots + interactive submission log
expected: The Composer demo shows default, with-badges, with-actions, badges+actions, and disabled (dimmed) variants. In the "Submission log" section, typing text and submitting appends a numbered entry below the composer and clears the field (D-07: the atom emits the string; the consumer owns the list).
result: pass
note: |
  Two issues found and fixed during UAT (see Gaps): the composer text field
  required two taps to gain keyboard entry on desktop. Fixed by (1) exposing
  a consumer-supplied focusNode on ScaffoldComposer (afb7ea6) and (2) fixing
  a ScaffoldFocusOutline remount bug (5f0ef51). Confirmed 2026-08-19:
  "the text edit focus and keyboard entry works on one click!"

### 4. ScaffoldDisclosure controlled mode (CR-01 regression check)
expected: In the Disclosure demo, the "Controlled" section row toggles open and stays open across rebuilds (it must NOT immediately collapse back). The "Uncontrolled (collapsed)" and "Uncontrolled (expanded)" rows toggle on tap, and the "Highlight when expanded" row tints its chevron to the accent green while expanded.
result: pass
note: Verified on macOS 2026-08-19.

### 5. ScaffoldTraceList render variants
expected: The Trace list demo shows (a) a simple ordered list of three steps with mixed status dots (none / success / info), (b) a "Pipeline" group header above two stages (success / warning), and (c) an empty-state that renders zero height (no visible widget under the label).
result: pass
note: Verified on macOS 2026-08-19.

### 6. Light default palette (WIDG-46)
expected: With the "Light mode" toggle ON, all four demos re-render under the light ThemeData: light backgrounds/surfaces, dark primary text, no dark-theme artifacts, and all four atoms remain legible and correctly themed.
result: pass
note: Verified on macOS 2026-08-19.

### 7. Theme override propagates dimens tokens (WR-01 / WR-02 check)
expected: With the "Theme overrides" toggle ON, the accent swaps to orange and the dimens-driven values follow the theme: the disabled chip/badge opacity and the selected-chip border width track ScaffoldDimens (no hardcoded 0.4 opacity or 2.0 border). The selected chip's border stays visually consistent with the focus-ring width.
result: pass
note: Verified on macOS 2026-08-19.

## Summary

total: 7
passed: 7
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

Both issues below were found during UAT and fixed in this phase before
completion; the fixes are part of the phase diff.

1. **ScaffoldComposer text field required two taps for keyboard entry
   (desktop).** First tap lit the outer focus ring; the caret and text-input
   connection only attached on a second tap.
   - *Fix part 1 (consumer policy, D-07):* ScaffoldComposer exposes an
     optional consumer-supplied `focusNode` (afb7ea6). The demo wires a
     translucent GestureDetector that requests the node through the field's
     FocusScope, so taps anywhere on the composer surface focus the field.
     The atom never requests focus itself — focus policy stays with the
     consumer.
   - *Fix part 2 (root cause):* ScaffoldFocusOutline returned bare `child`
     when the ring was hidden and a `Stack` when shown. Gaining focus under
     traditional (keyboard) highlight flipped the root runtimeType, remounting
     the entire child subtree — tearing down the EditableText state and the
     text-input connection the moment focus landed. Fixed by always returning
     a `Stack(fit: StackFit.passthrough)` with the ring conditionally added
     as a second child (5f0ef51). Regression test: "showing the ring does not
     remount the child subtree" in scaffold_focus_outline_test.dart.

2. **Outer composer outline only selectable directly over the text child.**
   Same root fixes as #1: the demo's translucent GestureDetector covers the
   whole composer surface, and the outline remount fix means focus now sticks
   regardless of where on the surface the tap lands.

Note: UAT executed on macOS only. Chrome target was approved but not
exercised before completion.
