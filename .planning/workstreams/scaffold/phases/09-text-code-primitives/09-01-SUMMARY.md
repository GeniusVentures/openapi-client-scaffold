---
phase: 09-text-code-primitives
plan: 01
subsystem: components
tags: [streaming, rich-text, citations, a11y, flutter]
requirements: [WIDG-32, WIDG-33, WIDG-34]
requires:
  - lib/components/scaffold_card.dart (D-02 optional-cubit fallback pattern)
  - lib/components/scaffold_card_state.dart (sentinel copyWith)
  - lib/components/scaffold_card_cubit.dart (named-transition Cubit)
  - lib/components/scaffold_live_region.dart (announce sink)
  - lib/components/scaffold_motion.dart (reduced-motion gating)
  - lib/components/scaffold_surface.dart (surface wrapper)
  - lib/components/scaffold_pressable.dart (citation pill interaction)
  - lib/theme/scaffold_theme.dart (context.palette / context.dimens)
provides:
  - ScaffoldStreamingRichText (typed-span streaming atom, WIDG-32/33/34)
  - ScaffoldStreamingRichTextCubit (appendSpans/complete/toggleCitation/reset)
  - ScaffoldStreamingRichTextState (immutable state, sentinel copyWith)
  - ScaffoldRichSpan sealed hierarchy (Text / Citation / Link / CodeInline)
  - ScaffoldStreamingAnnouncePolicy + ScaffoldBlockBoundaryAnnouncePolicy (D-06)
affects:
  - lib/components/ (new atom family)
  - lib/utils/ (new typed-span + announce-policy modules)
tech-stack:
  added: []
  patterns:
    - D-01 typed atom + optional DI slots (cubit, announcePolicy)
    - D-02 optional-consumer-Cubit with internal _ownsCubit fallback
    - D-03 typed spans; atom never parses Markdown
    - D-06 block-boundary announce policy with Timer-driven debounce
key-files:
  created:
    - lib/utils/scaffold_rich_spans.dart
    - lib/utils/streaming_announce_policy.dart
    - lib/components/scaffold_streaming_rich_text_state.dart
    - lib/components/scaffold_streaming_rich_text_cubit.dart
    - lib/components/scaffold_streaming_rich_text.dart
    - test/components/scaffold_streaming_rich_text_test.dart
  modified: []
decisions:
  - Used Timer (dart:async) for live-region debounce so widget tests can drive
    the 300ms window via tester.pump(Duration) under FakeAsync. Wall-clock
    DateTime diffs are not test-deterministic.
  - Reduced-motion + stream-complete paths stop the cursor AnimationController
    inside BlocBuilder.build to keep the controller in sync with state.
  - Citation pills use ScaffoldPressable so Enter/Space activation, focus
    outline, and 48x48 hit area come for free; Semantics(button: true) label
    is 'Citation ${index + 1}' counting citation spans only.
metrics:
  duration: ~25 minutes
  completed: 2026-08-20
  tasks: 3
  files-created: 6
  files-modified: 0
---

# Phase 09 Plan 01: ScaffoldStreamingRichText Atom Summary

**One-liner:** Typed-span streaming rich-text atom (ScaffoldStreamingRichText) with optional-consumer cubit, blinking cursor, citation pills with inline source reveal, response-action row, and block-boundary live-region announcements — D-02 + D-03 + D-06 applied.

## What shipped

- `lib/utils/scaffold_rich_spans.dart` — sealed `ScaffoldRichSpan` hierarchy with four `final` subtypes: `ScaffoldTextSpan`, `ScaffoldCitationSpan`, `ScaffoldLinkSpan`, `ScaffoldCodeInlineSpan`. Pure data shapes; no rendering logic.
- `lib/utils/streaming_announce_policy.dart` — abstract `ScaffoldStreamingAnnouncePolicy` + default `ScaffoldBlockBoundaryAnnouncePolicy(debounce: 300ms)`. Policy is pure/stateless; the widget owns the debounce timer.
- `lib/components/scaffold_streaming_rich_text_state.dart` — immutable state with `spans`, `isStreaming` (default true), `expandedCitations`; sentinel-based `copyWith` (`_unset` marker) copied from `scaffold_card_state.dart`.
- `lib/components/scaffold_streaming_rich_text_cubit.dart` — named-transition cubit (`appendSpans`, `complete`, `toggleCitation`, `reset`). Never exposes `emit`.
- `lib/components/scaffold_streaming_rich_text.dart` — the atom. `BlocProvider<ScaffoldStreamingRichTextCubit>.value` + `BlocBuilder`; `_ownsCubit` fallback per `scaffold_card.dart:99`. Cursor: `AnimationController` at 1060ms, hard-blink opacity step at 0.5; pinned to 1.0 under reduced motion; `SizedBox.shrink()` when `!isStreaming`. Citation pills toggle expanded source cards via `AnimatedSize` (zero duration under reduced motion). Action row separated by `dimens.space4`. Live region announced via `ScaffoldLiveRegion(value: _lastAnnouncedText)` with `Timer`-driven 300ms debounce.
- `test/components/scaffold_streaming_rich_text_test.dart` — 9 `testWidgets` blocks covering all behaviors in the plan; zero `pumpAndSettle` calls; explicit `tester.pump(Duration)` cycle points; token assertions against `ScaffoldPalette.defaultPalette` / `ScaffoldDimens.defaultDimens` only.

