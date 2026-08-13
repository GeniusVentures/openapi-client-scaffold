import 'package:flutter/material.dart';
import 'package:frontend_scaffold/utils/breakpoints.dart';

/// Comparison operator applied between the viewport width and a threshold.
enum ComparisonOperator {
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
}

/// Breakpoint-aware show/hide wrapper.
///
/// The only atom in the library with breakpoint awareness. It reads the
/// viewport width via [MediaQuery] and shows, hides, or replaces [child]
/// against a threshold. Use [ScaffoldBreakpoints] (`small` 760, `tablet` 1200,
/// `medium` 1644, `large` 1920) as the reference threshold values.
///
/// [showAt] reveals the child when `width (operator) threshold` is true;
/// [hideAt] hides the child when `width (operator) threshold` is true (the
/// inverse). When the child is hidden, [replacement] (or a zero-size box when
/// null) is rendered instead.
class ScaffoldResponsiveVisibility extends StatelessWidget {
  const ScaffoldResponsiveVisibility({
    super.key,
    this.child,
    this.showAt,
    this.hideAt,
    this.operator = ComparisonOperator.greaterThanOrEqual,
    this.breakpoint,
    this.replacement,
  });

  /// Content shown when the visibility condition is met.
  final Widget? child;

  /// Threshold width at which [child] becomes visible (show semantics).
  final double? showAt;

  /// Threshold width at which [child] is hidden (hide semantics).
  final double? hideAt;

  /// Comparison operator applied against the threshold. Defaults to
  /// [ComparisonOperator.greaterThanOrEqual].
  final ComparisonOperator operator;

  /// Explicit threshold override; takes precedence over [showAt] and [hideAt].
  final double? breakpoint;

  /// Widget rendered instead of [child] when the child is hidden.
  final Widget? replacement;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool visible;
    if (hideAt != null && breakpoint == null && showAt == null) {
      // Hide semantics: the child is hidden when the condition is met.
      visible = !_compare(screenWidth, hideAt!);
    } else {
      // Show semantics (default, and whenever breakpoint/showAt is provided).
      final double? threshold = breakpoint ?? showAt;
      visible = threshold == null ? true : _compare(screenWidth, threshold);
    }

    if (visible) {
      return child ?? const SizedBox.shrink();
    }
    return replacement ?? const SizedBox.shrink();
  }

  bool _compare(double width, double threshold) {
    switch (operator) {
      case ComparisonOperator.greaterThan:
        return width > threshold;
      case ComparisonOperator.lessThan:
        return width < threshold;
      case ComparisonOperator.greaterThanOrEqual:
        return width >= threshold;
      case ComparisonOperator.lessThanOrEqual:
        return width <= threshold;
    }
  }
}
