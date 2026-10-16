import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_gradients.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<ScaffoldPalette> _paletteUnder(
  WidgetTester tester,
  ThemeData theme,
) async {
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
      expect(
        identical(theme.extension<ScaffoldPalette>(), Midnight.darkPalette),
        isTrue,
      );
    });

    test('registers the light palette for Brightness.light', () {
      final theme = midnightTheme(Brightness.light);
      expect(
        identical(theme.extension<ScaffoldPalette>(), Midnight.lightPalette),
        isTrue,
      );
    });

    test('keeps the requested brightness and Material 3', () {
      for (final brightness in Brightness.values) {
        final theme = midnightTheme(brightness);
        expect(theme.brightness, brightness);
        expect(theme.useMaterial3, isTrue);
      }
    });

    testWidgets('light palette resolves through context.palette', (
      tester,
    ) async {
      final palette = await _paletteUnder(
        tester,
        midnightTheme(Brightness.light),
      );
      expect(palette.surfaceElevated, const Color(0xFFFFFFFF));
      expect(palette.textPrimary, const Color(0xFF10131A));
    });

    testWidgets('dark palette resolves through context.palette', (
      tester,
    ) async {
      final palette = await _paletteUnder(
        tester,
        midnightTheme(Brightness.dark),
      );
      expect(palette.surfaceElevated, const Color(0xFF0C0E14));
      expect(palette.textPrimary, const Color(0xFFFFFFFF));
    });
  });

  group('midnightTheme page and type', () {
    for (final brightness in Brightness.values) {
      final isDark = brightness == Brightness.dark;
      final colors = isDark ? Midnight.darkColors : Midnight.lightColors;
      final palette = isDark ? Midnight.darkPalette : Midnight.lightPalette;

      test('${brightness.name}: scaffold background is surfaceBase', () {
        expect(
          midnightTheme(brightness).scaffoldBackgroundColor,
          colors.surfaceBase,
        );
      });

      test('${brightness.name}: text theme is Inter and colored', () {
        final text = midnightTheme(brightness).textTheme;
        expect(text.bodyMedium?.fontFamily, 'Inter');
        expect(text.bodyMedium?.fontSize, 16);
        expect(text.bodyMedium?.color, palette.textPrimary);
        expect(text.bodySmall?.color, palette.textSecondary);
        expect(text.labelLarge, isNotNull);
        expect(text.labelLarge?.fontFamily, 'Inter');
      });
    }
  });

  group('midnightTheme widget smoke', () {
    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name}: Material widgets pump cleanly', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: midnightTheme(brightness),
            home: DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(title: const Text('Title')),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: 0,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Elevated'),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Text'),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Outlined'),
                          ),
                          FilledButton(
                            onPressed: () {},
                            child: const Text('Filled'),
                          ),
                          const TextField(
                            decoration: InputDecoration(labelText: 'Label'),
                          ),
                          Checkbox(value: true, onChanged: (_) {}),
                          const LinearProgressIndicator(value: 0.5),
                          const Divider(),
                          const TabBar(
                            tabs: [
                              Tab(text: 'One'),
                              Tab(text: 'Two'),
                            ],
                          ),
                          SearchBar(hintText: 'Search'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('${brightness.name}: DatePickerDialog pumps cleanly', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: midnightTheme(brightness),
            home: DatePickerDialog(
              initialDate: DateTime(2026, 10, 16),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('midnightTheme registers every scaffold extension', () {
    for (final brightness in Brightness.values) {
      final isDark = brightness == Brightness.dark;
      testWidgets('${brightness.name} groups resolve through the context', (
        tester,
      ) async {
        late BuildContext captured;
        await tester.pumpWidget(
          MaterialApp(
            theme: midnightTheme(brightness),
            home: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(identical(captured.dimens, Midnight.dimens), isTrue);
        expect(
          identical(
            captured.colorRoles,
            isDark ? Midnight.darkColorRoles : Midnight.lightColorRoles,
          ),
          isTrue,
        );
        expect(
          identical(
            captured.shadows,
            isDark ? Midnight.darkShadows : Midnight.lightShadows,
          ),
          isTrue,
        );
        expect(
          identical(
            captured.gradients,
            isDark
                ? Midnight.darkScaffoldGradients
                : Midnight.lightScaffoldGradients,
          ),
          isTrue,
        );
        expect(identical(captured.motion, Midnight.motion), isTrue);
        expect(identical(captured.typography, Midnight.typography), isTrue);
      });
    }
  });

  test('each mode registers exactly one ScaffoldGradients', () {
    for (final brightness in Brightness.values) {
      final count = midnightExtensions(
        brightness,
      ).whereType<ScaffoldGradients>().length;
      expect(count, 1, reason: brightness.name);
    }
  });

  test('the default extension list is unchanged', () {
    expect(scaffoldThemeExtensions, hasLength(2));
    expect(
      identical(scaffoldThemeExtensions[0], ScaffoldPalette.defaultPalette),
      isTrue,
    );
    expect(
      identical(scaffoldThemeExtensions[1], ScaffoldDimens.defaultDimens),
      isTrue,
    );
  });

  test('the package barrel does not export the preset', () {
    final barrel = File('lib/frontend_scaffold.dart').readAsStringSync();
    expect(barrel.contains('theme/presets'), isFalse);
  });
}
