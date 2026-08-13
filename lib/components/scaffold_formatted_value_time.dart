// ScaffoldFormattedValueTime — time formatted value display.
//
// Generated from formatted_value.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/formatted_value.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';

/// Displays a time value formatted for human consumption.
///
/// Renders the formatted value via [TextTheme.bodyLarge] inside a
/// [ScaffoldLiveRegion] so screen readers announce changes. A null value
/// renders [nullPlaceholder] (default '--'). Long values are clamped to a
/// single line with an ellipsis.
class ScaffoldFormattedValueTime extends StatelessWidget {
  /// Creates a [ScaffoldFormattedValueTime].
  const ScaffoldFormattedValueTime({
    super.key,

    this.value,
    this.is24Hour = false,

    this.nullPlaceholder = '--',
    this.style,
  });


  /// Value to format.
  final DateTime? value;


  /// When true, renders 24-hour time (HH:mm) instead of 12-hour (h:mm AM/PM).
  final bool is24Hour;


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


  String? _format(DateTime? value) {
    if (value == null) {
      return null;
    }
    if (is24Hour) {
      return '${value.hour.toString().padLeft(2, '0')}:'
          '${value.minute.toString().padLeft(2, '0')}';
    }
    final int hour =
        value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
  }

}
