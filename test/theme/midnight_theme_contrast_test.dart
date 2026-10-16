import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';

import 'wcag_contrast.dart';

/// Fills that are never drawn as a foreground, so no foreground contrast applies.
const Map<String, String> _excludedFills = {
  'primary':
      'accent fill behind onPrimary; borders and icons use accentOnSurface',
  'secondary':
      'accent fill behind onSecondary; never drawn as text or a border',
  'tertiary': 'accent fill behind onTertiary; never drawn as text or a border',
};

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
  }
}
