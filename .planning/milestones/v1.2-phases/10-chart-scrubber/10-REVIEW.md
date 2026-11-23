---
phase: 10-chart-scrubber
reviewed: 2026-08-22T00:00:00Z
depth: deep
files_reviewed: 14
files_reviewed_list:
  - example/lib/demos/chart_range_selector_demo.dart
  - example/lib/demos/chart_scrubber_demo.dart
  - example/lib/main.dart
  - lib/components/scaffold_chart.dart
  - lib/components/scaffold_chart_range_selector.dart
  - lib/components/scaffold_chart_scrubber.dart
  - lib/frontend_scaffold.dart
  - lib/utils/chart_geometry.dart
  - lib/utils/scaffold_chart_renderer.dart
  - test/components/scaffold_chart_range_selector_test.dart
  - test/components/scaffold_chart_scrubber_test.dart
  - test/components/scaffold_chart_test.dart
  - test/utils/chart_geometry_test.dart
  - test/utils/scaffold_chart_renderer_test.dart
findings:
  critical: 0
  warning: 7
  info: 5
  total: 12
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-08-22
**Depth:** deep
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 10 ships chart geometry helpers, the fl_chart renderer seam, and the
`ScaffoldChart` / `ScaffoldChartScrubber` / `ScaffoldChartRangeSelector`
composed atoms, with demos and tests. The D-02 support-part isolation is
genuinely honored — `package:fl_chart` is imported only inside
`lib/utils/scaffold_chart_renderer.dart`. Gesture-lifecycle plumbing
(pan/tap/long-press → scaffold-neutral callbacks) is carefully implemented,
the UAT-driven "hover must never clear" and "hover-exit must not clear
during a drag" regressions are both covered by tests, and theme tokens are
used throughout (no hardcoded colors in `lib/`).

No BLOCKER-tier defects. The warnings below are correctness and
maintainability concerns that are worth fixing before the next consumer
ships on top of this seam: two are edge-case bugs in the range selector
(null-callback clearing on a failed drag, floating-point tap-detection),
one is a cross-layer coordinate-mapping fragility (`_stackWidth`/`_stackHeight`
captured during build, read at gesture time), and the rest are minor.

## Warnings

### WR-01: Failed band drag fires `onRangeSelected(null)` — silently clears the user's existing range

**File:** `lib/components/scaffold_chart_range_selector.dart:432-449`
**Issue:** `_onDragEnd` invokes `widget.onRangeSelected?.call(_mapPixelsToRange(start, current))`.
`_mapPixelsToRange` returns `null` when `_chartXOfPixel` returns null for
either endpoint, which happens when `span <= 0.0` (degenerate X window),
`usableWidth <= 0.0` (layout collapsed mid-gesture), or `_windowXBounds()`
returns null (series became empty between drag start and end). In every one
of those cases the consumer receives `null` — the documented "clear the
range" signal — even though the user did not press Escape and the drag
simply could not be interpreted. A consumer that round-trips the range into
its own state will watch a valid selection vanish because, e.g., the parent
rebuilt with an empty series mid-drag, or the chart's `viewMinX == viewMaxX`
for one frame.
**Fix:** Drop the call when the mapping fails — only fire the callback when
a real range was produced:

```dart
void _onDragEnd(DragEndDetails details) {
  final Offset? start = _dragStart;
  final Offset? current = _dragCurrent;
  setState(() {
    _dragStart = null;
    _dragCurrent = null;
  });
  _downPosition = null;
  if (start == null || current == null || start.dx == current.dx) {
    return;
  }
  final (T, T)? mapped = _mapPixelsToRange(start, current);
  if (mapped == null) {
    return; // failed drag — do not emit a spurious "clear"
  }
  widget.onRangeSelected?.call(mapped);
}
```

If "clear on failed drag" is intended, it must be documented in the
`onRangeSelected` dartdoc; as written, the dartdoc only advertises `null`
"on clear (Escape)".

### WR-02: Tap-vs-drag discrimination uses exact floating-point equality on pixel coordinates

