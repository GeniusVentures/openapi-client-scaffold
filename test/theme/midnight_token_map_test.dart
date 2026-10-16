import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_motion_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_typography.dart';

/// Pins the midnight palette to the documented source token map, field by
/// field, so a token edit that drifts from the map fails here.

class _PaletteRow {
  const _PaletteRow(this.field, this.dark, this.light, this.note);

  final String field;
  final Color dark;
  final Color light;
  final String note;
}

final Map<String, Color Function(ScaffoldPalette)> _paletteFields = {
  'deepBlueCardColor': (p) => p.deepBlueCardColor,
  'lightGreenPrimary': (p) => p.lightGreenPrimary,
  'lightGreenSecondary': (p) => p.lightGreenSecondary,
  'gray500': (p) => p.gray500,
  'blue500': (p) => p.blue500,
  'borderGrey': (p) => p.borderGrey,
  'grayPrimary': (p) => p.grayPrimary,
  'deepBlueTertiary': (p) => p.deepBlueTertiary,
  'surfaceElevated': (p) => p.surfaceElevated,
  'borderSubtle': (p) => p.borderSubtle,
  'textPrimary': (p) => p.textPrimary,
  'textSecondary': (p) => p.textSecondary,
  'statusSuccess': (p) => p.statusSuccess,
  'statusError': (p) => p.statusError,
  'statusWarningText': (p) => p.statusWarningText,
  'focusRingColor': (p) => p.focusRingColor,
  'skeletonBaseColor': (p) => p.skeletonBaseColor,
  'skeletonShimmerColor': (p) => p.skeletonShimmerColor,
  'disabledOverlayColor': (p) => p.disabledOverlayColor,
  'dragFeedbackBackground': (p) => p.dragFeedbackBackground,
  'dropZoneHighlight': (p) => p.dropZoneHighlight,
  'dropZoneRejected': (p) => p.dropZoneRejected,
};

const List<_PaletteRow> _paletteRows = [
  _PaletteRow(
    'deepBlueCardColor',
    Color(0xFF0C0E14),
    Color(0xFFFFFFFF),
    'surfaceElevated, legacy card slot alias',
  ),
  _PaletteRow(
    'lightGreenPrimary',
    Color(0xFF0AAEE6),
    Color(0xFF0AAEE6),
    'brandPrimaryStrong',
  ),
  _PaletteRow(
    'lightGreenSecondary',
    Color(0xFF2BF5B4),
    Color(0xFF2BF5B4),
    'brandSecondary',
  ),
  _PaletteRow(
    'gray500',
    Color(0xFF8A8F9D),
    Color(0xFF5A606E),
    'textSecondary alias',
  ),
  _PaletteRow(
    'blue500',
    Color(0xFF14C8FF),
    Color(0xFF0A6885),
    'statusInfo; light uses brandPrimaryOnSurface',
  ),
  _PaletteRow(
    'borderGrey',
    Color(0x5CFFFFFF),
    Color(0x7A10131A),
    'borderControl',
  ),
  _PaletteRow(
    'grayPrimary',
    Color(0xFF171A21),
    Color(0xFFEFF2F6),
    'surfaceMenu',
  ),
  _PaletteRow(
    'deepBlueTertiary',
    Color(0xFF171A21),
    Color(0xFFEFF2F6),
    'surfaceMenu',
  ),
  _PaletteRow(
    'surfaceElevated',
    Color(0xFF0C0E14),
    Color(0xFFFFFFFF),
    'surfaceElevated',
  ),
  _PaletteRow(
    'borderSubtle',
    Color(0x1FFFFFFF),
    Color(0x1F10131A),
    'borderSubtle',
  ),
  _PaletteRow(
    'textPrimary',
    Color(0xFFFFFFFF),
    Color(0xFF10131A),
    'textPrimary',
  ),
  _PaletteRow(
    'textSecondary',
    Color(0xFF8A8F9D),
    Color(0xFF5A606E),
    'textSecondary',
  ),
  _PaletteRow(
    'statusSuccess',
    Color(0xFF0AD89C),
    Color(0xFF065F46),
    'light uses statusSuccessText',
  ),
  _PaletteRow(
    'statusError',
    Color(0xFFFF4D4D),
    Color(0xFF991B1B),
    'light uses statusErrorText',
  ),
  _PaletteRow(
    'statusWarningText',
    Color(0xFFFFC42E),
    Color(0xFF92400E),
    'statusWarningText',
  ),
  _PaletteRow(
    'focusRingColor',
    Color(0xFF0AAEE6),
    Color(0xFF0A6885),
    'brandPrimaryOnSurface',
  ),
  _PaletteRow(
    'skeletonBaseColor',
    Color(0xFF171A21),
    Color(0xFFEFF2F6),
    'preset choice: surfaceMenu',
  ),
  _PaletteRow(
    'skeletonShimmerColor',
    Color(0xFF0B0D12),
    Color(0xFFFFFFFF),
    'preset choice: surfaceBase dark, surfaceElevated light',
  ),
  _PaletteRow(
    'disabledOverlayColor',
    Color(0x66000000),
    Color(0x66000000),
    'no source token; default kept',
  ),
  _PaletteRow(
    'dragFeedbackBackground',
    Color(0xFF0C0E14),
    Color(0xFFFFFFFF),
    'preset choice: surfaceElevated',
  ),
  _PaletteRow(
    'dropZoneHighlight',
    Color(0x330AAEE6),
    Color(0x330AAEE6),
    'accent at 20%',
  ),
  _PaletteRow(
    'dropZoneRejected',
    Color(0x33FF4D4D),
    Color(0x33991B1B),
    'statusError at 20%',
  ),
];

