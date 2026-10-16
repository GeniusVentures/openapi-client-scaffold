import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/bottom_drawer/bottom_drawer.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

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
      extensions: [ScaffoldPalette.defaultPalette, ScaffoldDimens.defaultDimens],
    ),
    'light': ThemeData(
      brightness: Brightness.light,
      extensions: [ScaffoldPalette.lightPalette, ScaffoldDimens.defaultDimens],
    ),
    'no extensions': ThemeData(),
  };

  group('defaults are white and white at 12 percent', () {
    for (final entry in themes.entries) {
      testWidgets(entry.key, (tester) async {
        await _pumpDrawer(tester, entry.value);
        _expectHeader(
          tester: tester,
          foreground: const Color(0xFFFFFFFF),
          divider: const Color(0x1FFFFFFF),
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
}
