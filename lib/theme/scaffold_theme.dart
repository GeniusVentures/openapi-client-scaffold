import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

/// Lookup helpers for the frontend_scaffold Material 3 theme extensions.
extension ScaffoldThemeX on BuildContext {
  /// Resolves the registered [ScaffoldPalette], falling back to
  /// [ScaffoldPalette.defaultPalette] when the host app did not register one.
  ScaffoldPalette get palette =>
      Theme.of(this).extension<ScaffoldPalette>() ??
      ScaffoldPalette.defaultPalette;

  /// Resolves the registered [ScaffoldDimens], falling back to
  /// [ScaffoldDimens.defaultDimens] when the host app did not register one.
  ScaffoldDimens get dimens =>
      Theme.of(this).extension<ScaffoldDimens>() ?? ScaffoldDimens.defaultDimens;
}

/// Convenience list of the frontend_scaffold theme extensions to spread into
/// `ThemeData.extensions` (e.g. `ThemeData(extensions: [...scaffoldThemeExtensions])`).
const List<ThemeExtension<dynamic>> scaffoldThemeExtensions = [
  ScaffoldPalette.defaultPalette,
  ScaffoldDimens.defaultDimens,
];
