import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Interaction blocker with a visual dim.
///
/// When [disabled] is false, returns [child] unchanged (zero-opacity cost).
/// When true, paints a `palette.disabledOverlayColor` dim at
/// `dimens.disabledOverlayOpacity` over [child] and wraps everything in an
/// [IgnorePointer] so no interaction reaches the content. When [reason] is
/// supplied, a `Semantics(tooltip: reason)` explains why the atom is disabled.
class ScaffoldDisabledOverlay extends StatelessWidget {
  const ScaffoldDisabledOverlay({
    super.key,
    required this.child,
    this.disabled = false,
    this.reason,
  });

  /// Content rendered underneath the dim overlay.
  final Widget child;

  /// When true, dims and blocks interaction with [child].
  final bool disabled;

  /// Optional accessible reason for the disabled state.
  final String? reason;

  @override
  Widget build(BuildContext context) {
    if (!disabled) {
      return child;
    }

    final palette = context.palette;
    final dimens = context.dimens;

    final Color overlayColor = palette.disabledOverlayColor.withValues(
      alpha: dimens.disabledOverlayOpacity,
    );

    Widget overlay = IgnorePointer(
      child: Stack(
        children: <Widget>[
          child,
          Positioned.fill(child: ColoredBox(color: overlayColor)),
        ],
      ),
    );

    if (reason != null) {
      overlay = Semantics(tooltip: reason, child: overlay);
    }

    return overlay;
  }
}