final Map<String, Color Function(ScaffoldColorRoles)> _roleFields = {
  'accent': (c) => c.accent,
  'accentOnSurface': (c) => c.accentOnSurface,
  'accentSecondaryOnSurface': (c) => c.accentSecondaryOnSurface,
  'accentTextOnSurface': (c) => c.accentTextOnSurface,
  'borderControl': (c) => c.borderControl,
  'inputForeground': (c) => c.inputForeground,
  'sheetForeground': (c) => c.sheetForeground,
  'sheetDivider': (c) => c.sheetDivider,
};

const List<_PaletteRow> _roleRows = [
  _PaletteRow('accent', Color(0xFF0AAEE6), Color(0xFF0AAEE6), 'accent fill'),
  _PaletteRow(
    'accentOnSurface',
    Color(0xFF0AAEE6),
    Color(0xFF0A6885),
    'accent foreground on surfaces',
  ),
  _PaletteRow(
    'accentSecondaryOnSurface',
    Color(0xFF2BF5B4),
    Color(0xFF07875F),
    'secondary accent foreground; light uses an AA-tuned green',
  ),
  _PaletteRow(
    'accentTextOnSurface',
    Color(0xFF0AAEE6),
    Color(0xFF0A6885),
    'accent text on surfaces',
  ),
  _PaletteRow(
    'borderControl',
    Color(0x5CFFFFFF),
    Color(0x7A10131A),
    'control border',
  ),
  _PaletteRow(
    'inputForeground',
    Color(0xFFFFFFFF),
    Color(0xFF10131A),
    'primary text',
  ),
  _PaletteRow(
    'sheetForeground',
    Color(0xFFFFFFFF),
    Color(0xFF10131A),
    'primary text',
  ),
  _PaletteRow(
    'sheetDivider',
    Color(0x1FFFFFFF),
    Color(0x1F10131A),
    'subtle border',
  ),
];

final Map<String, Color Function(MidnightColors)> _presetFields = {
  'surfaceBase': (c) => c.surfaceBase,
  'surfaceSheet': (c) => c.surfaceSheet,
  'surfaceSunken': (c) => c.surfaceSunken,
  'scrim': (c) => c.scrim,
  'accentPrimary': (c) => c.accentPrimary,
  'accentPrimaryStrong': (c) => c.accentPrimaryStrong,
  'accentSecondary': (c) => c.accentSecondary,
  'accentSecondaryStrong': (c) => c.accentSecondaryStrong,
  'accentSecondaryBright': (c) => c.accentSecondaryBright,
  'accentTertiary': (c) => c.accentTertiary,
  'accentBadgeText': (c) => c.accentBadgeText,
  'textOnAccent': (c) => c.textOnAccent,
  'textOnError': (c) => c.textOnError,
  'textTertiary': (c) => c.textTertiary,
  'borderStrong': (c) => c.borderStrong,
  'borderControlOnAccent': (c) => c.borderControlOnAccent,
  'statusWarning': (c) => c.statusWarning,
  'selection': (c) => c.selection,
};

