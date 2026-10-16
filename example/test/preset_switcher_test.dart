import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

import 'package:frontend_scaffold_example/main.dart';

ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(HomePage)));

ScaffoldPalette _palette(WidgetTester tester) =>
    _theme(tester).extension<ScaffoldPalette>()!;

Future<void> _toggle(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switches default and midnight in both modes', (tester) async {
    await tester.pumpWidget(const ScaffoldExampleApp());
    await tester.pumpAndSettle();

    expect(_palette(tester), same(ScaffoldPalette.defaultPalette));

    await _toggle(tester, 'Midnight preset');
    expect(_palette(tester), same(Midnight.darkPalette));
    expect(
      _theme(tester).scaffoldBackgroundColor,
      Midnight.darkColors.surfaceBase,
    );

    await _toggle(tester, 'Light mode');
    expect(_palette(tester), same(Midnight.lightPalette));

    await _toggle(tester, 'Midnight preset');
    expect(_palette(tester), same(ScaffoldPalette.lightPalette));
  });

  testWidgets('theme overrides compose with the midnight preset',
      (tester) async {
    await tester.pumpWidget(const ScaffoldExampleApp());
    await tester.pumpAndSettle();

    await _toggle(tester, 'Midnight preset');
    await _toggle(tester, 'Theme overrides');

    final ScaffoldPalette palette = _palette(tester);
    expect(palette.lightGreenPrimary, Colors.orange);
    expect(palette.surfaceElevated, Midnight.darkPalette.surfaceElevated);
  });
}
