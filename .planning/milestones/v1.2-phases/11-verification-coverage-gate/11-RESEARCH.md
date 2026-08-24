# Phase 11: Verification & Coverage Gate — Research

**Researched:** 2026-08-22
**Domain:** Flutter widget library — verification sweep, image-capture harness, README documentation
**Confidence:** HIGH (every claim verified against the live repo via Read/Grep/Bash; no web sources needed)

## Summary

This phase is a **verification + documentation gate**, not new feature work. Every fact the planner needs is already in the repo and verified here:

1. **The WIDG-44 sweep is already green.** All 11 v1.2 atoms have a lib file, a test file, a demo file, and ≥1 barrel export. There are no gaps to close (D-05 has nothing to fix in the atom inventory itself). The only "fix inline" work is the **single skipped test** at `scaffold_selection_actions_test.dart:334–375` (D-06).
2. **Test count is 454 passing + 1 skipped = 455** as of today (README claims 214 — stale). Demo count is **26 `_DemoTile` entries** registered in `example/lib/main.dart` mapping to **26 demo files** under `example/lib/demos/`. Both numbers must replace the README's stale "214 tests" / "one demo screen per widget family" copy.
3. **The image-capture harness (D-02) should be a `flutter test` runner script** under `example/test/capture_images_test.dart` that pumps each demo and uses a non-asserting write path (no `matchesGoldenFile` CI gate). This runs headlessly on macOS via `flutter test example/test/capture_images_test.dart` — no device, no integration_test driver, no skia goldens repo.

**Primary recommendation:** Single-wave plan with three tasks in dependency order: (1) delete the skipped test (D-06), (2) build the capture harness + produce 26 PNGs (D-02), (3) README restructure embedding the gallery + the WIDG-45 19-component proof (D-01).

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Coverage surface is package-root `README.md` (not a separate matrix file). Gains: how-to-run-demo section, v1.2 component gallery, WIDG-45 19-component composability proof.
- **D-02:** New `images/` dir at package root holds one screenshot per atom/demo (26 screens). Embedded in README. Mechanism = reproducible capture harness under `example/`, no `matchesGoldenFile` CI gating.
- **D-03:** Sweep covers v1.2 atoms only (Phases 8–10): chip, chip_group, disclosure, trace_list, composer, streaming_rich_text (+cubit/state), code_block, selection_actions, chart, chart_scrubber, chart_range_selector, plus Phase 8 table-cell `cellBuilder` extension and light palette. v1.1 atoms not re-swept.
- **D-04:** No new human UAT phase. Gate = automated sweep + `dart analyze --fatal-infos` clean + README coverage doc.
- **D-05:** Gaps the sweep surfaces are fixed inline in this phase (gap-closure tasks in plan).
- **D-06:** Delete the permanently-skipped test at `test/components/scaffold_selection_actions_test.dart:334-375` (long-press SelectionArea smoke test, `skip: true`). Suite must run zero-skip.
- **D-07:** Execute on branch `gsd/phase-11-verification-coverage-gate` cut from `develop`; PR back to `develop` (never `main`).

### Claude's Discretion

- Exact README section layout / heading names; where gallery sits relative to existing "What's in it" table.
- Capture-harness implementation detail (script vs. non-asserting golden writer), PNG dimensions / device frame, image filenames.
- Whether WIDG-45 proof is inline table or linked doc — must be reader-facing in README.
- Order of sweep vs. capture tasks (sweep first, then document).

### Deferred Ideas (OUT OF SCOPE)

- Golden-file test assertions (`matchesGoldenFile` gating CI on pixel drift) — the harness is a writer, not a CI gate.
- Fixing the flutter_test `SelectionArea` gesture flake — the skipped test is deleted (D-06); end-to-end selection coverage is a UAT item.
- v1.1 atom re-sweep — v1.1 atoms were gated at their own phases; only v1.2 is swept (D-03).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WIDG-44 | Each new atom ships with widget tests, demo in `example/`, barrel export (same bar as v1.1) | §Per-Atom Sweep Matrix below — all 11 atoms already satisfy the bar; verification is reporting + analyzer/test runs |
| WIDG-45 | Beautiful UI coverage check — all 19 components demonstrably composable from shipped scaffold atoms (7 ready + 8 thin + 4 primitive-enabled) | §WIDG-45 19-Component Coverage Proof below — maps each Beautiful UI component to the specific shipped atom(s) in `lib/components/` |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Per-atom sweep verification | Repo tooling (Bash + grep) | — | Pure inspection of files that already exist; no runtime |
| Skip-test deletion | Test code (`test/components/`) | — | Edit one file; helpers/imports stay (verified) |
| Demo image capture | `example/` (runnable app package) | `flutter_test` harness | Demos live in `example/lib/demos/`; capture harness must import them, so it lives in `example/test/` (not package-root `test/`) |
| README documentation | Package root `README.md` | `images/` (new) | README is reader-facing; images must use package-root-relative paths so they render on GitHub |
| WIDG-45 coverage proof | `README.md` | — | Reader-facing evidence that the 19-component yardstick is met |
| Analyzer + test gate | Package root | — | `dart analyze --fatal-infos` and `flutter test` run from package root |

