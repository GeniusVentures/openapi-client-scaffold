/// ScaffoldSlider -- base slider with an optional in-track buffered layer.
///
/// Composable base widget: wraps Material [Slider] and, when
/// [bufferedValue] is set, installs a custom track shape that paints the
/// buffered span INSIDE the track shape itself. Buffered, played, and thumb
/// therefore share one coordinate space by construction -- the geometry comes
/// from [BaseSliderTrackShape.getPreferredRect], so the buffered band can
/// never drift from the played track regardless of the ambient
/// [SliderTheme] (track height, thumb/overlay size, padding, RTL).
///
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no framework-specific theme or state dependencies. Stateless -- the caller
/// owns [value] and updates it from [onChanged] (or wraps in its own state
/// for scrub semantics, as MediaControls does per D-03).
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Base slider with an optional buffered layer painted inside the track.
///
/// Unlike layering a separate bar behind/over a [Slider] (which breaks the
/// moment the theme changes track geometry), the buffered span is drawn by
/// the track shape using the same track rect as the played/inactive
/// segments, so the two can never misalign.
class ScaffoldSlider extends StatelessWidget {
  /// Creates a [ScaffoldSlider].
  const ScaffoldSlider({
    super.key,
    required this.value,
    this.bufferedValue,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticFormatterCallback,
  });

  /// Current played position, 0..1.
  final double value;

  /// Buffered position, 0..1. When null or <= [value], no buffered span is
  /// visible (the track shape still paints, but the span's right edge sits at
  /// the played position so it is fully covered by the played segment).
  /// Clamped to [value, 1] when present.
  final double? bufferedValue;

  /// Called continuously while the value changes. Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Called when a drag starts.
  final ValueChanged<double>? onChangeStart;

  /// Called when a drag ends, with the final value.
  final ValueChanged<double>? onChangeEnd;

  /// Forwarded to [Slider.semanticFormatterCallback].
  final SemanticFormatterCallback? semanticFormatterCallback;

  @override
  Widget build(BuildContext context) {
    // The buffered track shape is installed UNCONDITIONALLY. The shape must
    // never be added or removed in response to value/buffered changes: doing
    // so rebuilds the Slider's subtree mid-gesture (ScaffoldSlider is rebuilt
    // from the caller's setState on every drag tick), which tears down the
    // active pointer's gesture and stalls the drag. Keeping the tree stable
    // for the Slider's whole lifetime and only varying the painted fraction
    // avoids that entirely. A null/stale buffered simply clamps the span to
    // the played position, where the played segment covers it.
    final double effectiveBuffered =
        (bufferedValue ?? value).clamp(value, 1.0);

    // The track is painted by _BufferedTrackShape; all geometry (thumb,
    // overlay halo, played/buffered segments) comes straight from the
    // standard Slider machinery. No padding/overlay/thumb overrides — the
    // bar behaves exactly like a standard Material slider, including the
    // press/hover halo.
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackShape: _BufferedTrackShape(
          bufferedFraction: effectiveBuffered,
          bufferedColor: context.palette.borderSubtle,
        ),
      ),
      child: Slider(
        value: value.clamp(0.0, 1.0),
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        semanticFormatterCallback: semanticFormatterCallback,
      ),
    );
  }
}

/// Track shape that paints a buffered span inside the slider track.
///
/// Delegates the played/inactive segments to the stock rounded-rect painter,
/// then paints the buffered span — thumb to buffered edge — over the inactive
/// segment using the SAME [BaseSliderTrackShape] rect, so the buffered band
/// shares the track's exact origin, height, and rounding by construction.
/// Registered as the theme's track shape, Flutter positions the thumb
/// relative to this shape's rect (`isRounded`), keeping thumb and buffered
/// layer in one coordinate space.
class _BufferedTrackShape extends RoundedRectSliderTrackShape {
  const _BufferedTrackShape({
    required this.bufferedFraction,
    required this.bufferedColor,
  });

  /// Buffered fraction of the track, 0..1 (caller clamps >= played value).
  final double bufferedFraction;

  /// Color of the buffered span.
  final Color bufferedColor;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    // Stock played/inactive segments first. The inactive segment fills
    // thumb → track end with the ambient inactiveTrackColor.
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );

    // Buffered span: thumb → buffered edge, painted AFTER the stock segments
    // so the inactive segment can never cover it (Codex P2 on PR #8). The
    // leading edge → thumb interval intentionally shows the plain inactive
    // color — the band reads as "buffered ahead of the playhead". Geometry
    // comes from the same getPreferredRect the stock segments use, so the
    // band shares the track's exact origin, height, and rounding.
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Paint bufferedPaint = Paint()..color = bufferedColor;
    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final double bufferEdge =
        trackRect.width * bufferedFraction.clamp(0.0, 1.0);
    final Rect bufferedRect = switch (textDirection) {
      TextDirection.ltr => Rect.fromLTRB(thumbCenter.dx, trackRect.top,
          trackRect.left + bufferEdge, trackRect.bottom),
      TextDirection.rtl => Rect.fromLTRB(trackRect.right - bufferEdge,
          trackRect.top, thumbCenter.dx, trackRect.bottom),
    };
    if (!bufferedRect.isEmpty) {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(bufferedRect, trackRadius),
        bufferedPaint,
      );
    }
  }
}
