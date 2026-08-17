---
phase: 07-media-integration-widgets
reviewed: 2026-08-17T01:15:09Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - example/lib/demos/media_card_demo.dart
  - example/lib/demos/media_controls_demo.dart
  - example/lib/demos/wallet_connect_sheet_demo.dart
  - example/lib/main.dart
  - example/macos/Runner/MainFlutterWindow.swift
  - lib/components/media_card.dart
  - lib/components/media_controls.dart
  - lib/components/scaffold_slider.dart
  - lib/components/wallet_connect_sheet.dart
  - lib/frontend_scaffold.dart
  - lib/theme/scaffold_dimens.dart
  - templates/components/media_card.dart.jinja2
  - templates/components/media_card_vars.json
  - test/components/media_card_test.dart
  - test/components/media_controls_test.dart
  - test/components/scaffold_slider_test.dart
  - test/components/wallet_connect_sheet_test.dart
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-08-17T01:15:09Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

Reviewed the Phase 7 media-integration widgets (MediaCard, MediaControls, ScaffoldSlider, WalletConnectSheet), the barrel export, dimens tokens, four demos, the macOS runner, the MediaCard Jinja2 template + vars fixture, and the four widget test suites. The core composition work is solid: the ScaffoldSlider in-track buffered painting correctly shares the track rect with the played/inactive segments (no drift), the unconditional track-shape install genuinely avoids the mid-gesture subtree teardown regression (verified the drag test exercises the buffered-boundary crossing), and the WalletConnectSheet middle-truncation helper is correct, including the short-value early return.

Three warnings surfaced: the MediaControls time-label width measurement silently ignores ambient text scale (contradicting its own doc comment and breaking the no-jitter guarantee under accessibility text scaling), the same measurement under-reserves for durations of 10+ hours, and the checked-in `media_card.dart.jinja2` template has drifted from the generated `lib/components/media_card.dart` (missing `semanticLabel`, stale doc text) — a violation of the project's schema/generator drift rules. Six info items cover a dead parameter, stale "how to wire" comments in demos, magic numbers in demo/Swift code, a misleading test docstring, and one weak assertion.

No critical issues found.

## Warnings

### WR-01: `_measureTimeLabelWidth` ignores ambient text scale — reserved label width is wrong under text scaling

**File:** `lib/components/media_controls.dart:306-318`
**Issue:** The `TextPainter` is laid out without a `textScaler`, so it always measures at scale 1.0:

```dart
final TextPainter painter = TextPainter(
  text: TextSpan(text: longest, style: style),
  maxLines: 1,
  textDirection: TextDirection.ltr,
)..layout();
```

The rendered label is a `Text` widget inside `ScaffoldFormattedValueDuration`, which inherits the ambient `MediaQuery.textScaler`. When the user has accessibility text scaling enabled (scale > 1.0), the actual painted label is wider than the fixed reservation, the `Align` child clips/overflows, and the seekbar extent can shift — exactly the jitter the comment on lines 177-186 claims to eliminate ("tracks the ambient text theme / text scale instead of a magic number"). The claim about text scale is false.

**Fix:**
```dart
final TextPainter painter = TextPainter(
  text: TextSpan(text: longest, style: style),
  maxLines: 1,
  textDirection: TextDirection.ltr,
  textScaler: MediaQuery.textScalerOf(context),
)..layout();
```
`_measureTimeLabelWidth` is called from `build`, so `context` is available; pass it in or resolve the scaler before the call.

### WR-02: `_measureTimeLabelWidth` under-reserves for durations >= 10 hours

**File:** `lib/components/media_controls.dart:307-308`
**Issue:** The widest-label seed is hard-coded:

```dart
final String longest =
    duration.abs().inHours > 0 ? '0:00:00' : '0:00';
```

`ScaffoldFormattedValueDuration._format` prints hours unpadded (`'${abs.inHours}:...'`). For a duration of 10 hours or more the rendered label is `10:00:00` (8 glyphs) — one digit wider than the measured `0:00:00` (7 glyphs). With tabular figures every digit is the same width, so the rendered label deterministically overflows the reservation for long-form content (live-stream VODs, lectures). The position label is clamped to `[0, duration]`, so it can reach 8 glyphs too.

**Fix:** Derive the seed from the actual hour count instead of a constant:
```dart
final int hours = duration.abs().inHours;
final String longest = hours > 9 ? '00:00:00' : (hours > 0 ? '0:00:00' : '0:00');
```
or format `duration` with the same magnitude logic the formatter uses and measure that string.

### WR-03: Checked-in template `media_card.dart.jinja2` has drifted from the generated `media_card.dart`

