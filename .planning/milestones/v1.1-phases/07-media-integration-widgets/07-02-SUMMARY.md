---
phase: 07-media-integration-widgets
plan: 02
subsystem: components/media-controls
tags: [media-controls, WIDG-30, D-03, D-04, transient-scrub-state, tdd]
requires:
  - lib/components/scaffold_pressable.dart
  - lib/components/scaffold_touch_target.dart
  - lib/components/scaffold_formatted_value_duration.dart
  - lib/components/scaffold_motion.dart
  - lib/theme/scaffold_theme.dart
provides:
  - lib/components/media_controls.dart (MediaControls StatefulWidget, D-03)
  - test/components/media_controls_test.dart (12 widget tests)
  - example/lib/demos/media_controls_demo.dart (MediaControlsDemo)
affects: []
tech-stack:
  added: []
  patterns:
    - "D-03 private transient scrub state — single Duration? _scrubbing field, setState only during drag, onSeek fires on release only"
    - "D-04 time labels default-on via ScaffoldFormattedValueDuration, hideable via showTimeLabels"
    - "Buffered layer behind played position via FractionallySizedBox with widthFactor"
    - "All buttons ScaffoldPressable (inherits Phase 6 D-02 a11y: Semantics + 48x48 + focus)"
key-files:
  created:
    - lib/components/media_controls.dart
    - test/components/media_controls_test.dart
    - example/lib/demos/media_controls_demo.dart
  modified: []
decisions:
  - "MediaControls is a StatefulWidget with EXACTLY ONE state field (Duration? _scrubbing) — playback truth stays in the consuming app's cubit"
  - "Slider onChangeStart/onChanged update _scrubbing; onChangeEnd clears _scrubbing and emits onSeek exactly once"
  - "Buffered layer rendered only when buffered > position and <= duration; uses FractionallySizedBox with stable ValueKey for deterministic test lookup"
  - "Demo imports media_controls.dart directly (NOT via the barrel) because Plan 07-04 owns the barrel export — sequential brief forbids this plan from touching frontend_scaffold.dart"
metrics:
  duration_minutes: 5
  completed: 2026-08-15
  tasks: 3
  files_created: 3
  files_modified: 0
  tests_added: 12
---

# Phase 07 Plan 02: MediaControls Widget Summary

**One-liner:** Shipped `MediaControls` (WIDG-30) — a generic M3 media control bar with play/pause toggle, seekbar showing buffered amount behind played position, mute and fullscreen toggles; render-only from caller-supplied playback state with a single transient `Duration? _scrubbing` field for in-flight drag (D-03), and time labels default-on via `ScaffoldFormattedValueDuration` (D-04).

## What Was Built

| Artifact | Purpose |
|----------|---------|
| `lib/components/media_controls.dart` | StatefulWidget with single `_scrubbing` transient field; three ScaffoldPressable buttons; FractionallySizedBox buffered layer; ScaffoldFormattedValueDuration time labels |
| `test/components/media_controls_test.dart` | 12 widget tests covering icons, callbacks, null-callback no-op, seekbar value, buffered layer, scrub-on-release emission, time-labels toggle, a11y |
| `example/lib/demos/media_controls_demo.dart` | Three scenarios (paused+buffered / playing with hidden labels / muted+fullscreen) demonstrating D-03 contract via local setState |

## Tasks Executed

| Task | Name | Commit | Result |
|------|------|--------|--------|
| 1 | Failing widget tests (RED) | `1a812e5` | All 12 tests fail on missing MediaControls |
| 2 | Implement MediaControls (GREEN) | `2724697` | 12/12 tests pass, analyze clean |
| 3 | Add demo | `e63cdcf` | Three scenarios, analyze clean |

## Verification Results

