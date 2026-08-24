---
phase: 11-verification-coverage-gate
reviewed: 2026-08-23T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - example/test/capture_images_test.dart
  - lib/components/scaffold_disclosure.dart
  - lib/components/scaffold_selection_actions.dart
  - lib/components/scaffold_trace_list.dart
  - test/components/scaffold_selection_actions_test.dart
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-08-23
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the verification-coverage-gate artifacts: the deterministic demo-image capture harness (`example/test/capture_images_test.dart`), three library atoms (`scaffold_disclosure`, `scaffold_selection_actions`, `scaffold_trace_list`), and the selection-actions widget test suite.

No Critical (BLOCKER) findings. The capture harness is a deliberate WRITER (not an assertion) and drains pre-existing layout exceptions on purpose — that is documented behavior, not a bug. The selection-actions atom is thoughtful about pointer-deferral, escape, and scroll dismissal, and the test suite drives real gesture paths (double-tap + drag) rather than relying solely on the deterministic injection hook.

Five WARNINGs concentrate in `scaffold_selection_actions.dart`: the consumer `toolbarBuilder` is invoked twice per toolbar build (probe + real build), `_escapeFocusNode.requestFocus()` runs unconditionally on every toolbar insert, `ScaffoldDisclosure`'s AnimatedSize child swap likely breaks the collapse animation, the `_captureWalletSheet` write future is dropped, and the font-discovery loop uses a magic bound. Four Info items cover magic numbers and minor cleanup.

## Warnings

### WR-01: `toolbarBuilder` invoked twice per toolbar build (probe + real)

**File:** `lib/components/scaffold_selection_actions.dart:472-476` and `:552-556`
**Issue:** `_insertOrRefreshToolbar` calls `widget.toolbarBuilder(context, _lastSelection, _lastPlainText)` synchronously to probe whether the result is `SizedBox.shrink()`. The overlay builder then calls `widget.toolbarBuilder(overlayContext, ...)` AGAIN to actually build the card. If the consumer's builder has any side effect (constructs a stateful widget whose `initState` does work, logs, fires analytics, allocates a controller, closes over mutable state), the side effect runs twice per toolbar appearance. The probe widget itself is also discarded without being mounted, which can confuse consumers that return `StatefulWidget`s relying on `initState`/`dispose` symmetry.
**Fix:** Detect "empty" without invoking the builder — e.g. require consumers to opt out via a separate `bool showFor(TextSelection, String)` predicate, or change the contract so the builder returns `null`/`Widget?` and a single invocation feeds both the emptiness check and the overlay child:
```dart
final Widget? probe = widget.toolbarBuilder(context, _lastSelection, _lastPlainText);
if (probe == null || _isShrink(probe)) {
  _toolbarEntry?.remove();
  _toolbarEntry = null;
  return;
}
// Then pass `probe` into the OverlayEntry closure so it is reused, not rebuilt.
```
At minimum, document the double-invocation explicitly in the `toolbarBuilder` dartdoc.

### WR-02: `_escapeFocusNode.requestFocus()` steals focus on every toolbar insert

**File:** `lib/components/scaffold_selection_actions.dart:520`
**Issue:** `_insertOrRefreshToolbar` unconditionally calls `_escapeFocusNode.requestFocus()`. Because the same `_escapeFocusNode` is also passed to `SelectionArea` as its `focusNode` (line 672), this works while the selection is live, but it also fires when the toolbar is shown via `debugSimulateSelection` (test hook) or via a keyboard selection path where focus was elsewhere. Requesting focus from a state helper runs outside the focus system's normal traversal and can yank focus away from a consumer-controlled field that the user was about to type into (e.g. the user starts a selection, focus is in a sibling input, toolbar appears, focus jumps). It also means the `_onPointerReleased -> _insertOrRefreshToolbar` path can shift focus mid-gesture on platforms where pointer release precedes the focus change the user expects.
**Fix:** Only request focus when the toolbar was triggered by a keyboard selection (no pointer was down), or skip `requestFocus()` entirely and rely on `SelectionArea`'s own focus. If the Escape shortcut really requires the node to have primary focus, gate it:
```dart
if (_pointerSelectingCount == 0 && !_escapeFocusNode.hasFocus) {
  _escapeFocusNode.requestFocus();
}
```
At minimum, document the focus-stealing behavior in the class dartdoc.

