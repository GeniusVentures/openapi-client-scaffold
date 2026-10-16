---
phase: 13-theme-fields
plan: 03
subsystem: theme
tags: [theme-extension, motion, typography, hand-written-widgets]
requires:
  - "13-01 ScaffoldMotionTheme, ScaffoldTypography, context.motion, context.typography"
provides:
  - "Eleven hand-written widgets read durations and curves from context.motion"
  - "ScaffoldCodeBlock and inline code in ScaffoldStreamingRichText read context.typography.monoFontFamily"
  - "ScaffoldSkeleton sets its pulse period in didChangeDependencies"
affects: [13-04, 13-05]
tech-stack:
  added: []
  patterns:
    - "controller duration resolved from theme in didChangeDependencies (Theme.of is not readable in initState)"
    - "timer durations read context.motion at event time"
key-files:
  created:
    - test/components/motion_theme_hand_widgets_test.dart
  modified:
    - lib/components/scaffold_motion.dart
    - lib/components/scaffold_pressable.dart
    - lib/components/scaffold_selectable_surface.dart
    - lib/components/scaffold_drop_target.dart
    - lib/components/scaffold_scroll_edge_indicator.dart
    - lib/components/scaffold_disclosure.dart
    - lib/components/scaffold_selection_actions.dart
    - lib/components/scaffold_selection_copy_action.dart
    - lib/components/scaffold_streaming_copy_button.dart
    - lib/components/scaffold_code_block.dart
    - lib/components/scaffold_streaming_rich_text.dart
    - lib/components/scaffold_skeleton.dart
key-decisions:
  - "The static ScaffoldMotionDurations and ScaffoldMotionCurves keep their values and names; only their doc comments changed (PC-04)."
  - "Four files dropped the scaffold_motion.dart import because they no longer use ScaffoldMotion; the others still read the reduced-motion preference."
metrics:
  duration: "about 30 min"
  completed: 2026-10-16
status: complete
actuals:
  tokens: 17000
  tasks: 3
  commits: 3
---

# Phase 13 Plan 03: Hand-written widgets on motion and mono tokens Summary

The eleven hand-written widgets now take motion from `context.motion` and the two monospace sites take their family from `context.typography.monoFontFamily`. Defaults equal the old statics, so output is unchanged when nothing is registered.

## What was built

- Pressable, selectable surface, drop target, scroll-edge indicator, disclosure, selection actions, both copy buttons, code block, streaming rich text and skeleton no longer reference `ScaffoldMotionDurations` or `ScaffoldMotionCurves`.
- The copy revert timers (both buttons, code block) read the theme's medium at tap time. The code block highlight timer reads long.
- `ScaffoldSkeleton` creates its controller without a duration in `initState`, then sets the period and starts `repeat(reverse: true)` in `didChangeDependencies`. A theme change restarts the pulse at the new period.
- Code block text style and inline code spans use `monoFontFamily`.
- `scaffold_motion.dart`: doc comments only, now describing the statics as compatibility constants.
- `test/components/motion_theme_hand_widgets_test.dart`: 30 tests covering registered vs default motion per widget, reduced motion staying zero, the timer-driven revert, mono family, and the skeleton period including a theme change after mount.

## Verification

- `dart analyze --fatal-infos` (whole repo): no issues
- `flutter test`: 563 passed (30 new); `test/components`: 400 passed
- Existing tests of the eleven widgets are unchanged since b618159 and pass
- Plan-wide grep for `ScaffoldMotion(Durations|Curves).` across the eleven files: 0; `'monospace'` in code block and streaming rich text: 0
- `scaffold_motion.dart` diff against b618159 contains only `///` lines

## Deviations from Plan

### Requirement label

The plan frontmatter lists THM-02, which is a mislabel (THM-02 is motion-only). This plan implements THM-03 only. The mono-family change was done as the plan's tasks specify, but it is not claimed under THM-02.

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test helper typing**
- **Issue:** Spreading `scaffoldThemeExtensions` into a typed list literal failed to compile (`ThemeExtension<dynamic>` vs `ThemeExtension<ThemeExtension<dynamic>>`).
- **Fix:** The helper copies the list with `List<ThemeExtension<dynamic>>.of` and adds the optional extensions.
- **Files modified:** test/components/motion_theme_hand_widgets_test.dart

**2. Test helper sets `themeAnimationDuration: Duration.zero`**
- Without it, `MaterialApp` animates a theme change over 200 ms, so the skeleton saw interpolated motion values and the period-change assertion was not deterministic.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. T-13-09 is covered by the skeleton theme-change test and unmodified skeleton tests; T-13-10 by the default-value and reduced-motion tests.

## Commits

- 034753e: refactor(13-03): THM-03 pressable, selectable surface, drop target and scroll edge read context.motion
- f480662: refactor(13-03): THM-03 disclosure, selection actions and copy buttons read context.motion
- e1c7820: refactor(13-03): THM-03 code block, streaming rich text and skeleton read context.motion and mono family

## Self-Check: PASSED

The test file and all three commits exist in `git log`.
