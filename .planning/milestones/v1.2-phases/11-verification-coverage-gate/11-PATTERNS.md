# Phase 11: Verification & Coverage Gate - Pattern Map

**Mapped:** 2026-08-22
**Files analyzed:** 5 (1 NEW capture harness, 1 NEW images dir, 3 MODIFIED docs/tests)
**Analogs found:** 4 / 5 (capture harness has no exact analog — closest is the `_pump` helper used across all widget tests)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `example/test/capture_images_test.dart` (NEW) | test harness (rasterizer script) | batch (write 26 PNGs) | `test/components/scaffold_chip_test.dart` (`_pump` helper) + `test/components/scaffold_selection_actions_test.dart` (`_pump`/`_pumpLight`) | role-match (no existing `RepaintBoundary.toImage` usage anywhere) |
| `images/` (NEW dir, 26 PNGs) | asset output | file-I/O (write-only) | none — first image artifact in the package | no-analog (output of the harness, not source code) |
| `README.md` (MODIFIED) | docs | n/a | self — extend Part 1 with new sections | self (surgical edits to existing structure) |
| `test/components/scaffold_selection_actions_test.dart` (MODIFIED) | test | request-response (widget test) | self — delete lines 334–375, keep everything else | self (pure deletion, no pattern to copy) |
| `lib/frontend_scaffold.dart` (VERIFY only) | barrel export | n/a | self — no change expected | self (sweep confirms; no edit) |

## Pattern Assignments

### `example/test/capture_images_test.dart` (NEW — test harness, batch file-writer)

**Analogs:** `test/components/scaffold_chip_test.dart` and `test/components/scaffold_selection_actions_test.dart` (identical `_pump` shape). The capture harness is a *rasterizer script inside `flutter test`* — it inherits the `_pump` MaterialApp + theme-extension wrapper pattern verbatim, then adds a `RepaintBoundary` + `toImage()` + `File.writeAsBytes()` layer on top.

**Imports pattern** (from `test/components/scaffold_chip_test.dart:1-9`, extended for rasterization):

```dart
import 'dart:io';                            // NEW — File.writeAsBytes
import 'dart:ui' as ui;                      // NEW — ui.Image / ImageByteFormat.png

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';     // NEW — RenderRepaintBoundary
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

// Demo imports — replicate the same 26 imports from example/lib/main.dart
import 'package:frontend_scaffold_example/demos/chip_demo.dart';
import 'package:frontend_scaffold_example/demos/composer_demo.dart';
// ... (24 more, in the same order as main.dart's import block)
```

**`_pump` / theme-extension pattern** (copy verbatim from `test/components/scaffold_chip_test.dart:11-18`):

```dart
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
```

The capture harness MUST use `scaffoldThemeExtensions` (not a hand-rolled `[ScaffoldPalette.defaultPalette, ScaffoldDimens.defaultDimens]` list) so the captured pixels match what the existing widget tests assert against. `scaffoldThemeExtensions` is defined at `lib/theme/scaffold_theme.dart:21` and re-exported via the barrel.

**Capture primitive (new — no analog; the canonical Flutter SDK pattern):**

```dart
Future<void> _captureWidget(
  WidgetTester tester,
  Widget widget,
  String filename,
) async {
  await _pump(
    tester,
    SizedBox(
      width: 800,
      height: 600,
      child: RepaintBoundary(
        key: const ValueKey<String>('capture'),
        child: widget,
      ),
    ),
  );
  await tester.pumpAndSettle();   // See Pitfall: swap to pump(Duration(seconds:1)) for animated demos

  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byKey(const ValueKey<String>('capture')),
  );
  final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
  final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File('../images/$filename.png')
      .create(recursive: true)
      .then((f) => f.writeAsBytes(bytes!.buffer.asUint8List()));
}
```

Notes:
- `800x600` matches the default `flutter_test` surface, so demos that assume the test viewport (e.g. the deleted long-press smoke test) render in the same frame they were tuned for.
- `pixelRatio: 2.0` gives 1600x1200 PNGs — crisp for README embedding on HiDPI displays.
- `../images/` resolves to package-root `images/` because `flutter test` runs from `example/`.

**Iteration pattern (single testWidgets that walks the registry):**

