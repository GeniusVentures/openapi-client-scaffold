---
phase: 07-media-integration-widgets
fixed_at: 2026-08-17T01:28:00Z
review_path: .planning/workstreams/scaffold/phases/07-media-integration-widgets/07-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 8
skipped: 1
status: partial
---

# Phase 7: Code Review Fix Report

**Fixed at:** 2026-08-17T01:28:00Z
**Source review:** .planning/workstreams/scaffold/phases/07-media-integration-widgets/07-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 9
- Fixed: 8
- Skipped: 1

## Fixed Issues

### WR-01/WR-02: `_measureTimeLabelWidth` text scale + 10h under-reservation

**Files modified:** `lib/components/media_controls.dart`
**Commit:** 97f75fd
**Applied fix:** Combined both warnings (per orchestrator guidance — both touch the same helper). Changed signature to `_measureTimeLabelWidth(BuildContext, Duration, TextStyle)` so the helper can resolve the ambient text scaler, then:
- WR-01: pass `textScaler: MediaQuery.textScalerOf(context)` to the `TextPainter` so the measured reservation matches what `ScaffoldFormattedValueDuration`'s `Text` will actually paint under accessibility text scaling.
- WR-02: derive the widest-label seed from `duration.abs().inHours` (`'0:00'` for `<1h`, `'0:00:00'` for `1..9h`, `'00:00:00'` for `>=10h`) so 10+ hour durations reserve for the unpadded two-digit hour the formatter emits.
- Doc comment updated to reflect the new magnitude contract (previously claimed to track text scale; now actually does).

### WR-03: Jinja2 template drifted from generated `media_card.dart`

**Files modified:** `templates/components/media_card.dart.jinja2`
**Commit:** ed8859b
**Applied fix:** Re-synced the template TO the generated file (generated file is authoritative — it carries the UAT `semanticLabel` a11y fix). Preserved all `{% %}`/`{{ }}` control structure and the source-schema header; only the variable slots and doc text were aligned:
- Added `this.semanticLabel` constructor parameter (Jinja slot unchanged).
- Added `final String? semanticLabel;` field with the WCAG 4.1.2 doc comment.
- Forwarded `semanticLabel: semanticLabel` to the `ScaffoldPressable` call.
- Aligned class-level doc text (the "interaction is blocked — either via … or via …" wording) and the `metadataRow` doc comment (the "do NOT wrap children in [Flexible] or [Expanded] yourself" warning) with the generated file.
- Updated the file-level doc header (added "typed badge slots" wording) to match the generated file.

### IN-01: Dead `address` parameter on `WalletConnectSheet._titleFor`

**Files modified:** `lib/components/wallet_connect_sheet.dart`
**Commit:** 5f20007
**Applied fix:** Removed the unused `String? address` parameter from `_titleFor` and removed the corresponding argument at the call site (`_titleFor(sessionState, address)` → `_titleFor(sessionState)`). The connected branch's comment ("Address is shown in the body …") is retained as it still explains why the title is static.

### IN-02: Stale "how to wire into main.dart" comments in demos

**Files modified:** `example/lib/demos/media_card_demo.dart`, `example/lib/demos/media_controls_demo.dart`, `example/lib/demos/wallet_connect_sheet_demo.dart`
**Commit:** 5766398
**Applied fix:** Deleted the `_DemoTile`/`import` wiring instructions from all three demo header comments. All three demos are already registered in `example/lib/main.dart` (lines 192-206) — the comments were misleading. Also removed the now-stale "(Registration is owned by Plan 07-04 — do NOT modify main.dart here.)" parenthetical from `media_controls_demo.dart`.

### IN-05: Demo docstring referenced `TextOverflow.ellipsis` for the address

**Files modified:** `example/lib/demos/wallet_connect_sheet_demo.dart`
**Commit:** 3306daf
**Applied fix:** Updated the connected-state line in the demo header from "wallet address (truncated via TextOverflow.ellipsis)" to "wallet address (truncated in the middle — head…tail)" to match the `_truncateMiddle` implementation in `wallet_connect_sheet.dart`.

### IN-03: Magic numbers in demo layout code

**Files modified:** `example/lib/demos/media_card_demo.dart`, `example/lib/demos/media_controls_demo.dart`
**Commit:** a784252
**Applied fix:** Hoisted bare literals to file-level named constants:
- `media_card_demo.dart`: `const double _kDemoCardWidth = 180;` replaces the two `width: 180` literals (9:16 and 1:1 sections).
- `media_controls_demo.dart`: `const double _kDemoStageHeight = 120;` replaces the three `height: 120` literals (scenarios 1/2/3 stage containers).
Each constant carries a doc comment explaining what the value represents.

### IN-04: Magic numbers in `MainFlutterWindow.swift` min-size clamp

**Files modified:** `example/macos/Runner/MainFlutterWindow.swift`
**Commit:** 369cb9d
**Applied fix:** Introduced `private let kMinContentWidth: CGFloat = 420` and `private let kMinContentHeight: CGFloat = 480` at file scope and replaced the `NSSize(width: 420, height: 480)` literals. Moved the derivation comment from the call site up to the constants so the rationale is co-located with the named values.

## Skipped Issues

### IN-06: `scaffold_slider_test.dart` "buffered layer paints inside the track shape" asserts nothing about painting

**File:** `test/components/scaffold_slider_test.dart:47-57`
**Reason:** No golden-test infrastructure exists in this repo (no `goldens/` directories, no `flutter_test_config.dart`, no prior `matchesGoldenFile` usage anywhere in `test/components/`). Introducing the golden-test pattern in a fix pass would mean (a) adding new test infra, (b) generating platform-specific golden PNGs that are brittle across macOS/Linux/Windows host configurations and Flutter versions, and (c) making CI depend on bit-exact rendering for a single test. The alternative — capturing the canvas via a recording `PaintingContext` and asserting `drawRRect` calls — requires reaching into `_BufferedTrackShape`, which is private. Making it `@visibleForTesting` public solely for this test is API-surface scope creep beyond the review's intent. Per the orchestrator's guidance ("If a golden/canvas-capture proves too brittle to write reliably, mark it skipped with a clear reason rather than committing a broken test"), this finding is skipped. The drag-regression test at lines 59-85 still provides indirect coverage (the buffered boundary at 0.5 is crossed during the drag).
**Original issue:** The test only asserts `theme.trackShape, isNotNull` — identical to the two tests above it. The buffered value 0.8 is never observed, and the in-track alignment claim in the test name is unverified. The in-track buffered painting is the phase's headline UAT fix and has no direct rendering assertion.

---

_Fixed: 2026-08-17T01:28:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