- `flutter test test/components/media_controls_test.dart` → **12/12 passing**
- `dart analyze --fatal-infos lib/components/media_controls.dart` → **0 issues**
- `dart analyze --fatal-infos test/components/media_controls_test.dart` → **0 issues**
- `dart analyze --fatal-infos example/lib/demos/media_controls_demo.dart` → **0 issues**
- D-03 grep: `Duration? _scrubbing` count = **1** (single transient field)
- D-03 grep: `MediaControlsCubit` count = **0**
- Forbidden identifiers (`flutter_bloc`, `Cubit`, `Riverpod`, `sleep_for`) count = **0**
- `ScaffoldPressable(` count = **3** (play, mute, fullscreen)
- `ScaffoldFormattedValueDuration(` count = **2** (position, duration)
- `example/lib/main.dart` NOT modified (owned by Plan 07-04)
- `lib/frontend_scaffold.dart` NOT modified (owned by Plan 07-04)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Demo uses direct component import instead of barrel import**
- **Found during:** Task 3
- **Issue:** Plan acceptance criteria say "File imports `package:frontend_scaffold/frontend_scaffold.dart` (barrel, not individual paths)" BUT the sequential brief explicitly states "Do NOT add the media_controls barrel export — Plan 07-04 owns all remaining barrel additions". The barrel does not yet export `media_controls.dart`, so a barrel import would fail to resolve `MediaControls`.
- **Fix:** Imported `package:frontend_scaffold/components/media_controls.dart` directly plus `package:frontend_scaffold/theme/scaffold_theme.dart` for `context.palette` / `context.dimens`. Added a top-of-file NOTE explaining Plan 07-04 will switch to the barrel import when it adds the export line.
- **Files modified:** `example/lib/demos/media_controls_demo.dart`
- **Commit:** `e63cdcf`
- **Impact on Plan 07-04:** Plan 07-04 adds the barrel export and MAY update this demo to use the barrel import; the demo compiles cleanly either way.

**2. [Rule 1 - Lint] Removed "Riverpod" mention from library docstring**
- **Found during:** Task 2 acceptance grep
- **Issue:** Plan acceptance criterion requires zero occurrences of `Riverpod` in `media_controls.dart`. The initial docstring said "no Riverpod or GeniusTheme dependency" which is documentation, not code, but the strict grep flagged it.
- **Fix:** Reworded to "no framework-specific theme or state dependencies".
- **Files modified:** `lib/components/media_controls.dart`
- **Commit:** `2724697` (folded into GREEN commit)

**3. [Rule 1 - Test API] Replaced deprecated `SemanticsNode.hasFlag(SemanticsFlag.isSlider)` with `flagsCollection.isSlider`**
- **Found during:** Task 2 analyzer run
- **Issue:** `hasFlag` deprecated after Flutter v3.32.0-0.0.pre.
- **Fix:** Used the `flagsCollection` accessor; also imported `package:flutter/rendering.dart` for `SemanticsNode`.
- **Files modified:** `test/components/media_controls_test.dart`
- **Commit:** `2724697`

**4. [Rule 1 - Lint] Removed unused `ScaffoldMotionDurations` / `ScaffoldMotionCurves` reference hack**
- **Found during:** Task 2 analyzer run
- **Issue:** Initial implementation imported `scaffold_motion.dart` and added two unused private constants (`_motionReference`, `_motionCurveReference`) to "keep the import surface stable" — analyzer flagged both as `unused_element` warnings.
- **Fix:** Removed the import and the unused constants. MediaControls currently has no internal show/hide animation, so the motion tokens aren't needed; the underlying `ScaffoldPressable` already consumes `ScaffoldMotionDurations.short` + `ScaffoldMotionCurves.standard` for its own press-state AnimatedOpacity, satisfying the reduced-motion requirement transitively.
- **Files modified:** `lib/components/media_controls.dart`
- **Commit:** `2724697`

## Authentication Gates

None.

## TDD Gate Compliance

- **RED commit:** `1a812e5` (`test(07-02)`) — present
- **GREEN commit:** `2724697` (`feat(07-02)`) — present, follows RED
- **REFACTOR commit:** N/A — no refactor needed (minimal implementation already clean)

Gate sequence verified in `git log`.

## Known Stubs

None. All inputs are caller-supplied; the demo wires local setState to each callback so nothing renders placeholder or mock data.

## Threat Flags

None. This plan ships pure presentational UI (per the plan's `<threat_model>` — no network/auth/data surface; the standing rule that widgets must not log caller data is satisfied by source inspection — no `print` / `log` / `spdlog` calls).

## Self-Check: PASSED

- [x] `lib/components/media_controls.dart` exists
- [x] `test/components/media_controls_test.dart` exists
- [x] `example/lib/demos/media_controls_demo.dart` exists
- [x] Commit `1a812e5` present (RED)
- [x] Commit `2724697` present (GREEN)
- [x] Commit `e63cdcf` present (demo)
- [x] 12/12 tests pass; 0 analyzer warnings on all three files
- [x] Single `Duration? _scrubbing` field (D-03); zero `MediaControlsCubit` / `flutter_bloc` / `Cubit` / `Riverpod` / `sleep_for` occurrences
- [x] `example/lib/main.dart` NOT modified
- [x] `lib/frontend_scaffold.dart` NOT modified (Plan 07-04 owns barrel additions)
