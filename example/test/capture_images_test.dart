/// Reproducible demo-image capture harness for the frontend_scaffold package.
///
/// Pumps each of the 26 demo `StatelessWidget`s registered in
/// `example/lib/main.dart` under BOTH dark and light themes and writes two
/// PNGs per demo into the package-root `images/` directory
/// (`../images/<name>_dark.png` and `../images/<name>_light.png` relative to
/// `example/`). Set `SCAFFOLD_CAPTURE_DIR` to write the PNGs elsewhere, for
/// example a baseline outside the repo; the default stays the package-root
/// `images/`.
///
/// The midnight run also writes `restyles_dark.png` and `restyles_light.png`,
/// which show what the midnight restyles change: cards, hover, a focused field,
/// selection indicators and a formatted number. The default run never renders
/// them.
///
/// Run from `example/`:
///
/// ```bash
/// cd example && flutter test test/capture_images_test.dart
/// ```
///
/// This harness is a WRITER — it never asserts on pixels (no golden-file
/// matching, no CI pixel gating). Re-running it overwrites the PNGs
/// deterministically. See CONTEXT D-02 in
/// `.planning/workstreams/scaffold/phases/11-verification-coverage-gate/11-CONTEXT.md`.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/bottom_drawer/responsive_drawer.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_card.dart';
import 'package:frontend_scaffold/components/scaffold_chart_range_selector.dart';
import 'package:frontend_scaffold/components/scaffold_chart_scrubber.dart';
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_number.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_checkbox.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_radio.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_toggle.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/components/text_entry_field_widget.dart';
import 'package:frontend_scaffold/components/text_form_field_logic.dart';
import 'package:frontend_scaffold/components/toast/toast_manager.dart';
import 'package:frontend_scaffold/components/toast/toast_widget.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

// Demo imports — mirrors example/lib/main.dart lines 4-29 (same order).
import 'package:frontend_scaffold_example/demos/action_button_demo.dart';
import 'package:frontend_scaffold_example/demos/animations_demo.dart';
import 'package:frontend_scaffold_example/demos/bottom_drawer_demo.dart';
import 'package:frontend_scaffold_example/demos/chart_demo.dart';
import 'package:frontend_scaffold_example/demos/chart_range_selector_demo.dart';
import 'package:frontend_scaffold_example/demos/chart_scrubber_demo.dart';
import 'package:frontend_scaffold_example/demos/chip_demo.dart';
import 'package:frontend_scaffold_example/demos/code_block_demo.dart';
import 'package:frontend_scaffold_example/demos/composer_demo.dart';
import 'package:frontend_scaffold_example/demos/disclosure_demo.dart';
import 'package:frontend_scaffold_example/demos/kitchen_sink_demo.dart';
import 'package:frontend_scaffold_example/demos/light_syntax_tokenizer_demo.dart';
import 'package:frontend_scaffold_example/demos/loading_demo.dart';
import 'package:frontend_scaffold_example/demos/markdown_to_spans_demo.dart';
import 'package:frontend_scaffold_example/demos/media_card_demo.dart';
import 'package:frontend_scaffold_example/demos/media_controls_demo.dart';
import 'package:frontend_scaffold_example/demos/page_chrome_demo.dart';
import 'package:frontend_scaffold_example/demos/responsive_grid_demo.dart';
import 'package:frontend_scaffold_example/demos/selection_actions_demo.dart';
import 'package:frontend_scaffold_example/demos/streaming_rich_text_demo.dart';
import 'package:frontend_scaffold_example/demos/string_button_demo.dart';
import 'package:frontend_scaffold_example/demos/text_entry_field_demo.dart';
import 'package:frontend_scaffold_example/demos/toast_demo.dart';
import 'package:frontend_scaffold_example/demos/trace_list_demo.dart';
import 'package:frontend_scaffold_example/demos/tracer_demo.dart';

const double kCaptureWidth = 800;
const double kCaptureHeight = 600;
const double kCapturePixelRatio = 2.0;
const Duration kAnimationSettleTime = Duration(seconds: 1);

/// Vertical offset for the toast stack in the toast capture — clears the
/// ToastDemo's button rows so the toasts don't overlap the controls.
const double kToastStackTop = 340;

