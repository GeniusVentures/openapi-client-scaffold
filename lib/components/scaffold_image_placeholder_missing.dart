// ScaffoldImagePlaceholderMissing — missing image placeholder.
//
// Generated from image_placeholder.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/image_placeholder.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';

import 'package:frontend_scaffold/theme/scaffold_theme.dart';


/// A missing image placeholder.
///
/// Renders an
/// `Icons.image_not_supported` glyph on a `palette.deepBlueCardColor` surface
/// with an optional label.
class ScaffoldImagePlaceholderMissing extends StatelessWidget {
  /// Creates a [ScaffoldImagePlaceholderMissing].
  const ScaffoldImagePlaceholderMissing({
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
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: palette.deepBlueCardColor,
          border: Border.all(color: palette.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: palette.textSecondary,
            ),
            if (label.isNotEmpty)
              Text(label, textAlign: TextAlign.center, style: labelStyle),
          ],
        ),
      ),
    );

  }
}
