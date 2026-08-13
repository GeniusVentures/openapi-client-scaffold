import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Reorder grip: three parallel lines in a 48px touch target.
///
/// Renders three 2px horizontal lines (`palette.textSecondary` at 60%
/// opacity) spaced by `dimens.space2`, the grip spanning `dimens.dragHandleSize`
/// wide. The whole grip is wrapped in a [ScaffoldTouchTarget] for the 48px hit
/// area and registers the "Drag to reorder" label for screen readers.
class ScaffoldDragHandle extends StatelessWidget {
  /// Creates a [ScaffoldDragHandle].
  const ScaffoldDragHandle({super.key, this.color, this.size});

  /// Grip line color; defaults to `palette.textSecondary` at 60% opacity.
  final Color? color;

  /// Grip width; defaults to `dimens.dragHandleSize`.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final double lineWidth = size ?? dimens.dragHandleSize;
    final Color lineColor =
        (color ?? palette.textSecondary).withValues(alpha: 0.6);

    final Widget grip = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 3; i++) ...[
          Container(width: lineWidth, height: 2, color: lineColor),
          if (i < 2) SizedBox(height: dimens.space2),
        ],
      ],
    );

    return Semantics(
      label: 'Drag to reorder',
      child: ScaffoldTouchTarget(child: grip),
    );
  }
}