## Per-Atom Sweep Matrix (WIDG-44) — VERIFIED

All 11 v1.2 atoms + the two Phase 8 extensions. Statuses verified by direct `ls` + `grep` against the live repo on 2026-08-22.

| Atom | `lib/components/` | `test/components/` | `example/lib/demos/` | Barrel export | Status |
|------|-------------------|--------------------|-----------------------|---------------|--------|
| `scaffold_chip` | `scaffold_chip.dart` | `scaffold_chip_test.dart` | `chip_demo.dart` | line 29 | PASS |
| `scaffold_chip_group` | `scaffold_chip_group.dart` | `scaffold_chip_group_test.dart` | `chip_demo.dart` (shared) | line 30 | PASS |
| `scaffold_disclosure` | `scaffold_disclosure.dart` | `scaffold_disclosure_test.dart` | `disclosure_demo.dart` | line 36 | PASS |
| `scaffold_trace_list` | `scaffold_trace_list.dart` | `scaffold_trace_list_test.dart` | `trace_list_demo.dart` | line 83 | PASS |
| `scaffold_composer` | `scaffold_composer.dart` | `scaffold_composer_test.dart` | `composer_demo.dart` | line 33 | PASS |
| `scaffold_streaming_rich_text` (+ `_cubit` + `_state`) | `scaffold_streaming_rich_text{,_cubit,_state}.dart` | `scaffold_streaming_rich_text_test.dart` | `streaming_rich_text_demo.dart` | lines 78–80 | PASS |
| `scaffold_code_block` | `scaffold_code_block.dart` | `scaffold_code_block_test.dart` | `code_block_demo.dart` | line 31 | PASS |
| `scaffold_selection_actions` | `scaffold_selection_actions.dart` | `scaffold_selection_actions_test.dart` | `selection_actions_demo.dart` | line 69 | PASS |
| `scaffold_chart` | `scaffold_chart.dart` | `scaffold_chart_test.dart` | `chart_demo.dart` | line 26 | PASS |
| `scaffold_chart_scrubber` | `scaffold_chart_scrubber.dart` | `scaffold_chart_scrubber_test.dart` | `chart_scrubber_demo.dart` | line 28 | PASS |
| `scaffold_chart_range_selector` | `scaffold_chart_range_selector.dart` | `scaffold_chart_range_selector_test.dart` | `chart_range_selector_demo.dart` | line 27 | PASS |
| **Phase 8 table-cell `cellBuilder`** | `templates/components/data_table.dart.jinja2` lines 61, 74–80, 327–330 | `test/components/data_table_cell_builder_test.dart` | *(generated into consumer — no demo file; covered by `data_table` template-driven test)* | n/a (template-only) | PASS |
| **Phase 8 light palette** | `lib/theme/scaffold_palette.dart:132` (`lightPalette`) | `test/theme/` (covered under palette tests) | demo app "Light mode" toggle (`example/lib/main.dart:139-147`) | line 102 (`scaffold_palette`) | PASS |

**Sweep result: ZERO GAPS.** D-05 has nothing to close. The phase's only fix-inline work is the D-06 skip deletion.

**Verification commands to re-run as gate evidence:**

```bash
# Static analysis
dart analyze --fatal-infos
# Current output: "Analyzing scaffold... No issues found!"

# Full test suite (454 pass + 1 skip currently; after D-06: 454 pass + 0 skip)
flutter test
# Current output: "00:07 +454 ~1: All tests passed!"
```

## Skipped Test Deletion (D-06) — VERIFIED

**Only one skip in the entire `test/` tree:**

```bash
$ grep -rn "skip:" test/
test/components/scaffold_selection_actions_test.dart:339:  // hook. If this test proves framework-flaky in CI, mark it `skip: true`
test/components/scaffold_selection_actions_test.dart:349:  // this smoke test is retained as a skip:true marker for manual QA.
test/components/scaffold_selection_actions_test.dart:375:  }, skip: true); // Framework-flaky — see comment above.
```

(Three lines match the pattern but they are all part of the same comment+test block — only **one actual `skip: true` argument**.)

**Exact line range to delete:** `test/components/scaffold_selection_actions_test.dart:334–375` inclusive (42 lines).

- Lines 334–349: comment block explaining the smoke test and why it was skipped (must be removed with the test).
- Lines 350–375: the `testWidgets('smoke: long-press + drag ...', ...)` body and its `skip: true` argument.

