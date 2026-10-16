import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

import 'wcag_contrast.dart';

class _Theme {
  const _Theme(
    this.name,
    this.palette,
    this.brightness,
    this.roles, {
    this.checksFallback = false,
    this.extraSurfaces = const {},
  });

  final String name;
  final ScaffoldPalette palette;
  final Brightness brightness;
  final ScaffoldColorRoles roles;

  /// True when the theme relies on the derived roles of an unregistered
  /// [ScaffoldColorRoles]; a preset registers its own, so it has no fallback.
  final bool checksFallback;

  /// Backgrounds beyond the four palette surfaces.
  final Map<String, Color> extraSurfaces;
}

final _themes = <_Theme>[
  const _Theme(
    'default dark',
    ScaffoldPalette.defaultPalette,
    Brightness.dark,
    ScaffoldColorRoles.defaultColorRoles,
    checksFallback: true,
  ),
  const _Theme(
    'default light',
    ScaffoldPalette.lightPalette,
    Brightness.light,
    ScaffoldColorRoles.lightColorRoles,
    checksFallback: true,
  ),
  _Theme(
    'midnight dark',
    Midnight.darkPalette,
    Brightness.dark,
    Midnight.darkColorRoles,
    extraSurfaces: {
      'surfaceBase': Midnight.darkColors.surfaceBase,
      'surfaceSheet': Midnight.darkColors.surfaceSheet,
    },
  ),
  _Theme(
    'midnight light',
    Midnight.lightPalette,
    Brightness.light,
    Midnight.lightColorRoles,
    extraSurfaces: {
      'surfaceBase': Midnight.lightColors.surfaceBase,
      'surfaceSheet': Midnight.lightColors.surfaceSheet,
    },
  ),
];

/// The four palette surfaces plus the theme's extra surfaces.
Map<String, Color> _surfacesOf(_Theme theme) => {
  for (final surface in _surfaces.entries)
    surface.key: surface.value(theme.palette),
  ...theme.extraSurfaces,
};

final Map<String, Color Function(ScaffoldPalette)> _surfaces = {
  'surfaceElevated': (p) => p.surfaceElevated,
  'deepBlueCardColor': (p) => p.deepBlueCardColor,
  'grayPrimary': (p) => p.grayPrimary,
  'deepBlueTertiary': (p) => p.deepBlueTertiary,
};

enum _Role { surface, text, nonText, decorative, excluded }

class _Entry {
  const _Entry(this.role, this.reason);

  final _Role role;
  final String reason;
}

const _surface = _Entry(_Role.surface, 'background checked against');
const _text = _Entry(_Role.text, 'text, 4.5:1');

const _accentFill = _Entry(
  _Role.excluded,
  'accent fill carrying dark text; foreground uses read the colorRoles accents',
);

const _paletteClasses = <String, _Entry>{
  'surfaceElevated': _surface,
  'deepBlueCardColor': _surface,
  'grayPrimary': _surface,
  'deepBlueTertiary': _surface,
  'textPrimary': _text,
  'textSecondary': _text,
  'gray500': _text,
  'statusSuccess': _text,
  'statusError': _text,
  'statusWarningText': _text,
  'focusRingColor': _Entry(_Role.nonText, 'focus indicator, 3:1'),
  'borderGrey': _Entry(
    _Role.nonText,
    'control border: text-field enabled border via the color-role fallback, and the chart frame',
  ),
  'blue500': _Entry(
    _Role.nonText,
    'status and loading dots only, no text call site',
  ),
  'lightGreenPrimary': _accentFill,
  'lightGreenSecondary': _accentFill,
  'borderSubtle': _Entry(_Role.excluded, 'decorative hairline'),
  'skeletonBaseColor': _Entry(_Role.excluded, 'decorative loading placeholder'),
  'skeletonShimmerColor': _Entry(
    _Role.excluded,
    'decorative loading placeholder',
  ),
  'disabledOverlayColor': _Entry(_Role.excluded, 'disabled state is exempt'),
  'dragFeedbackBackground': _Entry(
    _Role.excluded,
    'drag-ghost surface; its text uses textPrimary',
  ),
  'dropZoneHighlight': _Entry(
    _Role.excluded,
    'translucent state wash supplementing the drop-target border and icon',
  ),
  'dropZoneRejected': _Entry(
    _Role.excluded,
    'translucent state wash supplementing the drop-target border and icon',
  ),
};

