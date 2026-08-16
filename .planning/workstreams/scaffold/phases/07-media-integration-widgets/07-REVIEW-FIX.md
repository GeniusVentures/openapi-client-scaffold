---
phase: 07-media-integration-widgets
fixed_at: 2026-08-15T00:00:00Z
review_path: .planning/workstreams/scaffold/phases/07-media-integration-widgets/07-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 11
skipped: 0
status: all_fixed
---

# Phase 7: Code Review Fix Report

**Fixed at:** 2026-08-15
**Source review:** .planning/workstreams/scaffold/phases/07-media-integration-widgets/07-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 11
- Fixed: 11
- Skipped: 0

## Fixed Issues

### CR-01: Missing semantic labels on all icon-only buttons and on the seekbar

**Files modified:** `lib/components/scaffold_pressable.dart`, `lib/components/media_controls.dart`, `lib/components/media_card.dart`
**Commit:** 11a7137
**Applied fix:**
- Added optional `semanticLabel` named parameter to `ScaffoldPressable` (default `null`) and threaded it into the `Semantics(label:)` registration. Additive, non-breaking.
- In `MediaControls`, supplied `semanticLabel` to the play/pause (`'Pause'`/`'Play'`), mute (`'Unmute'`/`'Mute'`), and fullscreen (`'Exit fullscreen'`/`'Enter fullscreen'`) icon-only `ScaffoldPressable`s, and added a `semanticFormatterCallback` on the `Slider` that renders the position as `m:ss`.
- In `MediaCard`, added an optional `semanticLabel` parameter and forwarded it to the wrapping `ScaffoldPressable` when `onTap` is non-null.

### WR-01: Hardcoded dimensions in WalletConnectSheet violate theme-token rule

**Files modified:** `lib/components/wallet_connect_sheet.dart`
**Commit:** f2893ab
**Applied fix:** Replaced every hardcoded `EdgeInsets` literal with theme-token lookups via `context.dimens`. Mapping used: `16 -> dimens.space8`, `8 -> dimens.space4`, `12 -> dimens.space6`, `24 -> dimens.space12`. Both `_childrenFor` and `_footerFor` resolve `dimens` from the build context they receive. `CircularProgressIndicator` remains `const` since only the padding depends on runtime tokens.

### WR-02: Hardcoded `Container(height: 4.0)` for buffered layer in MediaControls

**Files modified:** `lib/components/media_controls.dart`
**Commit:** d36d5cf
**Applied fix:** Resolved the buffered bar's height from `SliderTheme.of(context).trackHeight ?? 4.0` at the top of `build()` so the buffered layer stays aligned with the active slider theme. Falls back to Material's default `4.0` when no `SliderTheme` override is present. No new `ScaffoldDimens` token was added — the track height is owned by the slider theme, not by scaffold spacing, so this is the minimal correct fix.

### WR-03 + WR-04: Sheet builds children with the caller's `BuildContext` (stale theme + wrong Navigator)

**Files modified:** `lib/components/wallet_connect_sheet.dart`
**Commit:** 3ee1a5c
**Applied fix:** Combined into a single commit because they share the same root cause. `WalletConnectSheet.show` no longer invokes `_childrenFor` synchronously with the caller's context. Instead, it wraps the children list in a single `Builder` that re-invokes `_childrenFor` with the sheet's own `BuildContext` (`sheetContext`). As a result:
- `qrBuilder(sheetContext, uri)` now receives the sheet's context, so a consumer's `Navigator.of(sheetContext).pop()` dismisses the sheet (not the underlying page).
- `Theme.of(sheetContext)` is re-evaluated whenever the modal rebuilds, so the sheet's text styles track theme changes (light/dark toggle, palette override) while open.

Existing tests still pass (11/11 in `wallet_connect_sheet_test.dart`).

### WR-05: `MediaCard` disabled + onTap test asserts behavior owned by `ScaffoldPressable`

**Files modified:** `test/components/media_card_test.dart`
**Commit:** 1b71479
**Applied fix:** Tightened two assertions in the "disabled + onTap blocks interaction and wraps in ScaffoldDisabledOverlay" test:
- `find.byType(ScaffoldDisabledOverlay)` changed from `findsWidgets` (matches zero) to `findsOneWidget`.
- Added `tester.widget(find.byType(ScaffoldPressable)).disabled` assert to lock in that `MediaCard` itself passes `disabled: true` through to `ScaffoldPressable`.

Test-only change; no production behavior modified.

### WR-06: `MediaControls` scrub test gesture math is fragile

**Files modified:** `test/components/media_controls_test.dart`
**Commit:** 6679b6c
**Applied fix:** Replaced the coordinate math that subtracted a global top-left from `Size.bottomCenter(Offset.zero)` (which mixed a local size with a global offset). New code keeps `sliderSize` as a `Size` and computes the drag start as `sliderTopLeft + Offset(4, sliderSize.height / 2)` and the drag delta as `Offset(sliderSize.width / 4, 0)` — exactly what the review suggested. Test continues to pass (1 seek fired on release, none during drag).

### IN-01: MediaCard doc comment over-promises on `ScaffoldDisabledOverlay`

**Files modified:** `lib/components/media_card.dart`
**Commit:** b302e62
**Applied fix:** Rephrased the class doc to clarify ownership: "When [disabled] is true, interaction is blocked — either via [ScaffoldPressable]'s internal disabled state (when [onTap] is set) or via an explicit [ScaffoldDisabledOverlay] wrapper."

### IN-02: `WalletConnectSheet` duplicates the address as both title and body

**Files modified:** `lib/components/wallet_connect_sheet.dart`, `test/components/wallet_connect_sheet_test.dart`
**Commit:** 08cb7a3
**Applied fix:** `_titleFor` now returns the static label `'Wallet'` for the connected state (was `address ?? 'Wallet'`). The address is rendered only in the body via the existing `Text(address, overflow: TextOverflow.ellipsis, maxLines: 1, ...)`. Updated the "title switches with state" test to assert the new behavior: title is the static label, and `find.text(address)` matches exactly one widget (the body), not two.

### IN-03: `WalletConnectSheetDemo` uses hardcoded `Colors.black12`

**Files modified:** `example/lib/demos/wallet_connect_sheet_demo.dart`
**Commit:** 9912b17
**Applied fix:** Replaced `color: Colors.black12` with `color: ctx.palette.borderSubtle` so the QR placeholder tracks the active palette in both light and dark themes. The `qrBuilder` already receives a context, so no signature change was needed.

### IN-04: MediaControls Demo note is stale — Plan 07-04 has already landed

**Files modified:** `example/lib/demos/media_controls_demo.dart`
**Commit:** f7a1304
**Applied fix:** Deleted the four-line stale "NOTE on imports" comment block (lines 25-28 of the demo file). The file already imports `frontend_scaffold/frontend_scaffold.dart` (the barrel) and the barrel already exports `media_controls.dart`.

## Skipped Issues

None — all 11 findings in scope were fixed.

---

_Fixed: 2026-08-15_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
