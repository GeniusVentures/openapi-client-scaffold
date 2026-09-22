import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/media_card.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

// 1x1 transparent PNG used as a deterministic in-memory thumbnail provider.
final Uint8List _onePixelPng = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

// Test-harness width that keeps tall-aspect-ratio cards within the default
// 800x600 test surface. Chosen so a 9/16 card fits: 240 * (16/9) ≈ 427 < 600.
const double _kCardWidth = 240.0;

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: _kCardWidth,
            child: child,
          ),
        ),
      ),
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
    final MemoryImage provider = MemoryImage(_onePixelPng);

    await _pump(tester, MediaCard(thumbnail: provider));

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
    final Text text = flexible.child as Text;
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

    expect(find.byType(ScaffoldDisabledOverlay), findsOneWidget);

    final ScaffoldPressable pressable =
        tester.widget(find.byType(ScaffoldPressable));
    expect(pressable.disabled, isTrue);

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
