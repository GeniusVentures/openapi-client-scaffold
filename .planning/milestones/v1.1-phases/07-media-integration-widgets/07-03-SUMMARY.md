---
phase: 07-media-integration-widgets
plan: 03
subsystem: wallet-connect
tags: [flutter, dart, widget, walletconnect, reown, bottom-sheet, tdd]
requires:
  - lib/components/bottom_drawer/responsive_drawer.dart
  - lib/components/scaffold_badge.dart
  - lib/components/scaffold_pressable.dart
  - lib/theme/scaffold_theme.dart
provides:
  - WalletConnectSheet static show façade
  - WalletConnectSessionState enum
  - WalletConnectSheetDemo
affects:
  - genius-tube Phase 4 (Reown session UI)
  - GeniusWallet (shared Reown UI per ADR-002)
tech-stack:
  added: []
  patterns:
    - Static show façade over ResponsiveDrawer (no MediaQuery in consumer file)
    - Consumer-supplied qrBuilder slot (D-05) — zero QR dependency in scaffold
    - TDD RED → GREEN (failing tests first, then implementation)
key-files:
  created:
    - lib/components/wallet_connect_sheet.dart
    - test/components/wallet_connect_sheet_test.dart
    - example/lib/demos/wallet_connect_sheet_demo.dart
  modified: []
decisions:
  - D-05 honored — qrBuilder slot; scaffold gains NO QR dependency (pubspec.yaml unchanged, zero qr_flutter/QrImage/qr.dart refs in lib/)
  - Address truncation via Text(overflow: TextOverflow.ellipsis, maxLines: 1) — never manual substring
  - 800px desktop breakpoint owned by ResponsiveDrawer — sheet delegates presentation
  - Demo uses direct imports (barrel export lands in Plan 07-04 per wave contract)
metrics:
  duration_minutes: ~10
  completed: 2026-08-15
  tasks: 3
  commits: 3
  tests_added: 11
  tests_passing: 11
---

# Phase 7 Plan 03: WalletConnectSheet Summary

**One-liner:** Static show façade over ResponsiveDrawer presenting Reown WalletConnect session state (disconnected QR / connecting / connected address+network+disconnect) with a consumer-supplied `qrBuilder` slot per D-05 — zero QR dependency added to scaffold.

## What Was Built

Three files implementing WIDG-31 (Reown WalletConnect session sheet):

1. **`lib/components/wallet_connect_sheet.dart`** — `WalletConnectSheet` class with a single static `show<T>()` façade. Three states via `WalletConnectSessionState` enum:
   - **disconnected**: title "Connect Wallet"; children = consumer `qrBuilder(context, uri)` (when both non-null), optional Connect CTA (ScaffoldPressable, only when `onConnect != null`), hint text
   - **connecting**: title "Connect Wallet"; children = centered CircularProgressIndicator + status text
   - **connected**: title = address (or "Wallet"); children = ellipsis-truncated address Text + ScaffoldBadge(variant: BadgeVariant.text, text: networkName) when non-null; footer = Disconnect ScaffoldPressable
   - Presentation delegates to `ResponsiveDrawer.show<T>` — no `MediaQuery` in this file
2. **`test/components/wallet_connect_sheet_test.dart`** — 11 widget tests covering the full WIDG-31 contract
3. **`example/lib/demos/wallet_connect_sheet_demo.dart`** — two-button demo triggering both disconnected (with QR placeholder via `qrBuilder`) and connected sheet states

## Tasks Completed

| Task | Description | Commit | Status |
|------|-------------|--------|--------|
| 1 | Write failing widget tests (RED) | `c8dcae9` | Done — 11 testWidgets in failing state (undefined WalletConnectSheet/WalletConnectSessionState) |
| 2 | Implement WalletConnectSheet static show façade (GREEN) | `1d54e71` | Done — all 11 tests pass, analyzer clean |
| 3 | Add WalletConnectSheet demo | `69164cb` | Done — analyzer clean, both states reachable |

## Test Coverage

11 widget tests, all passing:

1. Disconnected state renders `qrBuilder` output containing the URI
2. `qrBuilder` is invoked with the exact URI passed to `show` (D-05 pass-through)
3. Connected state renders the address with `TextOverflow.ellipsis` + `maxLines: 1`
4. Connected state renders a `ScaffoldBadge` text chip with `networkName`
5. Tapping Disconnect in connected state invokes `onDisconnect` exactly once
6. Dismissing the sheet (close affordance) invokes `onClose` exactly once
7. Disconnected state with `onConnect` shows a Connect CTA that fires once on tap
8. Disconnected state with `onConnect: null` omits the Connect affordance
9. Title switches with state — "Connect Wallet" disconnected; address connected
10. No QR dependency — source contains zero `qr_flutter`/`QrImage`/`qr.dart` refs
11. Disconnect CTA is wrapped in a `ScaffoldPressable`

## Verification Results

| Check | Result |
|-------|--------|
| `flutter test test/components/wallet_connect_sheet_test.dart` | 11/11 pass |
| `dart analyze --fatal-infos lib/components/wallet_connect_sheet.dart` | clean (0 issues) |
| `dart analyze --fatal-infos example/lib/demos/wallet_connect_sheet_demo.dart` | clean (0 issues) |
| `dart analyze --fatal-infos test/components/wallet_connect_sheet_test.dart` | clean (0 issues) |
| `grep -E "qr_flutter\|QrImage\|qr\.dart" lib/` | 0 matches (D-05 verified) |
| `git diff pubspec.yaml` | empty (D-05 verified — no QR dependency) |
| `git diff example/lib/main.dart` | empty (Plan 07-04 owns demo registration) |
| `MediaQuery` references in wallet_connect_sheet.dart | 0 (breakpoint owned by ResponsiveDrawer) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Address-text test assertion disambiguated**

