import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Bounded precision number input with increment/decrement buttons.
///
/// Renders a horizontal decrement/value/increment layout. The value is
/// displayed in `textTheme.bodyLarge` (min 64px wide) and formatted as
/// `prefix + value.toStringAsFixed(decimalPlaces) + suffix`. Increment and
/// decrement are clamped to [min]/[max] before [onChanged] fires. The whole
/// control is wrapped in a [ScaffoldFocusOutline], dimmed by
/// [ScaffoldDisabledOverlay] when [disabled], and announces value changes via
/// [ScaffoldLiveRegion]. Buttons are labeled "Increment"/"Decrement".
class ScaffoldNumericInput extends StatefulWidget {
  /// Creates a [ScaffoldNumericInput].
  const ScaffoldNumericInput({
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
  });

  /// Current numeric value.
  final num value;

  /// Called with the next value after increment/decrement (clamped to bounds).
  final ValueChanged<num> onChanged;

  /// Lower bound; decrement stops here.
  final num min;

  /// Upper bound; increment stops here.
  final num max;

  /// Amount added/subtracted per button press.
  final num step;

  /// Decimal places shown in the formatted value.
  final int decimalPlaces;

  /// Optional text prepended to the value.
  final String? prefix;

  /// Optional text appended to the value.
  final String? suffix;

  /// When true, blocks interaction via [ScaffoldDisabledOverlay].
  final bool disabled;

  /// When non-null, tints the value text `palette.statusError` with a border.
  final String? error;

  @override
  State<ScaffoldNumericInput> createState() => _ScaffoldNumericInputState();
}

enum _PressedButton { none, decrement, increment }

class _ScaffoldNumericInputState extends State<ScaffoldNumericInput> {
  _PressedButton _pressed = _PressedButton.none;

  bool get _canIncrement =>
      !widget.disabled && (widget.value + widget.step) <= widget.max;

  bool get _canDecrement =>
      !widget.disabled && (widget.value - widget.step) >= widget.min;

  void _increment() {
    if (_canIncrement) {
      widget.onChanged(widget.value + widget.step);
    }
  }

  void _decrement() {
    if (_canDecrement) {
      widget.onChanged(widget.value - widget.step);
    }
  }

  void _setPressed(_PressedButton button) {
    if (_pressed != button) {
      setState(() => _pressed = button);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String formatted = _format();

    final Widget decrementButton = _buildButton(
      icon: Icons.remove,
      label: 'Decrement',
      pressed: _pressed == _PressedButton.decrement,
      enabled: _canDecrement,
      onTap: _decrement,
      onPressChanged: () => _setPressed(_PressedButton.decrement),
      onPressEnded: () => _setPressed(_PressedButton.none),
    );
    final Widget incrementButton = _buildButton(
      icon: Icons.add,
      label: 'Increment',
      pressed: _pressed == _PressedButton.increment,
      enabled: _canIncrement,
      onTap: _increment,
      onPressChanged: () => _setPressed(_PressedButton.increment),
      onPressEnded: () => _setPressed(_PressedButton.none),
    );

    final TextStyle? valueStyle = widget.error != null
        ? textTheme.bodyLarge?.copyWith(color: palette.statusError)
        : textTheme.bodyLarge;

    final Widget valueDisplay = ScaffoldLiveRegion(
      value: formatted,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        decoration: widget.error != null
            ? BoxDecoration(
                border: Border.all(
                  color: palette.statusError.withValues(alpha: 0.5),
                ),
              )
            : null,
        child: Text(
          formatted,
          textAlign: TextAlign.center,
          style: valueStyle,
        ),
      ),
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        decrementButton,
        valueDisplay,
        incrementButton,
      ],
    );

    content = ScaffoldFocusOutline(child: content);

    if (widget.disabled) {
      content = ScaffoldDisabledOverlay(disabled: true, child: content);
    }

    return content;
  }

  String _format() {
    final StringBuffer buffer = StringBuffer();
    if (widget.prefix != null) {
      buffer.write(widget.prefix);
    }
    buffer.write(widget.value.toStringAsFixed(widget.decimalPlaces));
    if (widget.suffix != null) {
      buffer.write(widget.suffix);
    }
    return buffer.toString();
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required bool pressed,
    required bool enabled,
    required VoidCallback onTap,
    required VoidCallback onPressChanged,
    required VoidCallback onPressEnded,
  }) {
    final palette = context.palette;
    final Color iconColor =
        pressed ? palette.lightGreenPrimary : palette.textPrimary;

    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => onPressChanged() : null,
        onTapUp: enabled ? (_) => onPressEnded() : null,
        onTapCancel: enabled ? onPressEnded : null,
        onTap: enabled ? onTap : null,
        child: ScaffoldTouchTarget(child: Icon(icon, color: iconColor)),
      ),
    );
  }
}