const List<_PaletteRow> _presetRows = [
  _PaletteRow(
    'surfaceBase',
    Color(0xFF0B0D12),
    Color(0xFFDCE0E6),
    'page background',
  ),
  _PaletteRow(
    'surfaceSheet',
    Color(0xFF171A21),
    Color(0xFFEFF2F6),
    'menu surface',
  ),
  _PaletteRow(
    'surfaceSunken',
    Color(0xFF06080C),
    Color(0xFFCFD4DB),
    'sunken surface',
  ),
  _PaletteRow(
    'scrim',
    Color(0x99000000),
    Color(0x99000000),
    'overlay, black at 60%',
  ),
  _PaletteRow(
    'accentPrimary',
    Color(0xFF14C8FF),
    Color(0xFF14C8FF),
    'primary accent',
  ),
  _PaletteRow(
    'accentPrimaryStrong',
    Color(0xFF0AAEE6),
    Color(0xFF0AAEE6),
    'strong primary accent',
  ),
  _PaletteRow(
    'accentSecondary',
    Color(0xFF2BF5B4),
    Color(0xFF2BF5B4),
    'secondary accent',
  ),
  _PaletteRow(
    'accentSecondaryStrong',
    Color(0xFF0AD89C),
    Color(0xFF0AD89C),
    'strong secondary accent',
  ),
  _PaletteRow(
    'accentSecondaryBright',
    Color(0xFF5BFFD0),
    Color(0xFF5BFFD0),
    'bright secondary accent',
  ),
  _PaletteRow(
    'accentTertiary',
    Color(0xFFC28FFF),
    Color(0xFFC28FFF),
    'tertiary accent',
  ),
  _PaletteRow(
    'accentBadgeText',
    Color(0xFF0AB2EB),
    Color(0xFF0A6480),
    'primary accent badge text',
  ),
  _PaletteRow(
    'textOnAccent',
    Color(0xFF000B18),
    Color(0xFF000B18),
    'text on accent',
  ),
  _PaletteRow(
    'textOnError',
    Color(0xFF000B18),
    Color(0xFFFFFFFF),
    'AA choice for onError',
  ),
  _PaletteRow(
    'textTertiary',
    Color(0xFF35363D),
    Color(0xFF35363D),
    'disabled text',
  ),
  _PaletteRow(
    'borderStrong',
    Color(0x3DFFFFFF),
    Color(0x3D10131A),
    'strong border, 24%',
  ),
  _PaletteRow(
    'borderControlOnAccent',
    Color(0x94FFFFFF),
    Color(0x8510131A),
    'control border on accent, 58% and 52%',
  ),
  _PaletteRow(
    'statusWarning',
    Color(0xFFFFC42E),
    Color(0xFFFFC42E),
    'warning fill',
  ),
  _PaletteRow(
    'selection',
    Color(0xFF8A8F9D),
    Color(0xFF8A8F9D),
    'text selection color',
  ),
];

final Map<String, double Function(ScaffoldDimens)> _dimensFields = {
  'horizontalPadding': (c) => c.horizontalPadding,
  'horizontalDesktopPadding': (c) => c.horizontalDesktopPadding,
  'verticalDesktopPadding': (c) => c.verticalDesktopPadding,
  'itemSpacing': (c) => c.itemSpacing,
  'borderRadiusCard': (c) => c.borderRadiusCard,
  'borderRadiusButton': (c) => c.borderRadiusButton,
  'appBarHeight': (c) => c.appBarHeight,
  'space2': (c) => c.space2,
  'space3': (c) => c.space3,
  'space4': (c) => c.space4,
  'space6': (c) => c.space6,
  'space8': (c) => c.space8,
  'space12': (c) => c.space12,
  'radiusMd': (c) => c.radiusMd,
  'radiusPill': (c) => c.radiusPill,
  'focusRingWidth': (c) => c.focusRingWidth,
  'skeletonCornerRadius': (c) => c.skeletonCornerRadius,
  'disabledOverlayOpacity': (c) => c.disabledOverlayOpacity,
  'dragHandleSize': (c) => c.dragHandleSize,
  'minTouchTarget': (c) => c.minTouchTarget,
  'touchTargetPadding': (c) => c.touchTargetPadding,
};

