import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

import 'wcag_contrast.dart';

class _Theme {
  const _Theme(this.name, this.palette, this.brightness, this.roles);

  final String name;
  final ScaffoldPalette palette;
  final Brightness brightness;
  final ScaffoldColorRoles roles;
}

const _themes = <_Theme>[
  _Theme(
    'default dark',
    ScaffoldPalette.defaultPalette,
    Brightness.dark,
    ScaffoldColorRoles.defaultColorRoles,
  ),
  _Theme(
    'default light',
    ScaffoldPalette.lightPalette,
    Brightness.light,
    ScaffoldColorRoles.lightColorRoles,
  ),
];

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

// As a foreground on light surfaces this is about 1.57:1. Plan 14-04 moves the
// foreground uses onto color roles and 14-05 gives them AA light values and
// reclassifies them.
const _accentFill = _Entry(
  _Role.excluded,
  'accent fill carrying dark text; foreground uses move to color roles in 14-04, AA values in 14-05',
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
  'accentOnSurface': _accentFill,
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

Map<String, dynamic> _scaffoldTokens() {
  final decoded =
      jsonDecode(File('design_tokens.json').readAsStringSync())
          as Map<String, dynamic>;
  return decoded['scaffold'] as Map<String, dynamic>;
}

Set<String> _keys(Map<String, dynamic> tokens, String group, String mode) =>
    ((tokens[group] as Map<String, dynamic>)[mode] as Map<String, dynamic>)
        .keys
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
  _ => throw ArgumentError(name),
};

Color _roleBackground(ScaffoldPalette palette, String name) => switch (name) {
  'inputForeground' => palette.grayPrimary,
  'sheetForeground' => palette.deepBlueTertiary,
  _ => throw ArgumentError(name),
};

void main() {
  test('every scaffold.palette and scaffold.colorRoles token is classified', () {
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
    for (final entry in {..._paletteClasses, ..._rolesClasses}.entries) {
      expect(entry.value.reason, isNotEmpty, reason: entry.key);
    }
  });

  for (final theme in _themes) {
    for (final entry in _paletteClasses.entries) {
      final role = entry.value.role;
      if (role != _Role.text && role != _Role.nonText) {
        continue;
      }
      final min = role == _Role.text ? kWcagText : kWcagNonText;
      for (final surface in _surfaces.entries) {
        test('${theme.name}: ${entry.key} on ${surface.key} >= $min', () {
          _expectPair(
            _paletteGetters[entry.key]!(theme.palette),
            surface.value(theme.palette),
            min,
          );
        });
      }
    }

    for (final surface in _surfaces.entries) {
      test(
        '${theme.name}: borderControl (roles) on ${surface.key} >= $kWcagNonText',
        () {
          _expectPair(
            theme.roles.borderControl,
            surface.value(theme.palette),
            kWcagNonText,
          );
        },
      );
      test(
        '${theme.name}: borderControl (fallback) on ${surface.key} >= $kWcagNonText',
        () {
          final roles = ScaffoldColorRoles.fallbackFor(
            theme.palette,
            theme.brightness,
          );
          _expectPair(
            roles.borderControl,
            surface.value(theme.palette),
            kWcagNonText,
          );
        },
      );
    }

    for (final name in ['inputForeground', 'sheetForeground']) {
      test('${theme.name}: $name (roles) on its surface >= $kWcagText', () {
        _expectPair(
          _roleColor(theme.roles, name),
          _roleBackground(theme.palette, name),
          kWcagText,
        );
      });
      test('${theme.name}: $name (fallback) on its surface >= $kWcagText', () {
        final roles = ScaffoldColorRoles.fallbackFor(
          theme.palette,
          theme.brightness,
        );
        _expectPair(
          _roleColor(roles, name),
          _roleBackground(theme.palette, name),
          kWcagText,
        );
      });
    }

    for (final source in ['roles', 'fallback']) {
      test('${theme.name}: sheetDivider ($source) has the sheet text polarity', () {
        final roles = source == 'roles'
            ? theme.roles
            : ScaffoldColorRoles.fallbackFor(theme.palette, theme.brightness);
        final panel = theme.palette.deepBlueTertiary;
        final line = Color.alphaBlend(roles.sheetDivider, panel);
        if (theme.brightness == Brightness.light) {
          expect(line.computeLuminance(), lessThan(panel.computeLuminance()));
        } else {
          expect(line.computeLuminance(), greaterThan(panel.computeLuminance()));
        }
      });
    }
  }

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
          expect(line.computeLuminance(), greaterThan(panel.computeLuminance()));
        }
      });
    }
  });
}