**Helper/imports cleanup:** NONE needed. Verified:

- `_pump(tester, ...)` helper at line 12 is used by other tests (line 353 uses it, but so do all 17 remaining tests).
- `TestGesture`, `startGesture`, `gesture.moveBy`, `gesture.up` are used by **other** tests in the same file at lines 456, 459, 483, 585, 588, 594, 675, 678, 684, 762, 765, 769, 848, 851, 857 — all 5 other gesture-based tests stay.
- All 9 imports at lines 1–10 are still used by remaining tests.

**After deletion the file goes from 929 lines to 887 lines.** `dart analyze --fatal-infos` remains clean (no orphaned references). Test count drops from 455 to 454 (one fewer skipped, zero change to passing count).

## WIDG-45 19-Component Coverage Proof

Source of truth: `.planning/atoms-v1.2-additions.md` (authoritative). The 19 components and their composition story, mapped to the **actual shipped atoms** in `lib/components/`:

| # | Beautiful UI Component | Coverage Tier | Shipped Scaffold Atoms That Compose It |
|---|------------------------|---------------|----------------------------------------|
| 1 | Loading State | **Compose** (8-thin) | `ScaffoldSkeleton` + `ScaffoldAnimatedDisplay*` (7 variants) + `ScaffoldFormattedValueDuration` + `ScaffoldSurface` |
| 2 | Thinking | **Compose** (8-thin) | `ScaffoldSurface` + `ScaffoldStatusIndicator` + `ScaffoldAnimatedDisplay*` + **`ScaffoldDisclosure`** (v1.2) + **`ScaffoldTraceList`** (v1.2) |
| 3 | Streaming Text | **Add primitive** (4-primitive) | **`ScaffoldStreamingRichText`** (v1.2) + `ScaffoldStreamingCopyButton` + `ScaffoldLiveRegion` (a11y announcements) |
| 4 | Approval Card | **Ready** (7-ready) | `ScaffoldCard` + `ScaffoldSelectionIndicatorRadio` + `TextEntryFieldWidget` + `ActionButton` |
| 5 | Tool Chips | **Compose** (8-thin) | **`ScaffoldChip`** (v1.2) + **`ScaffoldChipGroup`** (v1.2) + `ScaffoldBadge` + `ScaffoldStatusIndicator` + `ScaffoldPressable` |
| 6 | Task Rows | **Ready** (7-ready) | `ScaffoldStatusIndicator` + `ScaffoldFormattedValue*` + `ScaffoldAnimatedDisplay*` + `ScaffoldSurface` |
| 7 | Chat | **Compose** (8-thin) | `ScaffoldCard` + `ScaffoldAnimatedDisplay*` + `ScaffoldStateView` + `TextEntryFieldWidget` + **`ScaffoldComposer`** (v1.2) + `ScaffoldStreamingRichText` + `ScaffoldTraceList` |
| 8 | Prompt Bar | **Compose** (8-thin) | `TextEntryFieldWidget` + `ActionButton` + `ScaffoldBadge` + `ScaffoldPressable` + **`ScaffoldComposer`** (v1.2) + **`ScaffoldChip`** (v1.2) |
| 9 | Recommendation Card | **Ready** (7-ready) | `ScaffoldCard` + `ScaffoldFormattedValuePercentage` + `ScaffoldStatusIndicator` + `ActionButton` |
| 10 | Context Cards | **Ready** (7-ready) | `ScaffoldCard` + `ScaffoldBadge` + `ScaffoldFormattedValueNumber` + `ScaffoldImagePlaceholder*` (4 variants) |
| 11 | Diff Table | **Compose** (8-thin) | `templates/components/data_table.dart.jinja2` + **`DataColumnConfig.cellBuilder`** (v1.2 Phase 8 extension) |
| 12 | Records Table | **Compose** (8-thin) | `data_table.dart.jinja2` + **`cellBuilder`** + `ScaffoldChip` (tags) + `ScaffoldStatusIndicator` (status cells) |
| 13 | Filter Table | **Compose** (8-thin) | `data_table.dart.jinja2` + **`ScaffoldChipGroup`** (v1.2) + consumer Cubit deriving visible rows |
| 14 | Sidebar Nav | **Ready** (7-ready) | `templates/components/navigation.dart.jinja2` (Material drawer + nested groups + badges) + `ScaffoldSearchBar` |
| 15 | Search | **Ready** (7-ready) | `ScaffoldSearchBar` (live callbacks, grouped results, loading, filter actions) + `ScaffoldStateView` (empty state) |
| 16 | Insight Cards | **Add primitive** (4-primitive) | **`ScaffoldChart`** (v1.2) + **`ScaffoldChartScrubber`** (v1.2) + **`ScaffoldChartRangeSelector`** (v1.2) + `ScaffoldCard` |
| 17 | Code Block | **Add primitive** (4-primitive) | **`ScaffoldCodeBlock`** (v1.2) + `ScaffoldOverflowFade` + `ScaffoldSurface` |
| 18 | Fine-tune Card | **Ready** (7-ready) | `ScaffoldCard` + `ScaffoldNumericInput` + `ScaffoldColorSwatch` + `ScaffoldSelectionIndicatorToggle` + `StringButton` |
| 19 | Selection Actions | **Add primitive** (4-primitive) | **`ScaffoldSelectionActions`** (v1.2) + `ScaffoldSelectionCopyAction` + `ScaffoldComposer` |