Map<String, dynamic> _tokens() =>
    jsonDecode(File('tokens/midnight.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('midnight palette matches the source token map', () {
    for (final row in _paletteRows) {
      final read = _paletteFields[row.field]!;
      test('dark ${row.field} (${row.note})', () {
        expect(read(Midnight.darkPalette), row.dark);
      });
      test('light ${row.field} (${row.note})', () {
        expect(read(Midnight.lightPalette), row.light);
      });
    }
  });

  test('the rows cover every palette key of tokens/midnight.json', () {
    final tokens =
        jsonDecode(File('tokens/midnight.json').readAsStringSync())
            as Map<String, dynamic>;
    final palette =
        (tokens['scaffold'] as Map<String, dynamic>)['palette']
            as Map<String, dynamic>;
    final rowNames = _paletteRows.map((r) => r.field).toList();
    expect(rowNames, (palette['dark'] as Map<String, dynamic>).keys.toList());
    expect(rowNames, (palette['light'] as Map<String, dynamic>).keys.toList());
    expect(_paletteFields.keys.toList(), rowNames);
  });

  group('midnight color roles match the source token map', () {
    for (final row in _roleRows) {
      final read = _roleFields[row.field]!;
      test('dark ${row.field} (${row.note})', () {
        expect(read(Midnight.darkColorRoles), row.dark);
      });
      test('light ${row.field} (${row.note})', () {
        expect(read(Midnight.lightColorRoles), row.light);
      });
    }
  });

  group('midnight preset colors match the source token map', () {
    for (final row in _presetRows) {
      final read = _presetFields[row.field]!;
      test('dark ${row.field} (${row.note})', () {
        expect(read(Midnight.darkColors), row.dark);
      });
      test('light ${row.field} (${row.note})', () {
        expect(read(Midnight.lightColors), row.light);
      });
    }
  });

  test('the rows cover every colorRoles and preset.colors key', () {
    final tokens = _tokens();
    final roles =
        (tokens['scaffold'] as Map<String, dynamic>)['colorRoles']
            as Map<String, dynamic>;
    final colors =
        (tokens['preset'] as Map<String, dynamic>)['colors']
            as Map<String, dynamic>;
    final roleNames = _roleRows.map((r) => r.field).toList();
    final colorNames = _presetRows.map((r) => r.field).toList();
    for (final mode in ['dark', 'light']) {
      expect(roleNames, (roles[mode] as Map<String, dynamic>).keys.toList());
      expect(colorNames, (colors[mode] as Map<String, dynamic>).keys.toList());
    }
    expect(_roleFields.keys.toList(), roleNames);
    expect(_presetFields.keys.toList(), colorNames);
  });

  group('midnight dimens equal the defaults except appBarHeight', () {
    for (final entry in _dimensFields.entries) {
      test(entry.key, () {
        final expected = entry.key == 'appBarHeight'
            ? 68.0
            : entry.value(ScaffoldDimens.defaultDimens);
        expect(entry.value(Midnight.dimens), expected);
      });
    }

    test('the rows cover every dimens key', () {
      final dimens =
          (_tokens()['scaffold'] as Map<String, dynamic>)['dimens']
              as Map<String, dynamic>;
      expect(_dimensFields.keys.toList(), dimens.keys.toList());
    });
  });

  group('midnight shadows', () {
    for (final entry in {
      'dark': (Midnight.darkShadows, const Color(0x59000000)),
      'light': (Midnight.lightShadows, const Color(0x1F000000)),
    }.entries) {
      test('${entry.key} card is one 16 blur shadow offset (0, 4)', () {
        final card = entry.value.$1.card;
        expect(card, hasLength(1));
        expect(card.single.color, entry.value.$2);
        expect(card.single.blurRadius, 16.0);
        expect(card.single.offset, const Offset(0.0, 4.0));
      });

      test('${entry.key} elevated equals card', () {
        expect(entry.value.$1.elevated, entry.value.$1.card);
      });
    }
  });

  test('midnight motion durations and curves', () {
    const ScaffoldMotionTheme motion = Midnight.motion;
    expect(motion.short, const Duration(milliseconds: 120));
    expect(motion.medium, const Duration(milliseconds: 200));
    expect(motion.long, const Duration(milliseconds: 320));
    expect(motion.standard, Curves.easeOutCubic);
    expect(motion.decelerate, Curves.easeOut);
    expect(motion.emphasized, Curves.easeOutExpo);
  });

  test('midnight typography', () {
    const ScaffoldTypography typography = Midnight.typography;
    expect(typography.inputStyle.fontFamily, 'Inter');
    expect(typography.inputStyle.fontSize, 16.0);
    expect(typography.inputStyle.fontWeight, FontWeight.w400);
    expect(typography.monoFontFamily, 'JetBrainsMono');
  });

  group('midnight gradients match the source token map', () {
    for (final row in _gradientRows) {
      final read = _gradientFields[row.field]!;
      test('dark ${row.field} (${row.note})', () {
        expect(read(Midnight.darkGradients), row.dark);
      });
      test('light ${row.field} (${row.note})', () {
        expect(read(Midnight.lightGradients), row.light);
      });
    }

    test('canvas stops are 0.0, 0.4, 1.0 in both modes', () {
      expect(Midnight.darkGradients.canvas.stops, [0.0, 0.4, 1.0]);
      expect(Midnight.lightGradients.canvas.stops, [0.0, 0.4, 1.0]);
    });

    test('the glow exists in dark and is absent in light', () {
      expect(Midnight.darkGradients.canvasGlow, isA<RadialGradient>());
      expect(Midnight.lightGradients.canvasGlow, isNull);
    });
  });

  group('midnight elevation matches the source token map', () {
    for (final row in _elevationRows) {
      final read = _elevationFields[row.field]!;
      test('dark ${row.field}', () {
        expect(read(Midnight.darkElevation), row.dark);
      });
      test('light ${row.field}', () {
        expect(read(Midnight.lightElevation), row.light);
      });
    }
  });

  group('midnight text theme matches the source token map', () {
    for (final row in _textRows) {
      test(row.slot, () {
        final style = _textSlots[row.slot]!(Midnight.textTheme)!;
        expect(style.fontSize, row.size);
        expect(style.height, closeTo(row.lineHeight / row.size, 1e-9));
        expect(style.fontWeight, row.weight);
        expect(style.letterSpacing, row.letterSpacing);
        expect(style.fontFamily, isNull);
        expect(style.fontFeatures, isNull);
      });
    }

    test('the five slots the source leaves out stay null', () {
      const TextTheme theme = Midnight.textTheme;
      expect(theme.displaySmall, isNull);
      expect(theme.headlineSmall, isNull);
      expect(theme.titleSmall, isNull);
      expect(theme.labelLarge, isNull);
      expect(theme.labelSmall, isNull);
    });
  });

  group('midnight type scale matches the source token map', () {
    for (final row in _numericRows) {
      test(row.slot, () {
        final style = _numericSlots[row.slot]!(Midnight.typeScale);
        expect(style.fontSize, row.size);
        expect(style.height, closeTo(row.lineHeight / row.size, 1e-9));
        expect(style.fontWeight, row.weight);
        expect(style.letterSpacing, row.letterSpacing);
        expect(style.fontFeatures, [const FontFeature.tabularFigures()]);
      });
    }

    test('sans font family', () {
      expect(Midnight.typeScale.sansFontFamily, 'Inter');
    });
  });

  group('midnight scale matches the source token map', () {
    for (final entry in _scaleValues.entries) {
      test(entry.key, () {
        expect(_scaleFields[entry.key]!(Midnight.scale), entry.value);
      });
    }
  });

  test('the rows cover every gradient, shadow, type and scale key', () {
    final preset = _tokens()['preset'] as Map<String, dynamic>;
    Map<String, dynamic> section(String name) =>
        preset[name] as Map<String, dynamic>;

    final gradients = section('gradients');
    final gradientNames = _gradientRows.map((r) => r.field).toList();
    expect(gradientNames, (gradients['dark'] as Map).keys.toList());
    expect(
      gradientNames.where((n) => n != 'canvasGlow').toList(),
      (gradients['light'] as Map).keys.toList(),
    );
    expect(_gradientFields.keys.toList(), gradientNames);

    final shadows = section('shadows');
    final shadowNames = _elevationRows.map((r) => r.field).toList();
    expect(shadowNames, (shadows['dark'] as Map).keys.toList());
    expect(shadowNames, (shadows['light'] as Map).keys.toList());
    expect(_elevationFields.keys.toList(), shadowNames);

    final textNames = section('textTheme').keys.toList();
    expect(_textRows.map((r) => r.slot).toList(), textNames);
    expect(_textSlots.keys.toList(), textNames);

    final typeScale = section('typeScale');
    final numericNames = (typeScale['numeric'] as Map).keys.toList();
    expect(_numericRows.map((r) => r.slot).toList(), numericNames);
    expect(_numericSlots.keys.toList(), numericNames);
    expect((typeScale['fontFamilies'] as Map).keys.toList(), [
      'sansFontFamily',
    ]);

    final scaleNames = section('scale').keys.toList();
    expect(_scaleValues.keys.toList(), scaleNames);
    expect(_scaleFields.keys.toList(), scaleNames);
  });
}

