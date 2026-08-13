import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Stateless background / border / shape / elevation surface.
///
/// Renders whatever [child] is passed with a configurable background, border,
/// corner shape, and elevation. It has no content knowledge — it is a pure
/// visual wrapper that reads [ScaffoldPalette] and [ScaffoldDimens] tokens.
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

  /// Elevation shadow; when null or zero no shadow is painted.
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

    final Widget surface = Container(
      decoration: BoxDecoration(
        color: resolvedColor,
        border: border,
        borderRadius: shape == BoxShape.circle ? null : resolvedRadius,
        shape: shape,
      ),
      padding: padding,
      child: child,
    );

    if (elevation != null && elevation! > 0) {
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
