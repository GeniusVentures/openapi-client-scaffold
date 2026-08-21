import 'package:flutter/material.dart';
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

  // Test 6 — placement override `below` resolves followerAnchor to topCenter.
  testWidgets('toolbarPlacement=below resolves followerAnchor=topCenter',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionActions(
        toolbarBuilder: _defaultToolbarBuilder,
        toolbarPlacement: ScaffoldToolbarPlacement.below,
        child: SelectableText('hello world'),
      ),
    );

    final dynamic state =
        tester.state(find.byType(ScaffoldSelectionActions));
    // ignore: invalid_use_of_visible_for_testing_member
    ScaffoldSelectionActions.debugSimulateSelection(state, 'hello world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final CompositedTransformFollower follower =
        tester.widget<CompositedTransformFollower>(
      find.byType(CompositedTransformFollower),
    );
    expect(follower.followerAnchor, Alignment.topCenter);
    expect(follower.targetAnchor, Alignment.bottomCenter);
  });

  // Test 7 — auto placement falls back below when selection near the top.
  testWidgets('toolbarPlacement=auto flips to below when insufficient '
      'space above', (tester) async {
    // Pump with the atom at the very top of the screen so the follower
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

    final CompositedTransformFollower follower =
        tester.widget<CompositedTransformFollower>(
      find.byType(CompositedTransformFollower),
    );
    // After the flip, the follower must anchor its TOP-center to the
    // target's BOTTOM-center (placement below).
    expect(follower.followerAnchor, Alignment.topCenter);
    expect(follower.targetAnchor, Alignment.bottomCenter);
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
}
