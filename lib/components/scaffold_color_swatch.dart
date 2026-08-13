import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Selectable row of color samples.
///
/// Renders [colors] as a horizontal, scrollable row of configurable-size
/// circles, each wrapped in a `dimens.minTouchTarget` hit area. The selected
/// swatch shows a `palette.lightGreenPrimary` ring at `dimens.focusRingWidth`.
/// When [disabled], each swatch is dimmed with `palette.disabledOverlayColor`
/// at `dimens.disabledOverlayOpacity` and ignores pointer input.
///
/// Zero colors render a zero-size box; one color renders a single swatch; many
/// colors render a scrollable row (zero-one-many).
class ScaffoldColorSwatch extends StatelessWidget {
  const ScaffoldColorSwatch({
    super.key,
    required this.colors,
    this.selectedIndex,
    this.onSelected,
    this.dotSize = 24.0,
    this.disabled = false,
  });

  /// Color samples rendered as swatch dots.
  final List<Color> colors;

  /// Index of the selected swatch, or null when none is selected.
  final int? selectedIndex;

  /// Called with the tapped swatch's index when a non-selected color is
  /// tapped.
  final ValueChanged<int>? onSelected;

  /// Diameter of each swatch dot. Defaults to 24.0.
  final double dotSize;

  /// When true, swatches are dimmed and ignore pointer input.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;

    if (colors.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color overlayColor = palette.disabledOverlayColor.withValues(
      alpha: dimens.disabledOverlayOpacity,
    );

    final List<Widget> swatches = <Widget>[];
    for (int i = 0; i < colors.length; i++) {
      final bool selected = i == selectedIndex;

      final Widget circle = Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[i],
          border: selected
              ? Border.all(
                  color: palette.lightGreenPrimary,
                  width: dimens.focusRingWidth,
                )
              : null,
        ),
      );

      Widget swatch = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: dimens.minTouchTarget,
          minHeight: dimens.minTouchTarget,
        ),
        child: Center(child: circle),
      );

      if (disabled) {
        swatch = IgnorePointer(
          child: Stack(
            children: <Widget>[
              swatch,
              Positioned.fill(child: ColoredBox(color: overlayColor)),
            ],
          ),
        );
      } else {
        swatch = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSelected == null ? null : () => onSelected!(i),
          child: swatch,
        );
      }

      swatches.add(swatch);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: swatches,
      ),
    );
  }
}