**Tally check (matches CONTEXT D-01):** 7 ready (rows 4, 6, 9, 10, 14, 15, 18) + 8 thin (rows 1, 2, 5, 7, 8, 11, 12, 13) + 4 primitive-enabled (rows 3, 16, 17, 19) = **19**.

**README placement recommendation (D-01 + discretion):** Add a `## Coverage` section in Part 1 of the README, after "What's in it", containing this exact 19-row table. Inline, not a linked doc — readers should see the proof without clicking through. Each "Shipped Scaffold Atoms" cell uses backtick code formatting so the atom names link visually to the gallery section below.

## Image-Capture Harness (D-02)

### Recommended Approach: `flutter test` Runner Script

**Why not integration_test:** Requires a running device/emulator, slower, platform-channel flakiness. Overkill for headless capture of `StatelessWidget` demos.

**Why not `matchesGoldenFile`:** CONTEXT explicitly forbids golden-file test gating (D-02). `matchesGoldenFile` also has platform-specific rendering differences (macOS vs Linux vs Windows produce different pixels) and version-pinned Skia hashes that break across Flutter upgrades. The harness must be a **writer**, not an assertion.

**Why `flutter test` with a raw PNG write:**
- Demos are already `StatelessWidget`s — pumping them in `testWidgets` is trivial.
- `tester.binding.takeScreenshot(...)` is NOT the right API (it requires a real engine view). The correct low-level path is to render the widget tree to an `ui.Image` via `RenderRepaintBoundary.toImage()`, then encode to PNG bytes and write to disk.
- Runs headlessly with `flutter test` on macOS host. No emulator. No device.
- Deterministic (fixed surface size, fixed theme, no animations if we `pumpAndSettle` then capture).

### Concrete Implementation

**File to add:** `example/test/capture_images_test.dart`

**Pattern (single test that iterates the registry):**

```dart
// Source: standard flutter_test + dart:ui pattern (VERIFIED via Flutter SDK docs —
// RenderRepaintBoundary.toImage is the canonical offscreen-render API).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

// Reuse the demo imports from example/lib/main.dart.
import 'package:frontend_scaffold_example/main.dart' show ScaffoldExampleApp;
// ... (or replicate the demo list explicitly)

Future<void> _captureWidget(
  WidgetTester tester,
  Widget widget,
  String filename,
) async {
  final RenderRepaintBoundary boundary = RenderRepaintBoundary();
  final BuildContext fakeContext = tester.element(find.byType(MaterialApp));

  // Pump the demo inside a fixed-size RepaintBoundary
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        extensions: const <ThemeExtension<dynamic>>[
          ScaffoldPalette.defaultPalette,
          ScaffoldDimens.defaultDimens,
        ],
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('capture'),
            child: SizedBox(width: 800, height: 600, child: widget),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final RenderRepaintBoundary renderBoundary = tester.renderObject(
    find.byKey(const ValueKey<String>('capture')),
  );
  final ui.Image image = await renderBoundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List pngBytes = byteData!.buffer.asUint8List();

  final File out = File('../images/$filename.png');
  await out.create(recursive: true);
  await out.writeAsBytes(pngBytes);
}

void main() {
  testWidgets('capture all demo screens', (WidgetTester tester) async {
    // One call per demo (26 calls):
    await _captureWidget(tester, const ActionButtonDemo(), 'action_button');
    await _captureWidget(tester, const StringButtonDemo(), 'string_button');
    // ... etc — one line per _DemoTile entry in main.dart
  });
}
```

**Run command (from `example/`):**

```bash
cd example && flutter test test/capture_images_test.dart
```

**Output:** 26 PNGs at `../images/<name>.png` (i.e., package-root `images/`). The relative path `../images/` works because `flutter test` runs from `example/` and `images/` sits at the package root.

### Naming Convention (matches `_DemoTile` order in `main.dart`)