```dart
void main() {
  testWidgets('capture all demo screens', (WidgetTester tester) async {
    // Order mirrors example/lib/main.dart _DemoTile entries (26 total).
    await _captureWidget(tester, const ActionButtonDemo(),       'action_button');
    await _captureWidget(tester, const StringButtonDemo(),       'string_button');
    await _captureWidget(tester, const TextEntryFieldDemo(),     'text_entry_field');
    await _captureWidget(tester, const LoadingDemo(),            'loading');
    await _captureWidget(tester, const ToastDemo(),              'toast');
    await _captureWidget(tester, const BottomDrawerDemo(),       'bottom_drawer');
    await _captureWidget(tester, const AnimationsDemo(),         'animations');        // ← pump(1s), not pumpAndSettle
    await _captureWidget(tester, const PageChromeDemo(),         'page_chrome');
    await _captureWidget(tester, const ResponsiveGridDemo(),     'responsive_grid');
    await _captureWidget(tester, const TracerDemo(),             'tracer');
    await _captureWidget(tester, const KitchenSinkDemo(),        'kitchen_sink');      // ← contains ScaffoldAnimatedDisplay* — check for infinite animations
    await _captureWidget(tester, const MediaCardDemo(),          'media_card');
    await _captureWidget(tester, const MediaControlsDemo(),      'media_controls');
    await _captureWidget(tester, const WalletConnectSheetDemo(), 'wallet_connect_sheet');
    await _captureWidget(tester, const ScaffoldChipDemo(),              'chip');
    await _captureWidget(tester, const ScaffoldComposerDemo(),          'composer');
    await _captureWidget(tester, const ScaffoldDisclosureDemo(),        'disclosure');
    await _captureWidget(tester, const ScaffoldTraceListDemo(),         'trace_list');
    await _captureWidget(tester, const ScaffoldStreamingRichTextDemo(), 'streaming_rich_text');
    await _captureWidget(tester, const ScaffoldCodeBlockDemo(),         'code_block');
    await _captureWidget(tester, const ScaffoldSelectionActionsDemo(),  'selection_actions');
    await _captureWidget(tester, const ScaffoldMarkdownToSpansDemo(),   'markdown_to_spans');
    await _captureWidget(tester, const ScaffoldLightSyntaxTokenizerDemo(), 'light_syntax_tokenizer');
    await _captureWidget(tester, const ChartDemo(),                'chart');
    await _captureWidget(tester, const ChartScrubberDemo(),        'chart_scrubber');
    await _captureWidget(tester, const ChartRangeSelectorDemo(),   'chart_range_selector');
  });
}
```

**Error-handling pattern:** none — this is a writer script, not a library. If a demo fails to pump, the test fails and the planner fixes that demo inline (D-05).

**Location decision:** lives at `example/test/capture_images_test.dart` (NOT package-root `test/`) because:
1. It must import `package:frontend_scaffold_example/demos/*.dart`.
2. `example/pubspec.yaml` already declares `flutter_test` under `dev_dependencies`.
3. Keeps package-root `test/` scoped to the library's unit/widget tests.

**Run command:** `cd example && flutter test test/capture_images_test.dart`.

---

### `test/components/scaffold_selection_actions_test.dart` (MODIFIED — test deletion)

**Analog:** self — pure deletion of lines 334–375. No pattern to copy from elsewhere; this is a subtractive edit.

**Deletion pattern** (verbatim from `test/components/scaffold_selection_actions_test.dart:334-375`):

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
-  // drive SelectionArea.onSelectionChanged for widgets nested inside
-  // Center+Scaffold under the default 800x600 test viewport. The
-  // long-press+drag reaches the SelectableText but SelectionArea's internal
-  // SelectionRegistrar does not promote the drag into a selection event
-  // deterministically. Coverage of the SelectionArea wiring is preserved
-  // via debugSimulateSelection (the deterministic hook) in Tests 1-10;
-  // this smoke test is retained as a skip:true marker for manual QA.
-  testWidgets('smoke: long-press + drag on SelectableText fires '
-      'onSelectionChanged at least once', (tester) async {
-    int calls = 0;
-    await _pump(
-      tester,
-      ScaffoldSelectionActions(
-        toolbarBuilder: _defaultToolbarBuilder,
-        onSelectionChanged: (sel, text) => calls++,
-        child: const SelectableText('hello world'),
-      ),
-    );
-
-    final Finder text = find.text('hello world');
-    final Offset center = tester.getCenter(text);
-    // flutter_test has no longPressOn — start a long-press gesture, drag
-    // across the text, then release. This drives the real SelectionArea
-    // selection path end-to-end.
-    final TestGesture gesture = await tester.startGesture(center);
-    await tester.pump(const Duration(milliseconds: 500));
-    await gesture.moveBy(const Offset(40, 0));
-    await gesture.up();
-    await tester.pump();
-    await tester.pump(const Duration(milliseconds: 200));
-
-    expect(calls, greaterThanOrEqualTo(1));
-  }, skip: true); // Framework-flaky — see comment above.
-
   // Test 18 — the toolbar paints on-screen, centered above the selection.