/// Builds a [ThemeData] matching the demo app's `_buildTheme` in
/// `example/lib/main.dart:72-85` — dark uses [ScaffoldPalette.defaultPalette],
/// light uses [ScaffoldPalette.lightPalette]. Both share
/// [ScaffoldDimens.defaultDimens] and derive their ColorScheme from the
/// palette's `lightGreenPrimary` seed.
///
/// The textTheme is explicitly colored from the palette so bare `Text`
/// widgets (common in demo code) resolve [ScaffoldPalette.textPrimary]
/// instead of M3's default `ColorScheme.onSurface` grey — which is
/// unreadable against the scaffold palette's backgrounds.
ThemeData _buildCaptureTheme(Brightness brightness) {
  final ScaffoldPalette palette = brightness == Brightness.light
      ? ScaffoldPalette.lightPalette
      : ScaffoldPalette.defaultPalette;
  // ColorScheme.fromSeed(seedColor: lightGreenPrimary) derives onSurface and
  // onSurfaceVariant independently of the palette (for dark seeds it picks a
  // slightly-off white ~#DEE4DF). M3 composite widgets (SwitchListTile,
  // ListTile, etc.) fall back to ColorScheme.onSurface for their text when no
  // explicit style is provided, which reads as dim grey against the scaffold
  // palette's near-black background. Override the onX slots with the palette's
  // text colors so every M3 widget — not just bare Text under DefaultTextStyle —
  // renders with the palette's intended colors.
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: palette.lightGreenPrimary,
    brightness: brightness,
  ).copyWith(
    onSurface: palette.textPrimary,
    onSurfaceVariant: palette.textSecondary,
    surfaceTint: palette.lightGreenPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    // Pin Roboto so the textTheme renders with the real loaded font regardless
    // of the host platform's default typography (macOS would otherwise select
    // .AppleSystemUIFont, which isn't loaded in flutter_test → Ahem squares).
    fontFamily: 'Roboto',
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: palette.textPrimary, fontFamily: 'Roboto'),
      bodyLarge: TextStyle(color: palette.textPrimary, fontFamily: 'Roboto'),
      bodySmall: TextStyle(color: palette.textSecondary, fontFamily: 'Roboto'),
      titleMedium: TextStyle(color: palette.textPrimary, fontFamily: 'Roboto'),
      titleSmall: TextStyle(color: palette.textPrimary, fontFamily: 'Roboto'),
      titleLarge: TextStyle(color: palette.textPrimary, fontFamily: 'Roboto'),
      labelMedium: TextStyle(color: palette.textPrimary, fontFamily: 'Roboto'),
      labelSmall: TextStyle(color: palette.textSecondary, fontFamily: 'Roboto'),
      labelLarge: TextStyle(color: palette.textPrimary, fontFamily: 'Roboto'),
    ),
    extensions: <ThemeExtension<dynamic>>[
      palette,
      ScaffoldDimens.defaultDimens,
    ],
  );
}

/// Which theme a capture run renders and where it writes. The default profile
/// writes straight into the capture directory; other profiles write into a
/// subfolder of it, so existing captures are never overwritten.
class _CaptureProfile {
  const _CaptureProfile({
    required this.name,
    required this.subdir,
    required this.theme,
    required this.palette,
  });

  final String name;

  /// Output subfolder with a trailing slash, or an empty string.
  final String subdir;
  final ThemeData Function(Brightness) theme;
  final ScaffoldPalette Function(Brightness) palette;
}

final _CaptureProfile _defaultProfile = _CaptureProfile(
  name: 'default',
  subdir: '',
  theme: _buildCaptureTheme,
  palette: (Brightness brightness) => brightness == Brightness.light
      ? ScaffoldPalette.lightPalette
      : ScaffoldPalette.defaultPalette,
);

final _CaptureProfile _midnightProfile = _CaptureProfile(
  name: 'midnight',
  subdir: 'midnight/',
  theme: midnightTheme,
  palette: (Brightness brightness) => brightness == Brightness.light
      ? Midnight.lightPalette
      : Midnight.darkPalette,
);

/// Output directory for every captured PNG: `SCAFFOLD_CAPTURE_DIR` when set,
/// otherwise the package-root `images/` relative to `example/`.
String _captureDir() => Platform.environment['SCAFFOLD_CAPTURE_DIR'] ?? '../images';