**File:** `lib/components/scaffold_chart_range_selector.dart:445`
**Issue:** `start.dx == current.dx` decides whether the gesture was a tap
(zero-width band, discard) or a real drag (fire `onRangeSelected`).
`current.dx` comes from `DragUpdateDetails.localPosition`, which is the
slop-shifted position of the most recent move event. A drag that leaves the
down-point and returns to it (e.g., the user starts to drag left, changes
their mind, and releases exactly back over the press pixel) compares equal
to the start and is silently swallowed — no `onRangeSelected` fires, even
though the user performed a genuine horizontal drag. More subtly, on some
platforms the up-event coordinate can be reported as exactly the
down-coordinate due to pointer quantization even when the user dragged a
few pixels and dragged back.
**Fix:** Track whether any `DragUpdateDetails` arrived between start and
end (a `_sawDragUpdate` bool set in `_onDragUpdate`), and use that as the
tap-vs-drag discriminator; or compare against the touch slop
(`(current.dx - start.dx).abs() < kSlopEpsilon`) instead of equality. The
bool flag is simpler and matches what the gesture arena already decided.

### WR-03: `_stackWidth` / `_stackHeight` are written inside `LayoutBuilder`'s builder and read at gesture time — no invalidation on resize mid-drag

**File:** `lib/components/scaffold_chart_range_selector.dart:238-239, 524-527`
**Issue:** The pixel↔chart-x mapping in `_chartXOfPixel` / `_pixelXOfChart`
reads `_stackWidth`/`_stackHeight`, which are captured as a side effect of
the `LayoutBuilder` builder. If the parent resizes the selector while a
band drag is in progress (orientation change, split-view resize, window
drag on desktop), the LayoutBuilder rebuilds and updates the fields — but
the in-flight `_dragStart` was anchored against the OLD width, so the band
and the final mapped range are computed against mismatched geometries. The
user-visible symptom is a band whose left edge jumps and a reported range
whose startT is wrong.
Additionally, mutating State fields from a build method is a known Flutter
code smell: it makes the build non-idempotent and hides a dataflow
dependency from the reader.
**Fix:** Either (a) store the width/height in an `Overlay`/`LayoutId`-style
mechanism that also cancels an in-flight drag when the constraints change
(`onLayoutChanged`), or (b) at minimum, cancel the active band drag in
`didUpdateWidget` / when the LayoutBuilder's constraints materially change:

```dart
builder: (BuildContext context, BoxConstraints constraints) {
  if (_dragStart != null &&
      (constraints.maxWidth != _stackWidth ||
       constraints.maxHeight != _stackHeight)) {
    // Resize mid-drag — drop the band so the next drag starts clean.
    _dragStart = null;
    _dragCurrent = null;
  }
  _stackWidth = constraints.maxWidth;
  _stackHeight = constraints.maxHeight;
  ...
}
```

### WR-04: `_chartXOfPixel` reads `context.dimens.space8` at gesture time — depends on the State's `context` being valid and the theme not changing mid-drag

**File:** `lib/components/scaffold_chart_range_selector.dart:267, 287`
**Issue:** `_chartXOfPixel` and `_pixelXOfChart` call `context.dimens`,
which internally invokes `dependOnInheritedWidgetOfExactType` against the
State's `context`. Calling this from a gesture handler (not a build
method) is permitted, but (a) it establishes an inherited-widget dependency
outside the build phase, which Flutter's documentation flags as
unsupported, and (b) the captured value is whatever the theme resolves to
AT THAT MOMENT — so a theme swap mid-drag mixes old drag-start pixels with
new padding. The scaffold's own `space8` is the constant the surface uses
for padding (`scaffold_chart.dart:307`), so the value is also available as
a fixed input.
**Fix:** Resolve `dimens.space8` once in `build` (where the dependency is
legitimate) into a State field (or read it from the chart's own
`padding` parameter), and use the cached value in the gesture handlers.

### WR-05: `chartBandedBounds` early-returns on `available <= 0`, making `max(1, available)` dead defensive code

**File:** `lib/utils/chart_geometry.dart:163-167`
**Issue:** The guard `if (available <= 0) { return bounds; }` precedes the
`unitsPerPx = (hi - lo) / max(1, available)` line, so the `max(1, …)` can
never observe a value less than 1. Either the guard is sufficient (and the
`max` is dead), or the author intended the `max` to handle a case the
guard misses — they are mutually exclusive. Dead defensive code masks
intent.
**Fix:** Drop the `max(1, available)` in favor of `available` directly, or
remove the early return and rely on the clamp. Pick one.

### WR-06: `textTheme.labelSmall!` force-unwraps theme data in the base atom

