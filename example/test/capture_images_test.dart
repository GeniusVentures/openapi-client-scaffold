/// Reproducible demo-image capture harness for the frontend_scaffold package.
///
/// Pumps each of the 26 demo `StatelessWidget`s registered in
/// `example/lib/main.dart` under BOTH dark and light themes and writes two
/// PNGs per demo into the package-root `images/` directory
/// (`../images/<name>_dark.png` and `../images/<name>_light.png` relative to
/// `example/`).
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
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_chart_range_selector.dart';
import 'package:frontend_scaffold/components/scaffold_chart_scrubber.dart';
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/toast/toast_manager.dart';
import 'package:frontend_scaffold/components/toast/toast_widget.dart';
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
Future<void> _pump(WidgetTester tester, Widget child, Brightness brightness) {
  final ThemeData theme = _buildCaptureTheme(brightness);
  final ScaffoldPalette palette = brightness == Brightness.light
      ? ScaffoldPalette.lightPalette
      : ScaffoldPalette.defaultPalette;
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
/// `../images/<filename>.png` (package-root `images/`).
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
  PrepareCapture? prepare,
}) async {
  final ScaffoldPalette palette = brightness == Brightness.light
      ? ScaffoldPalette.lightPalette
      : ScaffoldPalette.defaultPalette;
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
        await File('../images/$filename.png').create(recursive: true);
    await f.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });

  // The capture harness is a WRITER, not an assertion. Drain any pending
  // rendering exceptions (e.g. the chart X-axis legend row overflows by 16px
  // at the fixed 800px surface width — a pre-existing ScaffoldChart layout
  // quirk at this size, not a harness bug) so they don't bubble up and fail
  // the test. Pixels are already on disk; layout warnings are out of scope.
  while (tester.takeException() != null) {
    // discard
  }
}

/// Captures [widget] under both dark and light themes, writing
/// `<filename>_dark.png` and `<filename>_light.png`.
Future<void> _captureBothThemes(
  WidgetTester tester,
  Widget widget,
  String filename, {
  PrepareCapture? prepare,
}) async {
  await _captureWidget(tester, widget, '${filename}_dark',
      brightness: Brightness.dark, prepare: prepare);
  // Drain any toast auto-dismiss timers before the next capture — the
  // 2s timer would otherwise fire during the next widget's settle and
  // call setState on the disposed demo.
  await _drainToasts(tester);
  await _captureWidget(tester, widget, '${filename}_light',
      brightness: Brightness.light, prepare: prepare);
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
  // least renders real glyphs instead of Ahem's placeholder squares.
  final Map<String, List<String>> fontFiles = <String, List<String>>{
    'Roboto-Regular.ttf': <String>['Roboto', 'monospace'],
    'Roboto-Medium.ttf': <String>['Roboto Medium'],
    'Roboto-Bold.ttf': <String>['Roboto Bold'],
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
Future<void> _captureToast(WidgetTester tester, Brightness brightness) async {
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
      '../images/toast_${brightness.name}.png',
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
      '../images/wallet_connect_sheet_${brightness.name}.png',
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
    await _captureAllDemos(tester);
  });
}

/// Drives every demo through both themes.
Future<void> _captureAllDemos(WidgetTester tester) async {
    // Order mirrors the _DemoTile registry in example/lib/main.dart.
    await _captureBothThemes(tester, const ActionButtonDemo(), 'action_button');
    await _captureBothThemes(tester, const StringButtonDemo(), 'string_button');
    await _captureBothThemes(tester, const TextEntryFieldDemo(), 'text_entry_field');
    await _captureBothThemes(tester, const LoadingDemo(), 'loading');
    await _captureToast(tester, Brightness.dark);
    await _captureToast(tester, Brightness.light);
    await _captureBothThemes(tester, const BottomDrawerDemo(), 'bottom_drawer');
    await _captureBothThemes(tester, const AnimationsDemo(), 'animations');
    await _captureBothThemes(tester, const PageChromeDemo(), 'page_chrome');
    await _captureBothThemes(tester, const ResponsiveGridDemo(), 'responsive_grid');
    await _captureBothThemes(tester, const TracerDemo(), 'tracer');
    await _captureBothThemes(tester, const KitchenSinkDemo(), 'kitchen_sink');
    await _captureBothThemes(tester, const MediaCardDemo(), 'media_card');
    await _captureBothThemes(tester, const MediaControlsDemo(), 'media_controls');
    // WalletConnectSheet demo is button-triggered — capture the sheet content
    // directly instead of the button page.
    await _captureWalletSheet(tester, Brightness.dark);
    await _captureWalletSheet(tester, Brightness.light);
    await _captureBothThemes(tester, const ScaffoldChipDemo(), 'chip');
    await _captureBothThemes(tester, const ScaffoldComposerDemo(), 'composer');
    await _captureBothThemes(tester, const ScaffoldDisclosureDemo(), 'disclosure',
        prepare: _expandAllDisclosures);
    await _captureBothThemes(tester, const ScaffoldTraceListDemo(), 'trace_list',
        prepare: _expandAllDisclosures);
    await _captureBothThemes(
      tester,
      const ScaffoldStreamingRichTextDemo(),
      'streaming_rich_text',
    );
    await _captureBothThemes(tester, const ScaffoldCodeBlockDemo(), 'code_block');
    await _captureBothThemes(
      tester,
      const ScaffoldSelectionActionsDemo(),
      'selection_actions',
    );
    await _captureBothThemes(
      tester,
      const ScaffoldMarkdownToSpansDemo(),
      'markdown_to_spans',
    );
    await _captureBothThemes(
      tester,
      const ScaffoldLightSyntaxTokenizerDemo(),
      'light_syntax_tokenizer',
    );
    await _captureBothThemes(tester, const ChartDemo(), 'chart');
    await _captureBothThemes(tester, const ChartScrubberDemo(), 'chart_scrubber',
        prepare: _tapChartCenter);
    await _captureBothThemes(
      tester,
      const ChartRangeSelectorDemo(),
      'chart_range_selector',
      prepare: _dragChartRange,
    );
}
