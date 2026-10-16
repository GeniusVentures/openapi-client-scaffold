import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/bottom_drawer/bottom_drawer.dart';
import 'package:frontend_scaffold/components/bottom_drawer/responsive_drawer.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_shapes.dart';

Future<void> _pumpDrawer(WidgetTester tester, ThemeData theme) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: BottomDrawer(title: 'Title', children: [Text('item')]),
      ),
    ),
  );
}

void _expectHeader({
  required WidgetTester tester,
  required Color foreground,
  required Color divider,
}) {
  final title = tester.widget<Text>(find.text('Title'));
  expect(
    title.style,
    TextStyle(color: foreground, fontWeight: FontWeight.w500, fontSize: 16),
  );
  expect(tester.widget<Icon>(find.byIcon(Icons.close)).color, foreground);
  expect(tester.widget<Divider>(find.byType(Divider)).color, divider);
}

void main() {
  final themes = <String, ThemeData>{
    'dark': ThemeData(
      brightness: Brightness.dark,
      extensions: [
        ScaffoldPalette.defaultPalette,
        ScaffoldDimens.defaultDimens,
      ],
    ),
    'light': ThemeData(
      brightness: Brightness.light,
      extensions: [ScaffoldPalette.lightPalette, ScaffoldDimens.defaultDimens],
    ),
    'no extensions': ThemeData(),
  };

  group('defaults follow the brightness', () {
    const dark = (foreground: Color(0xFFFFFFFF), divider: Color(0x1FFFFFFF));
    const light = (foreground: Color(0xFF17191E), divider: Color(0x1F000000));
    final expected = {'dark': dark, 'light': light, 'no extensions': dark};
    for (final entry in themes.entries) {
      testWidgets(entry.key, (tester) async {
        await _pumpDrawer(tester, entry.value);
        _expectHeader(
          tester: tester,
          foreground: expected[entry.key]!.foreground,
          divider: expected[entry.key]!.divider,
        );
      });
    }
  });

  testWidgets('registered color roles are drawn', (tester) async {
    await _pumpDrawer(
      tester,
      ThemeData(
        extensions: [
          ScaffoldPalette.defaultPalette,
          ScaffoldDimens.defaultDimens,
          const ScaffoldColorRoles(
            sheetForeground: Color(0xFF101010),
            sheetDivider: Color(0xFF202020),
          ),
        ],
      ),
    );
    _expectHeader(
      tester: tester,
      foreground: const Color(0xFF101010),
      divider: const Color(0xFF202020),
    );
  });

  group('ResponsiveDrawer.show', () {
    const desktop = Size(1000, 800);
    const phone = Size(400, 800);
    const scrim = Color(0x99000000);

    ThemeData midnight(Brightness brightness) {
      final isDark = brightness == Brightness.dark;
      return ThemeData(
        brightness: brightness,
        extensions: [
          isDark ? Midnight.darkPalette : Midnight.lightPalette,
          isDark ? Midnight.darkColorRoles : Midnight.lightColorRoles,
          Midnight.shapes,
          ScaffoldDimens.defaultDimens,
        ],
      );
    }

    final plain = ThemeData(
      extensions: [
        ScaffoldPalette.defaultPalette,
        ScaffoldDimens.defaultDimens,
      ],
    );

    Future<void> open(WidgetTester tester, Size size, ThemeData theme) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      ResponsiveDrawer.show<void>(
        context: context,
        title: 'Title',
        children: const [Text('item')],
      );
      await tester.pumpAndSettle();
    }

    Color? barrier(WidgetTester tester) {
      return tester
          .widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier).last)
          .color
          .value;
    }

    Material panelMaterial(WidgetTester tester) {
      return tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ResponsiveDrawerPanel),
              matching: find.byType(Material),
            )
            .first,
      );
    }

    Material sheetMaterial(WidgetTester tester) {
      return tester.widget<Material>(
        find
            .ancestor(
              of: find.byType(BottomDrawer),
              matching: find.byType(Material),
            )
            .first,
      );
    }

    testWidgets('at desktop width opens a ResponsiveDrawerPanel', (
      tester,
    ) async {
      await open(tester, desktop, plain);
      expect(find.byType(ResponsiveDrawerPanel), findsOneWidget);
    });

    testWidgets('default desktop keeps black87 and a square panel', (
      tester,
    ) async {
      await open(tester, desktop, plain);
      expect(barrier(tester), Colors.black87);
      final material = panelMaterial(tester);
      expect(material.shape, isNull);
      expect(material.clipBehavior, Clip.none);
    });

    testWidgets('default mobile keeps the Material barrier and 16 px top', (
      tester,
    ) async {
      await open(tester, phone, plain);
      expect(barrier(tester), Colors.black54);
      expect(
        sheetMaterial(tester).shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      );
    });

    for (final brightness in Brightness.values) {
      final isDark = brightness == Brightness.dark;
      final palette = isDark ? Midnight.darkPalette : Midnight.lightPalette;
      final edge = (isDark ? Midnight.darkColorRoles : Midnight.lightColorRoles)
          .surfaceEdge!;

      testWidgets('midnight ${brightness.name} desktop panel', (tester) async {
        await open(tester, desktop, midnight(brightness));
        expect(barrier(tester), scrim);
        final material = panelMaterial(tester);
        expect(material.color, palette.deepBlueTertiary);
        expect(material.color, palette.deepBlueCardColor);
        expect(
          material.shape,
          RoundedRectangleBorder(
            side: BorderSide(color: edge),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(24),
            ),
          ),
        );
        expect(material.clipBehavior, Clip.antiAlias);
      });

      testWidgets('midnight ${brightness.name} mobile sheet', (tester) async {
        await open(tester, phone, midnight(brightness));
        expect(barrier(tester), scrim);
        final material = sheetMaterial(tester);
        expect(material.color, palette.deepBlueTertiary);
        expect(
          material.shape,
          RoundedRectangleBorder(
            side: BorderSide(color: edge),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
        );
      });
    }

    testWidgets(
      'a theme with only ScaffoldShapes(sheetRadius: 30) gets 30 px',
      (tester) async {
        final theme = ThemeData(
          extensions: [
            ScaffoldPalette.defaultPalette,
            ScaffoldDimens.defaultDimens,
            const ScaffoldShapes(sheetRadius: 30),
          ],
        );
        await open(tester, phone, theme);
        expect(
          sheetMaterial(tester).shape,
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
        );
        await tester.tapAt(const Offset(200, 20));
        await tester.pumpAndSettle();
        await open(tester, desktop, theme);
        expect(
          panelMaterial(tester).shape,
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
          ),
        );
      },
    );
  });
}