class _GradientRow {
  const _GradientRow(this.field, this.dark, this.light, this.note);

  final String field;
  final Gradient? dark;
  final Gradient? light;
  final String note;
}

const LinearGradient _ctaFill = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF0AD89C), Color(0xFF0AAEE6)],
);

const LinearGradient _ctaBorder = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF14C8FF), Color(0xFF5BFFD0)],
);

const List<_GradientRow> _gradientRows = [
  _GradientRow('accentFill', _ctaFill, _ctaFill, 'brandCta'),
  _GradientRow('accentBorder', _ctaBorder, _ctaBorder, 'brandBorder'),
  _GradientRow(
    'heroWash',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0B0D12), Color(0xFF0C0E14)],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFDCE0E6), Color(0xFFFFFFFF)],
    ),
    'surfaceBase to surfaceElevated',
  ),
  _GradientRow(
    'canvas',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF14171E), Color(0xFF0B0D12), Color(0xFF07090D)],
      stops: [0.0, 0.4, 1.0],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE3E6EB), Color(0xFFDCE0E6), Color(0xFFD3D7DE)],
      stops: [0.0, 0.4, 1.0],
    ),
    'canvas',
  ),
  _GradientRow(
    'surfaceSheen',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0C0E14), Color(0xFF0C0E14)],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
    ),
    'flat in dark on purpose',
  ),
  _GradientRow(
    'canvasGlow',
    RadialGradient(
      center: Alignment(0.0, -0.9),
      radius: 1.0,
      colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
      stops: [0.0, 0.6],
    ),
    null,
    'canvasTopLight, dark only',
  ),
];

