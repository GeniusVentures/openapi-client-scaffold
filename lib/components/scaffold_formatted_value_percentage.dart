// ScaffoldFormattedValuePercentage — percentage formatted value display.
//
// Generated from formatted_value.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/formatted_value.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';

/// Displays a percentage value formatted for human consumption.
///
/// Renders the formatted value via [TextTheme.bodyLarge] inside a
/// [ScaffoldLiveRegion] so screen readers announce changes. A null value
/// renders [nullPlaceholder] (default '--'). Long values are clamped to a
/// single line with an ellipsis.
class ScaffoldFormattedValuePercentage extends StatelessWidget {
  /// Creates a [ScaffoldFormattedValuePercentage].
  const ScaffoldFormattedValuePercentage({
    super.key,

    this.value,
    this.decimalPlaces = 1,

    this.nullPlaceholder = '--',
    this.style,
  });


  /// Value to format, interpreted as a ratio in the range 0..1 (e.g. ``0.425``
  /// renders ``"42.5%"``). The value is multiplied by 100 before formatting.
  final num? value;


  /// Number of decimal places shown. Defaults to 1.
  final int decimalPlaces;


  /// Text rendered when [value] is null. Defaults to '--'.
  final String nullPlaceholder;

  /// Text style; defaults to [TextTheme.bodyLarge].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String display = _format(value) ?? nullPlaceholder;
    return ScaffoldLiveRegion(
      label: display,
      child: Text(
        display,
        style: style ?? textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }


  String? _format(num? value) {
    if (value == null) {
      return null;
    }
    return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
  }

}
