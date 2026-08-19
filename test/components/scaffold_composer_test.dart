import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_composer.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
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

void main() {
  testWidgets('default composer renders TextField with hintText and '
      'textTheme.bodyMedium style', (tester) async {
    await _pump(
      tester,
      const ScaffoldComposer(hintText: 'Type a message…'),
    );

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Type a message…');
    expect(field.decoration?.border, InputBorder.none);

    final BuildContext context = tester.element(find.byType(TextField));
    final TextStyle? expected = Theme.of(context).textTheme.bodyMedium;
    expect(field.style?.fontSize, expected?.fontSize);
    expect(field.style?.fontWeight, expected?.fontWeight);
  });

  testWidgets('badgeRow renders ABOVE the text field', (tester) async {
    const Key badgeKey = Key('composer-badge');
    await _pump(
      tester,
      const ScaffoldComposer(
        hintText: 'Type…',
        badgeRow: <Widget>[
          ScaffoldBadge(key: badgeKey, variant: BadgeVariant.text, text: 'Draft'),
        ],
      ),
    );

    final double badgeDy = tester.getTopLeft(find.byKey(badgeKey)).dy;
    final double fieldDy = tester.getTopLeft(find.byType(TextField)).dy;
    expect(badgeDy, lessThan(fieldDy));
  });

  testWidgets('actionRow renders BELOW the text field', (tester) async {
    const Key actionKey = Key('composer-action');
    await _pump(
      tester,
      ScaffoldComposer(
        hintText: 'Type…',
        actionRow: <Widget>[
          IconButton(
            key: actionKey,
            icon: const Icon(Icons.send),
            onPressed: () {},
          ),
        ],
      ),
    );

    final double actionDy = tester.getTopLeft(find.byKey(actionKey)).dy;
    final double fieldDy = tester.getTopLeft(find.byType(TextField)).dy;
    expect(actionDy, greaterThan(fieldDy));
  });

  testWidgets('badge + action rows render in order badge → field → actions',
      (tester) async {
    const Key badgeKey = Key('composer-badge');
    const Key actionKey = Key('composer-action');
    await _pump(
      tester,
      ScaffoldComposer(
        hintText: 'Type…',
        badgeRow: const <Widget>[
          ScaffoldBadge(key: badgeKey, variant: BadgeVariant.text, text: 'Draft'),
        ],
        actionRow: <Widget>[
          IconButton(
            key: actionKey,
            icon: const Icon(Icons.send),
            onPressed: () {},
          ),
        ],
      ),
    );

    final double badgeDy = tester.getTopLeft(find.byKey(badgeKey)).dy;
    final double fieldDy = tester.getTopLeft(find.byType(TextField)).dy;
    final double actionDy = tester.getTopLeft(find.byKey(actionKey)).dy;
    expect(badgeDy, lessThan(fieldDy));
    expect(actionDy, greaterThan(fieldDy));
  });

  testWidgets('composer without slots renders only the text field '
      '(no empty row placeholders)', (tester) async {
    await _pump(tester, const ScaffoldComposer(hintText: 'Type…'));

    expect(find.byType(TextField), findsOneWidget);
    // No Wrap (badge row) and no action Row inside the composer.
    expect(
      find.descendant(
        of: find.byType(ScaffoldComposer),
        matching: find.byType(Wrap),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ScaffoldComposer),
        matching: find.byType(Row),
      ),
      findsNothing,
    );
  });

  testWidgets('submitting text fires onSubmit once with the entered string '
      'and clears the controller', (tester) async {
    final List<String> submissions = <String>[];
    await _pump(
      tester,
      ScaffoldComposer(
        hintText: 'Type…',
        onSubmit: submissions.add,
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submissions, <String>['hello']);
    // Controller cleared — the TextField no longer holds the submitted text.
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('disabled composer blocks submission, is not focusable, and '
      'wraps in ScaffoldDisabledOverlay', (tester) async {
    final List<String> submissions = <String>[];
    await _pump(
      tester,
      ScaffoldComposer(
        hintText: 'Type…',
        disabled: true,
        onSubmit: submissions.add,
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ScaffoldComposer),
        matching: find.byType(ScaffoldDisabledOverlay),
      ),
      findsOneWidget,
    );

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submissions, isEmpty);
  });

  testWidgets('surface has surfaceElevated fill, borderSubtle 1px border, '
      'radiusMd corner radius', (tester) async {
    await _pump(tester, const ScaffoldComposer(hintText: 'Type…'));

    final ScaffoldSurface surface = tester.widget<ScaffoldSurface>(
      find.descendant(
        of: find.byType(ScaffoldComposer),
        matching: find.byType(ScaffoldSurface),
      ),
    );
    expect(surface.color, ScaffoldPalette.defaultPalette.surfaceElevated);
    expect(
      surface.borderRadius,
      BorderRadius.circular(ScaffoldDimens.defaultDimens.radiusMd),
    );
    final Border border = surface.border! as Border;
    expect(border.top.color, ScaffoldPalette.defaultPalette.borderSubtle);
    expect(border.top.width, 1);
  });

  testWidgets('ScaffoldFocusOutline receives the text field focus node',
      (tester) async {
    await _pump(tester, const ScaffoldComposer(hintText: 'Type…'));

    final ScaffoldFocusOutline outline = tester.widget<ScaffoldFocusOutline>(
      find.descendant(
        of: find.byType(ScaffoldComposer),
        matching: find.byType(ScaffoldFocusOutline),
      ),
    );
    expect(outline.focusNode, isNotNull);

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(outline.focusNode, same(field.focusNode));
  });

  testWidgets('consumer-supplied focusNode is wired to field and outline, '
      'and tapping the wrapping surface focuses it', (tester) async {
    final FocusNode externalNode = FocusNode();
    addTearDown(externalNode.dispose);

    await _pump(
      tester,
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: externalNode.requestFocus,
        child: ScaffoldComposer(hintText: 'Type…', focusNode: externalNode),
      ),
    );

    // The consumer's node is the one wired through to field + outline.
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode, same(externalNode));
    final ScaffoldFocusOutline outline = tester.widget<ScaffoldFocusOutline>(
      find.descendant(
        of: find.byType(ScaffoldComposer),
        matching: find.byType(ScaffoldFocusOutline),
      ),
    );
    expect(outline.focusNode, same(externalNode));

    // Tap the wrapping surface (off the text line) → focus is requested.
    expect(externalNode.hasFocus, isFalse);
    await tester.tap(find.byType(ScaffoldComposer));
    await tester.pump();
    expect(externalNode.hasFocus, isTrue);
  });

  testWidgets('composer does NOT dispose a consumer-supplied focus node',
      (tester) async {
    final FocusNode externalNode = FocusNode();
    await _pump(
      tester,
      ScaffoldComposer(hintText: 'Type…', focusNode: externalNode),
    );

    // Tear down the tree — the composer must leave the consumer node alive.
    await tester.pumpWidget(const SizedBox.shrink());
    // A disposed ChangeNotifier throws on addListener; a live one does not.
    void listener() {}
    expect(() => externalNode.addListener(listener), returnsNormally);
    externalNode.removeListener(listener);
    externalNode.dispose();
  });

  testWidgets('composer disposes its own internal focus node', (tester) async {
    await _pump(tester, const ScaffoldComposer(hintText: 'Type…'));
    final FocusNode captured =
        tester.widget<TextField>(find.byType(TextField)).focusNode!;

    await tester.pumpWidget(const SizedBox.shrink());
    // The composer-owned node is disposed with the tree: adding a listener
    // to a disposed ChangeNotifier throws a FlutterError.
    expect(() => captured.addListener(() {}), throwsFlutterError);
  });

  testWidgets('renders under lightPalette without exception', (tester) async {
    await _pumpLight(
      tester,
      const ScaffoldComposer(
        hintText: 'Type a message…',
        badgeRow: <Widget>[
          ScaffoldBadge(variant: BadgeVariant.text, text: 'Draft'),
        ],
      ),
    );

    expect(find.byType(ScaffoldComposer), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('action row uses MainAxisAlignment.end with space4 separation',
      (tester) async {
    await _pump(
      tester,
      ScaffoldComposer(
        hintText: 'Type…',
        actionRow: <Widget>[
          IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
          IconButton(icon: const Icon(Icons.send), onPressed: () {}),
        ],
      ),
    );

    final Row row = tester.widget<Row>(
      find.descendant(
        of: find.byType(ScaffoldComposer),
        matching: find.byType(Row),
      ),
    );
    expect(row.mainAxisAlignment, MainAxisAlignment.end);

    // One separator between the two action slots, sized dimens.space4.
    // IconButton contributes its own 24px internal SizedBoxes — filter to
    // width-only spacers (height == null), which only our separator matches.
    final Iterable<SizedBox> separators = tester
        .widgetList<SizedBox>(
          find.descendant(
            of: find.byType(Row),
            matching: find.byType(SizedBox),
          ),
        )
        .where((SizedBox box) => box.width != null && box.height == null);
    expect(separators, hasLength(1));
    expect(separators.single.width, ScaffoldDimens.defaultDimens.space4);
  });

  testWidgets('badge row uses Wrap with space4 spacing', (tester) async {
    await _pump(
      tester,
      const ScaffoldComposer(
        hintText: 'Type…',
        badgeRow: <Widget>[
          ScaffoldBadge(variant: BadgeVariant.text, text: 'Draft'),
          ScaffoldBadge(variant: BadgeVariant.text, text: '2 attachments'),
        ],
      ),
    );

    final Wrap wrap = tester.widget<Wrap>(
      find.descendant(
        of: find.byType(ScaffoldComposer),
        matching: find.byType(Wrap),
      ),
    );
    expect(wrap.spacing, ScaffoldDimens.defaultDimens.space4);
    expect(wrap.runSpacing, ScaffoldDimens.defaultDimens.space4);
  });
}