final Map<String, Gradient? Function(MidnightGradients)> _gradientFields = {
  'accentFill': (g) => g.accentFill,
  'accentBorder': (g) => g.accentBorder,
  'heroWash': (g) => g.heroWash,
  'canvas': (g) => g.canvas,
  'surfaceSheen': (g) => g.surfaceSheen,
  'canvasGlow': (g) => g.canvasGlow,
};

class _ElevationRow {
  const _ElevationRow(this.field, this.dark, this.light);

  final String field;
  final List<BoxShadow> dark;
  final List<BoxShadow> light;
}

const List<BoxShadow> _glowAccent = [
  BoxShadow(color: Color(0x2E14C8FF), blurRadius: 24.0),
];

const List<BoxShadow> _glowAccentPair = [
  BoxShadow(
    color: Color(0x2614C8FF),
    blurRadius: 28.0,
    offset: Offset(-6.0, 8.0),
  ),
  BoxShadow(
    color: Color(0x262BF5B4),
    blurRadius: 28.0,
    offset: Offset(6.0, 8.0),
  ),
];

const List<_ElevationRow> _elevationRows = [
  _ElevationRow(
    'dialog',
    [
      BoxShadow(
        color: Color(0x73000000),
        blurRadius: 32.0,
        offset: Offset(0.0, 8.0),
      ),
    ],
    [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 32.0,
        offset: Offset(0.0, 8.0),
      ),
    ],
  ),
  _ElevationRow('glowAccent', _glowAccent, _glowAccent),
  _ElevationRow('glowAccentPair', _glowAccentPair, _glowAccentPair),
];

