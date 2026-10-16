import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

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

final Map<String, Color Function(ScaffoldPalette)> _textTokens = {
  'textPrimary': (p) => p.textPrimary,
};

void main() {
  for (final theme in _themes) {
    for (final token in _textTokens.entries) {
      for (final surface in _surfaces.entries) {
        test('${theme.name}: ${token.key} on ${surface.key} >= $kWcagText', () {
          final fg = token.value(theme.palette);
          final bg = surface.value(theme.palette);
          final ratio = contrastRatio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(kWcagText),
            reason:
                '${argbHex(fg)} on ${argbHex(bg)} is ${ratio.toStringAsFixed(2)}, '
                'needs $kWcagText',
          );
        });
      }
    }
  }
}
