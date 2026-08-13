// ScaffoldSelectionIndicatorToggle — toggle selection indicator.
//
// Generated from selection_indicator.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/selection_indicator.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';

import 'package:frontend_scaffold/components/scaffold_motion.dart';

import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// A toggle selection indicator.
///
/// Renders a 40x24 pill
/// track whose 20px thumb slides to the on position, wrapped in a 48px
/// [ScaffoldTouchTarget].
class ScaffoldSelectionIndicatorToggle extends StatelessWidget {
  /// Creates a [ScaffoldSelectionIndicatorToggle].
  const ScaffoldSelectionIndicatorToggle({
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

    final Widget indicator = _buildToggle(palette);


    Widget result = Semantics(

      toggled: value,

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

  Widget _buildToggle(ScaffoldPalette palette) {
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: value ? palette.lightGreenPrimary : palette.textSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: ScaffoldMotionDurations.short,
            curve: ScaffoldMotionCurves.standard,
            left: value ? 18 : 2,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surfaceElevated,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
