// ScaffoldSelectionIndicatorCheckbox — checkbox selection indicator.
//
// Generated from selection_indicator.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/selection_indicator.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';

import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// A checkbox selection indicator.
///
/// Renders a 20px
/// rounded-rect outline that fills with `palette.lightGreenPrimary` and shows a
/// check (or dash when indeterminate), wrapped in a 48px
/// [ScaffoldTouchTarget].
class ScaffoldSelectionIndicatorCheckbox extends StatelessWidget {
  /// Creates a [ScaffoldSelectionIndicatorCheckbox].
  const ScaffoldSelectionIndicatorCheckbox({
    super.key,

    this.value,

    this.onChanged,
    this.disabled = false,

    this.tristate = false,

  });


  /// Whether the indicator is checked; null renders the indeterminate state.
  final bool? value;

  /// Called with the next value when the indicator is tapped.
  final ValueChanged<bool?>? onChanged;

  /// When true, tapping cycles unchecked -> checked -> indeterminate.
  final bool tristate;


  /// When true, blocks interaction and dims the indicator to 0.4 opacity.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final Widget indicator = _buildCheckbox(palette);


    Widget result = Semantics(

      checked: value ?? false,
      mixed: value == null,

      enabled: !disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : _handleTap,
        child: ScaffoldTouchTarget(child: indicator),
      ),
    );

    if (disabled) {
      result = Opacity(opacity: 0.4, child: result);
    }

    return result;
  }


  void _handleTap() {
    if (tristate) {
      final bool? next = value == null ? false : (value! ? null : true);
      onChanged?.call(next);
    } else {
      onChanged?.call(!(value ?? false));
    }
  }

  Widget _buildCheckbox(ScaffoldPalette palette) {
    final bool? checked = value;
    final Widget? icon = checked == null
        ? const Icon(Icons.remove, color: Colors.white, size: 16)
        : checked
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked == true ? palette.lightGreenPrimary : null,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: palette.textSecondary, width: 2),
      ),
      child: icon == null ? null : Center(child: icon),
    );
  }

}
