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

    final double? bufferedFraction = _bufferedFraction;
    // Keep the buffered layer's height aligned with the Slider's track so
    // the two bars overlay visually regardless of SliderTheme overrides.
    final double trackHeight =
        SliderTheme.of(context).trackHeight ?? 4.0;

    final Widget seekbar = Stack(
      alignment: Alignment.centerLeft,
      children: <Widget>[
        // Buffered layer behind the played position.
        if (bufferedFraction != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                key: const ValueKey<String>('media_controls_buffered'),
                widthFactor: bufferedFraction,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: palette.borderSubtle,
                    borderRadius: BorderRadius.circular(dimens.radiusPill),
                  ),
                ),
              ),
            ),
          ),
        Slider(
          value: _sliderValue.clamp(0.0, 1.0),
          onChangeStart:
              widget.onSeek != null ? _handleSeekStart : null,
          onChanged: widget.onSeek != null ? _handleSeekChanged : null,
          onChangeEnd: widget.onSeek != null ? _handleSeekEnd : null,
          semanticFormatterCallback: (double v) {
            final Duration d = Duration(
              milliseconds: (v * widget.duration.inMilliseconds).round(),
            );
            return '${d.inMinutes}:'
                '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
          },
        ),
      ],
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
          ScaffoldFormattedValueDuration(value: _effectivePosition),
        );
    }

    rowChildren
      ..add(SizedBox(width: dimens.space8))
      ..add(Expanded(child: seekbar));

    if (widget.showTimeLabels) {
      rowChildren
        ..add(SizedBox(width: dimens.space8))
        ..add(
          ScaffoldFormattedValueDuration(value: widget.duration),
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
}
