---
phase: 11-verification-coverage-gate
plan: 02
subsystem: example-capture-harness
tags: [capture-harness, d-02, writer, images, demo-gallery]
requires:
  - example/lib/main.dart (26 _DemoTile registry — capture order)
  - lib/theme/scaffold_theme.dart (scaffoldThemeExtensions)
provides:
  - example/test/capture_images_test.dart (reproducible WRITER harness)
  - images/ directory at package root with 26 demo PNGs (raw material for 11-03 README gallery)
affects:
  - .planning/workstreams/scaffold/phases/11-verification-coverage-gate/11-03-PLAN.md (consumes images/)
tech-stack:
  added: []
  patterns:
    - "RenderRepaintBoundary.toImage(pixelRatio:) + ui.Image.toByteData(png) + File.writeAsBytes (first offscreen-rasterization usage in this repo)"
    - "tester.runAsync() to escape the fake-async zone for real-async rasterization when demo widgets host infinite animations"
    - "tester.takeException() drain loop to swallow non-fatal layout overflows during capture (writer not assertion)"
key-files:
  created:
    - example/test/capture_images_test.dart
    - images/action_button.png
    - images/string_button.png
    - images/text_entry_field.png
    - images/loading.png
    - images/toast.png
    - images/bottom_drawer.png
    - images/animations.png
    - images/page_chrome.png
    - images/responsive_grid.png
    - images/tracer.png
    - images/kitchen_sink.png
    - images/media_card.png
    - images/media_controls.png
    - images/wallet_connect_sheet.png
    - images/chip.png
    - images/composer.png
    - images/disclosure.png
    - images/trace_list.png
    - images/streaming_rich_text.png
    - images/code_block.png
    - images/selection_actions.png
    - images/markdown_to_spans.png
    - images/light_syntax_tokenizer.png
    - images/chart.png
    - images/chart_scrubber.png
    - images/chart_range_selector.png
  modified: []
decisions:
  - "Harness runs entirely inside `tester.runAsync` for the raster+write portion — required because ActionButton rotate, Loading flickr, ScaffoldAnimatedDisplayPulse (kitchen_sink), and the streaming cursor all use `AnimationController.repeat()` and would otherwise stall fake-async forever (the original `pumpAndSettle` path timed out at 10 minutes)"
  - "Per-capture `tester.takeException()` drain loop absorbs the pre-existing ScaffoldChart X-axis legend Row overflow (lib/components/scaffold_chart.dart:302 overflows by 16px at the 800px capture width) — the harness is a WRITER per D-02 and must not fail on pre-existing layout warnings"
metrics:
  duration: "~1h (debugging the runAsync fix dominated)"
  tasks_completed: 2
  tasks_total: 2
  files_created: 27 (1 harness + 26 PNGs)
  files_modified: 0
  completed: 2026-08-23
---

# Phase 11 Plan 02: Demo Image Capture Harness Summary

Reproducible `flutter test`-driven WRITER harness that pumps all 26 demo
widgets from `example/lib/main.dart` inside a 800x600 `RepaintBoundary` and
writes one 1600x1200 PNG per demo into package-root `images/` — the raw
material Plan 11-03 embeds in the README gallery.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Build the capture harness at example/test/capture_images_test.dart | `a27540d` | `example/test/capture_images_test.dart` |
| 2 | Run the harness and verify 26 PNGs land in images/ | `616d35d` | `example/test/capture_images_test.dart` (reworked), `images/*.png` (26) |

## Verbatim Verification Output

```
$ cd example && flutter test test/capture_images_test.dart
00:03 +1: All tests passed!
```

```
$ ls images/ | wc -l
      26
```

```
$ file images/action_button.png
images/action_button.png: PNG image data, 1600 x 1200, 8-bit/color RGBA, non-interlaced

$ file images/chart.png
images/chart.png:         PNG image data, 1600 x 1200, 8-bit/color RGBA, non-interlaced
```

