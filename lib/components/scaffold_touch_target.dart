import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Transparent wrapper guaranteeing a minimum hit-test area.
///
/// Expands a small child to at least [minWidth] x [minHeight] (defaulting to
/// [ScaffoldDimens.minTouchTarget]) via a [ConstrainedBox], and registers a
/// [Semantics] container so screen readers identify the touch region. No
/// padding is added, so children that already meet the minimum keep their
/// intrinsic size.
class ScaffoldTouchTarget extends StatelessWidget {
  const ScaffoldTouchTarget({
    super.key,
    this.child,
    this.minWidth,
    this.minHeight,
  });

  final Widget? child;

  /// Minimum hit-test width; defaults to `dimens.minTouchTarget`.
  final double? minWidth;

  /// Minimum hit-test height; defaults to `dimens.minTouchTarget`.
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final resolvedMinWidth = minWidth ?? dimens.minTouchTarget;
    final resolvedMinHeight = minHeight ?? dimens.minTouchTarget;

    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: resolvedMinWidth,
          minHeight: resolvedMinHeight,
        ),
        child: child,
      ),
    );
  }
}
