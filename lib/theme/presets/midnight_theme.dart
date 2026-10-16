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
  final isDark = brightness == Brightness.dark;
  final p = isDark ? Midnight.darkPalette : Midnight.lightPalette;
  final r = isDark ? Midnight.darkColorRoles : Midnight.lightColorRoles;
  final c = isDark ? Midnight.darkColors : Midnight.lightColors;

  final colorScheme = isDark
      ? ColorScheme.dark(
          primary: c.accentPrimary,
          onPrimary: c.textOnAccent,
          secondary: c.accentSecondary,
          onSecondary: c.textOnAccent,
          tertiary: c.accentTertiary,
          // White on the tertiary fill is 2.42:1; textOnAccent clears AA.
          onTertiary: c.textOnAccent,
          surface: p.surfaceElevated,
          onSurface: p.textPrimary,
          surfaceContainerHighest: c.surfaceSheet,
          error: p.statusError,
          // White on the dark red is 3.27:1; textOnError is 6.05:1.
          onError: c.textOnError,
          // The raw accent is 1.96:1 on white in light; accentOnSurface is at least 4.76:1.
          outline: r.accentOnSurface,
          outlineVariant: c.surfaceSheet,
        )
      : ColorScheme.light(
          primary: c.accentPrimary,
          onPrimary: c.textOnAccent,
          secondary: c.accentSecondary,
          onSecondary: c.textOnAccent,
          tertiary: c.accentTertiary,
          // White on the tertiary fill is 2.42:1; textOnAccent clears AA.
          onTertiary: c.textOnAccent,
          surface: p.surfaceElevated,
          onSurface: p.textPrimary,
          surfaceContainerHighest: c.surfaceSheet,
          // The dark red as text on white is 3.27:1; statusError is 6.27:1.
          error: p.statusError,
          // White on the dark red is 3.27:1; textOnError is 8.31:1.
          onError: c.textOnError,
          // The raw accent is 1.96:1 on white; accentOnSurface is at least 4.76:1.
          outline: r.accentOnSurface,
          outlineVariant: c.surfaceSheet,
        );

  final t = Midnight.textTheme
      .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary)
      .copyWith(
        bodySmall: Midnight.textTheme.bodySmall?.copyWith(
          color: p.textSecondary,
        ),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.surfaceBase,
    fontFamily: Midnight.typeScale.sansFontFamily,
    textTheme: t,
    extensions: midnightExtensions(brightness),
  );
}

const List<ThemeExtension<dynamic>> _darkExtensions = [
  Midnight.darkPalette,
  Midnight.dimens,
  Midnight.darkColorRoles,
  Midnight.darkShadows,
  Midnight.motion,
  Midnight.typography,
];
const List<ThemeExtension<dynamic>> _lightExtensions = [
  Midnight.lightPalette,
  Midnight.dimens,
  Midnight.lightColorRoles,
  Midnight.lightShadows,
  Midnight.motion,
  Midnight.typography,
];

/// The scaffold theme extensions of the midnight preset for [brightness].
List<ThemeExtension<dynamic>> midnightExtensions(Brightness brightness) {
  return brightness == Brightness.dark ? _darkExtensions : _lightExtensions;
}
