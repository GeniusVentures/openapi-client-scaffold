import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

/// design_tokens.json is the source of the default palette, dimens and color roles. These
/// tests prove the token file equals what Dart resolves at runtime, including
/// entries the Dart source writes as ScaffoldColors references.

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

final Map<String, double Function(ScaffoldDimens)> _dimensFields = {
  'horizontalPadding': (d) => d.horizontalPadding,
  'horizontalDesktopPadding': (d) => d.horizontalDesktopPadding,
  'verticalDesktopPadding': (d) => d.verticalDesktopPadding,
  'itemSpacing': (d) => d.itemSpacing,
  'borderRadiusCard': (d) => d.borderRadiusCard,
  'borderRadiusButton': (d) => d.borderRadiusButton,
  'appBarHeight': (d) => d.appBarHeight,
  'space2': (d) => d.space2,
  'space3': (d) => d.space3,
  'space4': (d) => d.space4,
  'space6': (d) => d.space6,
  'space8': (d) => d.space8,
  'space12': (d) => d.space12,
  'radiusMd': (d) => d.radiusMd,
  'radiusPill': (d) => d.radiusPill,
  'focusRingWidth': (d) => d.focusRingWidth,
  'skeletonCornerRadius': (d) => d.skeletonCornerRadius,
  'disabledOverlayOpacity': (d) => d.disabledOverlayOpacity,
  'dragHandleSize': (d) => d.dragHandleSize,
  'minTouchTarget': (d) => d.minTouchTarget,
  'touchTargetPadding': (d) => d.touchTargetPadding,
};

final Map<String, Color Function(ScaffoldColorRoles)> _colorRoleFields = {
  'accent': (r) => r.accent,
  'accentOnSurface': (r) => r.accentOnSurface,
  'accentSecondaryOnSurface': (r) => r.accentSecondaryOnSurface,
  'accentTextOnSurface': (r) => r.accentTextOnSurface,
  'borderControl': (r) => r.borderControl,
  'inputForeground': (r) => r.inputForeground,
  'sheetForeground': (r) => r.sheetForeground,
  'sheetDivider': (r) => r.sheetDivider,
};

Map<String, dynamic> _scaffoldTokens() {
  final decoded =
      jsonDecode(File('design_tokens.json').readAsStringSync())
          as Map<String, dynamic>;
  return decoded['scaffold'] as Map<String, dynamic>;
}

int _argb(Object? entry) {
  final hex = entry is Map ? entry['value'] as String : entry as String;
  return int.parse(hex.substring(2), radix: 16);
}

void _expectPalette(Map<String, dynamic> region, ScaffoldPalette palette) {
  expect(region.keys.toList(), _paletteFields.keys.toList());
  for (final field in _paletteFields.entries) {
    expect(
      _argb(region[field.key]),
      field.value(palette).toARGB32(),
      reason: field.key,
    );
  }
}

/// [nullable] names the keys the region holds as null, after the rest.
void _expectColorRoles(
  Map<String, dynamic> region,
  ScaffoldColorRoles roles, {
  List<String> nullable = const [],
}) {
  expect(region.keys.toList(), [..._colorRoleFields.keys, ...nullable]);
  for (final key in nullable) {
    expect(region[key], isNull, reason: key);
  }
  expect(roles.surfaceEdge, isNull);
  for (final field in _colorRoleFields.entries) {
    expect(
      _argb(region[field.key]),
      field.value(roles).toARGB32(),
      reason: field.key,
    );
  }
}

void main() {
  final scaffold = _scaffoldTokens();

  test('scaffold.colorRoles.dark equals ScaffoldColorRoles.defaultColorRoles', () {
    final roles = scaffold['colorRoles'] as Map<String, dynamic>;
    _expectColorRoles(
      roles['dark'] as Map<String, dynamic>,
      ScaffoldColorRoles.defaultColorRoles,
      nullable: ['surfaceEdge'],
    );
  });

  test('scaffold.colorRoles.light equals ScaffoldColorRoles.lightColorRoles', () {
    final roles = scaffold['colorRoles'] as Map<String, dynamic>;
    _expectColorRoles(
      roles['light'] as Map<String, dynamic>,
      ScaffoldColorRoles.lightColorRoles,
    );
  });

  test('scaffold.palette.dark equals ScaffoldPalette.defaultPalette', () {
    final palette = scaffold['palette'] as Map<String, dynamic>;
    _expectPalette(
      palette['dark'] as Map<String, dynamic>,
      ScaffoldPalette.defaultPalette,
    );
  });

  test('scaffold.palette.light equals ScaffoldPalette.lightPalette', () {
    final palette = scaffold['palette'] as Map<String, dynamic>;
    _expectPalette(
      palette['light'] as Map<String, dynamic>,
      ScaffoldPalette.lightPalette,
    );
  });

  test('scaffold.dimens equals ScaffoldDimens.defaultDimens', () {
    final dimens = scaffold['dimens'] as Map<String, dynamic>;
    expect(dimens.keys.toList(), _dimensFields.keys.toList());
    for (final field in _dimensFields.entries) {
      expect(
        (dimens[field.key] as num).toDouble(),
        field.value(ScaffoldDimens.defaultDimens),
        reason: field.key,
      );
    }
  });
}
