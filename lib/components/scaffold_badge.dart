import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// The visual variants [ScaffoldBadge] renders.
enum BadgeVariant { dot, count, icon, text }

/// Dot / count / icon / text indicator.
///
/// Renders a compact status affordance: an 8px [BadgeVariant.dot], a pill
/// [BadgeVariant.count] (truncating to "99+" beyond [maxDigits]), a 16px
/// [BadgeVariant.icon] in a 24px circle, or a custom [BadgeVariant.text] pill.
/// The badge does NOT position itself — the consumer composes it with a
/// `Stack` + `Positioned` (pure composability).
///
/// Each variant registers `Semantics(role: status)` and renders at its
/// intrinsic size (the badge is non-interactive and does not enforce a touch
/// target). The [BadgeVariant.count] label reads "{count} items"; the
/// [BadgeVariant.text] label reads the text; dot/icon variants use [label]
/// (default "New item").
class ScaffoldBadge extends StatelessWidget {
  const ScaffoldBadge({
    super.key,
    this.variant = BadgeVariant.dot,
    this.count = 0,
    this.text,
    this.icon,
    this.badgeColor,
    this.label,
    this.child,
    this.disabled = false,
    this.maxDigits = 2,
  });

  /// Which visual form to render.
  final BadgeVariant variant;

  /// Numeric count for the [BadgeVariant.count] variant.
  final int count;

  /// Label for the [BadgeVariant.text] variant.
  final String? text;

  /// Icon for the [BadgeVariant.icon] variant.
  final IconData? icon;

  /// Fill color; defaults to `palette.lightGreenPrimary`.
  final Color? badgeColor;

  /// Accessible label for the dot/icon variants (default "New item").
  final String? label;

  /// Reserved for consumers that need a composition anchor; not rendered.
  final Widget? child;

  /// When true, dims the badge to 0.4 opacity.
  final bool disabled;

  /// Maximum digit count before truncating to "99+".
  final int maxDigits;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final textTheme = Theme.of(context).textTheme;

    if ((variant == BadgeVariant.count && count == 0) ||
        (variant == BadgeVariant.text && (text == null || text!.isEmpty))) {
      return const SizedBox.shrink();
    }

    final Color resolvedBadgeColor = badgeColor ?? palette.lightGreenPrimary;
    final Widget visual = _buildVisual(
      palette,
      dimens,
      textTheme,
      resolvedBadgeColor,
    );

    Widget result = Semantics(
      role: SemanticsRole.status,
      label: _semanticLabel(),
      child: visual,
    );

    if (disabled) {
      result = Opacity(opacity: 0.4, child: result);
    }

    return result;
  }

  Widget _buildVisual(
    ScaffoldPalette palette,
    ScaffoldDimens dimens,
    TextTheme textTheme,
    Color resolvedBadgeColor,
  ) {
    final TextStyle? labelStyle = textTheme.labelSmall?.copyWith(
      color: Colors.white,
    );

    switch (variant) {
      case BadgeVariant.dot:
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: resolvedBadgeColor,
          ),
        );
      case BadgeVariant.count:
        return Container(
          constraints: const BoxConstraints(minWidth: 20),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: resolvedBadgeColor,
            borderRadius: BorderRadius.circular(dimens.radiusPill),
          ),
          child: Text(
            _truncatedCount(),
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        );
      case BadgeVariant.icon:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: resolvedBadgeColor,
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        );
      case BadgeVariant.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: resolvedBadgeColor,
            borderRadius: BorderRadius.circular(dimens.radiusPill),
          ),
          child: Text(text ?? '', style: labelStyle),
        );
    }
  }

  String _truncatedCount() {
    if (count > 99 && maxDigits == 2) {
      return '99+';
    }
    return count.toString();
  }

  String _semanticLabel() {
    switch (variant) {
      case BadgeVariant.count:
        return '$count items';
      case BadgeVariant.text:
        return text ?? '';
      case BadgeVariant.dot:
      case BadgeVariant.icon:
        return label ?? 'New item';
    }
  }
}
