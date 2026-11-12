import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_numeric_input.dart';

/// Opt-in tappable-number composable over [ScaffoldNumericInput].
///
/// STUB (RED step of quick-261112-jw3 / SCF-POS-02): the public API is
/// final, the behavior is not implemented yet.
class ScaffoldNumericInputWithKeypad extends StatefulWidget {
  /// Creates a [ScaffoldNumericInputWithKeypad].
  const ScaffoldNumericInputWithKeypad({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = double.negativeInfinity,
    this.max = double.infinity,
    this.step = 1,
    this.decimalPlaces = 0,
    this.prefix,
    this.suffix,
    this.disabled = false,
    this.error,
    this.sheetTitle,
    this.applyLabel = 'Apply',
    this.clearLabel = 'Clear',
    this.backspaceLabel = 'Backspace',
  });

  /// Current numeric value.
  final num value;

  /// Called with the next committed value (stepper step or keypad Apply).
  final ValueChanged<num> onChanged;

  /// Lower bound.
  final num min;

  /// Upper bound.
  final num max;

  /// Amount added/subtracted per stepper button press.
  final num step;

  /// Decimal places shown in the formatted value.
  final int decimalPlaces;

  /// Optional text prepended to the value.
  final String? prefix;

  /// Optional text appended to the value.
  final String? suffix;

  /// When true, blocks interaction.
  final bool disabled;

  /// When non-null, tints the value text.
  final String? error;

  /// Optional title rendered above the keypad sheet's draft.
  final String? sheetTitle;

  /// Label of the sheet's Apply action.
  final String applyLabel;

  /// Label of the sheet's Clear action.
  final String clearLabel;

  /// Semantic label of the sheet's backspace key.
  final String backspaceLabel;

  @override
  State<ScaffoldNumericInputWithKeypad> createState() =>
      _ScaffoldNumericInputWithKeypadState();
}

class _ScaffoldNumericInputWithKeypadState
    extends State<ScaffoldNumericInputWithKeypad> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldNumericInput(
      value: widget.value,
      onChanged: widget.onChanged,
      min: widget.min,
      max: widget.max,
      step: widget.step,
      decimalPlaces: widget.decimalPlaces,
      prefix: widget.prefix,
      suffix: widget.suffix,
      disabled: widget.disabled,
      error: widget.error,
    );
  }
}

/// Opens the numeric keypad popover; pops the committed value, or null
/// when dismissed.
///
/// STUB (RED step).
Future<num?> showScaffoldNumericKeypad(
  BuildContext context, {
  required num initialValue,
  required num min,
  required num max,
  int decimalPlaces = 0,
  String? sheetTitle,
  String applyLabel = 'Apply',
  String clearLabel = 'Clear',
  String backspaceLabel = 'Backspace',
}) async {
  return null;
}

/// Pure keypad draft state.
///
/// STUB (RED step).
class ScaffoldKeypadEntry {
  /// Creates a [ScaffoldKeypadEntry] over raw [text].
  const ScaffoldKeypadEntry(this.text, {this.decimalPlaces = 0});

  /// Raw draft text.
  final String text;

  /// Fraction digit cap.
  final int decimalPlaces;

  /// Appends one key; stub.
  ScaffoldKeypadEntry append(String key) => this;

  /// Deletes the last character; stub.
  ScaffoldKeypadEntry backspace() => this;

  /// Empties the draft; stub.
  ScaffoldKeypadEntry clear() => this;

  /// Parses the draft; stub.
  num parse() => 0;
}
