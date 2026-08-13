// ScaffoldImagePlaceholderFailed — failed image placeholder.
//
// Generated from image_placeholder.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/image_placeholder.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';

import 'package:frontend_scaffold/theme/scaffold_theme.dart';


/// A failed image placeholder.
///
/// Renders an
/// `Icons.broken_image` glyph in `palette.statusError` with an optional retry
/// action.
class ScaffoldImagePlaceholderFailed extends StatelessWidget {
  /// Creates a [ScaffoldImagePlaceholderFailed].
  const ScaffoldImagePlaceholderFailed({
    super.key,
    this.width,
    this.height,

    this.label = 'Image failed to load',

    this.onRetry,
    this.retryLabel = 'Retry',

  });

  /// Box width; null lets the parent size the placeholder.
  final double? width;

  /// Box height; null lets the parent size the placeholder.
  final double? height;


  /// Accessible label announced to screen readers.
  final String label;


  /// Called when the retry action is tapped; the action is omitted when null.
  final VoidCallback? onRetry;

  /// Label rendered on the retry action. Defaults to 'Retry'.
  final String retryLabel;


  @override
  Widget build(BuildContext context) {

    final palette = context.palette;
    final TextStyle? errorStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: palette.statusError);
    return Semantics(
      image: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.broken_image, size: 48, color: palette.statusError),
          if (label.isNotEmpty)
            Text(label, textAlign: TextAlign.center, style: errorStyle),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );

  }
}