### WR-03: `AnimatedSize` child swap between `Padding` and `SizedBox.shrink` defeats the collapse animation

**File:** `lib/components/scaffold_disclosure.dart:118-138`
**Issue:** When `_effectiveExpanded` flips, the child of `AnimatedSize` changes from `Padding(...)` to `const SizedBox.shrink()` (and vice versa). Because these are different widget types with no shared `Key`, the element tree replaces the child rather than updating it. `AnimatedSize` measures the *new* child's size against the *previous* child's size, but only animates when it can keep the same render object across the transition — replacing a `Padding`'s render object with a `RenderConstrainedBox` (from `SizedBox.shrink`) mid-animation often results in a snap rather than a smooth collapse, especially on the closing direction. The file's docstring promises "`AnimatedSize` (body reveal)" with `ScaffoldMotionDurations.medium`, so the snap is a behavioral regression vs. the documented UX.
**Fix:** Keep a single stable child type and animate its size via the wrapping `AnimatedSize`'s `alignment` / `curve`, e.g. always render the `Padding` and gate its child:
```dart
child: Padding(
  padding: EdgeInsets.only(left: dimens.space6, top: dimens.space4),
  child: _effectiveExpanded
      ? DefaultTextStyle(style: ..., child: widget.body)
      : const SizedBox.shrink(),
)
```
Or wrap the swap in a `KeyedSubtree`/`SizeTransition` so the size animates continuously. Verify with a widget test that measures the disclosure's height across successive `pump()`s during the collapse — the height should be strictly monotonically decreasing, not step to zero.

### WR-04: `_captureWalletSheet` and `_captureWidget` drop the `writeAsBytes` future

**File:** `example/test/capture_images_test.dart:172-176` and `:452-456`
**Issue:** Both write paths do `await File(...).create(recursive: true).then((File f) => f.writeAsBytes(...))`. The `.then` callback returns the inner `Future<File>` from `writeAsBytes`, but that inner future is *not* awaited — the outer `await` resolves as soon as `create()` completes, so the test moves on (and the harness may exit) while the PNG bytes are still being flushed. The bytes will usually land because the test VM keeps the event loop alive, but if the test runner is aggressive about teardown or a subsequent capture immediately opens the same file, the previous write can race. It also silently swallows `writeAsBytes` errors (the returned future is un-awaited and not registered for error handling).
**Fix:** Await the inner future directly:
```dart
await tester.runAsync(() async {
  final File f = await File('../images/$filename.png').create(recursive: true);
  await f.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
});
```
Same change in `_captureWalletSheet` (lines 452-456).

### WR-05: Font-discovery upward walk uses magic iteration bound

**File:** `example/test/capture_images_test.dart:216-223`
**Issue:** `for (int i = 0; i < 6; i++)` walks up to six parents from `Platform.resolvedExecutable` looking for `bin/cache/artifacts/material_fonts`. The constant `6` is a magic number tied to a specific Flutter SDK layout (`<flutter>/bin/cache/dart-sdk/bin/dart` → up 4 to reach `<flutter>`). If the SDK layout shifts (e.g. `dart-sdk` is symlinked or relocated in a future Flutter release), the loop silently fails and the harness falls back to Ahem with only a `debugPrint` — captured images will regress to placeholder squares without an explicit failure.
**Fix:** Walk until filesystem root or until found:
```dart
Directory? dir = File(Platform.resolvedExecutable).parent;
while (dir != null) {
  final String candidate = '${dir.path}/bin/cache/artifacts/material_fonts';
  if (Directory(candidate).existsSync()) {
    fontDir = candidate;
    break;
  }
  final Directory parent = dir.parent;
  if (parent.path == dir.path) break; // reached filesystem root
  dir = parent;
}
if (fontDir == null) {
  throw StateError(
    'capture_images_test: could not locate material_fonts directory; '
    'real fonts are required for human-viewable demo images',
  );
}
```
Failing loudly is preferable to silent Ahem fallback for a WRITER harness whose entire output is a set of PNGs.

