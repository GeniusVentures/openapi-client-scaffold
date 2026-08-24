---
status: complete
phase: 07-media-integration-widgets
source:
  - 07-01-SUMMARY.md
  - 07-02-SUMMARY.md
  - 07-03-SUMMARY.md
  - 07-04-SUMMARY.md
started: 2026-08-16T01:10:00.000Z
updated: 2026-08-16T00:00:00.000Z
completed: 2026-08-16T00:00:00.000Z
---

# Phase 7 UAT — Media & Integration Widgets

These tests require running the example app and visually confirming each
widget. Run from the scaffold example:

```
cd src/scaffold/example
flutter run            # pick a device (macOS / iOS sim / Android emu / chrome)
```

Then open each demo from the example app's home list.

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 7
name: WalletConnectSheet — connected state (address, network chip, Disconnect)
expected: |
  Tap "Show connected sheet". A sheet titled "Wallet" opens showing the
  middle-truncated address (0xABCD…EF12), an "Ethereum" network chip, and a
  Disconnect button in the footer. Tapping Disconnect dismisses the sheet.
awaiting: none — all tests complete

## Tests

### 1. Example app launches and lists the three Phase 7 demos
expected: The example app builds and boots without errors. The home list contains three entries — "Media card", "Media controls", "Wallet connect sheet" — and tapping any entry opens its demo page without a crash.
result: pass
note: "Initial run crashed on MediaCard metadataRow (competing Expanded+Flexible FlexParentData). Fixed by removing the demo's Expanded wrapper (MediaCard wraps children in Flexible per D-02) and documenting the contract on metadataRow. Re-test: no errors."

### 2. MediaCard — aspect ratios, badge slots, metadataRow
expected: The MediaCard demo shows three sections. (a) 16:9 card with three text badges — LIVE (top-left), NEW (top-right), HD (bottom-right) — and a metadata row showing an ellipsized channel name plus "12:34". (b) A tall 9:16 card labeled "Shorts". (c) A square 1:1 card labeled "Album". Badges sit at their named corners; the long channel name truncates with an ellipsis instead of overflowing.
result: pass

### 3. MediaCard — tap and disabled state
expected: The 1:1 card has an onTap. Tapping/clicking it gives a visual press response (state-layer ripple / opacity) with no error. (Disabled state is covered by widget tests; not separately demoed.)
result: pass

### 4. MediaControls — play/pause, seekbar, buffered, scrub
expected: Scenario 1 shows a paused control bar (play icon) at 0:00 with the buffered layer visible ahead of the played position. Tapping play toggles to a pause icon and back. Dragging the seekbar thumb updates the position label live while dragging, and releasing commits the new position (time labels reflect it).
result: pass
note: "Multi-round fix loop. Final state: seekbar extracted to composable ScaffoldSlider base widget (buffered painted in-track via custom track shape, one coordinate space, no inset math); labels measured via TextPainter (tabular figures, no hard-coded width), right/left aligned flush to the bar; drag-stall fixed (unconditional track shape — no mid-gesture rebuild); halo + standard slider geometry restored; label↔bar spacing set to dimens.space4; window contentMinSize 420px so the bar never compresses into overlap. User confirmed: drag works, labels flush, no bounce, no overlap."

### 5. MediaControls — time-labels toggle and icon states
expected: Scenario 2 renders with NO time labels (showTimeLabels: false) — only the seekbar and buttons. Scenario 3 shows the muted volume icon and the exit-fullscreen icon. Tapping mute and fullscreen toggles their icons.
result: pass
note: "User confirmed Scenario 2 (no time labels) and Scenario 3 (muted + exit-fullscreen icons) work as expected visually."

### 6. WalletConnectSheet — disconnected state (QR + Connect CTA)
expected: Tapping "Show disconnected sheet" opens a bottom sheet titled "Connect Wallet" containing a QR placeholder box (with the wc: URI text) and a Connect button. Tapping Connect dismisses the sheet.
result: pass

### 7. WalletConnectSheet — connected state (address, network chip, Disconnect)
expected: Tapping "Show connected sheet" opens a sheet titled "Wallet" showing the truncated address (ellipsis), an "Ethereum" network chip, and a Disconnect button in the footer. Tapping Disconnect dismisses the sheet.
result: pass
note: "Issue found + fixed: address rendered with TextOverflow.ellipsis (END truncation), dropping the checksum tail. Fix: middle-truncate via WalletConnectSheet._truncateMiddle — keep leading 6 chars (0x… prefix) + trailing 4 chars (checksum tail), ellipsis between (0xABCD…EF12). Widget test asserts the truncated form renders and the full address does not. User re-test: 'works correctly now in UI.'"

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0

## Gaps

(none — the Test 4 MediaControls seekbar gap was diagnosed, fixed via the
ScaffoldSlider extraction + measured labels + window floor, and confirmed
passing by the user)