const _rolesClasses = <String, _Entry>{
  'accent': _accentFill,
  'accentOnSurface': _Entry(
    _Role.nonText,
    'accent icons, borders, lines, dots and state graphics, 3:1',
  ),
  'accentSecondaryOnSurface': _Entry(
    _Role.nonText,
    'secondary accent icon, 3:1',
  ),
  'accentTextOnSurface': _Entry(
    _Role.text,
    'accent text (links, citation marker, group label), 4.5:1',
  ),
  'borderControl': _Entry(_Role.nonText, 'control border, 3:1'),
  'inputForeground': _Entry(
    _Role.text,
    'typed text on the field fill (grayPrimary), 4.5:1',
  ),
  'sheetForeground': _Entry(
    _Role.text,
    'drawer title and close icon on the panel (deepBlueTertiary), 4.5:1 covers the icon 3:1',
  ),
  'sheetDivider': _Entry(
    _Role.decorative,
    'decorative hairline, exempt from 1.4.11; checked for polarity only',
  ),
};

const _presetAccentFill = _Entry(
  _Role.excluded,
  'fill or gradient stop; its foreground pair is checked in 15-04',
);
const _presetForegroundOnFill = _Entry(
  _Role.excluded,
  'foreground on a fill, checked as a pair in 15-04',
);

const _presetColorClasses = <String, _Entry>{
  'surfaceBase': _surface,
  'surfaceSheet': _surface,
  'accentBadgeText': _text,
  'surfaceSunken': _Entry(
    _Role.excluded,
    'recessed track or well that holds no text in the preset',
  ),
  'scrim': _Entry(_Role.excluded, 'modal barrier'),
  'accentPrimary': _presetAccentFill,
  'accentPrimaryStrong': _presetAccentFill,
  'accentSecondary': _presetAccentFill,
  'accentSecondaryStrong': _presetAccentFill,
  'accentSecondaryBright': _presetAccentFill,
  'accentTertiary': _presetAccentFill,
  'textOnAccent': _presetForegroundOnFill,
  'textOnError': _presetForegroundOnFill,
  'textTertiary': _Entry(
    _Role.excluded,
    'disabled label, exempt under WCAG 1.4.3',
  ),
  'borderStrong': _Entry(_Role.excluded, 'decorative hairline'),
  'borderControlOnAccent': _Entry(
    _Role.excluded,
    'edge on a translucent accent track, no consumer yet',
  ),
  'statusWarning': _Entry(_Role.excluded, 'warning fill'),
  'selection': _Entry(_Role.excluded, 'text selection highlight'),
};

final Map<String, Color Function(MidnightColors)> _presetTextGetters = {
  'accentBadgeText': (c) => c.accentBadgeText,
};

final Map<String, Color Function(ScaffoldPalette)> _paletteGetters = {
  'surfaceElevated': (p) => p.surfaceElevated,
  'deepBlueCardColor': (p) => p.deepBlueCardColor,
  'grayPrimary': (p) => p.grayPrimary,
  'deepBlueTertiary': (p) => p.deepBlueTertiary,
  'textPrimary': (p) => p.textPrimary,
  'textSecondary': (p) => p.textSecondary,
  'gray500': (p) => p.gray500,
  'statusSuccess': (p) => p.statusSuccess,
  'statusError': (p) => p.statusError,
  'statusWarningText': (p) => p.statusWarningText,
  'focusRingColor': (p) => p.focusRingColor,
  'borderGrey': (p) => p.borderGrey,
  'blue500': (p) => p.blue500,
};

Map<String, dynamic> _scaffoldTokens([String file = 'design_tokens.json']) {
  final decoded =
      jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>;
  return decoded['scaffold'] as Map<String, dynamic>;
}

Set<String> _presetColorKeys(String mode) {
  final decoded =
      jsonDecode(File('tokens/midnight.json').readAsStringSync())
          as Map<String, dynamic>;
  final colors =
      (decoded['preset'] as Map<String, dynamic>)['colors']
          as Map<String, dynamic>;
  return (colors[mode] as Map<String, dynamic>).keys.toSet();
}

