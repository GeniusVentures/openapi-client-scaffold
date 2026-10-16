/// One-call opt-in to the midnight preset. Deep-import this file; the package
/// barrel does not export it.
///
/// ```dart
/// MaterialApp(
///   theme: midnightTheme(Brightness.light),
///   darkTheme: midnightTheme(Brightness.dark),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';

/// The [ThemeData] of the midnight preset for [brightness].
ThemeData midnightTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    extensions: midnightExtensions(brightness),
  );
}

const List<ThemeExtension<dynamic>> _darkExtensions = [
  Midnight.darkPalette,
  Midnight.darkColorRoles,
];
const List<ThemeExtension<dynamic>> _lightExtensions = [
  Midnight.lightPalette,
  Midnight.lightColorRoles,
];

/// The scaffold theme extensions of the midnight preset for [brightness].
List<ThemeExtension<dynamic>> midnightExtensions(Brightness brightness) {
  return brightness == Brightness.dark ? _darkExtensions : _lightExtensions;
}
