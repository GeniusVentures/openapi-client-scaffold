import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<ScaffoldPalette> _paletteUnder(WidgetTester tester, ThemeData theme) async {
  late ScaffoldPalette palette;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          palette = context.palette;
          return const SizedBox();
        },
      ),
    ),
  );
  return palette;
}

void main() {
  group('midnightTheme', () {
    test('registers the dark palette for Brightness.dark', () {
      final theme = midnightTheme(Brightness.dark);
      expect(identical(theme.extension<ScaffoldPalette>(), Midnight.darkPalette), isTrue);
    });

    test('registers the light palette for Brightness.light', () {
      final theme = midnightTheme(Brightness.light);
      expect(identical(theme.extension<ScaffoldPalette>(), Midnight.lightPalette), isTrue);
    });

    test('keeps the requested brightness and Material 3', () {
      for (final brightness in Brightness.values) {
        final theme = midnightTheme(brightness);
        expect(theme.brightness, brightness);
        expect(theme.useMaterial3, isTrue);
      }
    });

    testWidgets('light palette resolves through context.palette', (tester) async {
      final palette = await _paletteUnder(tester, midnightTheme(Brightness.light));
      expect(palette.surfaceElevated, const Color(0xFFFFFFFF));
      expect(palette.textPrimary, const Color(0xFF10131A));
    });

    testWidgets('dark palette resolves through context.palette', (tester) async {
      final palette = await _paletteUnder(tester, midnightTheme(Brightness.dark));
      expect(palette.surfaceElevated, const Color(0xFF0C0E14));
      expect(palette.textPrimary, const Color(0xFFFFFFFF));
    });
  });

  test('the default extension list is unchanged', () {
    expect(scaffoldThemeExtensions, hasLength(2));
    expect(identical(scaffoldThemeExtensions[0], ScaffoldPalette.defaultPalette), isTrue);
    expect(identical(scaffoldThemeExtensions[1], ScaffoldDimens.defaultDimens), isTrue);
  });

  test('the package barrel does not export the preset', () {
    final barrel = File('lib/frontend_scaffold.dart').readAsStringSync();
    expect(barrel.contains('theme/presets'), isFalse);
  });
}
