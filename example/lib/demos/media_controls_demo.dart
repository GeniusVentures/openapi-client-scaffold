// MediaControls demo (Phase 7 Plan 07-02, WIDG-30).
//
// Renders three scenarios stacked vertically to demonstrate the D-03 /
// D-04 contract:
//   1. Paused at 0 with buffered ahead — play icon visible.
//   2. Playing mid-stream with time labels hidden — pause icon visible.
//   3. Muted + fullscreen active — alternate icons.
//
// Tapping play/pause toggles `isPlaying` LOCALLY in this demo — the widget
// itself is render-only, and playback truth lives in the consuming app's
// playback cubit (D-03).
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Demo page for the Phase 7 MediaControls widget.
class MediaControlsDemo extends StatefulWidget {
  const MediaControlsDemo({super.key});

  @override
  State<MediaControlsDemo> createState() => _MediaControlsDemoState();
}

class _MediaControlsDemoState extends State<MediaControlsDemo> {
  // Scenario 1: paused at 0 with buffered ahead.
  bool _scenario1Playing = false;
  Duration _scenario1Position = Duration.zero;

  // Scenario 2: playing mid-stream (labels hidden).
  bool _scenario2Playing = true;
  Duration _scenario2Position = const Duration(seconds: 32);

  // Scenario 3: muted + fullscreen active.
  bool _scenario3Playing = false;
  bool _scenario3Muted = true;
  bool _scenario3Fullscreen = true;

  static const Duration _duration1 = Duration(seconds: 90);
  static const Duration _buffered1 = Duration(seconds: 45);

  static const Duration _duration2 = Duration(minutes: 2, seconds: 10);

  static const Duration _duration3 = Duration(minutes: 1);

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('MediaControls')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Scenario 1 — Paused at 0 with buffered ahead. '
              'Tap play to toggle local state.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: dimens.space8),
            Container(
              color: palette.deepBlueTertiary,
              height: 120,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MediaControls(
                  isPlaying: _scenario1Playing,
                  position: _scenario1Position,
                  duration: _duration1,
                  buffered: _buffered1,
                  onPlayPause: () {
                    setState(() {
                      _scenario1Playing = !_scenario1Playing;
                    });
                  },
                  onSeek: (Duration value) {
                    setState(() {
                      _scenario1Position = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: dimens.itemSpacing),
            Text(
              'Scenario 2 — Playing mid-stream, time labels hidden '
              '(showTimeLabels: false).',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: dimens.space8),
            Container(
              color: palette.deepBlueTertiary,
              height: 120,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MediaControls(
                  isPlaying: _scenario2Playing,
                  position: _scenario2Position,
                  duration: _duration2,
                  showTimeLabels: false,
                  onPlayPause: () {
                    setState(() {
                      _scenario2Playing = !_scenario2Playing;
                    });
                  },
                  onSeek: (Duration value) {
                    setState(() {
                      _scenario2Position = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: dimens.itemSpacing),
            Text(
              'Scenario 3 — Muted + fullscreen active. All four callbacks '
              'wired locally.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: dimens.space8),
            Container(
              color: palette.deepBlueTertiary,
              height: 120,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MediaControls(
                  isPlaying: _scenario3Playing,
                  position: Duration.zero,
                  duration: _duration3,
                  isMuted: _scenario3Muted,
                  isFullscreen: _scenario3Fullscreen,
                  onPlayPause: () {
                    setState(() {
                      _scenario3Playing = !_scenario3Playing;
                    });
                  },
                  onToggleMute: () {
                    setState(() {
                      _scenario3Muted = !_scenario3Muted;
                    });
                  },
                  onToggleFullscreen: () {
                    setState(() {
                      _scenario3Fullscreen = !_scenario3Fullscreen;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