## Info

### IN-01: Magic number for disclosure chevron size

**File:** `lib/components/scaffold_disclosure.dart:108`
**Issue:** `Icon(Icons.chevron_right, size: 24, ...)` hardcodes the chevron glyph size. Per project conventions (GNUS/AI coding standards — "NEVER use magic numbers"), this should be a named constant. The size is also a visual-design token that arguably belongs in `ScaffoldDimens` alongside `space4`, `radiusMd`, etc.
**Fix:** Add `static const double kChevronSize = 24.0;` at the top of the file, or (better) add `disclosureChevronSize` to `ScaffoldDimens` so consumers can override it via theme extension.

### IN-02: Magic number for trace-list status dot size

**File:** `lib/components/scaffold_trace_list.dart:120`
**Issue:** `ScaffoldStatusIndicator(status: item.status!, dotSize: 8)` hardcodes the status-dot diameter. Same magic-number convention as IN-01.
**Fix:** Add `static const double kStatusDotSize = 8.0;` or extend `ScaffoldDimens`.

### IN-03: `_captureWalletSheet` is ~150 lines of hand-built widget tree duplicated inside the test

**File:** `example/test/capture_images_test.dart:311-458`
**Issue:** The function re-implements the WalletConnectSheet card layout (colors, spacing, borders, two states) inline rather than reusing the actual sheet widget. If the real sheet's design changes (different padding, additional button, different border radius), the captured image will silently drift from production pixels. The inline comment acknowledges this is deliberate ("bypassing the button-triggered demo"), but the duplicated layout is a maintenance hazard.
**Fix:** Extract a public static `buildWalletSheetPreview(BuildContext, {required bool connected})` helper on the real sheet widget, then call it from both the demo and the capture harness. That keeps the source of truth in one place. If that's too invasive for this phase, at least add a `// SYNC: must match wallet_connect_sheet.dart card layout` comment and a test that smoke-builds the real sheet to catch API drift.

### IN-04: `dynamic` state lookup in tests bypasses the `@visibleForTesting` boundary

**File:** `test/components/scaffold_selection_actions_test.dart:55-56, 79-80, 109-110, 145-146, 170-171, 193-194, 234-235, 265-266, 300-301, 323-324, 347, 396, 415, 458, 490, 517, 547, 577, 615, 657, 689, 720, 754, 793, 830, 868`
**Issue:** Every test does `final dynamic state = tester.state(find.byType(ScaffoldSelectionActions));` and then calls `ScaffoldSelectionActions.debugSimulateSelection(state, ...)` which casts via `(state as _ScaffoldSelectionActionsState)`. The `dynamic` erases compile-time checking; a refactor that renames `_ScaffoldSelectionActionsState` or changes the cast signature would fail at runtime inside the test, not at analyze time. The `// ignore: invalid_use_of_visible_for_testing_member` comments suggest the author is already aware.
**Fix:** `tester.state` returns a `State<ScaffoldSelectionActions>` already — pass that directly:
```dart
final State<ScaffoldSelectionActions> state =
    tester.state(find.byType(ScaffoldSelectionActions));
ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
```
The `dynamic` keyword and the `// ignore:` comment can both be dropped, restoring type safety without changing the public test-hook contract.

---

_Reviewed: 2026-08-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