- **Found during:** Task 2 (GREEN iteration)
- **Issue:** Test 3 used `tester.widget<Text>(find.text(address).first)` assuming only one Text widget contains the address. But `BottomDrawer` also renders the title text (which equals the address in connected state), so `find.text(address)` matched 2 widgets and `.first` was the header copy (whose overflow is set but maxLines is 2, not 1).
- **Fix:** Changed the assertion to `tester.widgetList<Text>(...)` and asserted that *any* of the matched Text widgets has `overflow == TextOverflow.ellipsis && maxLines == 1`. This still validates the contract (the body copy uses ellipsis truncation) without coupling to BottomDrawer's header rendering.
- **Files modified:** `test/components/wallet_connect_sheet_test.dart`
- **Commit:** `1d54e71`

**2. [Rule 1 - Bug] Removed `qr_flutter` from doc comment**

- **Found during:** Task 2 (D-05 verification)
- **Issue:** The library-header docstring said "Scaffold gains NO QR dependency — qr_flutter, custom painters, etc." — the literal string `qr_flutter` matched the D-05 grep `grep -E "qr_flutter|QrImage|qr\.dart" lib/`, failing the verify step.
- **Fix:** Rephrased to "third-party QR packages, custom painters, etc." — semantic content unchanged.
- **Files modified:** `lib/components/wallet_connect_sheet.dart`
- **Commit:** `1d54e71`

**3. [Rule 3 - Blocking] Demo uses direct imports instead of barrel**

- **Found during:** Task 3
- **Issue:** Plan said "Import via the barrel `package:frontend_scaffold/frontend_scaffold.dart`" but the barrel does not yet export `WalletConnectSheet` — the sequential execution context explicitly states "Plan 07-04 owns all remaining barrel additions (media_controls, wallet_connect_sheet)". Importing the barrel would have caused a compilation error.
- **Fix:** Used direct imports (`components/wallet_connect_sheet.dart` + `theme/scaffold_theme.dart`) matching the pattern already established by `media_controls_demo.dart` (which is also awaiting its barrel export in 07-04).
- **Files modified:** `example/lib/demos/wallet_connect_sheet_demo.dart`
- **Commit:** `69164cb`

### Extra Tests (Beyond Plan Minimum)

The plan specified 9 tests; I wrote 11. The two extras:
- Test 10 ("no QR dependency") was in the plan as a code-inspection verify step; I promoted it to a `testWidgets` so it exercises the build path even though the real guard is the CI grep.
- Test 11 asserts the Disconnect CTA is wrapped in `ScaffoldPressable` — locks in the WIDG-31 atom-composition contract (Disconnect must be a true pressable with focus/hover/touch-target behavior, not a plain GestureDetector).

These are additive coverage, not scope creep — they do not add features to the widget.

## D-05 Compliance Statement

- `pubspec.yaml` byte-identical before/after this plan (`git diff pubspec.yaml` → empty)
- Zero `qr_flutter`, `QrImage`, or `qr.dart` references anywhere under `lib/`
- `qrBuilder` parameter signature: `Widget Function(BuildContext context, String uri)?` — consumer owns QR rendering choice
- Demo exercises the slot with a `Container` + `Text` placeholder (no real QR renderer needed for the demo)

## Decisions Locked In

- **Title for connected state = full address** (per "Claude's Discretion" in 07-CONTEXT.md). The address is too long for the BottomDrawer header (which uses `maxLines: 2` + ellipsis internally), so it visibly truncates in the header while the body copy uses the plan-mandated `maxLines: 1` + ellipsis.
- **Disconnect button is in the `footer` slot** of `BottomDrawer`, not in `children` — matches the plan's `footer: <Disconnect button when connected>` specification.
- **Connect CTA is in `children`** (under the QR) per WIDG-31's "Connect CTA under the QR in disconnected state".
- **No `Semantics` wrapper added beyond what `ScaffoldPressable` and `ScaffoldBadge` already provide** — both atoms self-register their a11y roles (button / status).

## Auth Gates

None — pure presentational UI with no external services.

## Threat Flags

None. The plan's threat_model explicitly states "Phase 7 is PURE PRESENTATIONAL UI" and the three trust-boundary rows (T-07-06, T-07-07, T-07-08) were all satisfied:

- T-07-06 (accept): presentational-only façade — verified
- T-07-07 (mitigate): pubspec.yaml unchanged, no qr_* import in lib/ — verified
- T-07-08 (accept): no print/log statements in any new file — verified by source inspection

## Files Created/Modified

**Created:**
- `lib/components/wallet_connect_sheet.dart` (179 lines)
- `test/components/wallet_connect_sheet_test.dart` (251 lines)
- `example/lib/demos/wallet_connect_sheet_demo.dart` (97 lines)

**Modified:** None.

**Not touched (intentionally):**
- `lib/frontend_scaffold.dart` — barrel export lands in Plan 07-04
- `example/lib/main.dart` — demo registration lands in Plan 07-04
- `pubspec.yaml` — D-05

## Self-Check: PASSED

- `lib/components/wallet_connect_sheet.dart` — FOUND
- `test/components/wallet_connect_sheet_test.dart` — FOUND
- `example/lib/demos/wallet_connect_sheet_demo.dart` — FOUND
- Commit `c8dcae9` (Task 1 RED) — FOUND
- Commit `1d54e71` (Task 2 GREEN) — FOUND
- Commit `69164cb` (Task 3 demo) — FOUND
- 11/11 tests pass; analyzer clean on all three files; D-05 verified.