```
$ git check-ignore images/action_button.png
exit=1   (NOT ignored — deliverable is committable)

$ cd example && dart analyze --fatal-infos
Analyzing example...
No issues found!
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] pumpAndSettle / fake-async zone hung on infinite animations**

- **Found during:** Task 2 first run.
- **Issue:** The plan-prescribed pattern (`pumpAndSettle` by default, `pump(1s)`
  for known-infinite demos) timed out at the 10-minute flutter_test limit on
  the very first capture. The plan only listed `AnimationsDemo` and
  `KitchenSinkDemo` as needing `pump(1s)`, but `ActionButtonDemo`
  (`ActionButtonAnimation.rotate`), `LoadingDemo` (`LoadingAnimationWidget.
  flickr`), and `ScaffoldStreamingRichTextDemo` (cursor blink during stream)
  also host infinite `AnimationController.repeat()`s. Even with `pump(1s)`,
  the test could not terminate because the test binding's fake-async zone
  waits for all pending animations before exit, and repeating controllers
  never idle.
- **Fix:** Reworked `_captureWidget` to run the raster + PNG-encode + file
  write inside `tester.runAsync(() async { ... })` (the canonical Flutter
  SDK pattern for escaping fake-async). Removed the `useAnimationSettle`
  flag — every capture now uses a fixed `pump(kAnimationSettleTime)` and
  infinite animations simply render whatever frame is current at 1s.
- **Files modified:** `example/test/capture_images_test.dart`
- **Commit:** `616d35d`

**2. [Rule 3 - Blocking] ScaffoldChart X-axis legend Row overflows by 16px at the 800px capture width**

- **Found during:** Task 2 second run.
- **Issue:** `lib/components/scaffold_chart.dart:302` lays out its X-axis
  legend labels in a `Row(mainAxisAlignment: spaceBetween)` that overflows
  by 16 pixels when the plot area is 674 px wide (the width produced by the
  plan-mandated 800 px capture surface after the chart's internal padding).
  flutter_test reports each overflow as a test failure; 4 such exceptions
  (one per chart-flavoured demo) were thrown. This is a **pre-existing
  ScaffoldChart layout quirk** at this specific width, not a harness bug.
  Fixing the chart itself would touch the public atom and is out of scope
  for this plan (D-05 fixes gaps the *sweep* surfaces, not chart layout).
- **Fix:** Added a per-capture `tester.takeException()` drain loop at the
  end of `_captureWidget`. Pixels are still written; the harness is a
  WRITER per D-02 and must not gate on layout warnings. The overflow is
  recorded here so 11-03 / a future chart fix can revisit it.
- **Files modified:** `example/test/capture_images_test.dart`
- **Commit:** `616d35d`

## Per-Demo pump Strategy (Task 2 D-05 Inline Log)

Final harness behaviour (post Rule 3 fix): every demo uses the same
`pump(kAnimationSettleTime)` strategy inside `runAsync`, so no per-demo
branches remain. The known infinite-animation hosts (verified by grep
against the live sources):

- `ActionButtonDemo` — `ActionButtonAnimation.rotate` → `_controller.repeat()`
  (`lib/components/action_button.dart:52`)
- `LoadingDemo` — `LoadingAnimationWidget.flickr` → `..repeat()`
  (`loading_animation_widget-1.3.0/lib/src/flickr/flickr.dart:30`)
- `AnimationsDemo` — `CheckmarkAnimation` / `XAnimation` are forward-only
  (one-shot), but the plan listed it as animated; treated the same.
- `KitchenSinkDemo` — `ScaffoldAnimatedDisplayPulse` → `_controller.repeat(reverse: true)`
  (`lib/components/scaffold_animated_display_pulse.dart:79`)
- `ScaffoldStreamingRichTextDemo` — `_cursorController.repeat()` while streaming
  (`lib/components/scaffold_streaming_rich_text.dart:121,202`)

## `.gitignore` Confirmation

`.gitignore` already compatible — no edits required.

```
$ grep -E "images|\.png" .gitignore
(no matches, exit 1)

$ git check-ignore -v images/action_button.png
(no matching rule, exit 1)
```

## Acceptance Criteria Verification

All plan acceptance criteria for both tasks were verified live:

- `example/test/capture_images_test.dart` exists, analyzer-clean, with the
  canonical `_pump` shape copied from `test/components/scaffold_chip_test.dart:11-18`.
- `grep -c matchesGoldenFile example/test/capture_images_test.dart` → `0` (D-02 hard rule).
- `grep -c scaffoldThemeExtensions example/test/capture_images_test.dart` → `2`.
- `grep -c _captureWidget example/test/capture_images_test.dart` → `27`
  (1 declaration + 26 call sites).
- `grep -c RenderRepaintBoundary example/test/capture_images_test.dart` → `2`.
- `grep -c 'pixelRatio: kCapturePixelRatio' example/test/capture_images_test.dart` → `1`.
- All numeric literals (`kCaptureWidth=800`, `kCaptureHeight=600`,
  `kCapturePixelRatio=2.0`, `kAnimationSettleTime=Duration(seconds:1)`) are
  named `const`s at the top of the file.
- `cd example && flutter test test/capture_images_test.dart` → `00:03 +1: All tests passed!`.
- `ls images/ | wc -l` → `26`.
- `file images/action_button.png` and `file images/chart.png` → `PNG image data, 1600 x 1200`.
- `git check-ignore images/action_button.png` → exit 1.
- Whole-example `dart analyze --fatal-infos` → `No issues found!`.

## Threat Flags

None. The harness writes PNGs to a known-relative path inside the repo; no
network, no auth, no schema changes, no FFI surface. 11-RESEARCH.md §Security
Domain explicitly scopes this phase out of ASVS.

## Self-Check: PASSED

- `example/test/capture_images_test.dart` — FOUND
- All 26 PNGs under `images/` — FOUND (`ls images/ | wc -l` → 26)
- Commit `a27540d` (Task 1) — FOUND (`git log --oneline` shows it)
- Commit `616d35d` (Task 2) — FOUND
