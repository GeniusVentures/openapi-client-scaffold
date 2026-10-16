import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_motion_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_shadows.dart';
import 'package:frontend_scaffold/theme/scaffold_typography.dart';

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

  /// Resolves the registered [ScaffoldMotionTheme], falling back to
  /// [ScaffoldMotionTheme.defaultMotion] when the host app did not register one.
  ScaffoldMotionTheme get motion =>
      Theme.of(this).extension<ScaffoldMotionTheme>() ??
      ScaffoldMotionTheme.defaultMotion;

  /// Resolves the registered [ScaffoldTypography], falling back to
  /// [ScaffoldTypography.defaultTypography] when the host app did not register one.
  ScaffoldTypography get typography =>
      Theme.of(this).extension<ScaffoldTypography>() ??
      ScaffoldTypography.defaultTypography;

  /// Resolves the registered [ScaffoldColorRoles]. Without one it derives them
  /// from the resolved [palette] and [ThemeData.brightness] with
  /// [ScaffoldColorRoles.fallbackFor].
  ScaffoldColorRoles get colorRoles =>
      Theme.of(this).extension<ScaffoldColorRoles>() ??
      ScaffoldColorRoles.fallbackFor(palette, Theme.of(this).brightness);

  /// Resolves the registered [ScaffoldShadows], falling back to
  /// [ScaffoldShadows.lightShadows] or [ScaffoldShadows.defaultShadows]
  /// according to [ThemeData.brightness] when the host app did not register one.
  ScaffoldShadows get shadows {
    final theme = Theme.of(this);
    return theme.extension<ScaffoldShadows>() ??
        (theme.brightness == Brightness.light
            ? ScaffoldShadows.lightShadows
            : ScaffoldShadows.defaultShadows);
  }
}

/// Convenience list of the frontend_scaffold theme extensions to spread into
/// `ThemeData.extensions` (e.g. `ThemeData(extensions: [...scaffoldThemeExtensions])`).
const List<ThemeExtension<dynamic>> scaffoldThemeExtensions = [
  ScaffoldPalette.defaultPalette,
  ScaffoldDimens.defaultDimens,
];
