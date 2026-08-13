// ScaffoldImagePlaceholderLoading — loading image placeholder.
//
// Generated from image_placeholder.dart.jinja2 — do not edit by hand.
// Source schema: templates/components/image_placeholder.dart.jinja2
// Generator version: 0.4.0
library;

import 'package:flutter/material.dart';

import 'package:frontend_scaffold/components/scaffold_skeleton.dart';


/// A loading image placeholder.
///
/// Renders a [ScaffoldSkeleton] stand-in while an
/// image loads.
class ScaffoldImagePlaceholderLoading extends StatelessWidget {
  /// Creates a [ScaffoldImagePlaceholderLoading].
  const ScaffoldImagePlaceholderLoading({
    super.key,
    this.width,
    this.height,

    this.borderRadius,

    this.label = 'Loading image',

  });

  /// Box width; null lets the parent size the placeholder.
  final double? width;

  /// Box height; null lets the parent size the placeholder.
  final double? height;


  /// Skeleton corner radius; defaults to `dimens.skeletonCornerRadius`.
  final double? borderRadius;


  /// Accessible label announced to screen readers.
  final String label;


  @override
  Widget build(BuildContext context) {

    return Semantics(
      image: true,
      label: label,
      child: ScaffoldSkeleton(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
    );

  }
}