```

**What stays (verified by 11-RESEARCH.md):**
- `_pump(tester, ...)` at line 12 — used by all 17 remaining tests.
- `_pumpLight(tester, ...)` at line 21 — used by light-palette tests.
- `_defaultToolbarBuilder` at line 37 — used by remaining tests.
- All 9 imports at lines 1–10 — `TestGesture`, `startGesture`, `gesture.moveBy`, `gesture.up` are still used by 5 other gesture-based tests (lines 456, 459, 483, 585, 588, 594, 675, 678, 684, 762, 765, 769, 848, 851, 857).
- No orphan cleanup needed.

**Post-edit verification:**
- File shrinks 929 → 887 lines.
- `dart analyze --fatal-infos` clean.
- `flutter test` reports `+454` passing, zero skips (`~1` gone).
- `grep -rn "skip: true" test/` returns nothing.

---

### `README.md` (MODIFIED — docs)

**Analog:** self — surgical edits only. No structural rewrite; the existing Part 1 / Part 2 layout, "What's in it" table, and codegen section stay untouched.

**Pattern 1 — Test-count bump (2 occurrences):**

```diff
 # Develop section (line 86)
-flutter test                  # 214 tests
+flutter test                  # 454 tests

 # Repository layout tree (line 300)
-├── test/                           ← 214 widget + token tests
+├── test/                           ← 454 widget + token tests
```

**Pattern 2 — Demo-app section expansion (lines 73–79):**

```diff
 ## Demo app

 ```bash
 cd example && flutter run -d macos    # or -d chrome
 ```

-`example/` is a runnable gallery with one demo screen per widget family.
+`example/` is a runnable gallery with 26 demo screens covering every widget
+family and the v1.2 atoms. The component gallery below shows a captured
+screenshot of each demo.
```

**Pattern 3 — New `## Component gallery` section (insert after "Demo app"):**

Per-atom block shape — one `###` heading + one `![alt](images/<name>.png)` + one-line description:

```markdown
## Component gallery

### ActionButton
![ActionButton demo](images/action_button.png)
Enabled, disabled, and rotate-animation states.

### StringButton
![StringButton demo](images/string_button.png)
Keypad-style button that emits its string value.

<!-- ... 24 more entries, one per _DemoTile in example/lib/main.dart,
     using the filename table from 11-RESEARCH.md §Naming Convention ... -->

### Chart Range Selector
![Chart Range Selector demo](images/chart_range_selector.png)
Drag-range selection + consumer-policy zoom.
```

**Pattern 4 — New `## Coverage` section (insert after the gallery):**

Insert the 19-row WIDG-45 table **verbatim** from `11-RESEARCH.md` §WIDG-45 19-Component Coverage Proof (rows: 7 ready + 8 thin + 4 primitive-enabled = 19). Do not paraphrase — the tally was checked against `.planning/atoms-v1.2-additions.md` and drift here would defeat the gate.

**Pattern 5 — Repository-layout tree addition:**

```diff
 ├── example/                        ← runnable demo gallery
+├── images/                         ← per-demo screenshots (gallery above)
 ├── templates/                      ← Jinja2 templates (base, components, module, cpp)
```

**What NOT to touch:**
- Part 2 (codegen toolkit) — out of scope.
- "What's in it" table — unchanged.
- "~70 widgets" claims at lines 5, 53, 297 — still accurate.
- Existing heading names — surgical inserts only.

---

### `lib/frontend_scaffold.dart` (VERIFY only — no edit)

