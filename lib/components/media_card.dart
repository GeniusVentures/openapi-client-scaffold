/// MediaCard -- M3 media card with thumbnail, typed badge slots, and metadata.
///
/// Composes ScaffoldSurface + ScaffoldPressable + ScaffoldBadge (WIDG-29).
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// A Material 3 media card with configurable aspect ratio, thumbnail, typed
/// badge slots, and a caller-supplied metadata row.
///
/// The card renders its [thumbnail] inside an [AspectRatio] box (default
/// `16 / 9`). Three typed badge slots — [topLeftBadge], [topRightBadge],
/// [bottomRightBadge] — each accept a [ScaffoldBadge]; null slots are omitted
/// from the layout. The [metadataRow] is a list of caller-supplied widgets
/// laid out in a [Row] with `dimens.space8` spacing; each child is wrapped
/// in [Flexible] so [TextOverflow.ellipsis] works for long labels.
///
/// When [onTap] is non-null the card is wrapped in a [ScaffoldPressable];
/// when [disabled] is true a [ScaffoldDisabledOverlay] blocks interaction.
class MediaCard extends StatelessWidget {
  /// Creates a [MediaCard].
  const MediaCard({
    super.key,
    this.aspectRatio = 16 / 9,
    this.thumbnail,
    this.topLeftBadge,
    this.topRightBadge,
    this.bottomRightBadge,
    this.metadataRow = const <Widget>[],
    this.onTap,
    this.disabled = false,
  });

  /// Width / height ratio of the thumbnail area (default 16:9).
  final double aspectRatio;

  /// Thumbnail image provider; when null the slot renders a plain surface
  /// color.
  final ImageProvider? thumbnail;

  /// Optional badge rendered at the top-left corner of the thumbnail.
  final ScaffoldBadge? topLeftBadge;

  /// Optional badge rendered at the top-right corner of the thumbnail.
  final ScaffoldBadge? topRightBadge;

  /// Optional badge rendered at the bottom-right corner of the thumbnail.
  final ScaffoldBadge? bottomRightBadge;

  /// Caller-supplied metadata widgets laid out beneath the thumbnail in a
  /// [Row] with theme spacing. Children should use
  /// [TextOverflow.ellipsis] for overflow.
  final List<Widget> metadataRow;

  /// When non-null, wraps the card in a [ScaffoldPressable].
  final VoidCallback? onTap;

  /// When true, blocks interaction via [ScaffoldDisabledOverlay].
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;

    final BorderRadiusGeometry radius =
        BorderRadius.circular(dimens.borderRadiusCard);

    // --- Thumbnail area ---
    final Widget thumbnailChild = thumbnail != null
        ? Image(
            image: thumbnail!,
            fit: BoxFit.cover,
          )
        : const SizedBox.expand();

    final List<Widget> stackChildren = <Widget>[
      Positioned.fill(child: thumbnailChild),
    ];

    if (topLeftBadge != null) {
      stackChildren.add(
        Positioned(
          top: dimens.space8,
          left: dimens.space8,
          child: topLeftBadge!,
        ),
      );
    }
    if (topRightBadge != null) {
      stackChildren.add(
        Positioned(
          top: dimens.space8,
          right: dimens.space8,
          child: topRightBadge!,
        ),
      );
    }
    if (bottomRightBadge != null) {
      stackChildren.add(
        Positioned(
          bottom: dimens.space8,
          right: dimens.space8,
          child: bottomRightBadge!,
        ),
      );
    }

    final Widget thumbArea = AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(children: stackChildren),
    );

    // --- Metadata row (optional) ---
    final List<Widget> columnChildren = <Widget>[thumbArea];
    if (metadataRow.isNotEmpty) {
      final List<Widget> rowChildren = <Widget>[];
      for (int i = 0; i < metadataRow.length; i++) {
        if (i > 0) {
          rowChildren.add(SizedBox(width: dimens.space8));
        }
        rowChildren.add(Flexible(child: metadataRow[i]));
      }
      columnChildren.add(
        Padding(
          padding: EdgeInsets.all(dimens.space8),
          child: Row(children: rowChildren),
        ),
      );
    }

    final Widget cardChild = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: columnChildren,
    );

    final Widget surface = ScaffoldSurface(
      color: palette.deepBlueCardColor,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: cardChild,
      ),
    );

    if (onTap != null) {
      return ScaffoldPressable(
        onPressed: onTap,
        disabled: disabled,
        child: surface,
      );
    }
    if (disabled) {
      return ScaffoldDisabledOverlay(disabled: true, child: surface);
    }
    return surface;
  }
}
