---
phase: 13-theme-fields
plan: 04
subsystem: theme
tags: [theme-extension, motion, codegen, templates]
requires:
  - "13-01 ScaffoldMotionTheme and context.motion"
provides:
  - "selection_indicator, search_bar and animated_display templates read context.motion"
  - "Regenerated toggle, search bar and seven animated display variants"
affects: [13-05]
tech-stack:
  added: []
  patterns:
    - "generated controller duration and animations set up in didChangeDependencies behind a one-shot flag"
key-files:
  created:
    - test/components/motion_theme_generated_widgets_test.dart
  modified:
    - templates/components/selection_indicator.dart.jinja2
    - templates/components/search_bar.dart.jinja2
    - templates/components/animated_display.dart.jinja2
    - lib/components/scaffold_selection_indicator_toggle.dart
    - lib/components/scaffold_search_bar.dart
    - lib/components/scaffold_animated_display_bounce.dart
    - lib/components/scaffold_animated_display_fade.dart
    - lib/components/scaffold_animated_display_pulse.dart
    - lib/components/scaffold_animated_display_rotate.dart
    - lib/components/scaffold_animated_display_scale.dart
    - lib/components/scaffold_animated_display_shake.dart
    - lib/components/scaffold_animated_display_slide.dart
key-decisions:
  - "Animated display builds its controller without a duration in initState; didChangeDependencies sets the duration every call and runs _configureAnimation and _start once."
  - "The toggle's _buildToggle now takes BuildContext so it can read context.motion."
metrics:
  duration: "about 25 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 14000
  tasks: 2
  commits: 2
---

# Phase 13 Plan 04: Generated families on motion tokens Summary

The toggle, the search bar results panel and all seven animated displays now take duration and curve from `context.motion`. Only the three templates were edited; the Dart is their regenerated output. Defaults equal the old statics.

## What was built

- Toggle: `AnimatedPositioned` reads `context.motion.short` and `.standard`. The toggle-only `scaffold_motion.dart` import is gone.
- Search bar: results `AnimatedSize` reads `context.motion.medium`; the unused `scaffold_motion.dart` import is gone.
- Animated display: `initState` only creates the controller. `didChangeDependencies` sets `_controller.duration` to `widget.duration ??` theme short (pulse) or medium, and on the first call runs `_configureAnimation()` then `_start()`. `didUpdateWidget` re-resolves duration through the same getter. Curves use `widget.curve ?? context.motion.standard`. Class docs name `ScaffoldMotionTheme`.
- `test/components/motion_theme_generated_widgets_test.dart`: 11 tests (toggle, search bar, fade/pulse theme timing, explicit duration and curve winning, didUpdateWidget duration, shake and bounce).

## Verification

- Drift check: all three drivers re-run after commit, `git diff --exit-code -- lib/` clean
- `dart analyze --fatal-infos` (whole repo): no issues
- `flutter test`: 574 passed (11 new)
- Grep for `ScaffoldMotion(Durations|Curves).` across the three templates and their outputs: 0
- Among selection indicator, card, state_view and search bar outputs, only the toggle and search bar differ from b618159
- Existing family tests (selection indicator, search bar, animated display, scaffold_motion) unchanged and passing

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Template whitespace changed radio and checkbox output**
- **Found during:** Task 1
- **Issue:** Removing the toggle-only import block dropped a blank line from the radio and checkbox outputs, violating the byte-identical requirement.
- **Fix:** Kept a blank line in the template where the block was. The toggle output gets one extra blank line; radio and checkbox are unchanged.
- **Files modified:** templates/components/selection_indicator.dart.jinja2

**2. [Rule 3 - Blocking] Toggle builder had no BuildContext**
- **Issue:** `_buildToggle(palette)` could not read `context.motion`.
- **Fix:** Signature is now `_buildToggle(BuildContext context, ScaffoldPalette palette)`.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. T-13-11 is covered by the clean drift check; T-13-12 by the lifecycle tests and the unmodified family tests.

## Commits

- aa6ac46: refactor(13-04): THM-03 toggle and search bar templates read context.motion
- c285b70: refactor(13-04): THM-03 animated display template resolves duration and curve from the theme

## Self-Check: PASSED

The test file and both commits exist in `git log`.
