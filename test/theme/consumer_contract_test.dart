// A compile or test failure here is a consumer-visible break for apps that
// register these constants in their own const extension lists.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

const List<ThemeExtension<dynamic>> _lightExtensions = [
  ScaffoldPalette.lightPalette,
  ScaffoldDimens.defaultDimens,
];

const List<ThemeExtension<dynamic>> _darkExtensions = [
  ScaffoldPalette.defaultPalette,
  ScaffoldDimens.defaultDimens,
];

void main() {
  test('light registration resolves the same const instances', () {
    final ThemeData theme = ThemeData(extensions: _lightExtensions);
    expect(
      identical(theme.extension<ScaffoldPalette>(), ScaffoldPalette.lightPalette),
      isTrue,
    );
    expect(
      identical(theme.extension<ScaffoldDimens>(), ScaffoldDimens.defaultDimens),
      isTrue,
    );
  });

  test('dark registration resolves the same const instances', () {
    final ThemeData theme = ThemeData(extensions: _darkExtensions);
    expect(
      identical(theme.extension<ScaffoldPalette>(), ScaffoldPalette.defaultPalette),
      isTrue,
    );
    expect(
      identical(theme.extension<ScaffoldDimens>(), ScaffoldDimens.defaultDimens),
      isTrue,
    );
  });

  test('scaffoldThemeExtensions holds the dark palette then the dimens', () {
    expect(scaffoldThemeExtensions, hasLength(2));
    expect(identical(scaffoldThemeExtensions[0], ScaffoldPalette.defaultPalette), isTrue);
    expect(identical(scaffoldThemeExtensions[1], ScaffoldDimens.defaultDimens), isTrue);
  });
}
