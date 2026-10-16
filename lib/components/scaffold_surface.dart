import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Stateless background / border / shape / elevation surface.
///
/// Renders whatever [child] is passed with a configurable background, border,
/// corner shape, and elevation. It has no content knowledge — it is a pure
/// visual wrapper that reads [ScaffoldPalette] and [ScaffoldDimens] tokens.
/// An elevated surface draws `ScaffoldShadows.elevated` when the theme sets it,
/// and Material elevation otherwise.
class ScaffoldSurface extends StatelessWidget {
  const ScaffoldSurface({
    super.key,
    this.color,
    this.borderRadius,
    this.border,
    this.elevation,
    this.padding,
    this.shape = BoxShape.rectangle,
    this.child,
  });

  /// Background color; defaults to `palette.deepBlueCardColor`.
  final Color? color;

  /// Corner radius; defaults to `dimens.borderRadiusCard`.
  final BorderRadiusGeometry? borderRadius;

  /// Optional border painted on top of the background.
  final BoxBorder? border;

  /// Elevation shadow; when null or zero no shadow is painted. A themed
  /// `ScaffoldShadows.elevated` replaces Material elevation.
  final double? elevation;

  /// Inner padding applied around [child].
  final EdgeInsetsGeometry? padding;

  /// Rectangle or circle clip of the surface.
  final BoxShape shape;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;

    final resolvedColor = color ?? palette.deepBlueCardColor;
    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(dimens.borderRadiusCard);

    final isElevated = elevation != null && elevation! > 0;
    final themedShadow = isElevated ? context.shadows.elevated : null;

    final Widget surface = Container(
      decoration: BoxDecoration(
        color: resolvedColor,
        border: border,
        borderRadius: shape == BoxShape.circle ? null : resolvedRadius,
        shape: shape,
        boxShadow: themedShadow,
      ),
      padding: padding,
      child: child,
    );

    if (themedShadow != null) {
      return surface;
    }

    if (isElevated) {
      return Material(
        color: Colors.transparent,
        elevation: elevation!,
        shape: shape == BoxShape.circle
            ? const CircleBorder()
            : RoundedRectangleBorder(borderRadius: resolvedRadius),
        clipBehavior: Clip.none,
        child: surface,
      );
    }

    if (shape == BoxShape.circle) {
      return ClipOval(child: surface);
    }

    return surface;
  }
}
