import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';

import 'wcag_contrast.dart';

/// Fills that are never drawn as a foreground, so no foreground contrast applies.
const Map<String, String> _excludedFills = {
  'primary':
      'accent fill behind onPrimary; borders and icons use accentOnSurface',
  'secondary':
      'accent fill behind onSecondary; never drawn as text or a border',
  'tertiary': 'accent fill behind onTertiary; never drawn as text or a border',
};

Color _resolve<T extends Color?>(
  WidgetStateProperty<T> property, [
  Set<WidgetState> states = const {},
]) => property.resolve(states)!;

Color _shapeSide(WidgetStateProperty<OutlinedBorder?> shape) =>
    (shape.resolve(const {})! as RoundedRectangleBorder).side.color;

String _modeName(Brightness b) => b == Brightness.dark ? 'dark' : 'light';

void _expectRatio(
  String label,
  Color foreground,
  Color background,
  double minimum,
) {
  final ratio = contrastRatio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(minimum),
    reason:
        '$label: ${argbHex(foreground)} on ${argbHex(background)} is '
        '${ratio.toStringAsFixed(2)}:1, needs $minimum:1',
  );
}

void main() {
  group('exclusion list', () {
    test('is non-empty and every entry has a reason', () {
      expect(_excludedFills, isNotEmpty);
      for (final entry in _excludedFills.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      }
    });
  });

  for (final brightness in Brightness.values) {
    final mode = _modeName(brightness);
    final isDark = brightness == Brightness.dark;
    final theme = midnightTheme(brightness);
    final scheme = theme.colorScheme;
    final surfaces = <String, Color>{
      'surface': scheme.surface,
      'surfaceContainerHighest': scheme.surfaceContainerHighest,
      'scaffoldBackgroundColor': theme.scaffoldBackgroundColor,
    };

    group('ColorScheme', () {
      final pairs = <String, (Color, Color)>{
        'onPrimary on primary': (scheme.onPrimary, scheme.primary),
        'onSecondary on secondary': (scheme.onSecondary, scheme.secondary),
        'onTertiary on tertiary': (scheme.onTertiary, scheme.tertiary),
        'onError on error': (scheme.onError, scheme.error),
      };
      for (final entry in pairs.entries) {
        test('$mode: ${entry.key} >= $kWcagText', () {
          _expectRatio(entry.key, entry.value.$1, entry.value.$2, kWcagText);
        });
      }

      for (final surface in surfaces.entries) {
        test('$mode: onSurface on ${surface.key} >= $kWcagText', () {
          _expectRatio('onSurface', scheme.onSurface, surface.value, kWcagText);
        });
        test('$mode: onSurfaceVariant on ${surface.key} >= $kWcagText', () {
          _expectRatio(
            'onSurfaceVariant',
            scheme.onSurfaceVariant,
            surface.value,
            kWcagText,
          );
        });
        test('$mode: error text on ${surface.key} >= $kWcagText', () {
          _expectRatio('error', scheme.error, surface.value, kWcagText);
        });
        test('$mode: outline on ${surface.key} >= $kWcagNonText', () {
          _expectRatio('outline', scheme.outline, surface.value, kWcagNonText);
        });
      }
    });

    group('component themes', () {
      final textColors = <String, Color>{
        'tabBarTheme.labelColor': theme.tabBarTheme.labelColor!,
        'tabBarTheme.unselectedLabelColor':
            theme.tabBarTheme.unselectedLabelColor!,
        'elevated button foreground': _resolve(
          theme.elevatedButtonTheme.style!.foregroundColor!,
        ),
        'textTheme.bodyMedium': theme.textTheme.bodyMedium!.color!,
        'textTheme.bodySmall': theme.textTheme.bodySmall!.color!,
      };
      final nonTextColors = <String, Color>{
        'progressIndicatorTheme.color': theme.progressIndicatorTheme.color!,
        'tabBarTheme.indicatorColor': theme.tabBarTheme.indicatorColor!,
        'inputDecorationTheme focused border':
            theme.inputDecorationTheme.focusedBorder!.borderSide.color,
        'checkboxTheme.side': theme.checkboxTheme.side!.color,
        'elevated button shape side': _shapeSide(
          theme.elevatedButtonTheme.style!.shape!,
        ),
        'textSelectionTheme.cursorColor': theme.textSelectionTheme.cursorColor!,
        'navigationRailTheme selected icon':
            theme.navigationRailTheme.selectedIconTheme!.color!,
        'bottomNavigationBarTheme.selectedItemColor':
            theme.bottomNavigationBarTheme.selectedItemColor!,
        'datePickerTheme.todayBorder': theme.datePickerTheme.todayBorder!.color,
      };

      for (final surface in surfaces.entries) {
        for (final entry in textColors.entries) {
          test('$mode: ${entry.key} on ${surface.key} >= $kWcagText', () {
            _expectRatio(entry.key, entry.value, surface.value, kWcagText);
          });
        }
        for (final entry in nonTextColors.entries) {
          test('$mode: ${entry.key} on ${surface.key} >= $kWcagNonText', () {
            _expectRatio(entry.key, entry.value, surface.value, kWcagNonText);
          });
        }
      }

      test('$mode: text button foreground on its background >= $kWcagText', () {
        final style = theme.textButtonTheme.style!;
        _expectRatio(
          'text button',
          _resolve(style.foregroundColor!),
          _resolve(style.backgroundColor!),
          kWcagText,
        );
      });

      test('$mode: checkbox check on fill >= $kWcagText', () {
        const selected = {WidgetState.selected};
        _expectRatio(
          'checkbox',
          _resolve(theme.checkboxTheme.checkColor!, selected),
          _resolve(theme.checkboxTheme.fillColor!, selected),
          kWcagText,
        );
      });

      test(
        '$mode: date picker header foreground on background >= $kWcagText',
        () {
          _expectRatio(
            'header',
            theme.datePickerTheme.headerForegroundColor!,
            theme.datePickerTheme.headerBackgroundColor!,
            kWcagText,
          );
        },
      );

      test('$mode: selected day foreground on background >= $kWcagText', () {
        const selected = {WidgetState.selected};
        _expectRatio(
          'selected day',
          _resolve(theme.datePickerTheme.dayForegroundColor!, selected),
          _resolve(theme.datePickerTheme.dayBackgroundColor!, selected),
          kWcagText,
        );
      });

      test('$mode: divider is the sheet surface', () {
        final sheet = isDark ? Midnight.darkColors : Midnight.lightColors;
        expect(theme.dividerTheme.color, scheme.surfaceContainerHighest);
        expect(theme.dividerTheme.color, sheet.surfaceSheet);
      });
    });
  }
}