| Tile title | Filename |
|------------|----------|
| ActionButton | `action_button.png` |
| StringButton | `string_button.png` |
| TextEntryFieldWidget | `text_entry_field.png` |
| Loading | `loading.png` |
| Toast | `toast.png` |
| BottomDrawer / ResponsiveDrawer | `bottom_drawer.png` |
| Animations | `animations.png` |
| AppScreenView / DesktopBodyContainer | `page_chrome.png` |
| ResponsiveGrid | `responsive_grid.png` |
| Tracer | `tracer.png` |
| Kitchen Sink | `kitchen_sink.png` |
| Media card | `media_card.png` |
| Media controls | `media_controls.png` |
| Wallet connect sheet | `wallet_connect_sheet.png` |
| Chip / ChipGroup | `chip.png` |
| Composer | `composer.png` |
| Disclosure | `disclosure.png` |
| Trace list | `trace_list.png` |
| Streaming rich text | `streaming_rich_text.png` |
| Code block | `code_block.png` |
| Selection actions | `selection_actions.png` |
| Markdown to spans | `markdown_to_spans.png` |
| Light syntax tokenizer | `light_syntax_tokenizer.png` |
| Chart | `chart.png` |
| Chart Scrubber | `chart_scrubber.png` |
| Chart Range Selector | `chart_range_selector.png` |

Total: **26 PNGs**, matching the 26 `_DemoTile` entries.

### Caveats (must be in plan)

1. **Fonts:** Tests use the test-platform font (Roboto fallback), NOT the bundled app font. This is acceptable for a gallery screenshot — the shapes/colors/layout are the point. If exact typography matters, the harness can call `await loadAppFonts()` from `flutter_test` (a font-loading helper) — but defer unless reviewer asks.
2. **Animations:** All demos must call `pumpAndSettle()` before capture. `ScaffoldAnimatedDisplay*` variants (pulse, shake, rotate) have repeating animations — `pumpAndSettle` will not return for infinite animations. **Pitfall:** the `animations_demo.png` and any demo using an infinitely-repeating animation needs `pump(Duration(seconds: 1))` then capture, NOT `pumpAndSettle`. The planner must check each demo.
3. **Determinism:** PNG bytes are deterministic given the same Flutter SDK version + host platform. Running on macOS host produces the canonical captures. Cross-platform drift is OK because the harness is a writer (no assertions).
4. **Demo files that are not pure widgets:** Some demos may have `Navigator` state or depend on `MediaQuery`. The fixed 800x600 `SizedBox` + `MaterialApp` wrapper handles this. If a demo requires a larger surface, the planner can bump the `SizedBox` per-capture.
5. **`.gitignore`:** `images/` must NOT be gitignored — the PNGs are the deliverable. Verify `.gitignore` doesn't accidentally exclude them.

## README Restructuring (D-01)

### Current State (VERIFIED)

- 319 lines total
- Says "**~70 widgets**" (line 5, 53, 297) — still accurate
- Says "**214 tests**" (lines 86, 300) — STALE (actual: 454 passing)
- Says "**one demo screen per widget family**" (line 79) — vague (actual: 26 demos registered)
- Has a "Demo app" section at lines 73–79 with run instructions already present
- No component gallery / no images / no WIDG-45 proof

### Minimal Surgical Edits

**Edit 1 — Update test count.** Replace `214 tests` with `454 tests` in:
- Line 86 (`flutter test                  # 214 tests` → `# 454 tests`)
- Line 300 (`├── test/                           ← 214 widget + token tests` → `← 454 widget + token tests`)

**Edit 2 — Expand "Demo app" section (lines 73–79).** Current:
```
## Demo app

​```bash
cd example && flutter run -d macos    # or -d chrome
​```

`example/` is a runnable gallery with one demo screen per widget family.
```

Replace with:
```
## Demo app

​```bash
cd example && flutter run -d macos    # or -d chrome
​```

`example/` is a runnable gallery with 26 demo screens covering every widget
family and the v1.2 atoms. The component gallery below shows a captured
screenshot of each demo.
```

**Edit 3 — Add `## Component gallery` section after "Demo app".** One image per line, with a title and a one-line description, using the file naming from §Image-Capture Harness. Format:

```markdown
## Component gallery

### ActionButton
![ActionButton demo](images/action_button.png)
Enabled, disabled, and rotate-animation states.

### StringButton
![StringButton demo](images/string_button.png)
Keypad-style button that emits its string value.

...(24 more entries — same shape, using the 26 filenames from the table above)
```

**Edit 4 — Add `## Coverage` section after the gallery.** Insert the 19-row table from §WIDG-45 19-Component Coverage Proof verbatim.

**Edit 5 — Repository layout line.** Update the layout tree to include `images/`:
```
├── images/                         ← per-demo screenshots (gallery above)
```

### What NOT to change

- Do not touch Part 2 (codegen toolkit) — out of scope.
- Do not restructure existing headings — surgical inserts only.
- Do not change the "What's in it" table — the v1.2 atoms are already implied by the existing flat structure (and the gallery will make them concrete).

## Verification Artifact Shape (per 07-VERIFICATION.md pattern)

