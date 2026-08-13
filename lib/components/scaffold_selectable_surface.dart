import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Selected / focused / pressed / disabled surface.
///
/// Composes [ScaffoldSurface] + [ScaffoldPressable] into a selectable card.
/// Unselected renders the default `palette.deepBlueCardColor` surface; selected
/// overlays `palette.lightGreenPrimary` at 12% opacity with a 1px
/// `palette.lightGreenPrimary` border. Focus ring, press state layer, and
/// disabled dim come from [ScaffoldPressable]. State transitions use
/// [ScaffoldMotionDurations.medium] with [ScaffoldMotionCurves.standard].
class ScaffoldSelectableSurface extends StatelessWidget {
  const ScaffoldSelectableSurface({
    super.key,
    this.child,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.disabled = false,
  });

  /// Content rendered inside the selectable surface.
  final Widget? child;

  /// When true, shows the selected overlay + border.
  final bool selected;

  /// Called when the surface is tapped.
  final VoidCallback? onTap;

  /// Called on a long press.
  final VoidCallback? onLongPress;

  /// When true, blocks interaction and applies [ScaffoldDisabledOverlay].
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;

    Widget content = ScaffoldSurface(child: child);

    if (selected) {
      content = Stack(
        children: <Widget>[
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: palette.lightGreenPrimary.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      );
    }

    content = AnimatedContainer(
      duration: ScaffoldMotionDurations.medium,
      curve: ScaffoldMotionCurves.standard,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: selected
            ? Border.all(color: palette.lightGreenPrimary, width: 1)
            : null,
        borderRadius: BorderRadius.circular(dimens.borderRadiusCard),
      ),
      child: content,
    );

    content = ScaffoldPressable(
      onPressed: onTap,
      onLongPress: onLongPress,
      disabled: disabled,
      child: content,
    );

    return Semantics(selected: selected, child: content);
  }
}