**File:** `lib/components/scaffold_chart.dart:217`
**Issue:** `textTheme.labelSmall!.copyWith(...)` will throw a null-check
error if a consumer's `ThemeData` has `labelSmall: null`. M3 default themes
populate `labelSmall`, but a consumer constructing a stripped-down
`ThemeData(textTheme: TextTheme())` (legitimate for embedded surfaces)
crashes the chart rather than degrading to a fallback. The atom is part of
the public library contract, so this is a footgun for downstream consumers.
**Fix:** Use a safe fallback:

```dart
final TextStyle baseLabel =
    textTheme.labelSmall ?? const TextStyle(fontSize: 11.0);
final TextStyle axisLabelStyle = baseLabel.copyWith(
  color: textSecondary,
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
);
```

### WR-07: Stale "RED — fails against the current implementation" comment in a now-passing test

**File:** `test/components/scaffold_chart_scrubber_test.dart:393-396, 754`
**Issue:** Two tests carry TDD-workflow comments stating the test "FAILS
against the current (toggle) implementation — RED" and "FAILS against the
current type-toggling build — RED". Both implementations have since been
updated to make the tests pass, but the comments were never flipped. A
future reader investigating a regression will be misled about whether the
test is supposed to be green.
**Fix:** Rewrite the comments to describe the contract being asserted
("Asserts the NEW contract: tap on the selected point is a no-op re-select")
and drop the RED/GREEN TDD bookkeeping — that belongs in commit messages,
not in the test source.

## Info

### IN-01: `_downPosition` is never cleared if the gesture is cancelled before `_onDragStart`

**File:** `lib/components/scaffold_chart_range_selector.dart:509-513`
**Issue:** `Listener.onPointerDown` always overwrites `_downPosition`. If a
pointer-down is followed by a cancel (no drag ever starts), the field
retains a stale position until the next pointer-down. It is always
overwritten before use, so this is not a bug — but the field's lifecycle
is implicit. A one-line `_downPosition = null;` inside a
`Listener.onPointerCancel` (or a comment explaining the invariant) would
make the contract explicit.

### IN-02: `_smoothDotPosition` setState fires on every gesture end even when no dot is visible

**File:** `lib/utils/scaffold_chart_renderer.dart:334-336`
**Issue:** `_handleSmoothPixel(null)` is invoked on every gesture-end event,
even when `_smoothDotPosition` is already null (no smooth scrub ever began).
Each call schedules a rebuild of the smooth-mode wrapper. Trivial cost, but
the early-out is one line:

```dart
void _handleSmoothPixel(Offset? pixel) {
  if (pixel == _smoothDotPosition) {
    return;
  }
  setState(() => _smoothDotPosition = pixel);
}
```

### IN-03: `_smoothSpots` test fixture is shared mutable top-level state

**File:** `test/utils/scaffold_chart_renderer_test.dart:59`
**Issue:** `final List<ChartPoint> _smoothSpots = _spots();` is a top-level
`final` list shared across every smooth-mode test. No current test mutates
it, but a future test that sorts, filters, or adds to the list will
silently contaminate later tests in the same run. Returning a fresh list
from a function (mirroring `_spots()`) removes the hazard.

### IN-04: `chartTickStep`'s loop bound `v <= hi + step * 1e-9` allows a tick just past `hi`

**File:** `lib/utils/chart_geometry.dart:87`
**Issue:** The floating-point slack `step * 1e-9` is a relative epsilon, so
for very small steps (e.g., `step = 1e-12`) the slack is `1e-24` — far
below double-precision resolution at the magnitude of `hi`. The intent
(tolerate representation error at the top of the ladder) is fine; the
magnitude of the slack just isn't doing what the comment implies for tiny
steps. Not a bug today because no caller drives it with such steps, but a
comment would help.

### IN-05: `example/lib/demos/chart_range_selector_demo.dart` line 32 packs three constants into one expression

**File:** `example/lib/demos/chart_range_selector_demo.dart:32`
**Issue:** `100.0 + 50.0 * (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2) - 25.0`
combines a base, amplitude, and offset in one line. The demo is readable
enough that this is not worth restructuring, but naming `kBaseValue`,
`kAmplitude`, `kYOffset` would match the project's "no magic numbers"
convention for `lib/` code. Demo-only — cosmetic.

---

_Reviewed: 2026-08-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