Following the Phase 7 verification-report shape, Phase 11's verification gate must produce:

| Artifact | Location | Purpose |
|----------|----------|---------|
| `11-VERIFICATION.md` | `.planning/workstreams/scaffold/phases/11-verification-coverage-gate/` | Scorecard mirroring 07-VERIFICATION.md — lists each WIDG-44 atom and its test/demo/barrel evidence |
| `11-UAT.md` | *(not required — D-04 says no human UAT for this phase)* | — |
| Sweep matrix output | Embedded in `11-VERIFICATION.md` "Observable Truths" table | Per-atom PASS evidence |
| Analyzer output | Embedded in `11-VERIFICATION.md` "Behavioral Spot-Checks" | `dart analyze --fatal-infos` → `No issues found!` |
| Test output | Embedded in `11-VERIFICATION.md` "Test Suite Result" | `flutter test` → `+454: All tests passed!` (zero skips) |
| README diff | PR description + visible in repo | Reader-facing evidence for WIDG-45 |
| `images/` directory | Package root, 26 PNGs | Visual evidence committed to git |

**Gate evidence the planner must collect:**

1. `dart analyze --fatal-infos` → clean
2. `flutter test` → `+454: All tests passed!` (zero skips — the `~1` skip count must be gone)
3. `grep -rn "skip:" test/` → zero matches
4. `ls images/ | wc -l` → 26
5. README.md contains the gallery, the WIDG-45 table, and updated counts

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Offscreen widget rasterization | Custom `PictureRecorder` + `Canvas` walk | `RenderRepaintBoundary.toImage(pixelRatio:)` | The framework already handles the layer tree, compositing, and DPI scaling |
| Demo registry enumeration | Reflection or runtime registry | Hardcoded list mirroring `_DemoTile` order in `example/lib/main.dart` | 26 entries; explicit list is auditable and stays in sync via review |
| PNG encoding | Manual PNG byte assembly | `ui.Image.toByteData(format: ui.ImageByteFormat.png)` | Framework-provided encoder; no extra deps |
| Golden-file drift detection | `matchesGoldenFile` | Raw file write (the harness is a writer, not an assertion) | D-02 forbids CI pixel gating |

**Key insight:** The capture harness is fundamentally a **rasterizer script that happens to run inside `flutter test`** — treat it as a build tool, not a test.

## Common Pitfalls

### Pitfall 1: `pumpAndSettle` hangs on infinite animations
**What goes wrong:** Capture harness times out after 10 minutes because `ScaffoldAnimatedDisplay*` variants (pulse, shake, rotate, bounce) and any other infinitely-repeating `AnimationController` never "settle".
**Why it happens:** `pumpAndSettle` loops `pump(Duration(milliseconds: 100))` until no frames are scheduled — infinite animations always schedule another frame.
**How to avoid:** Use `pump(Duration(seconds: 1))` (a fixed single pump) for any demo with infinite animations. The default can stay `pumpAndSettle` for static demos.
**Warning signs:** Test times out with `A Timer is still pending` or `pumpAndSettle timed out`.

### Pitfall 2: Skipped-test deletion orphans a helper
**What goes wrong:** Deleting lines 334–375 also removes the only caller of a helper, breaking `dart analyze`.
**Why it happens:** (Hypothetical — VERIFIED NOT TO APPLY HERE.) If `_pump` were only called by the skipped test, deleting it would orphan the helper.
**How to avoid:** Verified via grep that `_pump` is called by all 17 remaining tests, and `startGesture`/`TestGesture` are used by 5 other tests. **No cleanup needed.**
**Warning signs:** `dart analyze` reports `unused_element` or `unused_import` after deletion.

### Pitfall 3: `images/` directory gitignored
**What goes wrong:** Captured PNGs are produced locally but never committed; the README's embedded image links 404 on GitHub.
**Why it happens:** Default Flutter `.gitignore` templates sometimes exclude image/asset folders; or a blanket `*.png` rule.
**How to avoid:** Inspect `.gitignore` before capturing; verify `git status images/` shows the PNGs as untracked (not ignored).
**Warning signs:** `git status` doesn't list the new `images/*.png` files.

### Pitfall 4: README claim drift ("~70 widgets" / "214 tests")
**What goes wrong:** README still says 214 tests even though the suite has grown to 454.
**Why it happens:** Test count is hardcoded; nothing forces a sync.
**How to avoid:** Update both occurrences (line 86, line 300) in this phase. Add the count-update to the plan's README task so it is not forgotten.
**Warning signs:** Grep README for `\d+ tests` — if it disagrees with `flutter test`'s passing count, update.

