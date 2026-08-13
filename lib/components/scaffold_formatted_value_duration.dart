// ScaffoldFormattedValueDuration — duration formatted value display.
//
// Generated from formatted_value.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/formatted_value.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';

/// Displays a duration value formatted for human consumption.
///
/// Renders the formatted value via [TextTheme.bodyLarge] inside a
/// [ScaffoldLiveRegion] so screen readers announce changes. A null value
/// renders [nullPlaceholder] (default '--'). Long values are clamped to a
/// single line with an ellipsis.
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


  String? _format(Duration? value) {
    if (value == null) {
      return null;
    }
    String two(int n) => n.toString().padLeft(2, '0');
    final int hours = value.inHours;
    final int minutes = value.inMinutes % 60;
    final int seconds = value.inSeconds % 60;
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

}
