/// MediaControls -- M3 media playback control bar.
///
/// Composes ScaffoldPressable + ScaffoldFormattedValueDuration (WIDG-30).
/// Stateless render from caller-supplied isPlaying / position / duration /
/// buffered; a private StatefulWidget holds ONLY the transient seek-scrub
/// position during drag and emits onSeek on release (D-03). No cubit —
/// playback truth lives in the consuming app's playback cubit.
///
/// Time labels are shown by default via ScaffoldFormattedValueDuration and
/// hideable via [showTimeLabels] (D-04). All interactive controls inherit
/// Semantics + 48x48 touch target + focus from ScaffoldPressable (Phase 6
/// D-02). Standalone widget consuming Theme.of(context) via
/// context.palette/dimens; no framework-specific theme or state dependencies.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_duration.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_slider.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Material 3 media playback control bar.
///
/// Renders a play/pause toggle, a seekbar showing current position relative
/// to [duration] with an optional buffered-amount layer behind the played
/// position, a mute toggle, and a fullscreen toggle. All callbacks are
/// optional; a null callback renders the corresponding button disabled (no
/// tap, no hover, no focus ring) per ScaffoldPressable's contract.
///
/// The widget is render-only with respect to playback truth — the caller
/// owns `isPlaying`, `position`, `duration`, `buffered`, `isMuted`, and
/// `isFullscreen` and updates them in response to the exposed callbacks.
/// The ONLY internal state is the transient seek-scrub position held while
/// the user is dragging the seekbar; `onSeek` fires on release only (D-03).
class MediaControls extends StatefulWidget {
  /// Creates a [MediaControls].
  const MediaControls({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.buffered,
    this.onPlayPause,
    this.onSeek,
    this.onToggleMute,
    this.onToggleFullscreen,
    this.isMuted = false,
    this.isFullscreen = false,
    this.showTimeLabels = true,
  });

  /// Whether media is currently playing; drives the play/pause icon.
  final bool isPlaying;

  /// Current playback position; drives the seekbar's played value.
  final Duration position;

  /// Total media duration; the seekbar's denominator.
  final Duration duration;

  /// Buffered amount; when null or <= [position], the buffered layer is not
  /// rendered. Clamped to [position, duration] when present.
  final Duration? buffered;

  /// Called when the user taps the play/pause button. Null renders the
  /// button disabled.
  final VoidCallback? onPlayPause;

  /// Called once on seek-release with the released [Duration]. NOT called
  /// during the drag — the caller receives only the final scrub target.
  final ValueChanged<Duration>? onSeek;

  /// Called when the user taps the mute toggle. Null renders disabled.
  final VoidCallback? onToggleMute;

  /// Called when the user taps the fullscreen toggle. Null renders disabled.
  final VoidCallback? onToggleFullscreen;

  /// Whether audio is muted; drives the mute icon.
  final bool isMuted;

  /// Whether fullscreen is active; drives the fullscreen icon.
  final bool isFullscreen;

  /// Whether to show the position/duration time labels beside the seekbar
  /// (D-04). Defaults to true.
  final bool showTimeLabels;

  @override
  State<MediaControls> createState() => _MediaControlsState();
}

class _MediaControlsState extends State<MediaControls> {
  /// The ONLY transient state owned by this widget (D-03): the in-progress
  /// scrub position while the user drags the seekbar. Set to null on release
  /// after emitting [MediaControls.onSeek].
  Duration? _scrubbing;

  Duration get _effectivePosition =>
      _clamp(_scrubbing ?? widget.position, Duration.zero, widget.duration);

