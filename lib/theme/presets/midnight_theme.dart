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
  const d = Midnight.dimens;
  const s = Midnight.scale;

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

  // ThemeData applies fontFamily only to its own default text theme, so the
  // styles reused by appBarTheme and tabBarTheme need it set here.
  final base = Midnight.textTheme.apply(
    fontFamily: Midnight.typeScale.sansFontFamily,
    bodyColor: p.textPrimary,
    displayColor: p.textPrimary,
  );
  final t = base.copyWith(
    bodySmall: base.bodySmall?.copyWith(color: p.textSecondary),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.surfaceBase,
    fontFamily: Midnight.typeScale.sansFontFamily,
    textTheme: t,
    extensions: midnightExtensions(brightness),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: r.accentOnSurface,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: t.titleMedium,
      unselectedLabelStyle: t.titleMedium,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: p.textPrimary,
      dividerColor: Colors.transparent,
      // The source's fixed grey is 3.3:1 on white; textSecondary clears 4.5:1.
      unselectedLabelColor: p.textSecondary,
      indicatorColor: r.accentOnSurface,
    ),
    datePickerTheme: DatePickerThemeData(
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: r.accentOnSurface, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: r.accentOnSurface, width: 1),
        ),
      ),
      backgroundColor: p.surfaceElevated,
      headerBackgroundColor: c.accentPrimaryStrong,
      // White on accentPrimaryStrong is 2.56:1; textOnAccent is 7.74:1.
      headerForegroundColor: c.textOnAccent,
      todayBorder: BorderSide(color: r.accentOnSurface, width: 2),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return c.accentPrimaryStrong;
        }
        return c.accentPrimary.withAlpha(33);
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return c.textOnAccent;
        }
        if (states.contains(WidgetState.disabled)) {
          return c.textTertiary;
        }
        return p.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return c.accentPrimaryStrong;
        }
        if (states.contains(WidgetState.dragged)) {
          return c.accentPrimary.withAlpha(51);
        }
        return Colors.transparent;
      }),
      rangeSelectionBackgroundColor: c.accentPrimary.withAlpha(38),
      rangeSelectionOverlayColor: WidgetStatePropertyAll(
        c.accentPrimary.withAlpha(51),
      ),
    ),
    appBarTheme: AppBarTheme(
      iconTheme: const IconThemeData(size: 24),
      titleTextStyle: t.titleLarge,
      titleSpacing: d.space4,
      centerTitle: true,
      surfaceTintColor: p.surfaceElevated,
      backgroundColor: p.surfaceElevated,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: d.space8),
        textStyle: t.titleMedium,
        foregroundColor: p.textPrimary,
      ),
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      borderRadius: BorderRadius.circular(d.borderRadiusButton),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: d.space8),
        textStyle: t.titleMedium,
      ),
    ),
    dialogTheme: DialogThemeData(actionsPadding: EdgeInsets.all(d.space6)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(t.titleMedium),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: d.space8, vertical: s.space10),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            side: BorderSide(color: r.accentOnSurface, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(d.borderRadiusCard)),
          ),
        ),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.textTertiary;
          }
          return p.textPrimary;
        }),
        iconSize: const WidgetStatePropertyAll(20),
        iconColor: WidgetStatePropertyAll(p.textPrimary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: EdgeInsets.all(s.space10),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(d.borderRadiusCard)),
        borderSide: BorderSide(color: r.accentOnSurface),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(d.borderRadiusCard)),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(t.titleMedium),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: d.space12, vertical: s.space10),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(d.borderRadiusCard)),
          ),
        ),
        backgroundColor: WidgetStatePropertyAll(c.surfaceSheet),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.textTertiary;
          }
          return p.textPrimary;
        }),
        iconSize: const WidgetStatePropertyAll(16),
        iconColor: WidgetStatePropertyAll(p.textPrimary),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: d.space6),
      ),
      textStyle: WidgetStatePropertyAll(t.bodyLarge),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(s.radiusXs)),
        ),
      ),
      backgroundColor: WidgetStatePropertyAll(p.surfaceElevated),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: r.accentOnSurface,
      selectionColor: c.selection,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: t.bodyLarge,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.surfaceElevated),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(d.radiusPill)),
          borderSide: BorderSide(color: r.accentOnSurface),
        ),
        contentPadding: EdgeInsets.only(left: s.space10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(d.radiusPill)),
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surfaceElevated,
      indicatorColor: Colors.transparent,
      selectedLabelTextStyle: TextStyle(color: r.accentOnSurface),
      labelType: NavigationRailLabelType.none,
      useIndicator: false,
      selectedIconTheme: IconThemeData(color: r.accentOnSurface, size: 30),
      unselectedIconTheme: IconThemeData(
        color: p.textPrimary,
        opacity: 1,
        size: 30,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: r.accentOnSurface,
      selectedIconTheme: IconThemeData(size: 35, color: r.accentOnSurface),
      unselectedIconTheme: IconThemeData(size: 35, color: p.textPrimary),
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: r.accentOnSurface),
      // White on accentPrimaryStrong is 2.56:1; textOnAccent is 7.74:1.
      checkColor: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return c.textOnAccent;
      }),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return c.accentPrimaryStrong;
      }),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.surfaceContainerHighest),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHighest,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(d.borderRadiusCard)),
          ),
        ),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(textStyle: WidgetStatePropertyAll(t.bodySmall)),
    ),
    buttonTheme: const ButtonThemeData(padding: EdgeInsets.zero),
  );
}

const List<ThemeExtension<dynamic>> _darkExtensions = [
  Midnight.darkPalette,
  Midnight.dimens,
  Midnight.darkColorRoles,
  Midnight.darkShadows,
  Midnight.darkScaffoldGradients,
  Midnight.motion,
  Midnight.typography,
];
const List<ThemeExtension<dynamic>> _lightExtensions = [
  Midnight.lightPalette,
  Midnight.dimens,
  Midnight.lightColorRoles,
  Midnight.lightShadows,
  Midnight.lightScaffoldGradients,
  Midnight.motion,
  Midnight.typography,
];

/// The scaffold theme extensions of the midnight preset for [brightness].
List<ThemeExtension<dynamic>> midnightExtensions(Brightness brightness) {
  return brightness == Brightness.dark ? _darkExtensions : _lightExtensions;
}
