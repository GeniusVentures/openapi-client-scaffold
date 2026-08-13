// ScaffoldFormattedValueMoney — money formatted value display.
//
// Generated from formatted_value.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/formatted_value.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';

/// Displays a money value formatted for human consumption.
///
/// Renders the formatted value via [TextTheme.bodyLarge] inside a
/// [ScaffoldLiveRegion] so screen readers announce changes. A null value
/// renders [nullPlaceholder] (default '--'). Long values are clamped to a
/// single line with an ellipsis.
class ScaffoldFormattedValueMoney extends StatelessWidget {
  /// Creates a [ScaffoldFormattedValueMoney].
  const ScaffoldFormattedValueMoney({
    super.key,

    this.value,
    this.currencySymbol = r'$',
    this.decimalPlaces = 2,

    this.nullPlaceholder = '--',
    this.style,
  });


  /// Value to format.
  final num? value;


  /// Currency symbol prepended to the formatted value. Defaults to '$'.
  final String currencySymbol;

  /// Number of decimal places shown. Defaults to 2.
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
    final String fixed = value.abs().toStringAsFixed(decimalPlaces);
    final int dot = fixed.indexOf('.');
    final String intPart = dot == -1 ? fixed : fixed.substring(0, dot);
    final String fracPart = dot == -1 ? '' : fixed.substring(dot);
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }
    return (value < 0 ? '-' : '') + currencySymbol + buffer.toString() + fracPart;
  }

}