final Map<String, List<BoxShadow> Function(MidnightElevation)>
_elevationFields = {
  'dialog': (e) => e.dialog,
  'glowAccent': (e) => e.glowAccent,
  'glowAccentPair': (e) => e.glowAccentPair,
};

class _TextRow {
  const _TextRow(
    this.slot,
    this.size,
    this.lineHeight,
    this.weight, [
    this.letterSpacing,
  ]);

  final String slot;
  final double size;
  final double lineHeight;
  final FontWeight weight;
  final double? letterSpacing;
}

const List<_TextRow> _textRows = [
  _TextRow('displayLarge', 32.0, 40.0, FontWeight.w700, -0.4),
  _TextRow('displayMedium', 28.0, 36.0, FontWeight.w700, -0.4),
  _TextRow('headlineLarge', 24.0, 32.0, FontWeight.w600, -0.4),
  _TextRow('headlineMedium', 20.0, 28.0, FontWeight.w600),
  _TextRow('titleLarge', 18.0, 24.0, FontWeight.w600),
  _TextRow('titleMedium', 16.0, 22.0, FontWeight.w500),
  _TextRow('bodyLarge', 16.0, 24.0, FontWeight.w400),
  _TextRow('bodyMedium', 16.0, 24.0, FontWeight.w400),
  _TextRow('bodySmall', 14.0, 20.0, FontWeight.w400),
  _TextRow('labelMedium', 13.0, 18.0, FontWeight.w500),
];

final Map<String, TextStyle? Function(TextTheme)> _textSlots = {
  'displayLarge': (t) => t.displayLarge,
  'displayMedium': (t) => t.displayMedium,
  'headlineLarge': (t) => t.headlineLarge,
  'headlineMedium': (t) => t.headlineMedium,
  'titleLarge': (t) => t.titleLarge,
  'titleMedium': (t) => t.titleMedium,
  'bodyLarge': (t) => t.bodyLarge,
  'bodyMedium': (t) => t.bodyMedium,
  'bodySmall': (t) => t.bodySmall,
  'labelMedium': (t) => t.labelMedium,
};

const List<_TextRow> _numericRows = [
  _TextRow('numericDisplay', 32.0, 40.0, FontWeight.w700, -0.4),
  _TextRow('numericHeadline', 24.0, 32.0, FontWeight.w600),
  _TextRow('numericBody', 14.0, 20.0, FontWeight.w500),
];

final Map<String, TextStyle Function(MidnightTypeScale)> _numericSlots = {
  'numericDisplay': (s) => s.numericDisplay,
  'numericHeadline': (s) => s.numericHeadline,
  'numericBody': (s) => s.numericBody,
};

const Map<String, double> _scaleValues = {
  'space10': 20.0,
  'space16': 32.0,
  'space20': 40.0,
  'space24': 48.0,
  'space32': 64.0,
  'radiusXs': 4.0,
  'radiusSm': 8.0,
  'radiusBase': 10.0,
  'radius2xl': 16.0,
  'radiusXl': 24.0,
};

final Map<String, double Function(MidnightScale)> _scaleFields = {
  'space10': (s) => s.space10,
  'space16': (s) => s.space16,
  'space20': (s) => s.space20,
  'space24': (s) => s.space24,
  'space32': (s) => s.space32,
  'radiusXs': (s) => s.radiusXs,
  'radiusSm': (s) => s.radiusSm,
  'radiusBase': (s) => s.radiusBase,
  'radius2xl': (s) => s.radius2xl,
  'radiusXl': (s) => s.radiusXl,
};
