/// ScaffoldChip — M3 pill-shaped pressable atom.
///
/// Composes [ScaffoldSurface] (pill radius) + [ScaffoldPressable] (which
/// supplies [ScaffoldTouchTarget] internally for the 48px minimum hit area).
/// Selected state is a 2px `palette.lightGreenPrimary` BORDER — the fill
/// stays at the default `palette.deepBlueCardColor`, preserving the 60/30/10
/// contract. Optional leading [icon], trailing [status]
/// ([ScaffoldStatusIndicator]). Disabled wraps in [ScaffoldDisabledOverlay]
/// at `dimens.disabledOverlayOpacity` via [ScaffoldPressable].
///
/// Accessibility contract (D-03): when the chip renders icon-only
/// (`label == null && icon != null`), [semanticLabel] is REQUIRED — enforced
/// by a constructor assert.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Pill-shaped pressable token atom with optional leading icon, label, and
/// trailing [ScaffoldStatusIndicator].
class ScaffoldChip extends StatelessWidget {
  /// Creates a chip. When [label] is null and [icon] is non-null,
  /// [semanticLabel] is REQUIRED (WCAG 4.1.2 Name, Role, Value).
  const ScaffoldChip({
    super.key,
    this.label,
    this.icon,
    this.status,
    this.selected = false,
    this.disabled = false,
    this.semanticLabel,
    this.onPressed,
  }) : assert(
          label != null || semanticLabel != null,
          'Icon-only ScaffoldChip requires semanticLabel (WCAG 4.1.2)',
        );

  /// Chip label text rendered with `textTheme.labelMedium`.
  final String? label;

  /// Optional leading icon rendered at 16px.
  final IconData? icon;

  /// Optional trailing status indicator variant.
  final StatusVariant? status;

  /// When true, draws a 2px `palette.lightGreenPrimary` border. The fill
  /// remains `palette.deepBlueCardColor` — selected state is a border, not
  /// a fill change.
  final bool selected;

  /// When true, blocks interaction and applies [ScaffoldDisabledOverlay].
  final bool disabled;

  /// Accessible name announced by screen readers. REQUIRED when [label] is
  /// null and [icon] is non-null.
  final String? semanticLabel;

  /// Called when the chip is tapped or activated via Enter/Space.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final textTheme = Theme.of(context).textTheme;

    final List<Widget> rowChildren = <Widget>[];
    if (icon != null) {
      rowChildren.add(Icon(icon, size: 16));
    }
    if (label != null) {
      if (rowChildren.isNotEmpty) {
        rowChildren.add(SizedBox(width: dimens.space2));
      }
      rowChildren.add(Text(label!, style: textTheme.labelMedium));
    }
    if (status != null) {
      if (rowChildren.isNotEmpty) {
        rowChildren.add(SizedBox(width: dimens.space2));
      }
      rowChildren.add(ScaffoldStatusIndicator(status: status!, dotSize: 8));
    }

    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: rowChildren,
    );

    final Widget surface = ScaffoldSurface(
      color: palette.deepBlueCardColor,
      borderRadius: BorderRadius.circular(dimens.radiusPill),
      border: selected
          ? Border.all(
              color: palette.lightGreenPrimary,
              width: dimens.focusRingWidth,
            )
          : null,
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space4,
      ),
      child: row,
    );

    final Widget pressable = ScaffoldPressable(
      onPressed: onPressed,
      disabled: disabled,
      semanticLabel: semanticLabel,
      child: surface,
    );

    return Semantics(
      selected: selected,
      child: pressable,
    );
  }
}