## Commits

| Commit  | Type | Message |
|---------|------|---------|
| 48c4621 | feat | ship typed span model + announce-policy hook + state + cubit |
| 46a51e5 | feat | ship ScaffoldStreamingRichText widget |
| 9504206 | fix  | drive announce debounce with Timer for FakeAsync testability |
| 10c0844 | test | widget tests for ScaffoldStreamingRichText |

## Verification

- `dart analyze --fatal-infos` on all 6 touched files: clean (0 issues).
- `flutter test test/components/scaffold_streaming_rich_text_test.dart`: 9/9 passed.
- `grep -c pumpAndSettle` on the test file: 0.
- `grep -E "^import 'package:" lib/components/scaffold_streaming_rich_text.dart | grep -v flutter/material|flutter_bloc|frontend_scaffold`: 0 lines (no third-party deps added, D-08 upheld).
- `pubspec.yaml dependencies:` block unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Wall-clock debounce blocked test determinism**
- **Found during:** Task 3 (Test 7 — live region debounce).
- **Issue:** Plan specified `DateTime.now().difference(_lastAnnounceAt!) >= policyDebounce`, which uses wall-clock time. `tester.pump(Duration)` advances only Flutter's FakeAsync clock; the widget never observed the 300ms window expiring, so the post-debounce announcement never fired.
- **Fix:** Replaced the wall-clock diff with a `Timer`-driven throttle (`_announceThrottled` flag + `_announceThrottleTimer`). Timers respect FakeAsync, so widget tests advance the window with `tester.pump(Duration)`. Added `Timer.cancel()` in `dispose`.
- **Files modified:** `lib/components/scaffold_streaming_rich_text.dart`
- **Commit:** 9504206

**2. [Rule 1 — Bug] Cursor Container detection used the wrong property**
- **Found during:** Task 3 (Test 3 — cursor visible while streaming).
- **Issue:** Test predicate checked `Container.decoration.color` but `Container(width, height, color)` shorthand assigns `color` directly to `Container.color` (constraints + color, no BoxDecoration). Predicate never matched.
- **Fix:** Predicate now checks `w.color == ScaffoldPalette.defaultPalette.lightGreenPrimary` directly.
- **Files modified:** `test/components/scaffold_streaming_rich_text_test.dart`
- **Commit:** 10c0844

**3. [Rule 1 — Bug] find.text() missed span runs inside Text.rich**
- **Found during:** Task 3 (Test 2 — incremental append).
- **Issue:** `Text.rich` composes a single `RichText`; `find.text('hello')` only matches `Text` widgets and returned zero hits after the second append.
- **Fix:** Switched to `find.textContaining(...)` for the single-span case and read `RichText.text.toPlainText()` for the multi-span case, asserting both substrings are present (additive render).
- **Files modified:** `test/components/scaffold_streaming_rich_text_test.dart`
- **Commit:** 10c0844

## Authentication Gates

None.

## Known Stubs

None. All six shipped artifacts are fully wired; no TODOs, no placeholder text, no empty defaults flowing to UI.

## Threat Flags

None. This plan adds no new network endpoints, auth paths, file-access patterns, or schema changes; the atom renders consumer-supplied typed spans locally with no I/O.

## Self-Check: PASSED

- `lib/utils/scaffold_rich_spans.dart` — FOUND
- `lib/utils/streaming_announce_policy.dart` — FOUND
- `lib/components/scaffold_streaming_rich_text_state.dart` — FOUND
- `lib/components/scaffold_streaming_rich_text_cubit.dart` — FOUND
- `lib/components/scaffold_streaming_rich_text.dart` — FOUND
- `test/components/scaffold_streaming_rich_text_test.dart` — FOUND
- Commit `48c4621` — FOUND
- Commit `46a51e5` — FOUND
- Commit `9504206` — FOUND
- Commit `10c0844` — FOUND