  Duration _clamp(Duration value, Duration min, Duration max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  double get _sliderValue {
    final int totalMs = widget.duration.inMilliseconds;
    if (totalMs <= 0) {
      return 0.0;
    }
    return _effectivePosition.inMilliseconds / totalMs;
  }

  double? get _bufferedFraction {
    final Duration? b = widget.buffered;
    if (b == null) {
      return null;
    }
    final Duration clamped = _clamp(b, widget.position, widget.duration);
    if (clamped <= widget.position) {
      return null;
    }
    final int totalMs = widget.duration.inMilliseconds;
    if (totalMs <= 0) {
      return null;
    }
    return clamped.inMilliseconds / totalMs;
  }

  void _handleSeekStart(double value) {
    setState(() {
      _scrubbing = Duration(
        milliseconds: (value * widget.duration.inMilliseconds).round(),
      );
    });
  }

  void _handleSeekChanged(double value) {
    setState(() {
      _scrubbing = Duration(
        milliseconds: (value * widget.duration.inMilliseconds).round(),
      );
    });
  }

  void _handleSeekEnd(double value) {
    final Duration released = Duration(
      milliseconds: (value * widget.duration.inMilliseconds).round(),
    );
    setState(() {
      _scrubbing = null;
    });
    widget.onSeek?.call(released);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;

    // Tabular (fixed-pitch) figures for the time labels so the digits never
    // reflow as the value changes — every digit is the same width, so the
    // label text is visually stable regardless of alignment. Combined with
    // the fixed-width label box this eliminates all seekbar jitter.
    final TextStyle baseLabelStyle =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final TextStyle timeLabelStyle = baseLabelStyle.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    // The label width is MEASURED, not hard-coded: format the widest value
    // the magnitude-aware formatter can emit for this duration (`-H:MM:SS`
    // when the duration is >= 1 hour, `-M:SS` otherwise) in the actual label
    // style, and reserve exactly its painted width. The seekbar's extent then
    // never shifts as the formatted value changes (D-04), and the reservation
    // tracks the ambient text theme / text scale instead of a magic number.
    final double labelWidth = _measureTimeLabelWidth(
      widget.duration,
      timeLabelStyle,
    );

    // The seekbar is the composable ScaffoldSlider base widget: its buffered
    // span is painted INSIDE the track shape using the same track rect as the
    // played/inactive segments, so the buffered band and the played track
    // share one coordinate space by construction — no inset math, and the two
    // can never drift apart under any SliderTheme.
    final Widget seekbar = ScaffoldSlider(
      value: _sliderValue,
      bufferedValue: _bufferedFraction,
      onChangeStart: widget.onSeek != null ? _handleSeekStart : null,
      onChanged: widget.onSeek != null ? _handleSeekChanged : null,
      onChangeEnd: widget.onSeek != null ? _handleSeekEnd : null,
      semanticFormatterCallback: (double v) {
        final Duration d = Duration(
          milliseconds: (v * widget.duration.inMilliseconds).round(),
        );
        return '${d.inMinutes}:'
            '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
      },
    );

    final List<Widget> rowChildren = <Widget>[
      ScaffoldPressable(
        semanticLabel: widget.isPlaying ? 'Pause' : 'Play',
        onPressed: widget.onPlayPause,
        child: Icon(
          widget.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    ];

    if (widget.showTimeLabels) {
      rowChildren
        ..add(SizedBox(width: dimens.space8))
        ..add(
          // Fixed-width box reserving the exact measured label width, with
          // tabular figures, so the label text never reflows and the seekbar
          // extent never shifts (D-04). Right-aligned so the glyphs sit flush
          // against the seekbar side of the box.
          SizedBox(
            width: labelWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: ScaffoldFormattedValueDuration(
                value: _effectivePosition,
                style: timeLabelStyle,
              ),
            ),
          ),
        );
    }

    rowChildren
      ..add(SizedBox(width: dimens.space4))
      ..add(Expanded(child: seekbar));

    if (widget.showTimeLabels) {
      rowChildren
        ..add(SizedBox(width: dimens.space4))
        ..add(
          // Fixed-width, left-aligned to mirror the position label.
          SizedBox(
            width: labelWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ScaffoldFormattedValueDuration(
                value: widget.duration,
                style: timeLabelStyle,
              ),
            ),
          ),
        );
    }

    rowChildren
      ..add(SizedBox(width: dimens.space8))
      ..add(
        ScaffoldPressable(
          semanticLabel: widget.isMuted ? 'Unmute' : 'Mute',
          onPressed: widget.onToggleMute,
          child: Icon(
            widget.isMuted ? Icons.volume_off : Icons.volume_up,
          ),
        ),
      )
      ..add(
        ScaffoldPressable(
          semanticLabel:
              widget.isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
          onPressed: widget.onToggleFullscreen,
          child: Icon(
            widget.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          ),
        ),
      );

    return Container(
      color: palette.deepBlueCardColor,
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space8,
        vertical: dimens.space8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowChildren,
      ),
    );
  }

  /// Measures the width of the widest time label this control renders, using
  /// the ambient label [style]. Reserved so the seekbar's extent never shifts
  /// as the position label changes magnitude (D-04).
  ///
  /// Mirrors the magnitude logic of ScaffoldFormattedValueDuration: at or
  /// above one hour the widest label is `H:MM:SS`, otherwise `M:SS`. The
  /// width comes from a [TextPainter] laid out with the real style, so it
  /// tracks font family, size, and text scale instead of a magic number. The
  /// position is clamped to [0, duration], so it is never negative and never
  /// exceeds the duration — no sign or extra digit needs reserving.
  double _measureTimeLabelWidth(Duration duration, TextStyle style) {
    final String longest =
        duration.abs().inHours > 0 ? '0:00:00' : '0:00';
    final TextPainter painter = TextPainter(
      text: TextSpan(text: longest, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    // Ceil so the reserved width is a whole pixel: a fractional width beside
    // integer-sized siblings (48px pressables, 8px spacers) can overflow a
    // tight Row by a sub-pixel fraction.
    return painter.width.ceilToDouble();
  }
}