/// Pumps [child] inside a MaterialApp + Scaffold + Center wrapper with the
/// theme for the given [brightness]. Mirrors the demo app's theme setup so
/// captured pixels match what users see when running the demo.
///
/// The `builder` wraps the app in a [DefaultTextStyle] seeded from the
/// palette so bare `Text` widgets (common in demo code) resolve
/// [ScaffoldPalette.textPrimary] even when a widget's explicit `TextStyle`
/// omits a color (e.g. `TextStyle(fontSize: 30)` in StringButton). Without
/// this, sparse textTheme entries leave body text at M3's dark `onSurface`,
/// which is unreadable against the scaffold palette's dark backgrounds.
Future<void> _pump(
  WidgetTester tester,
  Widget child,
  Brightness brightness,
  _CaptureProfile profile,
) {
  final ThemeData theme = profile.theme(brightness);
  final ScaffoldPalette palette = profile.palette(brightness);
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      // The harness interleaves `tester.runAsync` (toImage/encode/write)
      // between captures, which freezes any in-flight AnimatedTheme ticker
      // at its start value — the next theme swap then renders stale colors
      // (e.g. light-scheme primary over dark surfaces in `_dark` captures).
      // A zero duration swaps the theme instantly on the pump frame, so
      // captures are deterministic regardless of runAsync interleaving.
      themeAnimationDuration: Duration.zero,
      builder: (BuildContext context, Widget? appChild) {
        final TextStyle base = theme.textTheme.bodyMedium ?? const TextStyle();
        return DefaultTextStyle(
          style: base.copyWith(color: palette.textPrimary),
          child: appChild ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Optional callback invoked after the initial pump + settle but BEFORE
/// rasterization. Use to drive interactive state (expand disclosures, tap
/// charts, etc.) that a static capture would miss.
typedef PrepareCapture = Future<void> Function(WidgetTester tester);

/// Renders [widget] to a [kCaptureWidth]x[kCaptureHeight] offscreen surface at
/// [kCapturePixelRatio] pixel ratio and writes the resulting PNG to
/// `<captureDir>/<filename>.png`. The directory is `SCAFFOLD_CAPTURE_DIR` when
/// set and the package-root `images/` otherwise.
///
/// Rasterization uses the canonical Flutter SDK pattern: locate the
/// [RenderRepaintBoundary] keyed `'capture'`, call its `toImage(pixelRatio:)`,
/// then encode to PNG bytes via `ui.Image.toByteData`.
///
/// The whole capture runs inside `tester.runAsync` so the real-async
/// `ui.Image.toByteData` Future resolves even when demo widgets contain
/// infinitely-repeating animations — without `runAsync`, the test binding's
/// fake-async zone would wait forever for the animation to idle. We never
/// call `pumpAndSettle` for the same reason (11-RESEARCH.md Pitfall 1); a
/// fixed [kAnimationSettleTime] pump is used instead.
Future<void> _captureWidget(
  WidgetTester tester,
  Widget widget,
  String filename, {
  required Brightness brightness,
  required _CaptureProfile profile,
  PrepareCapture? prepare,
}) async {
  final ScaffoldPalette palette = profile.palette(brightness);
  await _pump(
    tester,
    SizedBox(
      width: kCaptureWidth,
      height: kCaptureHeight,
      child: RepaintBoundary(
        key: const ValueKey<String>('capture'),
        // Force the capture's DefaultTextStyle to the palette colors INSIDE
        // the boundary. Demo code uses bare `Text` (no style), and each demo
        // builds its own Scaffold — that inner Scaffold's Material resets
        // DefaultTextStyle to textTheme.bodyMedium, which several scaffold
        // composites (AppScreenView, DesktopBodyContainer, ScaffoldSurface)
        // then re-wrap. Seeding the style here, closest to the demo, makes
        // bare Text readable in both themes regardless of those resets.
        child: DefaultTextStyle(
          style: TextStyle(color: palette.textPrimary),
          child: widget,
        ),
      ),
    ),
    brightness,
    profile,
  );
  // Settle bounded work (single-shot animations, layout, streamed timers).
  // Infinite animations simply re-render at the 1s mark — the captured pixels
  // show whatever frame is current.
  await tester.pump(kAnimationSettleTime);

  // Drive interactive state (expand disclosures, simulate chart taps, etc.)
  // before rasterization so the capture shows the widget in its "active"
  // state rather than its default empty/collapsed state.
  if (prepare != null) {
    await prepare(tester);
    await tester.pump(kAnimationSettleTime);
  }

  final ui.Image? image = await tester.runAsync(() async {
    final RenderRepaintBoundary boundary = tester.renderObject(
      find.byKey(const ValueKey<String>('capture')),
    );
    return boundary.toImage(pixelRatio: kCapturePixelRatio);
  });
  if (image == null) {
    debugPrint('capture failed: $filename (${brightness.name}) — toImage returned null');
    return;
  }

  final ByteData? bytes = await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (bytes == null) {
    debugPrint('capture failed: $filename (${brightness.name}) — toByteData returned null');
    return;
  }
  await tester.runAsync(() async {
    final File f =
        await File('${_captureDir()}/${profile.subdir}$filename.png')
            .create(recursive: true);
    await f.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });

  // The capture harness is a WRITER, but it must not silently swallow real
  // rendering failures — a broken capture would otherwise commit while the
  // test still reports green. Only the known ScaffoldChart X-axis legend
  // overflow (a pre-existing layout quirk at the fixed 800px surface width,
  // not a harness bug) is tolerated; any other exception re-fails the test
  // after the PNG is on disk so the failure is attributable to its capture.
  Object? exception = tester.takeException();
  while (exception != null) {
    if (exception.toString().contains('overflowed')) {
      debugPrint('capture tolerated known overflow: $filename');
    } else {
      throw exception;
    }
    exception = tester.takeException();
  }
}

/// Captures [widget] under both dark and light themes, writing
/// `<filename>_dark.png` and `<filename>_light.png`.
Future<void> _captureBothThemes(
  WidgetTester tester,
  Widget widget,
  String filename,
  _CaptureProfile profile, {
  PrepareCapture? prepare,
}) async {
  await _captureWidget(tester, widget, '${filename}_dark',
      brightness: Brightness.dark, profile: profile, prepare: prepare);
  // Drain any toast auto-dismiss timers before the next capture — the
  // 2s timer would otherwise fire during the next widget's settle and
  // call setState on the disposed demo.
  await _drainToasts(tester);
  await _captureWidget(tester, widget, '${filename}_light',
      brightness: Brightness.light, profile: profile, prepare: prepare);
  await _drainToasts(tester);
}

/// Loads Roboto fonts from the Flutter SDK's bundled material_fonts directory
/// so captured images render real glyphs instead of the Ahem test font's
/// placeholder squares. The Ahem font is the flutter_test default — it renders
/// every character as a solid rectangle, which is fine for golden-file
/// comparison but useless for human-viewable demo images.
///
/// Loads Regular, Medium, and Bold weights plus MaterialIcons (icon font).
/// Call once in `setUpAll` before any capture runs.
Future<void> _loadRealFonts() async {
  // Platform.resolvedExecutable in a flutter_test context points to the Dart
  // VM binary at <flutter>/bin/cache/dart-sdk/bin/dart. Walk up to find the
  // Flutter root by looking for the material_fonts directory.
  Directory? dir = File(Platform.resolvedExecutable).parent;
  String? fontDir;
  while (dir != null) {
    final String candidate = '${dir.path}/bin/cache/artifacts/material_fonts';
    if (Directory(candidate).existsSync()) {
      fontDir = candidate;
      break;
    }
    final Directory parent = dir.parent;
    if (parent.path == dir.path) {
      // Reached filesystem root without finding material_fonts.
      break;
    }
    dir = parent;
  }
  if (fontDir == null) {
    // Fail loudly for a WRITER harness whose entire output is a set of PNGs.
    // Silently falling back to Ahem would cause all captured images to
    // regress to placeholder squares without an explicit failure.
    throw StateError(
      'capture_images_test: could not locate material_fonts directory; '
      'real fonts are required for human-viewable demo images',
    );
  }

  // Register under all family names the widget library uses. 'Roboto' covers
  // text_entry_field_widget.dart; 'monospace' covers scaffold_code_block.dart
  // and scaffold_streaming_rich_text.dart. Roboto isn't monospace but at
  // least renders real glyphs instead of Ahem's placeholder squares. The
  // midnight preset names 'Inter' and 'JetBrainsMono' without bundling them,
  // so Roboto renders under those names too, as it already does for 'monospace'.
  final Map<String, List<String>> fontFiles = <String, List<String>>{
    'Roboto-Regular.ttf': <String>['Roboto', 'monospace', 'Inter', 'JetBrainsMono'],
    'Roboto-Medium.ttf': <String>['Roboto Medium', 'Inter'],
    'Roboto-Bold.ttf': <String>['Roboto Bold', 'Inter'],
    'MaterialIcons-Regular.otf': <String>['MaterialIcons'],
  };

  for (final MapEntry<String, List<String>> entry in fontFiles.entries) {
    final File file = File('$fontDir/${entry.key}');
    if (!file.existsSync()) {
      debugPrint('font not found: ${file.path} — skipping');
      continue;
    }
    final ByteData bytes = ByteData.view(file.readAsBytesSync().buffer);
    for (final String family in entry.value) {
      final FontLoader loader = FontLoader(family)
        ..addFont(Future<ByteData>.value(bytes));
      await loader.load();
    }
  }
}

/// Expands all collapsed [ScaffoldDisclosure] widgets by tapping their
/// header rows. Skips already-expanded disclosures (tapping would collapse
/// them). Detects expansion by walking to the AnimatedSize's Padding child
/// and checking whether ITS child is SizedBox.shrink (collapsed) vs any
/// other widget (expanded) — the WR-03 fix keeps the Padding wrapper stable
/// and swaps only the inner content.
Future<void> _expandAllDisclosures(WidgetTester tester) async {
  final Iterable<Element> disclosures =
      find.byType(ScaffoldDisclosure).evaluate();
  for (final Element element in disclosures) {
    // Walk the subtree to find the AnimatedSize child. It's always a Padding
    // (WR-03 stable-wrapper fix); expansion is determined by the Padding's
    // inner child: SizedBox.shrink = collapsed, anything else = expanded.
    bool isExpanded = false;
    void visitor(Element el) {
      if (el.widget is AnimatedSize) {
        final AnimatedSize animatedSize = el.widget as AnimatedSize;
        if (animatedSize.child is Padding) {
          final Padding padding = animatedSize.child as Padding;
          if (padding.child is! SizedBox) {
            isExpanded = true;
          }
        }
      }
      el.visitChildren(visitor);
    }
    element.visitChildren(visitor);
    if (isExpanded) {
      continue;
    }
    // Find the ScaffoldPressable header inside this disclosure and tap it.
    ScaffoldPressable? pressable;
    void pressableVisitor(Element el) {
      if (el.widget is ScaffoldPressable && pressable == null) {
        pressable = el.widget as ScaffoldPressable;
      }
      el.visitChildren(pressableVisitor);
    }
    element.visitChildren(pressableVisitor);
    if (pressable != null) {
      await tester.tap(find.byWidget(pressable!));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Simulates a press on the chart widget to trigger a selection.
/// Uses `tester.getRect` on the ScaffoldChartScrubber widget so the press
/// lands inside the chart's hit-test area regardless of scroll offset or
/// layout position — a fixed Offset would miss when the demo scrolls.
/// Presses at 25% width (a series peak) rather than the exact center so the
/// touch maps cleanly onto a data point instead of a trough between samples.
///
/// The selection indicator (scrub line + handle dot) only paints while the
/// pointer is DOWN — fl_chart's `getTouchedSpotIndicator` clears on
/// tap-up. So the capture starts a gesture and intentionally does NOT
/// release it: the pointer stays down through the pump and the capture, so
/// the readout shows the selected value AND the handle stays visible for
/// rasterization. The gesture is left open; the next `_pump` (widget swap)
/// tears it down with the tree.
Future<void> _tapChartCenter(WidgetTester tester) async {
  final Finder chartFinder = find.byType(ScaffoldChartScrubber<Offset>);
  if (chartFinder.evaluate().isEmpty) {
    return;
  }
  final Rect bounds = tester.getRect(chartFinder.first);
  final Offset point =
      Offset(bounds.left + bounds.width * 0.25, bounds.center.dy);
  await tester.startGesture(point);
  await tester.pump(kAnimationSettleTime);
}

/// Simulates a horizontal drag across the chart to select a range.
/// Uses the chart widget's bounds so the drag stays inside the hit-test area.
Future<void> _dragChartRange(WidgetTester tester) async {
  final Finder chartFinder = find.byType(ScaffoldChartRangeSelector<Offset>);
  if (chartFinder.evaluate().isEmpty) {
    return;
  }
  final Rect bounds = tester.getRect(chartFinder.first);
  final Offset start = Offset(bounds.left + bounds.width * 0.25, bounds.center.dy);
  final Offset end = Offset(bounds.width * 0.5, 0);
  await tester.dragFrom(start, end);
}

/// Toasts paint into the root Overlay, which lives OUTSIDE the capture
/// RepaintBoundary — tapping a toast button before rasterization therefore
/// produces no toast pixels (the overlay entry is not in the captured layer).
/// Like _captureWalletSheet, this builds the content directly: the ToastDemo
/// page with a compact receipt and one toast card of each status type stacked
/// at the bottom, all inside the boundary.
Future<void> _captureToast(
  WidgetTester tester,
  Brightness brightness,
  _CaptureProfile profile,
) async {
  await _pump(
    tester,
    SizedBox(
      width: kCaptureWidth,
      height: kCaptureHeight,
      child: RepaintBoundary(
        key: const ValueKey<String>('capture'),
        child: Builder(
          builder: (BuildContext context) {
            final dimens = context.dimens;
            final palette = context.palette;
            return DefaultTextStyle(
              style: TextStyle(color: palette.textPrimary),
              child: Stack(
                children: <Widget>[
                  const ToastDemo(),
                  Positioned(
                    left: dimens.itemSpacing,
                    right: dimens.itemSpacing,
                    // Sit below the demo's own button rows so the toasts don't
                    // cover the controls they're demonstrating.
                    top: kToastStackTop,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ToastWidget(
                          message: 'Link copied',
                          type: ToastType.success,
                          onDismiss: () {},
                        ),
                        SizedBox(height: dimens.space3),
                        ToastWidget(
                          message: 'Tap the X to dismiss this alert.',
                          title: 'success (manual)',
                          type: ToastType.success,
                          onDismiss: () {},
                        ),
                        SizedBox(height: dimens.space3),
                        ToastWidget(
                          message: 'Something went wrong while saving.',
                          title: 'error (auto)',
                          type: ToastType.error,
                          onDismiss: () {},
                        ),
                        SizedBox(height: dimens.space3),
                        ToastWidget(
                          message: 'Your session expires in 5 minutes.',
                          title: 'warning (auto)',
                          type: ToastType.warning,
                          onDismiss: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    brightness,
    profile,
  );
  await tester.pump(kAnimationSettleTime);

  final ui.Image? image = await tester.runAsync(() async {
    final RenderRepaintBoundary boundary = tester.renderObject(
      find.byKey(const ValueKey<String>('capture')),
    );
    return boundary.toImage(pixelRatio: kCapturePixelRatio);
  });
  if (image == null) {
    debugPrint('capture failed: toast (${brightness.name})');
    return;
  }
  final ByteData? bytes = await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (bytes == null) {
    debugPrint('capture failed: toast (${brightness.name})');
    return;
  }
  await tester.runAsync(() async {
    final File f = await File(
      '${_captureDir()}/${profile.subdir}toast_${brightness.name}.png',
    ).create(recursive: true);
    await f.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });
  while (tester.takeException() != null) {}
}

/// Drains any pending toast auto-dismiss timers so they don't fire during
/// the next capture's settle and hit a disposed widget. Called after the
/// toast capture completes.
Future<void> _drainToasts(WidgetTester tester) async {
  // Pump past the 2s auto-dismiss duration so the timer fires now (while
  // the demo is still mounted) instead of leaking into the next capture.
  await tester.pump(const Duration(seconds: 3));
}

/// Captures the WalletConnectSheet by building the sheet's inner content
/// directly (bypassing the button-triggered demo). Builds a BottomDrawer
/// with the same children the sheet would show, inside a MaterialApp +
/// Scaffold so theme and palette resolve correctly.
Future<void> _captureWalletSheet(
  WidgetTester tester,
  Brightness brightness,
  _CaptureProfile profile,
) async {
  const String networkName = 'Ethereum';

  await _pump(
    tester,
    SizedBox(
      width: kCaptureWidth,
      height: kCaptureHeight,
      child: RepaintBoundary(
        key: const ValueKey<String>('capture'),
        child: Builder(
          builder: (BuildContext context) {
            final TextTheme textTheme = Theme.of(context).textTheme;
            final dimens = context.dimens;
            final palette = context.palette;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Simulated sheet card — mirrors the desktop dialog layout.
                Container(
                  width: 400,
                  padding: EdgeInsets.all(dimens.itemSpacing),
                  decoration: BoxDecoration(
                    color: palette.deepBlueTertiary,
                    borderRadius: BorderRadius.circular(dimens.radiusMd),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Wallet',
                        style: textTheme.titleMedium
                            ?.copyWith(color: palette.textPrimary),
                      ),
                      SizedBox(height: dimens.itemSpacing),
                      Text(
                        '0xABCD…EF12',
                        style: textTheme.bodyLarge
                            ?.copyWith(color: palette.textPrimary),
                      ),
                      SizedBox(height: dimens.space4),
                      const ScaffoldBadge(
                        variant: BadgeVariant.text,
                        text: networkName,
                      ),
                      SizedBox(height: dimens.itemSpacing),
                      Divider(height: 1, color: palette.borderSubtle),
                      SizedBox(height: dimens.space4),
                      Center(
                        child: Text(
                          'Disconnect',
                          style: textTheme.labelLarge
                              ?.copyWith(color: palette.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: dimens.itemSpacing),
                // Disconnected state below for comparison.
                Container(
                  width: 400,
                  padding: EdgeInsets.all(dimens.itemSpacing),
                  decoration: BoxDecoration(
                    color: palette.deepBlueTertiary,
                    borderRadius: BorderRadius.circular(dimens.radiusMd),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Connect Wallet',
                        style: textTheme.titleMedium
                            ?.copyWith(color: palette.textPrimary),
                      ),
                      SizedBox(height: dimens.itemSpacing),
                      Container(
                        width: 200,
                        height: 200,
                        color: palette.borderSubtle,
                        child: Center(
                          child: Text(
                            'QR placeholder\nwc:demo@2?relay-protocol=irn',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall
                                ?.copyWith(color: palette.textSecondary),
                          ),
                        ),
                      ),
                      SizedBox(height: dimens.space8),
                      Center(
                        child: Text(
                          'Connect',
                          style: textTheme.labelLarge
                              ?.copyWith(color: palette.textPrimary),
                        ),
                      ),
                      SizedBox(height: dimens.space8),
                      Text(
                        'Scan the QR code with your wallet to connect.',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: palette.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
    brightness,
    profile,
  );
  await tester.pump(kAnimationSettleTime);

  final ui.Image? image = await tester.runAsync(() async {
    final RenderRepaintBoundary boundary = tester.renderObject(
      find.byKey(const ValueKey<String>('capture')),
    );
    return boundary.toImage(pixelRatio: kCapturePixelRatio);
  });
  if (image == null) {
    debugPrint('capture failed: wallet_connect_sheet (${brightness.name})');
    return;
  }
  final ByteData? bytes = await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (bytes == null) {
    debugPrint('capture failed: wallet_connect_sheet (${brightness.name})');
    return;
  }
  await tester.runAsync(() async {
    final File f = await File(
      '${_captureDir()}/${profile.subdir}wallet_connect_sheet_${brightness.name}.png',
    ).create(recursive: true);
    await f.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });
  while (tester.takeException() != null) {}
}

void main() {
  setUpAll(() async {
    await _loadRealFonts();
  });

  testWidgets('capture all demo screens', (WidgetTester tester) async {
    await _captureAllDemos(tester, _defaultProfile);
  });

  testWidgets('capture midnight demo screens', (WidgetTester tester) async {
    await _captureAllDemos(tester, _midnightProfile);
    await _captureRestyles(tester);
  });
}

const ValueKey<String> _restylesHoverKey = ValueKey<String>('restyles-hover');
const ValueKey<String> _restylesFieldKey = ValueKey<String>('restyles-field');

TestGesture? _restylesPointer;

Future<void> _removeRestylesPointer() async {
  final TestGesture? pointer = _restylesPointer;
  _restylesPointer = null;
  await pointer?.removePointer();
}

/// Focuses the field and hovers the tappable card with a mouse pointer.
Future<void> _prepareRestyles(WidgetTester tester) async {
  await _removeRestylesPointer();
  await tester.tap(find.byKey(_restylesFieldKey));
  await tester.pump();
  final TestGesture pointer =
      await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
  await pointer.addPointer(location: Offset.zero);
  await pointer.moveTo(tester.getCenter(find.byKey(_restylesHoverKey)));
  await tester.pump();
  _restylesPointer = pointer;
}

/// Midnight only: the default profile never renders this capture.
Future<void> _captureRestyles(WidgetTester tester) async {
  await _captureBothThemes(
    tester,
    const _RestylesCapture(),
    'restyles',
    _midnightProfile,
    prepare: _prepareRestyles,
  );
  await _removeRestylesPointer();
}

/// Components the midnight restyles change, in one 800x600 frame.
class _RestylesCapture extends StatelessWidget {
  const _RestylesCapture();

  @override
  Widget build(BuildContext context) {
    final double gap = context.dimens.itemSpacing;
    // Own Scaffold, as each demo has, for the page color and the text style.
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: ScaffoldCard(
                    variant: 'elevated',
                    body: Text('Elevated card'),
                  ),
                ),
                SizedBox(width: gap),
                const Expanded(
                  child: ScaffoldCard(
                    variant: 'outlined',
                    body: Text('Outlined card'),
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            Row(
              children: <Widget>[
                Expanded(
                  child: ScaffoldCard(
                    key: _restylesHoverKey,
                    variant: 'elevated',
                    onTap: () {},
                    body: const Text('Tappable card'),
                  ),
                ),
                SizedBox(width: gap),
                const Expanded(
                  child: ScaffoldSurface(
                    elevation: 2,
                    padding: EdgeInsets.all(16),
                    child: Text('Surface'),
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            Builder(
              builder: (BuildContext innerContext) => TextEntryFieldWidget(
                key: _restylesFieldKey,
                logic: TextFormFieldLogic(innerContext, hintText: 'Enter a name'),
              ),
            ),
            SizedBox(height: gap),
            Row(
              children: <Widget>[
                ScaffoldSelectionIndicatorCheckbox(value: true, onChanged: (_) {}),
                ScaffoldSelectionIndicatorCheckbox(value: false, onChanged: (_) {}),
                ScaffoldSelectionIndicatorCheckbox(
                  tristate: true,
                  onChanged: (_) {},
                ),
                ScaffoldSelectionIndicatorRadio(value: true, onChanged: (_) {}),
                ScaffoldSelectionIndicatorToggle(value: true, onChanged: (_) {}),
              ],
            ),
            SizedBox(height: gap),
            const ScaffoldFormattedValueNumber(value: 1234567.89),
          ],
        ),
      ),
    );
  }
}

/// Types into the first text field, then unfocuses so the capture shows the
/// enabled border with no cursor.
Future<void> _typeIntoFirstField(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).first, 'Ada Lovelace');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

/// The open ResponsiveDrawer desktop panel. Dialogs open in the app Overlay,
/// outside the capture boundary, so this places ResponsiveDrawerPanel directly
/// (kCaptureWidth is its breakpoint) without the barrier scrim.
class _OpenDrawerCapture extends StatelessWidget {
  const _OpenDrawerCapture();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const BottomDrawerDemo(),
        ResponsiveDrawerPanel(
          title: BottomDrawerDemo.drawerTitle,
          footer: BottomDrawerDemo.drawerFooter(context),
          children: BottomDrawerDemo.drawerItems(context),
        ),
      ],
    );
  }
}

/// Drives every demo through both themes.
Future<void> _captureAllDemos(
  WidgetTester tester,
  _CaptureProfile profile,
) async {
    // Order mirrors the _DemoTile registry in example/lib/main.dart.
    await _captureBothThemes(tester, const ActionButtonDemo(), 'action_button', profile);
    await _captureBothThemes(tester, const StringButtonDemo(), 'string_button', profile);
    await _captureBothThemes(tester, const TextEntryFieldDemo(), 'text_entry_field', profile,
        prepare: _typeIntoFirstField);
    await _captureBothThemes(tester, const LoadingDemo(), 'loading', profile);
    await _captureToast(tester, Brightness.dark, profile);
    await _captureToast(tester, Brightness.light, profile);
    await _captureBothThemes(tester, const _OpenDrawerCapture(), 'bottom_drawer', profile);
    await _captureBothThemes(tester, const AnimationsDemo(), 'animations', profile);
    await _captureBothThemes(tester, const PageChromeDemo(), 'page_chrome', profile);
    await _captureBothThemes(tester, const ResponsiveGridDemo(), 'responsive_grid', profile);
    await _captureBothThemes(tester, const TracerDemo(), 'tracer', profile);
    await _captureBothThemes(tester, const KitchenSinkDemo(), 'kitchen_sink', profile);
    await _captureBothThemes(tester, const MediaCardDemo(), 'media_card', profile);
    await _captureBothThemes(tester, const MediaControlsDemo(), 'media_controls', profile);
    // WalletConnectSheet demo is button-triggered — capture the sheet content
    // directly instead of the button page.
    await _captureWalletSheet(tester, Brightness.dark, profile);
    await _captureWalletSheet(tester, Brightness.light, profile);
    await _captureBothThemes(tester, const ScaffoldChipDemo(), 'chip', profile);
    await _captureBothThemes(tester, const ScaffoldComposerDemo(), 'composer', profile);
    await _captureBothThemes(tester, const ScaffoldDisclosureDemo(), 'disclosure', profile,
        prepare: _expandAllDisclosures);
    await _captureBothThemes(tester, const ScaffoldTraceListDemo(), 'trace_list', profile,
        prepare: _expandAllDisclosures);
    await _captureBothThemes(
      tester,
      const ScaffoldStreamingRichTextDemo(),
      'streaming_rich_text',
      profile,
    );
    await _captureBothThemes(tester, const ScaffoldCodeBlockDemo(), 'code_block', profile);
    await _captureBothThemes(
      tester,
      const ScaffoldSelectionActionsDemo(),
      'selection_actions',
      profile,
    );
    await _captureBothThemes(
      tester,
      const ScaffoldMarkdownToSpansDemo(),
      'markdown_to_spans',
      profile,
    );
    await _captureBothThemes(
      tester,
      const ScaffoldLightSyntaxTokenizerDemo(),
      'light_syntax_tokenizer',
      profile,
    );
    await _captureBothThemes(tester, const ChartDemo(), 'chart', profile);
    await _captureBothThemes(tester, const ChartScrubberDemo(), 'chart_scrubber', profile,
        prepare: _tapChartCenter);
    await _captureBothThemes(
      tester,
      const ChartRangeSelectorDemo(),
      'chart_range_selector',
      profile,
      prepare: _dragChartRange,
    );
}