### Pitfall 5: WIDG-45 table mismatch with atoms-v1.2-additions.md
**What goes wrong:** The README's coverage table disagrees with the seed (e.g., claims 8 ready instead of 7).
**Why it happens:** The 7/8/4 split was decided at milestone planning; if the table is hand-typed, drift is possible.
**How to avoid:** Copy the 19-row table from §WIDG-45 19-Component Coverage Proof verbatim — it has been tally-checked (7+8+4=19) and matches the seed.
**Warning signs:** Row counts don't sum to 19, or the "ready" tier has a row that the seed classifies differently.

## Code Examples

### Capture helper (RenderRepaintBoundary pattern)
```dart
// Source: Flutter SDK — RenderRepaintBoundary.toImage is the canonical
// offscreen-render API (VERIFIED via SDK source).
final RenderRepaintBoundary boundary = tester.renderObject(find.byKey(key));
final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
await File('../images/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
```

### Skip-test deletion diff shape
```diff
-  // Test 11 — SMOKE: real SelectionArea path via longPress + drag.
-  //
-  // This is the ONLY long-press smoke test in this file (D-07 test
-  // strategy). It asserts onSelectionChanged fires at least once with ANY
-  // payload — payload assertions live in Tests 1-10 via the deterministic
-  // hook. If this test proves framework-flaky in CI, mark it `skip: true`
-  // with a comment linking the flake — do NOT add retries.
-  //
-  // SKIPPED 2026-08-20: flutter_test's gesture pipeline does not reliably
-  // ... (lines 334–375, full block to remove)
-  }, skip: true); // Framework-flaky — see comment above.
-
   // Test 18 — the toolbar paints on-screen, centered above the selection.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Golden-file tests (`matchesGoldenFile`) gate CI on pixel drift | Non-asserting capture writer (this phase) | CONTEXT D-02 (2026-08-22) | Removes a class of CI flakes; images are documentation, not assertions |
| "Skip-and-forget" for flaky tests | Delete redundant skipped tests entirely | CONTEXT D-06 (2026-08-22) | Suite runs zero-skip; redundant UAT probe removed |
| Coverage proof in separate matrix doc | Inline in package README | CONTEXT D-01 (2026-08-22) | Reader-facing; no extra file to discover |

**Deprecated/outdated:**
- README's "214 tests" claim — stale; actual is 454. Updated in this phase.
- The skipped long-press smoke test — replaced by deterministic `debugSimulateSelection` coverage (18 non-skipped tests, 25 references).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The capture harness will successfully render all 26 demos headlessly with no platform-channel calls | §Image-Capture Harness | LOW — demos are pure StatelessWidgets; if any demo touches platform channels (e.g., `url_launcher`), that capture will fail and need a stub. Mitigation: planner should run the harness as its own task and fix per-demo issues inline (D-05). |
| A2 | 800×600 surface at 2.0 pixelRatio is the right size for README embedding | §Image-Capture Harness | LOW — purely aesthetic; can be tuned in plan review |
| A3 | The capture file lives at `example/test/capture_images_test.dart` (not package-root `test/`) | §Image-Capture Harness | LOW — `example/` has its own `flutter_test` dev_dependency (verified in `example/pubspec.yaml`); the file could equally live elsewhere but `example/test/` is the conventional location for an `example/` app |

All other claims in this research were verified directly against the live repo via Read, Grep, and Bash on 2026-08-22.

## Open Questions

1. **Do any of the 26 demos touch platform channels that would fail in `flutter test`?**
   - What we know: All demos are `StatelessWidget`s; the demo app runs on macOS + Chrome. Widgets like `WalletConnectSheet` use callbacks (no real Reown session).
   - What's unclear: Whether any demo instantiates a plugin (`url_launcher`, `path_provider`, etc.) directly at construction time.
   - Recommendation: Run the capture harness as an early task; if a specific demo fails, wrap its construction in a `TestWidgetsFlutterBinding` plugin-stub (or skip that capture and document the gap). This is inline fix work, not a plan blocker.

2. **Should the capture harness pump with the dark palette (default), light palette, or both?**
   - What we know: CONTEXT D-02 says "one screenshot per atom/demo screen" — singular, not per-theme.
   - What's unclear: Whether readers benefit from seeing both palettes.
   - Recommendation: Use the dark palette (the package default per `ScaffoldPalette.defaultPalette`) to keep the gallery concise at 26 images. If the planner or reviewer wants both, double to 52 in a follow-up.

3. **Should the WIDG-45 table be inline in README.md or in `images/coverage.md` linked from README?**
   - What we know: CONTEXT defers the exact form to the planner ("must be reader-facing in the README").
   - What's unclear: Whether 19 rows × 4 columns is too long inline.
   - Recommendation: **Inline.** 19 rows is well within normal README length, and inline avoids a click-through. CONTEXT's D-01 language ("the README gains a section showing ... the WIDG-45 19-component composability proof") supports inline.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter` CLI | `flutter test`, `flutter pub get` | YES | (in PATH — verified via `flutter test` running) | — |