**File:** `templates/components/media_card.dart.jinja2` (whole file; divergences at lines 1, 30, 37-47, 65-68, 162-168 vs `lib/components/media_card.dart:31-42, 76, 168`)
**Issue:** The generated `lib/components/media_card.dart` carries a `semanticLabel` field (constructor line 41, field lines 73-76, forwarded to `ScaffoldPressable` at line 168) and updated doc text. The template has neither: its constructor (lines 37-47) omits `semanticLabel`, its `ScaffoldPressable` call (lines 162-168) does not forward it, and several doc comments are the older revision (e.g. template line 34 vs generated lines 26-28; template metadata-row doc lines 65-68 vs generated lines 60-64). Regenerating from this template would silently drop the `semanticLabel` a11y API. Project rules require generated code to stay in lock-step with its schema/template and CI to regenerate-and-diff to prevent exactly this drift.

**Fix:** Re-sync the template to the current generated file (add the `semanticLabel` parameter/field/forwarding, align doc comments), or regenerate `lib/components/media_card.dart` from the template — whichever direction is authoritative — then verify the CI drift check covers `media_card`.

## Info

### IN-01: Dead parameter `address` on `WalletConnectSheet._titleFor`

**File:** `lib/components/wallet_connect_sheet.dart:54, 92-105`
**Issue:** `_titleFor(sessionState, address)` accepts `address` but never reads it (the connected branch returns the static `'Wallet'`). Dead parameter at a private call site.
**Fix:** Remove the parameter and the corresponding argument at line 54, or implement address-aware titling.

### IN-02: Stale "how to wire into main.dart" comments in demos that are already wired

**File:** `example/lib/demos/media_card_demo.dart:7-16`, `example/lib/demos/media_controls_demo.dart:13-23`, `example/lib/demos/wallet_connect_sheet_demo.dart:10-19`
**Issue:** Each demo file's header comment instructs the reader to add a `_DemoTile` entry and import to `example/lib/main.dart` — but `example/lib/main.dart:192-206` already registers all three. `media_controls_demo.dart:23` even says "(Registration is owned by Plan 07-04 — do NOT modify main.dart here.)" while the registration is present. Misleading for the next reader.
**Fix:** Delete the stale wiring instructions from the demo headers.

### IN-03: Magic numbers in demo layout code

**File:** `example/lib/demos/media_card_demo.dart:74, 88` (`width: 180`), `example/lib/demos/media_controls_demo.dart:76, 106, 136` (`height: 120`)
**Issue:** Bare numeric literals for demo container sizes. Project convention is named constants over magic numbers; demo code sets the example consumers copy from.
**Fix:** Hoist to file-level `const double _kDemoCardWidth = 180;` / `_kDemoStageHeight = 120;`.

### IN-04: Magic numbers in `MainFlutterWindow.swift` min-size clamp

**File:** `example/macos/Runner/MainFlutterWindow.swift:16`
**Issue:** `NSSize(width: 420, height: 480)` with the derivation explained only in the comment. The 420 is load-bearing (the MediaControls minimum usable width); a future control-bar change that alters the ~346px fixed content has no single named constant to update.
**Fix:** Introduce named constants (`kMinContentWidth = 420`, `kMinContentHeight = 480`) so the comment ties to named values.

### IN-05: Stale demo docstring references `TextOverflow.ellipsis` for the address

**File:** `example/lib/demos/wallet_connect_sheet_demo.dart:6-7`
**Issue:** The header says the connected state shows "wallet address (truncated via TextOverflow.ellipsis)" — the implementation now middle-truncates via `_truncateMiddle` (`wallet_connect_sheet.dart:213-222`). Cosmetic but misstates which truncation contract the demo exercises.
**Fix:** Update the comment to "truncated in the middle (head…tail)".

### IN-06: `scaffold_slider_test.dart` "buffered layer paints inside the track shape" asserts nothing about painting

**File:** `test/components/scaffold_slider_test.dart:47-57`
**Issue:** The test body only asserts `theme.trackShape, isNotNull` — identical to the two tests above it (lines 22-45). The buffered value 0.8 is never observed, and the in-track alignment claim in the test name is unverified; the test would pass even if `_BufferedTrackShape.paint` painted nothing. The in-track buffered painting is the phase's headline UAT fix and has no direct rendering assertion (the media_controls test at line 116 explicitly defers to this test for "the in-track alignment assertion" — but no such assertion exists).
**Fix:** Either drop the redundant test or make it real: capture the canvas (e.g. a recording `PaintingContext` or a golden) and assert the buffered `RRect` is drawn within the track rect at the expected fraction.

---

_Reviewed: 2026-08-17T01:15:09Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
