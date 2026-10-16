import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

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
}