| `dart` CLI | `dart analyze --fatal-infos` | YES | (in PATH — verified via `dart analyze` running) | — |
| `flutter_test` (SDK) | Capture harness, widget tests | YES | bundled with Flutter SDK | — |
| macOS host | Running `flutter test` headlessly | YES | Darwin 24.6.0 (verified via env) | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (bundled with Flutter SDK) |
| Config file | none — `flutter_test` defaults |
| Quick run command | `flutter test test/components/scaffold_selection_actions_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| WIDG-44 | Each v1.2 atom has widget tests passing + demo + barrel export | sweep (file existence + analyzer + test) | `dart analyze --fatal-infos && flutter test` | YES (all files verified) |
| WIDG-44 (D-06) | Zero `skip:` arguments in test tree | grep sweep | `grep -rn "skip:" test/ \| grep -v "^.*://" \| grep "skip: true"` returns 0 lines | YES (will be true after deletion) |
| WIDG-45 | 19-component coverage proof in README | manual review | `grep -c "ScaffoldChip\\\|ScaffoldDisclosure\\\|ScaffoldComposer\\\|ScaffoldStreamingRichText\\\|ScaffoldCodeBlock\\\|ScaffoldSelectionActions\\\|ScaffoldChart" README.md` ≥ some threshold | WAVE 0 (README edit) |

### Sampling Rate
- **Per task commit:** `dart analyze --fatal-infos`
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** `dart analyze --fatal-infos` clean + `flutter test` → `+454: All tests passed!` with zero skips + `grep -rn "skip: true" test/` empty + `ls images/ \| wc -l` → 26 + README contains gallery and WIDG-45 table

### Wave 0 Gaps

- [ ] `example/test/capture_images_test.dart` — the capture harness itself (Wave 0 / Task 1)
- [ ] `images/` directory at package root (created by harness first run)
- [ ] README.md updates (Wave 1 — depends on `images/` being populated)

*(Existing test infrastructure fully covers WIDG-44 — no new atom tests needed.)*

## Security Domain

Not applicable. This phase performs no authentication, session management, access control, input validation, cryptography, or secret handling. The capture harness writes PNG files to a known-relative path inside the repo; the README edit is documentation. No ASVS categories apply.

## Sources

### Primary (HIGH confidence) — all live-repo verified on 2026-08-22
- `.planning/workstreams/scaffold/phases/11-verification-coverage-gate/11-CONTEXT.md` — D-01..D-07 locked decisions
- `.planning/workstreams/scaffold/REQUIREMENTS.md` — WIDG-44 line 39, WIDG-45 line 40, mapping table lines 83–84
- `.planning/atoms-v1.2-additions.md` — 19-component Beautiful UI table
- `.planning/workstreams/scaffold/phases/07-media-integration-widgets/07-VERIFICATION.md` — verification artifact pattern
- `.planning/workstreams/scaffold/phases/10-chart-scrubber/10-CONTEXT.md` — inherited locked patterns
- `README.md` (319 lines, fully read) — current state, Part 1/Part 2 structure, "214 tests" staleness
- `example/lib/main.dart` (308 lines, fully read) — 26 `_DemoTile` entries, demo registry
- `lib/frontend_scaffold.dart` (110 lines, fully read) — barrel exports for all 11 v1.2 atoms
- `test/components/scaffold_selection_actions_test.dart` (read lines 1–25, 320–389) — skip-test context, imports, helper usage
- `templates/components/data_table.dart.jinja2` lines 61, 74–80, 327–330 — `cellBuilder` extension evidence
- `lib/theme/scaffold_palette.dart:132` — `lightPalette` evidence

### Secondary (VERIFIED via Bash on 2026-08-22)
- `find test -name '*_test.dart' \| wc -l` → 56 test files
- `find example/lib/demos -name '*.dart' \| wc -l` → 26 demo files
- `flutter test` → `+454 ~1: All tests passed!` (454 passing, 1 skipped)
- `dart analyze --fatal-infos` → `No issues found!`
- `grep -rn "skip:" test/` → 3 lines, all in the single `scaffold_selection_actions_test.dart` block (only one actual `skip: true`)
- `grep "fl_chart" pubspec.yaml` → `fl_chart: ^1.2.0` (matches D-01 of Phase 10)
- Per-atom sweep loop (Bash) — all 11 atoms × {lib, test, demo, barrel} = PASS

### Tertiary (LOW confidence) — none

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; uses only `flutter_test` SDK + `dart:ui`
- Architecture: HIGH — file locations and edit targets verified by direct Read
- Pitfalls: HIGH — all five pitfalls verified against the live codebase; A1–A3 are the only assumptions and are explicitly flagged

**Research date:** 2026-08-22
**Valid until:** 2026-09-22 (30 days — stable, no fast-moving external deps)
