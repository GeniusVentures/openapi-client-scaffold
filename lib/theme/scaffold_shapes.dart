import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Corner radii and stroke widths of individual components. Every field is
/// null by default, which keeps each widget's built-in geometry. Register on
/// [ThemeData.extensions] to restyle them; without one, `context.shapes` falls
/// back to [defaultShapes].
class ScaffoldShapes extends ThemeExtension<ScaffoldShapes> {
  /// Width of the focused `TextEntryFieldWidget` border. Null keeps 1 px.
  final double? inputFocusedBorderWidth;

  /// Corner radius of the open edge of drawers and bottom sheets: the top
  /// corners on mobile, the left corners of the desktop panel. Null keeps 16 px
  /// top corners on mobile and a square desktop panel.
  final double? sheetRadius;

  /// Corner radius of a ScaffoldSelectionIndicatorCheckbox. Null keeps 2 px.
  final double? checkboxRadius;

  /// Edge width of a ScaffoldSelectionIndicatorCheckbox. Null keeps 2 px.
  final double? checkboxBorderWidth;

  const ScaffoldShapes({
    // GENERATED from design_tokens.json scaffold.shapes. Do not edit.
    this.inputFocusedBorderWidth,
    this.sheetRadius,
    this.checkboxRadius,
    this.checkboxBorderWidth,
    // END GENERATED scaffold.shapes
  });

  /// Default shapes: none set. Rendered from `design_tokens.json`.
  static const ScaffoldShapes defaultShapes = ScaffoldShapes();

  /// Returns a copy of these shapes with the given fields replaced.
  @override
  ScaffoldShapes copyWith({
    double? inputFocusedBorderWidth,
    double? sheetRadius,
    double? checkboxRadius,
    double? checkboxBorderWidth,
  }) {
    return ScaffoldShapes(
      inputFocusedBorderWidth:
          inputFocusedBorderWidth ?? this.inputFocusedBorderWidth,
      sheetRadius: sheetRadius ?? this.sheetRadius,
      checkboxRadius: checkboxRadius ?? this.checkboxRadius,
      checkboxBorderWidth: checkboxBorderWidth ?? this.checkboxBorderWidth,
    );
  }

  @override
  ScaffoldShapes lerp(ThemeExtension<ScaffoldShapes>? other, double t) {
    if (other is! ScaffoldShapes) {
      return this;
    }
    return ScaffoldShapes(
      inputFocusedBorderWidth: lerpDouble(
        inputFocusedBorderWidth,
        other.inputFocusedBorderWidth,
        t,
      ),
      sheetRadius: lerpDouble(sheetRadius, other.sheetRadius, t),
      checkboxRadius: lerpDouble(checkboxRadius, other.checkboxRadius, t),
      checkboxBorderWidth: lerpDouble(
        checkboxBorderWidth,
        other.checkboxBorderWidth,
        t,
      ),
    );
  }
}
