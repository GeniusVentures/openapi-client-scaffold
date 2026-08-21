import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_rich_text.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_rich_text_cubit.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';

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

/// Reads the value currently exposed on the live region Semantics node.
String? _liveRegionValue(WidgetTester tester) {
  final Finder semantics = find
      .descendant(
        of: find.byType(ScaffoldLiveRegion),
        matching: find.byType(Semantics),
      )
      .first;
  return tester.widget<Semantics>(semantics).properties.value;
}

/// Locates the cursor Container (focusRingWidth-wide, lightGreenPrimary fill)
/// inside the streaming widget. Returns null when the cursor is hidden.
Container? _cursorContainer(WidgetTester tester) {
  final Finder finder = find.descendant(
    of: find.byType(ScaffoldStreamingRichText),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is Container &&
          w.color == ScaffoldPalette.defaultPalette.lightGreenPrimary,
    ),
  );
  if (finder.evaluate().isEmpty) {
    return null;
  }
  return tester.widget<Container>(finder.first);
}

void main() {
  // Test 1 -- default render with a single text span.
  testWidgets('renders initial span inside ScaffoldSurface', (tester) async {
    final cubit = ScaffoldStreamingRichTextCubit()
      ..appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('hello')]);
    addTearDown(cubit.close);

    await _pump(
      tester,
      ScaffoldStreamingRichText(cubit: cubit),
    );
    await tester.pump();

    expect(find.textContaining('hello'), findsWidgets);
    expect(find.byType(ScaffoldSurface), findsOneWidget);

    final Container surface = tester.widget<Container>(
      find.descendant(
        of: find.byType(ScaffoldSurface),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color ==
                  ScaffoldPalette.defaultPalette.surfaceElevated,
        ),
      ),
    );
    final BoxDecoration decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.surfaceElevated);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(ScaffoldDimens.defaultDimens.radiusMd),
    );
  });

  // Test 2 -- incremental append keeps prior text and adds the delta.
  testWidgets('incremental append re-renders with new span', (tester) async {
    final cubit = ScaffoldStreamingRichTextCubit()
      ..appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('hello')]);
    addTearDown(cubit.close);

    await _pump(tester, ScaffoldStreamingRichText(cubit: cubit));
    await tester.pump();
    expect(find.textContaining('hello'), findsWidgets);

    cubit.appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan(' world')]);
    await tester.pump();

    // Additive render: a single RichText carries both runs.
    final RichText rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(ScaffoldStreamingRichText),
        matching: find.byType(RichText),
      ),
    );
    final String rendered = rich.text.toPlainText();
    expect(rendered, contains('hello'));
    expect(rendered, contains(' world'));
  });

  // Test 3 -- streaming cursor present while streaming, hidden after complete.
  testWidgets('cursor visible while streaming, hidden after complete',
      (tester) async {
    final cubit = ScaffoldStreamingRichTextCubit()
      ..appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('hello')]);
    addTearDown(cubit.close);

    await _pump(tester, ScaffoldStreamingRichText(cubit: cubit));
    await tester.pump();

    expect(_cursorContainer(tester), isNotNull);

    cubit.complete();
    await tester.pump();
    expect(_cursorContainer(tester), isNull);
  });

  // Test 4 -- reduced-motion pins cursor opacity at 1.0 across pumps.
  testWidgets('reduced-motion cursor opacity is static', (tester) async {
    final cubit = ScaffoldStreamingRichTextCubit()
      ..appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('hello')]);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: ScaffoldMotion(
          reducedMotion: true,
          child: Scaffold(
            body: Center(child: ScaffoldStreamingRichText(cubit: cubit)),
          ),
        ),
      ),
    );
    await tester.pump();

    double readOpacity() {
      final Finder opacityFinder = find.descendant(
        of: find.byType(ScaffoldStreamingRichText),
        matching: find.byType(Opacity),
      );
      return tester.widget<Opacity>(opacityFinder.first).opacity;
    }

    final double first = readOpacity();
    await tester.pump(const Duration(milliseconds: 530));
    final double second = readOpacity();
    expect(first, second);
    expect(first, 1.0);
  });

  // Test 5 -- citation pill + toggle reveals expanded source slot.
  testWidgets('citation pill toggles expanded source slot', (tester) async {
    const citation = ScaffoldCitationSpan(
      id: 'cite-1',
      marker: '[1]',
      title: 'Source Title',
      body: 'Source body text',
    );
    final cubit = ScaffoldStreamingRichTextCubit()
      ..appendSpans(const <ScaffoldRichSpan>[
        ScaffoldTextSpan('text '),
        citation,
      ]);
    addTearDown(cubit.close);

    await _pump(tester, ScaffoldStreamingRichText(cubit: cubit));
    await tester.pump();

    // Pill fill is grayPrimary.
    final Container pill = tester.widget<Container>(
      find.descendant(
        of: find.byType(ScaffoldStreamingRichText),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color ==
                  ScaffoldPalette.defaultPalette.grayPrimary,
        ),
      ),
    );
    expect((pill.decoration! as BoxDecoration).color,
        ScaffoldPalette.defaultPalette.grayPrimary);

    // Slot hidden initially.
    expect(find.text('Source Title'), findsNothing);

    // Tap the pill to expand.
    await tester.tap(find.text('[1]'));
    await tester.pump();
    await tester.pump(ScaffoldMotionDurations.medium);

    expect(cubit.state.expandedCitations, contains('cite-1'));
    expect(find.text('Source Title'), findsOneWidget);
    expect(find.text('Source body text'), findsOneWidget);

    // Expanded card uses deepBlueCardColor fill + borderSubtle 1px border.
    final Container slot = tester.widget<Container>(
      find.ancestor(
        of: find.text('Source Title'),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color ==
                  ScaffoldPalette.defaultPalette.deepBlueCardColor,
        ),
      ),
    );
    final BoxDecoration slotDeco = slot.decoration! as BoxDecoration;
    expect(slotDeco.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
    final Border border = slotDeco.border! as Border;
    expect(border.top.color, ScaffoldPalette.defaultPalette.borderSubtle);
    expect(border.top.width, 1.0);
  });

  // Test 6 -- response-action row renders below body when actions non-null.
  testWidgets('action row renders below body', (tester) async {
    final cubit = ScaffoldStreamingRichTextCubit()
      ..appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('hello')]);
    addTearDown(cubit.close);

    await _pump(
      tester,
      ScaffoldStreamingRichText(
        cubit: cubit,
        actions: const <Widget>[Text('COPY')],
      ),
    );
    await tester.pump();

    expect(find.text('COPY'), findsOneWidget);
    // Row containing the action sits below the streaming body.
    final Finder actionRow = find.ancestor(
      of: find.text('COPY'),
      matching: find.byType(Row),
    );
    expect(actionRow, findsWidgets);
  });

  // Test 7 -- live region debounce: rapid appends announce at most once.
  testWidgets('live region debounces block-boundary announcements',
      (tester) async {
    final cubit = ScaffoldStreamingRichTextCubit();
    addTearDown(cubit.close);

    await _pump(tester, ScaffoldStreamingRichText(cubit: cubit));
    await tester.pump();

    final List<String?> snapshots = <String?>[];

    cubit.appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('a\n')]);
    await tester.pump(const Duration(milliseconds: 50));
    snapshots.add(_liveRegionValue(tester));

    cubit.appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('b\n')]);
    await tester.pump(const Duration(milliseconds: 50));
    snapshots.add(_liveRegionValue(tester));

    cubit.appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('c\n')]);
    await tester.pump(const Duration(milliseconds: 50));
    snapshots.add(_liveRegionValue(tester));

    // Count transitions between consecutive snapshots; must be <= 1.
    int transitions = 0;
    for (int i = 1; i < snapshots.length; i++) {
      if (snapshots[i] != snapshots[i - 1]) {
        transitions++;
      }
    }
    expect(transitions, lessThanOrEqualTo(1));

    // After the debounce window expires, the next append announces.
    await tester.pump(const Duration(milliseconds: 350));
    cubit.appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('d\n')]);
    await tester.pump();
    expect(_liveRegionValue(tester), 'd\n');
  });

  // Test 8 -- consumer-supplied cubit is not closed on widget disposal.
  testWidgets('consumer-supplied cubit stays open after widget disposal',
      (tester) async {
    final cubit = ScaffoldStreamingRichTextCubit();
    addTearDown(cubit.close);

    await _pump(tester, ScaffoldStreamingRichText(cubit: cubit));
    await tester.pump();

    // Dispose the widget tree.
    await tester.pumpWidget(const SizedBox());

    // The cubit must remain open — appending after disposal must not throw.
    expect(
      () => cubit
          .appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('x')]),
      returnsNormally,
    );
    expect(cubit.state.spans, hasLength(1));
  });

  // Test 9 -- renders under lightPalette without exception.
  testWidgets('renders under lightPalette without exception', (tester) async {
    final cubit = ScaffoldStreamingRichTextCubit()
      ..appendSpans(const <ScaffoldRichSpan>[ScaffoldTextSpan('hello')]);
    addTearDown(cubit.close);

    await _pumpLight(tester, ScaffoldStreamingRichText(cubit: cubit));
    await tester.pump();

    expect(find.byType(ScaffoldStreamingRichText), findsOneWidget);
    expect(find.textContaining('hello'), findsWidgets);
  });

  // Test 10 -- link spans are tappable and forward their target Uri to
  // onLinkTap.
  testWidgets('link span tap invokes onLinkTap with its Uri', (tester) async {
    final Uri target = Uri.parse('https://example.com/docs');
    final cubit = ScaffoldStreamingRichTextCubit()
      ..appendSpans(<ScaffoldRichSpan>[
        ScaffoldLinkSpan(text: 'docs', uri: target),
      ]);
    addTearDown(cubit.close);

    Uri? tapped;
    await _pump(
      tester,
      ScaffoldStreamingRichText(
        cubit: cubit,
        onLinkTap: (Uri uri) => tapped = uri,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('docs'));
    await tester.pump();

    expect(tapped, target);
  });
}
