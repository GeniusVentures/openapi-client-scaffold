import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// The status variants [ScaffoldStatusIndicator] can express.
enum StatusVariant { success, warning, error, info, neutral }

/// Generic status dot rendered via color.
///
/// Renders a configurable-size circle (default 12px) whose fill maps to the
/// [StatusVariant]: success -> `palette.statusSuccess`, warning ->
/// `palette.statusWarningText`, error -> `palette.statusError`, info ->
/// `palette.blue500`, neutral -> `palette.textSecondary`. When [label] is
/// supplied, registers `Semantics(role: status)`. When [disabled], dims to
/// 0.4 opacity.
class ScaffoldStatusIndicator extends StatelessWidget {
  const ScaffoldStatusIndicator({
    super.key,
    required this.status,
    this.dotSize = 12.0,
    this.label,
    this.disabled = false,
  });

  /// Which status color to render.
  final StatusVariant status;

  /// Circle diameter. Defaults to 12.0.
  final double dotSize;

  /// Accessible status label announced by screen readers.
  final String? label;

  /// When true, dims the indicator to 0.4 opacity.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget indicator = Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _resolveColor(palette)),
    );

    if (label != null) {
      indicator = Semantics(
        role: SemanticsRole.status,
        label: label,
        child: indicator,
      );
    }

    if (disabled) {
      indicator = Opacity(opacity: 0.4, child: indicator);
    }

    return indicator;
  }

  Color _resolveColor(ScaffoldPalette palette) {
    switch (status) {
      case StatusVariant.success:
        return palette.statusSuccess;
      case StatusVariant.warning:
        return palette.statusWarningText;
      case StatusVariant.error:
        return palette.statusError;
      case StatusVariant.info:
        return palette.blue500;
      case StatusVariant.neutral:
        return palette.textSecondary;
    }
  }
}
