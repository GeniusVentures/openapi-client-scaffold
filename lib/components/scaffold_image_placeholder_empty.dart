// ScaffoldImagePlaceholderEmpty — empty image placeholder.
//
// Generated from image_placeholder.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/image_placeholder.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';

import 'package:frontend_scaffold/theme/scaffold_theme.dart';


/// A empty image placeholder.
///
/// Renders an
/// `Icons.photo_outlined` glyph with an optional label.
class ScaffoldImagePlaceholderEmpty extends StatelessWidget {
  /// Creates a [ScaffoldImagePlaceholderEmpty].
  const ScaffoldImagePlaceholderEmpty({
    super.key,
    this.width,
    this.height,

    this.label = 'No image',

  });

  /// Box width; null lets the parent size the placeholder.
  final double? width;

  /// Box height; null lets the parent size the placeholder.
  final double? height;


  /// Accessible label announced to screen readers.
  final String label;


  @override
  Widget build(BuildContext context) {

    final palette = context.palette;
    final TextStyle? labelStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: palette.textSecondary);
    return Semantics(
      image: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.photo_outlined, size: 48, color: palette.textSecondary),
          if (label.isNotEmpty)
            Text(label, textAlign: TextAlign.center, style: labelStyle),
        ],
      ),
    );

  }
}
