import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/media_card.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
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

Positioned _positionedFor(WidgetTester tester, ScaffoldBadge badge) {
  return tester.widget<Positioned>(
    find.ancestor(
      of: find.byWidget(badge),
      matching: find.byType(Positioned),
    ),
  );
}

void main() {
  testWidgets('aspectRatio 16/9 produces AspectRatio widget with that ratio',
      (tester) async {
    await _pump(tester, const MediaCard(aspectRatio: 16 / 9));

    final AspectRatio aspect =
        tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(aspect.aspectRatio, 16 / 9);
  });

  testWidgets('aspectRatio 9/16 produces AspectRatio widget with that ratio',
      (tester) async {
    await _pump(tester, const MediaCard(aspectRatio: 9 / 16));

    final AspectRatio aspect =
        tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(aspect.aspectRatio, 9 / 16);
  });

  testWidgets('aspectRatio 1.0 produces AspectRatio widget with that ratio',
      (tester) async {
    await _pump(tester, const MediaCard(aspectRatio: 1.0));

    final AspectRatio aspect =
        tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(aspect.aspectRatio, 1.0);
  });

  testWidgets('thumbnail ImageProvider renders an Image with that provider',
      (tester) async {
    const NetworkImage provider = NetworkImage('https://example.com/t.png');

    await _pump(tester, const MediaCard(thumbnail: provider));

    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.image, provider);
  });

  testWidgets('typed badge slots render at topLeft/topRight/bottomRight',
      (tester) async {
    const ScaffoldBadge topLeft = ScaffoldBadge(
      variant: BadgeVariant.text,
      text: 'LIVE',
    );
    const ScaffoldBadge topRight = ScaffoldBadge(
      variant: BadgeVariant.text,
      text: 'NEW',
    );
    const ScaffoldBadge bottomRight = ScaffoldBadge(
      variant: BadgeVariant.text,
      text: 'HD',
    );

    await _pump(
      tester,
      const MediaCard(
        topLeftBadge: topLeft,
        topRightBadge: topRight,
        bottomRightBadge: bottomRight,
      ),
    );

    expect(find.byType(ScaffoldBadge), findsNWidgets(3));

    final Positioned tl = _positionedFor(tester, topLeft);
    expect(tl.top, isNotNull);
    expect(tl.left, isNotNull);
    expect(tl.right, isNull);
    expect(tl.bottom, isNull);

    final Positioned tr = _positionedFor(tester, topRight);
    expect(tr.top, isNotNull);
    expect(tr.right, isNotNull);
    expect(tr.left, isNull);
    expect(tr.bottom, isNull);

    final Positioned br = _positionedFor(tester, bottomRight);
    expect(br.bottom, isNotNull);
    expect(br.right, isNotNull);
    expect(br.top, isNull);
    expect(br.left, isNull);
  });

  testWidgets('metadataRow renders children in order inside a Row',
      (tester) async {
    await _pump(
      tester,
      const MediaCard(
        metadataRow: <Widget>[Text('a'), Text('b')],
      ),
    );

    final Row row = tester.widget<Row>(
      find.descendant(
        of: find.byType(MediaCard),
        matching: find.byType(Row),
      ),
    );

    final List<Text> textChildren = row.children
        .whereType<Flexible>()
        .map((Flexible f) => f.child)
        .whereType<Text>()
        .toList();
    expect(textChildren.length, 2);
    expect(textChildren[0].data, 'a');
    expect(textChildren[1].data, 'b');
  });

  testWidgets('metadataRow children are wrapped in Flexible for ellipsis',
      (tester) async {
    await _pump(
      tester,
      const MediaCard(
        metadataRow: <Widget>[
          Text(
            'a very long metadata label that should be ellipsized',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );

    final Flexible flexible = tester.widget<Flexible>(
      find.descendant(
        of: find.byType(MediaCard),
        matching: find.byType(Flexible),
      ),
    );
    expect(flexible.child, isA<Text>());
    final Text text = flexible.child! as Text;
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('onTap wraps card in ScaffoldPressable and fires callback once',
      (tester) async {
    int taps = 0;
    await _pump(
      tester,
      MediaCard(
        onTap: () => taps++,
        metadataRow: const <Widget>[Text('meta')],
      ),
    );

    expect(find.byType(ScaffoldPressable), findsOneWidget);

    await tester.tap(find.byType(ScaffoldPressable));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets(
      'disabled + onTap blocks interaction and wraps in ScaffoldDisabledOverlay',
      (tester) async {
    int taps = 0;
    await _pump(
      tester,
      MediaCard(
        disabled: true,
        onTap: () => taps++,
        metadataRow: const <Widget>[Text('meta')],
      ),
    );

    expect(find.byType(ScaffoldDisabledOverlay), findsWidgets);

    await tester.tap(find.byType(MediaCard), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('a11y: pressable ancestor exposes Semantics(button: true); '
      'disabled state exposes enabled: false', (tester) async {
    // Enabled case: button semantics present.
    await _pump(
      tester,
      MediaCard(onTap: () {}),
    );

    final Semantics enabledSemantics = tester.widget<Semantics>(
      find.descendant(
        of: find.byType(ScaffoldPressable),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.button == true,
        ),
      ),
    );
    expect(enabledSemantics.properties.enabled, true);

    // Disabled case: enabled=false.
    await _pump(
      tester,
      MediaCard(onTap: () {}, disabled: true),
    );

    final Semantics disabledSemantics = tester.widget<Semantics>(
      find.descendant(
        of: find.byType(ScaffoldPressable),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.button == true,
        ),
      ),
    );
    expect(disabledSemantics.properties.enabled, false);
  });

  testWidgets('surface uses palette.deepBlueCardColor', (tester) async {
    await _pump(tester, const MediaCard());

    final ScaffoldSurface surface =
        tester.widget<ScaffoldSurface>(find.byType(ScaffoldSurface));
    expect(surface.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
  });
}
