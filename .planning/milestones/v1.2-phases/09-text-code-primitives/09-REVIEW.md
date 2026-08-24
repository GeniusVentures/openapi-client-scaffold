---
phase: 09-text-code-primitives
reviewed: 2026-08-21T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - lib/components/scaffold_selection_actions.dart
  - test/components/scaffold_selection_actions_test.dart
  - example/lib/demos/selection_actions_demo.dart
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 09: Code Review Report

**Reviewed:** 2026-08-21
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the WIDG-39 `ScaffoldSelectionActions` toolbar-alignment fix across the
widget (`scaffold_selection_actions.dart`), its test suite, and the demo. The
core horizontal-anchor change is sound for the primary goal: `left`/`center`/
`right` now derive from the selection bounding box (`min`/`mid`/`max` of the two
endpoints) and are direction-independent, which fixes the UAT-reported
block-centering bug. The Dart 3 `switch` statements correctly rely on implicit
per-case termination (no fall-through — verified empirically against Dart
3.11.5). Tests 23 and 24 are sound.

One substantive defect remains: the `first`/`last` "selection order" semantics
are built on a false premise about the Flutter SDK's `selectionEndpoints`
contract, and invert for reversed multi-line selections. Details below.

## Warnings

### WR-01: `first`/`last` horizontal semantics invert for reversed multi-line selections

**File:** `lib/components/scaffold_selection_actions.dart:419-437`

**Issue:** The change assumes `SelectableRegionState.selectionEndpoints`
preserves selection order as `[base, extent]`. It does not. The SDK getter
(`packages/flutter/lib/src/widgets/selectable_region.dart:1787-1805`) reorders
the two endpoints by vertical position before returning them:

```dart
if (startLocalPosition.dy > endLocalPosition.dy) {
  points = <TextSelectionPoint>[end, start];   // top (extent) first
} else {
  points = <TextSelectionPoint>[start, end];   // top (base) first
}
```

`start`/`end` here are `startSelectionPoint`/`endSelectionPoint` (base/anchor and
extent/cursor, respectively), but the returned list is always `[top, bottom]` by
`dy` — not `[base, extent]`. Consequences for `_computeAnchors()`:

- `first` -> `endpoints.first.dx` and `last` -> `endpoints.last.dx` are actually
  "top endpoint dx" and "bottom endpoint dx", not "anchor" and "cursor".
- For a forward (down-dragging) multi-line selection this is coincidentally
  correct (base is at the top). For a **reversed (up-dragging) multi-line**
  selection, base is at the bottom and extent at the top, so the SDK returns
  `[extent, base]` and `first`/`last` map to the *opposite* edges of what the
  enum doc (lines 61-82) promises: "first selected character ... the anchor edge
  where the selection started" vs "last ... the cursor edge where it ended".

The vertical anchors (lines 441-444) are correct precisely *because* the list is
dy-sorted (`firstGlobal.dy` is always the top, `lastGlobal.dy` the bottom), but
the horizontal `first`/`last` interpretation is not.

Note this also contradicts the stated review premise ("selectionEndpoints is
`[base, extent]`") and the code comment at lines 415-418 ("selectionEndpoints
preserves SELECTION ORDER"). Single-line selections are unaffected (equal `dy`
takes the `else` branch, preserving base/extent order), which is why Tests 20-23
(all single-line text) pass and do not catch this.

**Fix:** For `first`/`last`, do not trust the list ordering. Derive the anchor
edge from the actual base/extent order. The region exposes
`region.selectionEndpoints` sorted top-to-bottom, so compare the two endpoints'
`dx` against a known anchor. The simplest correct approach is to read the raw
base/extent `TextSelection` (or `region`'s internal base/extent indices, if
exposed) and map `first` -> base edge, `last` -> extent edge; alternatively, for
single-direction glyph runs, `first`/`last` can be defined as
`min`/`max` of the two `dx` combined with the selection's direction. At minimum,
correct the doc comment and enum docs to state that `first`/`last` follow
top-to-bottom (dy) order rather than selection order, or fix the mapping to
genuinely reflect anchor/cursor.

## Info

### IN-01: Stale doc comment in `_computeAnchors`

**File:** `lib/components/scaffold_selection_actions.dart:356-358`

**Issue:** The docstring still states "the horizontal center is the midpoint of
the two endpoints." Since the horizontal anchor is now alignment-dependent
(`min`/`mid`/`max`/`first`/`last`), this sentence is inaccurate.

**Fix:** Update to describe that the horizontal anchor is chosen per
`widget.toolbarAlignment` (bounding-box min/mid/max vs selection-order first/last).

### IN-02: No test exercises `first`/`last` on a reversed multi-line selection

**File:** `test/components/scaffold_selection_actions_test.dart`

**Issue:** Test 20 (`last`) and Test 23 (`first`) both use a single-line forward
drag, and Test 21 exercises `right` (not `first`/`last`) on a reversed drag. The
reversed multi-line case — where WR-01 manifests — has no coverage, so the
inversion is invisible to CI.

**Fix:** Add a test selecting text upward across multiple lines (or at minimum a
reversed multi-line selection) and assert `first`/`last` land on the anchor/
cursor edges, not the top/bottom edges.

---

_Reviewed: 2026-08-21_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