**Analog:** self. The file is the barrel export. The sweep's job is to *confirm* all 11 v1.2 atoms + the chart renderer support part are present, not to modify.

**Verification grep:**

```bash
grep -E "scaffold_(chip|chip_group|disclosure|trace_list|composer|streaming_rich_text|streaming_rich_text_cubit|streaming_rich_text_state|code_block|selection_actions|chart|chart_scrubber|chart_range_selector|chart_renderer)\.dart" \
  lib/frontend_scaffold.dart
```

Expected hits (line numbers verified 2026-08-22): 26, 27, 28, 29, 30, 31, 33, 36, 69, 78, 79, 80, 83, 108.

**No edit is planned.** If the sweep surfaces a missing export, add it adjacent to its existing sibling lines (alphabetical within the `scaffold_*` block) — but the 11-RESEARCH.md sweep matrix already shows zero gaps.

---

## Shared Patterns

### Theme extension setup (the `_pump` convention)
**Source:** `test/components/scaffold_chip_test.dart:11-18` (identical shape in every widget test)
**Apply to:** `example/test/capture_images_test.dart`

```dart
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
```

Every widget test in the package uses this exact wrapper. The capture harness MUST match it so captured pixels are comparable to what widget tests assert against. Do not hand-roll `[ScaffoldPalette.defaultPalette, ScaffoldDimens.defaultDimens]` — go through `scaffoldThemeExtensions`.

### Light-palette variant (for reference only — capture harness does NOT use it)
**Source:** `test/components/scaffold_chip_test.dart:20-32`

```dart
Future<void> _pumpLight(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[
          ScaffoldPalette.lightPalette,
          ScaffoldDimens.defaultDimens,
        ],
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
```

CONTEXT D-02 says "one screenshot per atom/demo screen" (singular, dark default per Research Open Question 2). The capture harness uses the dark `_pump` only. If a future phase wants both palettes, double the harness.

### Demo-widget shape (what the harness pumps)
**Source:** `example/lib/demos/chip_demo.dart:14-108`
**Apply to:** capture harness — confirms every demo is a `StatelessWidget` with `Scaffold` + `AppBar` + scrollable body, requiring no extra setup beyond the `_pump` wrapper.

```dart
class ScaffoldChipDemo extends StatelessWidget {
  const ScaffoldChipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldChip')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[ /* ... */ ],
        ),
      ),
    );
  }
}
```

Key implication: demos already render their own `Scaffold` + `AppBar`. The capture harness's `_pump` will nest a second `Scaffold` around them — this is intentional (matches what widget tests do), and the `Center(child: SizedBox(800x600, child: RepaintBoundary(...)))` wrapper frames the demo uniformly.

### Barrel-export naming
**Source:** `lib/frontend_scaffold.dart` (full file)
**Apply to:** sweep verification only

All v1.2 atoms are alphabetically interleaved into the flat export list. New exports (if any surface during the sweep) slot alphabetically into the existing `scaffold_*` block — never appended at the end.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `images/` (26 PNGs) | asset output | file-write | First non-source artifact in the package; output of the capture harness, not source code. No pattern needed beyond "commit to git, do not gitignore." |

The capture-harness *rasterization* technique (`RenderRepaintBoundary.toImage` + `toByteData(png)` + `File.writeAsBytes`) also has no prior use in the repo — it is the canonical Flutter SDK pattern, cited from SDK docs in `11-RESEARCH.md` §Image-Capture Harness. The planner should treat it as a *new* pattern layered on top of the existing `_pump` wrapper, not as a variant of anything already in the codebase.

## Metadata

**Analog search scope:**
- `test/components/scaffold_chip_test.dart`, `test/components/scaffold_selection_actions_test.dart` (widget-test `_pump` convention)
- `example/lib/main.dart` (demo registry — 26 `_DemoTile` entries)
- `example/lib/demos/chip_demo.dart` (demo-widget shape)
- `lib/frontend_scaffold.dart` (barrel — all 110 lines)
- `lib/theme/scaffold_theme.dart` (via Grep for `scaffoldThemeExtensions`)
- `example/pubspec.yaml` (flutter_test dev-dependency verified)
- `.gitignore` (verified `images/` and `*.png` not excluded)

**Files scanned:** 8 primary + 1 grep across `lib/theme/`
**Pattern extraction date:** 2026-08-22