Set<String> _keys(Map<String, dynamic> tokens, String group, String mode) =>
    ((tokens[group] as Map<String, dynamic>)[mode] as Map<String, dynamic>).keys
        .toSet();

void _expectPair(Color fg, Color bg, double min) {
  final ratio = contrastRatio(fg, bg);
  expect(
    ratio,
    greaterThanOrEqualTo(min),
    reason:
        '${argbHex(fg)} on ${argbHex(bg)} is ${ratio.toStringAsFixed(2)}, '
        'needs $min',
  );
}

Color _roleColor(ScaffoldColorRoles roles, String name) => switch (name) {
  'inputForeground' => roles.inputForeground,
  'sheetForeground' => roles.sheetForeground,
  'accentOnSurface' => roles.accentOnSurface,
  'accentSecondaryOnSurface' => roles.accentSecondaryOnSurface,
  'accentTextOnSurface' => roles.accentTextOnSurface,
  _ => throw ArgumentError(name),
};

Color _roleBackground(ScaffoldPalette palette, String name) => switch (name) {
  'inputForeground' => palette.grayPrimary,
  'sheetForeground' => palette.deepBlueTertiary,
  _ => throw ArgumentError(name),
};

void main() {
  test(
    'every scaffold.palette and scaffold.colorRoles token is classified',
    () {
      final tokens = _scaffoldTokens();
      for (final mode in ['dark', 'light']) {
        expect(
          _paletteClasses.keys.toSet(),
          _keys(tokens, 'palette', mode),
          reason: 'scaffold.palette.$mode',
        );
        expect(
          _rolesClasses.keys.toSet(),
          _keys(tokens, 'colorRoles', mode),
          reason: 'scaffold.colorRoles.$mode',
        );
      }
      final midnight = _scaffoldTokens('tokens/midnight.json');
      for (final mode in ['dark', 'light']) {
        expect(
          _paletteClasses.keys.toSet(),
          _keys(midnight, 'palette', mode),
          reason: 'midnight scaffold.palette.$mode',
        );
        expect(
          _rolesClasses.keys.toSet(),
          _keys(midnight, 'colorRoles', mode),
          reason: 'midnight scaffold.colorRoles.$mode',
        );
        expect(
          _presetColorClasses.keys.toSet(),
          _presetColorKeys(mode),
          reason: 'midnight preset.colors.$mode',
        );
      }
      for (final entry in {
        ..._paletteClasses,
        ..._rolesClasses,
        ..._presetColorClasses,
      }.entries) {
        expect(entry.value.reason, isNotEmpty, reason: entry.key);
      }
    },
  );

  for (final theme in _themes) {
    for (final entry in _paletteClasses.entries) {
      final role = entry.value.role;
      if (role != _Role.text && role != _Role.nonText) {
        continue;
      }
      final min = role == _Role.text ? kWcagText : kWcagNonText;
      for (final surface in _surfacesOf(theme).entries) {
        test('${theme.name}: ${entry.key} on ${surface.key} >= $min', () {
          _expectPair(
            _paletteGetters[entry.key]!(theme.palette),
            surface.value,
            min,
          );
        });
      }
    }

    for (final surface in _surfacesOf(theme).entries) {
      test(
        '${theme.name}: borderControl (roles) on ${surface.key} >= $kWcagNonText',
        () {
          _expectPair(theme.roles.borderControl, surface.value, kWcagNonText);
        },
      );
      if (theme.checksFallback) {
        test(
          '${theme.name}: borderControl (fallback) on ${surface.key} >= $kWcagNonText',
          () {
            final roles = ScaffoldColorRoles.fallbackFor(
              theme.palette,
              theme.brightness,
            );
            _expectPair(roles.borderControl, surface.value, kWcagNonText);
          },
        );
      }
    }

    for (final name in ['inputForeground', 'sheetForeground']) {
      test('${theme.name}: $name (roles) on its surface >= $kWcagText', () {
        _expectPair(
          _roleColor(theme.roles, name),
          _roleBackground(theme.palette, name),
          kWcagText,
        );
      });
      if (theme.checksFallback) {
        test(
          '${theme.name}: $name (fallback) on its surface >= $kWcagText',
          () {
            final roles = ScaffoldColorRoles.fallbackFor(
              theme.palette,
              theme.brightness,
            );
            _expectPair(
              _roleColor(roles, name),
              _roleBackground(theme.palette, name),
              kWcagText,
            );
          },
        );
      }
    }

    for (final name in [
      'accentOnSurface',
      'accentSecondaryOnSurface',
      'accentTextOnSurface',
    ]) {
      final min = _rolesClasses[name]!.role == _Role.text
          ? kWcagText
          : kWcagNonText;
      for (final surface in _surfacesOf(theme).entries) {
        test('${theme.name}: $name (roles) on ${surface.key} >= $min', () {
          _expectPair(_roleColor(theme.roles, name), surface.value, min);
        });
        if (theme.checksFallback) {
          test('${theme.name}: $name (fallback) on ${surface.key} >= $min', () {
            final roles = ScaffoldColorRoles.fallbackFor(
              theme.palette,
              theme.brightness,
            );
            _expectPair(_roleColor(roles, name), surface.value, min);
          });
        }
      }
    }

    if (theme.name.startsWith('midnight')) {
      final colors = theme.brightness == Brightness.dark
          ? Midnight.darkColors
          : Midnight.lightColors;
      for (final entry in _presetColorClasses.entries) {
        if (entry.value.role != _Role.text) {
          continue;
        }
        for (final surface in _surfacesOf(theme).entries) {
          test(
            '${theme.name}: ${entry.key} (preset) on ${surface.key} >= $kWcagText',
            () {
              _expectPair(
                _presetTextGetters[entry.key]!(colors),
                surface.value,
                kWcagText,
              );
            },
          );
        }
      }
    }

    for (final source in ['roles', if (theme.checksFallback) 'fallback']) {
      test(
        '${theme.name}: sheetDivider ($source) has the sheet text polarity',
        () {
          final roles = source == 'roles'
              ? theme.roles
              : ScaffoldColorRoles.fallbackFor(theme.palette, theme.brightness);
          final panel = theme.palette.deepBlueTertiary;
          final line = Color.alphaBlend(roles.sheetDivider, panel);
          if (theme.brightness == Brightness.light) {
            expect(line.computeLuminance(), lessThan(panel.computeLuminance()));
          } else {
            expect(
              line.computeLuminance(),
              greaterThan(panel.computeLuminance()),
            );
          }
        },
      );
    }
  }

  test('midnightExtensions registers ScaffoldColorRoles in both modes', () {
    for (final brightness in Brightness.values) {
      expect(
        midnightExtensions(brightness).whereType<ScaffoldColorRoles>(),
        hasLength(1),
        reason: '$brightness',
      );
    }
  });

  group('unregistered colorRoles are readable on the palette in use', () {
    // ThemeData brightness x registered palette, no ScaffoldColorRoles registered.
    final cases = <String, ThemeData>{
      'light theme, no palette': ThemeData(brightness: Brightness.light),
      'dark theme, no palette': ThemeData(brightness: Brightness.dark),
      'light theme, light palette': ThemeData(
        brightness: Brightness.light,
        extensions: const [ScaffoldPalette.lightPalette],
      ),
      'dark theme, dark palette': ThemeData(
        brightness: Brightness.dark,
        extensions: const [ScaffoldPalette.defaultPalette],
      ),
    };
    for (final entry in cases.entries) {
      testWidgets(entry.key, (tester) async {
        late BuildContext captured;
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox();
              },
            ),
          ),
        );
        final palette = captured.palette;
        final roles = captured.colorRoles;
        for (final name in ['inputForeground', 'sheetForeground']) {
          _expectPair(
            _roleColor(roles, name),
            _roleBackground(palette, name),
            kWcagText,
          );
        }
        final panel = palette.deepBlueTertiary;
        final line = Color.alphaBlend(roles.sheetDivider, panel);
        if (panel.computeLuminance() > 0.5) {
          expect(line.computeLuminance(), lessThan(panel.computeLuminance()));
        } else {
          expect(
            line.computeLuminance(),
            greaterThan(panel.computeLuminance()),
          );
        }
      });
    }
  });
}
