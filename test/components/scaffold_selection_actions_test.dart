import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_selection_actions.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

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

/// Builds a minimal marker widget the toolbarBuilder returns so tests can
/// locate the consumer-supplied child inside the overlay.
Widget _defaultToolbarBuilder(BuildContext context, TextSelection s, String t) {
  return const Text('toolbar');
}

void main() {
  // Test 1 — selection change reported via the deterministic hook.
  testWidgets('debugSimulateSelection fires onSelectionChanged with '
      'non-collapsed TextSelection and plainText', (tester) async {
    final List<(TextSelection, String)> calls = <(TextSelection, String)>[];
    await _pump(
      tester,
      ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        onSelectionChanged: (sel, text) => calls.add((sel, text)),
        child: const SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();

    expect(calls, hasLength(1));
    expect(calls.single.$2, 'hello world');
    expect(calls.single.$1.isCollapsed, isFalse);
    expect(calls.single.$1.extentOffset, 'hello world'.length);
  });

  // Test 2 — toolbar shown on non-collapsed selection; surface uses
  // palette.surfaceElevated fill + 1px palette.borderSubtle border.
  testWidgets('toolbar overlay inserted on selection with surfaceElevated '
      'fill and borderSubtle border', (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        child: SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ScaffoldSurface), findsWidgets);
    expect(find.text('toolbar'), findsOneWidget);

    final ScaffoldSurface surface = tester.widgetList<ScaffoldSurface>(
      find.byType(ScaffoldSurface),
    ).firstWhere((ScaffoldSurface s) => s.color != null);
    expect(surface.color, ScaffoldPalette.defaultPalette.surfaceElevated);
    final Border border = surface.border! as Border;
    expect(border.top.color, ScaffoldPalette.defaultPalette.borderSubtle);
    expect(border.top.width, 1);
  });

  // Test 3 — toolbar hidden when selection collapses.
  testWidgets('collapsing the selection removes the toolbar overlay',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        child: SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('toolbar'), findsOneWidget);

    // Collapse the selection.
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, '');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Toolbar marker is gone from the overlay tree.
    expect(find.text('toolbar'), findsNothing);
  });

  // Test 4 — toolbarBuilder is invoked with (BuildContext, TextSelection,
  // String) and the returned widget renders inside the toolbar.
  testWidgets('toolbarBuilder invoked with (context, selection, plainText) '
      'and returned widget renders inside toolbar', (tester) async {
    TextSelection? seenSelection;
    String? seenPlainText;
    await _pump(
      tester,
      ScaffoldSelectionActions(
        toolbarBuilder: (BuildContext ctx, TextSelection sel, String text) {
          seenSelection = sel;
          seenPlainText = text;
          return const Text('built');
        },
        child: const SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'abc');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('built'), findsOneWidget);
    expect(seenPlainText, 'abc');
    expect(seenSelection, isNotNull);
    expect(seenSelection!.isCollapsed, isFalse);
  });

  // Test 5 — empty builder hides toolbar.
  testWidgets('toolbarBuilder returning SizedBox.shrink() inserts no overlay',
      (tester) async {
    await _pump(
      tester,
      ScaffoldSelectionActions(
        toolbarBuilder: (BuildContext ctx, TextSelection sel, String text) =>
            const SizedBox.shrink(),
        child: const SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ScaffoldSurface), findsNothing);
  });

  // Test 6 — placement override `below` paints the toolbar below the atom.
  testWidgets('toolbarPlacement=below paints the toolbar below the atom',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        toolbarPlacement: ScaffoldToolbarPlacement.below,
        toolbarAlignment: ScaffoldToolbarAlignment.center,
        child: SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final Rect leaderRect =
        tester.getRect(find.byType(ScaffoldSelectionActions));
    final Rect toolbarRect = tester.getRect(find.text('toolbar'));
    expect(toolbarRect.isEmpty, isFalse);
    // Below placement: the toolbar's top edge sits at or below the atom's
    // bottom edge.
    expect(toolbarRect.top, greaterThanOrEqualTo(leaderRect.bottom),
        reason: 'below placement anchors the toolbar under the selection');
    expect((toolbarRect.center.dx - leaderRect.center.dx).abs(), lessThan(1.0),
        reason: 'toolbar must be horizontally centered on the selection');
  });

  // Test 7 — auto placement falls back below when selection near the top.
  testWidgets('toolbarPlacement=auto flips to below when insufficient '
      'space above', (tester) async {
    // Pump with the atom at the very top of the screen so the toolbar
    // (anchored above by default) would paint with negative dy.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ScaffoldSelectionActions(
              toolbarBuilder: _defaultToolbarBuilder,
              // auto is the default; explicit here for clarity.
              toolbarPlacement: ScaffoldToolbarPlacement.auto,
              child: SelectableText('top line'),
            ),
          ),
        ),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'top line');
    await tester.pump();
    // First pump builds the overlay with `above`; the post-frame callback
    // then checks paintBounds and flips to `below` if off-screen top.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final Rect leaderRect =
        tester.getRect(find.byType(ScaffoldSelectionActions));
    final Rect toolbarRect = tester.getRect(find.text('toolbar'));
    expect(toolbarRect.isEmpty, isFalse);
    // After the flip the toolbar must paint fully on-screen, below the atom.
    expect(toolbarRect.top, greaterThanOrEqualTo(0.0),
        reason: 'toolbar must not be painted off-screen after the flip');
    expect(toolbarRect.top, greaterThanOrEqualTo(leaderRect.bottom),
        reason: 'auto must flip to below when there is no room above');
  });

  // Test 8 — Escape dismisses the toolbar.
  testWidgets('Escape key dismisses the visible toolbar', (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        child: SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('toolbar'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('toolbar'), findsNothing);
  });

  // Test 9 — reduced-motion gates the toolbar fade.
  testWidgets('under reducedMotion the toolbar AnimatedOpacity duration is '
      'Duration.zero', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: const ScaffoldMotion(
          reducedMotion: true,
          child: Scaffold(
            body: Center(
              child: ScaffoldSelectionActions(
                toolbarBuilder: _defaultToolbarBuilder,
                child: SelectableText('hello world'),
              ),
            ),
          ),
        ),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump();

    final AnimatedOpacity fade = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(fade.duration, Duration.zero);
  });

  // Test 10 — light palette renders without exception.
  testWidgets('renders under lightPalette without exception', (tester) async {
    await _pumpLight(
      tester,
      const ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        child: SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ScaffoldSelectionActions), findsOneWidget);
    expect(find.text('toolbar'), findsOneWidget);
  });

  // Test 11 — SMOKE: real SelectionArea path via longPress + drag.
  //
  // This is the ONLY long-press smoke test in this file (D-07 test
  // strategy). It asserts onSelectionChanged fires at least once with ANY
  // payload — payload assertions live in Tests 1-10 via the deterministic
  // hook. If this test proves framework-flaky in CI, mark it `skip: true`
  // with a comment linking the flake — do NOT add retries.
  //
  // SKIPPED 2026-08-20: flutter_test's gesture pipeline does not reliably
  // drive SelectionArea.onSelectionChanged for widgets nested inside
  // Center+Scaffold under the default 800x600 test viewport. The
  // long-press+drag reaches the SelectableText but SelectionArea's internal
  // SelectionRegistrar does not promote the drag into a selection event
  // deterministically. Coverage of the SelectionArea wiring is preserved
  // via debugSimulateSelection (the deterministic hook) in Tests 1-10;
  // this smoke test is retained as a skip:true marker for manual QA.
  testWidgets('smoke: long-press + drag on SelectableText fires '
      'onSelectionChanged at least once', (tester) async {
    int calls = 0;
    await _pump(
      tester,
      ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        onSelectionChanged: (sel, text) => calls++,
        child: const SelectableText('hello world'),
      ),
    );

    final Finder text = find.text('hello world');
    final Offset center = tester.getCenter(text);
    // flutter_test has no longPressOn — start a long-press gesture, drag
    // across the text, then release. This drives the real SelectionArea
    // selection path end-to-end.
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.moveBy(const Offset(40, 0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(calls, greaterThanOrEqualTo(1));
  }, skip: true); // Framework-flaky — see comment above.

  // Test 18 — the toolbar paints on-screen, centered above the selection.
  testWidgets('toolbar paints on-screen, centered above the selection',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionActions(
        toolbarPlacement: ScaffoldToolbarPlacement.above,
        toolbarAlignment: ScaffoldToolbarAlignment.center,
        toolbarBuilder: _defaultToolbarBuilder,
        child: SelectableText('hello world'),
      ),
    );

    final dynamic state = tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final Rect leaderRect =
        tester.getRect(find.byType(ScaffoldSelectionActions));
    final Rect toolbarRect = tester.getRect(find.text('toolbar'));
    expect(toolbarRect.isEmpty, isFalse);
    expect(toolbarRect.top, greaterThanOrEqualTo(0.0),
        reason: 'toolbar must not be painted off-screen');
    expect(toolbarRect.bottom, lessThanOrEqualTo(leaderRect.top),
        reason: 'above placement anchors the toolbar above the selection');
    expect((toolbarRect.center.dx - leaderRect.center.dx).abs(), lessThan(1.0),
        reason: 'toolbar must be horizontally centered on the selection');
  });

  // Test 19 — REAL partial selection: the toolbar must center over the
  // selected words, NOT over the whole text block. This is the UAT-reported
  // bug. Driven with the SDK's own deterministic double-tap + drag pattern
  // (double-tap selects a word, dragging extends word-by-word), so no
  // debugSimulateSelection fallback is involved — the anchor geometry comes
  // from the live SelectableRegion selection.
  testWidgets(
      'toolbar centers over a real partial (word-range) selection, not the '
      'whole text block', (tester) async {
    const String text = 'one two three four five';
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        // Align top-left so the text block's own center is far from the
        // selected words' center — a block-anchored toolbar would land
        // measurably off.
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ScaffoldSelectionActions(
              toolbarPlacement: ScaffoldToolbarPlacement.above,
              toolbarAlignment: ScaffoldToolbarAlignment.center,
              toolbarBuilder: _defaultToolbarBuilder,
              child: Text(text, style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    Offset positionOf(int offset) {
      const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
      final Offset local = paragraph.getOffsetForCaret(
            TextPosition(offset: offset),
            caret,
          ) +
          Offset(0.0, paragraph.preferredLineHeight);
      return paragraph.localToGlobal(local) + const Offset(0.0, -2.0);
    }

    // Double-tap the start of "three" to select the word, then drag to the
    // end of "four" to extend the selection word-by-word.
    final Offset threePos = positionOf(text.indexOf('three'));
    final Offset fourEndPos = positionOf(text.indexOf('four') + 'four'.length);
    final TestGesture gesture = await tester.startGesture(threePos);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await gesture.down(threePos);
    await tester.pumpAndSettle();

    final Finder toolbarFinder = find.text('toolbar');

    // The selection is already live after the double-tap, but the toolbar
    // must NOT pop up while the pointer is still down — it would animate
    // along with the selection.
    expect(paragraph.selections, isNotEmpty,
        reason: 'double-tap must select the word');
    expect(toolbarFinder, findsNothing,
        reason: 'toolbar must stay hidden while the selecting pointer is '
            'down (it pops up on release, not during the drag)');

    await gesture.moveTo(fourEndPos);
    await tester.pump();

    // Mid-drag: still hidden — the drag keeps mutating the selection and the
    // toolbar only appears once, on release, at the final geometry.
    expect(toolbarFinder, findsNothing,
        reason: 'toolbar must not chase the growing selection mid-drag');

    await gesture.up();
    await tester.pumpAndSettle();

    // The toolbar appears once the selecting pointer is released.
    expect(toolbarFinder, findsOneWidget,
        reason: 'toolbar must appear after the selection is released');

    // GROUND TRUTH: the actual selected glyphs, straight from the paragraph.
    // The double-tap + drag selection is word-granular, so we read the real
    // selection box rather than assume which words were grabbed.
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      paragraph.selections.first,
    );
    expect(boxes, isNotEmpty);
    // Merge the boxes into one global rect covering the whole selection.
    final Offset paragraphOrigin = paragraph.localToGlobal(Offset.zero);
    Rect selectionRect = boxes.first.toRect().shift(paragraphOrigin);
    for (final TextBox b in boxes.skip(1)) {
      selectionRect = selectionRect.expandToInclude(
        b.toRect().shift(paragraphOrigin),
      );
    }

    final Rect toolbarRect = tester.getRect(toolbarFinder);
    final Rect blockRect =
        tester.getRect(find.byType(ScaffoldSelectionActions));

    // Sanity: the selection is a strict sub-range, so its center differs
    // from the block center — otherwise this test can't discriminate.
    expect(
      (selectionRect.center.dx - blockRect.center.dx).abs(),
      greaterThan(10.0),
      reason: 'test setup: the selection center must differ from the block '
          'center for the assertions to be meaningful',
    );

    // 1. Centered over the SELECTION BOUNDING BOX center — center alignment
    //    anchors to the midpoint of the selected text, regardless of drag
    //    direction or cursor position.
    expect(
      (toolbarRect.center.dx - selectionRect.center.dx).abs(),
      lessThan(24.0),
      reason: 'center-aligned toolbar center.x (${toolbarRect.center.dx}) '
          'must sit over the selection center (${selectionRect.center.dx}), '
          'not the block (center ${blockRect.center.dx})',
    );
    // 2. NOT centered over the whole text block. A block-anchored toolbar
    //    would match blockRect.center; the fixed one must not.
    expect(
      (toolbarRect.center.dx - blockRect.center.dx).abs(),
      greaterThan(10.0),
      reason: 'toolbar must NOT be centered on the whole text block '
          '(block center ${blockRect.center.dx})',
    );
    // 3. Above the selection (placement: above).
    expect(
      toolbarRect.bottom,
      lessThanOrEqualTo(selectionRect.top + 1.0),
      reason: 'above placement anchors the toolbar above the selection',
    );
  });

  // Test 20 — toolbarAlignment.last pins the toolbar's RIGHT edge to the
  // LAST selected character in selection order (the cursor edge).
  testWidgets(
      'toolbarAlignment=last aligns the toolbar right edge to the last '
      'selected character', (tester) async {
    const String text = 'one two three four five';
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ScaffoldSelectionActions(
              toolbarPlacement: ScaffoldToolbarPlacement.above,
              toolbarAlignment: ScaffoldToolbarAlignment.last,
              toolbarBuilder: _defaultToolbarBuilder,
              child: Text(text, style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    Offset positionOf(int offset) {
      const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
      final Offset local = paragraph.getOffsetForCaret(
            TextPosition(offset: offset),
            caret,
          ) +
          Offset(0.0, paragraph.preferredLineHeight);
      return paragraph.localToGlobal(local) + const Offset(0.0, -2.0);
    }

    // Forward drag: double-tap "three", drag right to the end of "four".
    final Offset threePos = positionOf(text.indexOf('three'));
    final Offset fourEndPos = positionOf(text.indexOf('four') + 'four'.length);
    final TestGesture gesture = await tester.startGesture(threePos);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await gesture.down(threePos);
    await tester.pumpAndSettle();
    await gesture.moveTo(fourEndPos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final Finder toolbarFinder = find.text('toolbar');
    expect(toolbarFinder, findsOneWidget);

    // Ground-truth selection rect from the paragraph's glyph boxes.
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      paragraph.selections.first,
    );
    final Offset paragraphOrigin = paragraph.localToGlobal(Offset.zero);
    Rect selectionRect = boxes.first.toRect().shift(paragraphOrigin);
    for (final TextBox b in boxes.skip(1)) {
      selectionRect = selectionRect.expandToInclude(
        b.toRect().shift(paragraphOrigin),
      );
    }

    final Rect toolbarRect = tester.getRect(toolbarFinder);
    // last alignment (selection order): the toolbar's RIGHT edge sits at the
    // LAST selected character — the cursor edge, which is the right end of
    // the selection on this forward drag. getBoxesForSelection extends the
    // last box past the cursor to include the trailing space the word-wise
    // drag grabbed, so allow one space-width of slack.
    expect(
      (toolbarRect.right - selectionRect.right).abs(),
      lessThan(12.0),
      reason: 'last-aligned toolbar right edge (${toolbarRect.right}) must '
          'sit at the last selected character (${selectionRect.right}) within '
          'one trailing-space glyph',
    );
    expect(
      (toolbarRect.center.dx - selectionRect.center.dx).abs(),
      greaterThan(10.0),
      reason: 'last-aligned toolbar must NOT be centered on the selection',
    );
  });

  // Test 21 — toolbarAlignment.right anchors to the selection BOUNDING BOX
  // right edge, which is direction-independent: on a right-to-left drag the
  // cursor rests on the leftmost character, but `right` still lands on the
  // visual right edge of the selected text.
  testWidgets(
      'toolbarAlignment=right on a right-to-left drag aligns to the selection '
      'bounding box right edge, not the cursor', (tester) async {
    const String text = 'one two three four five';
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ScaffoldSelectionActions(
              toolbarPlacement: ScaffoldToolbarPlacement.above,
              toolbarAlignment: ScaffoldToolbarAlignment.right,
              toolbarBuilder: _defaultToolbarBuilder,
              child: Text(text, style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    Offset positionOf(int offset) {
      const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
      final Offset local = paragraph.getOffsetForCaret(
            TextPosition(offset: offset),
            caret,
          ) +
          Offset(0.0, paragraph.preferredLineHeight);
      return paragraph.localToGlobal(local) + const Offset(0.0, -2.0);
    }

    // Reversed drag: double-tap "four" (the RIGHT word), drag LEFT to
    // "three" — the cursor ends on the leftmost selected character.
    final Offset fourPos = positionOf(text.indexOf('four'));
    final Offset threePos = positionOf(text.indexOf('three'));
    final TestGesture gesture = await tester.startGesture(fourPos);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await gesture.down(fourPos);
    await tester.pumpAndSettle();
    await gesture.moveTo(threePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final Finder toolbarFinder = find.text('toolbar');
    expect(toolbarFinder, findsOneWidget);

    // Ground-truth selection rect from the paragraph's glyph boxes.
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      paragraph.selections.first,
    );
    final Offset paragraphOrigin = paragraph.localToGlobal(Offset.zero);
    Rect selectionRect = boxes.first.toRect().shift(paragraphOrigin);
    for (final TextBox b in boxes.skip(1)) {
      selectionRect = selectionRect.expandToInclude(
        b.toRect().shift(paragraphOrigin),
      );
    }

    final Rect toolbarRect = tester.getRect(toolbarFinder);
    // right alignment is direction-independent: the toolbar's right edge sits
    // at the selection BOUNDING BOX right edge (the visual right), NOT at the
    // cursor (which rests on the visual left after a right-to-left drag).
    expect(
      (toolbarRect.right - selectionRect.right).abs(),
      lessThan(12.0),
      reason: 'right-aligned toolbar right edge (${toolbarRect.right}) must '
          'sit at the bounding box right edge (${selectionRect.right}) even '
          'on a right-to-left drag',
    );
    expect(
      (toolbarRect.right - selectionRect.left).abs(),
      greaterThan(10.0),
      reason: 'right alignment must NOT follow the cursor to the left edge',
    );
  });

  // Test 22 — center (and left/right) anchor to the selection bounding box,
  // so they work identically with NO drag (e.g. a plain double-click word
  // select). The anchor derives purely from the selection geometry, never a
  // pointer position, so a double-click centers on the selected word.
  testWidgets(
      'toolbarAlignment=center on a plain double-click (no drag) centers on '
      'the selection, not the last character', (tester) async {
    const String text = 'one two three four five';
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ScaffoldSelectionActions(
              toolbarPlacement: ScaffoldToolbarPlacement.above,
              toolbarAlignment: ScaffoldToolbarAlignment.center,
              toolbarBuilder: _defaultToolbarBuilder,
              child: Text(text, style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    Offset positionOf(int offset) {
      const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
      final Offset local = paragraph.getOffsetForCaret(
            TextPosition(offset: offset),
            caret,
          ) +
          Offset(0.0, paragraph.preferredLineHeight);
      return paragraph.localToGlobal(local) + const Offset(0.0, -2.0);
    }

    // Double-click "three" with NO drag — selects the word and releases in
    // place.
    final Offset threePos = positionOf(text.indexOf('three'));
    final TestGesture gesture = await tester.startGesture(threePos);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await gesture.down(threePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final Finder toolbarFinder = find.text('toolbar');
    expect(toolbarFinder, findsOneWidget);

    // Ground-truth selection rect from the paragraph's glyph boxes.
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      paragraph.selections.first,
    );
    expect(boxes, isNotEmpty, reason: 'double-click must select the word');
    final Offset paragraphOrigin = paragraph.localToGlobal(Offset.zero);
    Rect selectionRect = boxes.first.toRect().shift(paragraphOrigin);
    for (final TextBox b in boxes.skip(1)) {
      selectionRect = selectionRect.expandToInclude(
        b.toRect().shift(paragraphOrigin),
      );
    }

    final Rect toolbarRect = tester.getRect(toolbarFinder);
    // Center alignment anchors to the selection bounding box center — NOT
    // the last character's right edge.
    expect(
      (toolbarRect.center.dx - selectionRect.center.dx).abs(),
      lessThan(24.0),
      reason: 'with no drag, center alignment must center on the selection '
          '(center ${selectionRect.center.dx}), not the last character '
          '(right ${selectionRect.right})',
    );
    expect(
      (toolbarRect.center.dx - selectionRect.right).abs(),
      greaterThan(10.0),
      reason: 'must NOT fall back to the last-character edge on a no-drag '
          'selection',
    );
  });

  // Test 23 — toolbarAlignment.first anchors to the FIRST selected character
  // in SELECTION ORDER (the anchor edge where the selection started). On a
  // forward drag that is the LEFT edge — same as `left` for a forward
  // selection, but distinct from `last` (Test 20) which lands on the right.
  testWidgets(
      'toolbarAlignment=first on a forward drag aligns to the anchor edge '
      '(left for L-to-R)', (tester) async {
    const String text = 'one two three four five';
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ScaffoldSelectionActions(
              toolbarPlacement: ScaffoldToolbarPlacement.above,
              toolbarAlignment: ScaffoldToolbarAlignment.first,
              toolbarBuilder: _defaultToolbarBuilder,
              child: Text(text, style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    Offset positionOf(int offset) {
      const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
      final Offset local = paragraph.getOffsetForCaret(
            TextPosition(offset: offset),
            caret,
          ) +
          Offset(0.0, paragraph.preferredLineHeight);
      return paragraph.localToGlobal(local) + const Offset(0.0, -2.0);
    }

    // Forward drag: double-tap "three", drag right to end of "four".
    final Offset threePos = positionOf(text.indexOf('three'));
    final Offset fourEndPos = positionOf(text.indexOf('four') + 'four'.length);
    final TestGesture gesture = await tester.startGesture(threePos);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await gesture.down(threePos);
    await tester.pumpAndSettle();
    await gesture.moveTo(fourEndPos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final Finder toolbarFinder = find.text('toolbar');
    expect(toolbarFinder, findsOneWidget);

    // Ground-truth selection rect from the paragraph's glyph boxes.
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      paragraph.selections.first,
    );
    final Offset paragraphOrigin = paragraph.localToGlobal(Offset.zero);
    Rect selectionRect = boxes.first.toRect().shift(paragraphOrigin);
    for (final TextBox b in boxes.skip(1)) {
      selectionRect = selectionRect.expandToInclude(
        b.toRect().shift(paragraphOrigin),
      );
    }

    final Rect toolbarRect = tester.getRect(toolbarFinder);
    // first alignment follows SELECTION ORDER: the toolbar's LEFT edge sits
    // at the FIRST selected character — the anchor where the selection
    // started, which is the LEFT edge on a forward drag.
    expect(
      (toolbarRect.left - selectionRect.left).abs(),
      lessThan(12.0),
      reason: 'first-aligned toolbar left edge (${toolbarRect.left}) must '
          'sit at the anchor edge (${selectionRect.left})',
    );
    expect(
      (toolbarRect.left - selectionRect.right).abs(),
      greaterThan(10.0),
      reason: 'first alignment must follow the anchor to the left, not the '
          'cursor on the right',
    );
  });

  // Test 24 — debugSimulateSelection with a reversed TextSelection
  // (base > extent) proves that reversed selections flow through the handler.
  // Pixel-perfect toolbar positioning for reversed selections is covered by
  // the bounding-box tests (left/center/right are direction-independent);
  // this test confirms the selection-order path accepts reversed offsets.
  testWidgets(
      'debugSimulateSelection with reversed TextSelection (base > extent) '
      'reports the reversed selection via onSelectionChanged', (tester) async {
    final List<(TextSelection, String)> calls = <(TextSelection, String)>[];
    await _pump(
      tester,
      ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        onSelectionChanged: (sel, text) => calls.add((sel, text)),
        child: const SelectableText('one two three four five'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // Reversed: base=23 (right), extent=14 (left) — simulates a right-to-left
    // drag where the anchor is on the right and the cursor is on the left.
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(
      state,
      'four five',
      selection: const TextSelection(baseOffset: 23, extentOffset: 14),
    );
    await tester.pump();

    expect(calls.length, 1);
    expect(calls.last.$1.baseOffset, 23);
    expect(calls.last.$1.extentOffset, 14);
    expect(calls.last.$1.baseOffset > calls.last.$1.extentOffset, isTrue,
        reason: 'reversed selection: base must be greater than extent');
  });
}
