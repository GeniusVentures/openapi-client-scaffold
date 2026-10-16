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
/// rounded-rect outline that fills and shows a check (or dash when
/// indeterminate), wrapped in a 48px [ScaffoldTouchTarget]. The fill, mark, edge
/// color, corner radius and edge width come from `colorRoles.checkboxFill`,
/// `checkboxMark`, `checkboxEdge` and `shapes.checkboxRadius`,
/// `checkboxBorderWidth`; unset, they keep `colorRoles.accentOnSurface`, white,
/// `palette.textSecondary`, 2 px and 2 px.
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

    final Widget indicator = _buildCheckbox(context, palette);


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

  Widget _buildCheckbox(BuildContext context, ScaffoldPalette palette) {
    final bool? checked = value;
    final colorRoles = context.colorRoles;
    final shapes = context.shapes;
    final Color mark = colorRoles.checkboxMark ?? Colors.white;
    final Widget? icon = checked == null
        ? Icon(Icons.remove, color: mark, size: 16)
        : checked
            ? Icon(Icons.check, color: mark, size: 16)
            : null;
    // A themed mark is read against the themed fill, so the dash gets the fill
    // too; unthemed, only the checked state is filled.
    final Color? fill = checked == true
        ? colorRoles.checkboxFill ?? colorRoles.accentOnSurface
        : checked == null
            ? colorRoles.checkboxFill
            : null;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(shapes.checkboxRadius ?? 2),
        border: Border.all(
          color: colorRoles.checkboxEdge ?? palette.textSecondary,
          width: shapes.checkboxBorderWidth ?? 2,
        ),
      ),
      child: icon == null ? null : Center(child: icon),
    );
  }

}
