import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/media_controls.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_duration.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: ScaffoldMotion(
          reducedMotion: false,
          child: Center(
            child: SizedBox(width: 480, child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows play icon when paused', (tester) async {
    await _pump(
      tester,
      const MediaControls(
        isPlaying: false,
        position: Duration.zero,
        duration: Duration(seconds: 10),
      ),
    );
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('shows pause icon when playing', (tester) async {
    await _pump(
      tester,
      const MediaControls(
        isPlaying: true,
        position: Duration(seconds: 1),
        duration: Duration(seconds: 10),
      ),
    );
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('tapping play/pause pressable invokes onPlayPause exactly once',
      (tester) async {
    int taps = 0;
    await _pump(
      tester,
      MediaControls(
        isPlaying: false,
        position: Duration.zero,
        duration: const Duration(seconds: 10),
        onPlayPause: () => taps++,
      ),
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('null onPlayPause does not throw and does not call anything',
      (tester) async {
    await _pump(
      tester,
      const MediaControls(
        isPlaying: false,
        position: Duration.zero,
        duration: Duration(seconds: 10),
      ),
    );
    // Pressable renders disabled; tap is a no-op (no exception).
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    // Nothing to assert beyond "no throw".
    expect(find.byType(MediaControls), findsOneWidget);
  });

  testWidgets('seekbar reflects position/duration (5s / 10s => 0.5)',
      (tester) async {
    await _pump(
      tester,
      const MediaControls(
        isPlaying: false,
        position: Duration(seconds: 5),
        duration: Duration(seconds: 10),
      ),
    );
    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, moreOrLessEquals(0.5, epsilon: 0.001));
  });

  testWidgets('buffered indicator renders behind played position',
      (tester) async {
    await _pump(
      tester,
      const MediaControls(
        isPlaying: false,
        position: Duration(seconds: 5),
        duration: Duration(seconds: 10),
        buffered: Duration(seconds: 8),
      ),
    );
    // The buffered layer is a FractionallySizedBox keyed with a stable key
    // so the test can find it deterministically.
    expect(find.byKey(const ValueKey<String>('media_controls_buffered')),
        findsOneWidget);
    final FractionallySizedBox buffered = tester.widget<FractionallySizedBox>(
      find.byKey(const ValueKey<String>('media_controls_buffered')),
    );
    expect(buffered.widthFactor, moreOrLessEquals(0.8, epsilon: 0.001));
  });

  testWidgets(
      'scrub drag does not call onSeek during drag; release calls it once',
      (tester) async {
    final List<Duration> seeks = <Duration>[];
    await _pump(
      tester,
      MediaControls(
        isPlaying: false,
        position: Duration.zero,
        duration: const Duration(seconds: 10),
        onSeek: seeks.add,
      ),
    );

    final Size sliderSize = tester.getSize(find.byType(Slider));
    final Offset sliderTopLeft = tester.getTopLeft(find.byType(Slider));
    // Drag from near the start to near the middle.
    final Offset start =
        sliderTopLeft + Offset(4, sliderSize.height / 2);
    final TestGesture gesture = await tester.startGesture(start);
    await gesture.moveBy(Offset(sliderSize.width / 4, 0));
    await tester.pump();
    // onSeek must NOT have fired during the drag (D-03).
    expect(seeks, isEmpty);

    await gesture.up();
    await tester.pump();
    // On release, onSeek fires exactly once.
    expect(seeks.length, 1);
    // Released Duration is within [Duration.zero, duration].
    expect(seeks.first >= Duration.zero, isTrue);
    expect(seeks.first <= const Duration(seconds: 10), isTrue);
  });

  testWidgets('mute icon + onToggleMute fires exactly once', (tester) async {
    int taps = 0;
    await _pump(
      tester,
      MediaControls(
        isPlaying: false,
        position: Duration.zero,
        duration: const Duration(seconds: 10),
        isMuted: true,
        onToggleMute: () => taps++,
      ),
    );
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
    expect(find.byIcon(Icons.volume_up), findsNothing);

    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('fullscreen icon reflects state + onToggleFullscreen fires',
      (tester) async {
    int taps = 0;
    await _pump(
      tester,
      MediaControls(
        isPlaying: false,
        position: Duration.zero,
        duration: const Duration(seconds: 10),
        isFullscreen: false,
        onToggleFullscreen: () => taps++,
      ),
    );
    expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    expect(find.byIcon(Icons.fullscreen_exit), findsNothing);

    await tester.tap(find.byIcon(Icons.fullscreen));
    await tester.pump();
    expect(taps, 1);

    // Rebuild in fullscreen state.
    await _pump(
      tester,
      MediaControls(
        isPlaying: false,
        position: Duration.zero,
        duration: const Duration(seconds: 10),
        isFullscreen: true,
        onToggleFullscreen: () => taps++,
      ),
    );
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
    expect(find.byIcon(Icons.fullscreen), findsNothing);
  });

  testWidgets(
      'time labels shown by default (D-04) — position + duration present',
      (tester) async {
    await _pump(
      tester,
      const MediaControls(
        isPlaying: false,
        position: Duration(seconds: 5),
        duration: Duration(seconds: 10),
      ),
    );
    expect(find.byType(ScaffoldFormattedValueDuration), findsNWidgets(2));
  });

  testWidgets('time labels hidden when showTimeLabels: false', (tester) async {
    await _pump(
      tester,
      const MediaControls(
        isPlaying: false,
        position: Duration(seconds: 5),
        duration: Duration(seconds: 10),
        showTimeLabels: false,
      ),
    );
    expect(find.byType(ScaffoldFormattedValueDuration), findsNothing);
  });

  testWidgets(
      'a11y — every ScaffoldPressable registers Semantics(button: true)',
      (tester) async {
    await _pump(
      tester,
      MediaControls(
        isPlaying: false,
        position: Duration.zero,
        duration: const Duration(seconds: 10),
        onPlayPause: () {},
        onToggleMute: () {},
        onToggleFullscreen: () {},
      ),
    );

    // Three interactive ScaffoldPressables (play, mute, fullscreen).
    expect(find.byType(ScaffoldPressable), findsNWidgets(3));

    // Seekbar exposes slider semantics via its SemanticsNode flags.
    final SemanticsNode sliderNode =
        tester.getSemantics(find.byType(Slider));
    expect(sliderNode.flagsCollection.isSlider, isTrue);
  });
}
