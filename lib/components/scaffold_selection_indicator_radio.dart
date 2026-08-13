// ScaffoldSelectionIndicatorRadio — radio selection indicator.
//
// Generated from selection_indicator.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/selection_indicator.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';

import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// A radio selection indicator.
///
/// Renders a 20px circle outline that fills with a
/// 12px `palette.lightGreenPrimary` dot when checked, wrapped in a 48px
/// [ScaffoldTouchTarget].
class ScaffoldSelectionIndicatorRadio extends StatelessWidget {
  /// Creates a [ScaffoldSelectionIndicatorRadio].
  const ScaffoldSelectionIndicatorRadio({
    super.key,

    required this.value,

    this.onChanged,
    this.disabled = false,

  });


  /// Whether the indicator is in the checked/on state.
  final bool value;

  /// Called with the toggled value when the indicator is tapped.
  final ValueChanged<bool>? onChanged;


  /// When true, blocks interaction and dims the indicator to 0.4 opacity.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final Widget indicator = _buildRadio(palette);


    Widget result = Semantics(

      checked: value,
      inMutuallyExclusiveGroup: true,

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


  void _handleTap() => onChanged?.call(!value);

  Widget _buildRadio(ScaffoldPalette palette) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: palette.textSecondary, width: 2),
      ),
      child: value
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.lightGreenPrimary,
                ),
              ),
            )
          : null,
    );
  }

}
