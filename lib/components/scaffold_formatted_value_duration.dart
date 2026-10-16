// ScaffoldFormattedValueDuration — duration formatted value display.
//
// Generated from formatted_value.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/formatted_value.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Displays a duration value formatted for human consumption.
///
/// Renders the formatted value via [TextTheme.bodyLarge] inside a
/// [ScaffoldLiveRegion] so screen readers announce changes. A null value
/// renders [nullPlaceholder] (default '--'). Long values are clamped to a
/// single line with an ellipsis. When the theme sets
/// [ScaffoldTypography.numericStyle] it is merged onto the style, so its font
/// features replace those of the base style.
class ScaffoldFormattedValueDuration extends StatelessWidget {
  /// Creates a [ScaffoldFormattedValueDuration].
  const ScaffoldFormattedValueDuration({
    super.key,

    this.value,

    this.nullPlaceholder = '--',
    this.style,
  });


  /// Value to format.
  final Duration? value;



  /// Text rendered when [value] is null. Defaults to '--'.
  final String nullPlaceholder;

  /// Text style; defaults to [TextTheme.bodyLarge]. [ScaffoldTypography.numericStyle]
  /// is merged onto it.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String display = _format(value) ?? nullPlaceholder;
    final TextStyle? base = style ?? textTheme.bodyLarge;
    final TextStyle? numericStyle = context.typography.numericStyle;
    final TextStyle? resolved = numericStyle == null
        ? base
        : (base ?? const TextStyle()).merge(numericStyle);
    return ScaffoldLiveRegion(
      label: display,
      child: Text(
        display,
        style: resolved,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }


  String? _format(Duration? value) {
    if (value == null) {
      return null;
    }
    String two(int n) => n.toString().padLeft(2, '0');
    final bool negative = value.isNegative;
    final Duration abs = value.abs();
    // H:MM:SS when at least one hour, otherwise M:SS (magnitude-aware); the
    // sign is applied once, up front, so negative durations format correctly.
    if (abs.inHours > 0) {
      return '${negative ? '-' : ''}${abs.inHours}:'
          '${two(abs.inMinutes % 60)}:${two(abs.inSeconds % 60)}';
    }
    return '${negative ? '-' : ''}${abs.inMinutes}:'
        '${two(abs.inSeconds % 60)}';
  }

}
