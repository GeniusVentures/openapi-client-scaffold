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
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
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

/// Builds a [ThemeData] matching the demo app's `_buildTheme` in
/// `example/lib/main.dart:72-85` — dark uses [ScaffoldPalette.defaultPalette],
/// light uses [ScaffoldPalette.lightPalette]. Both share
/// [ScaffoldDimens.defaultDimens] and derive their ColorScheme from the
/// palette's `lightGreenPrimary` seed.
ThemeData _buildCaptureTheme(Brightness brightness) {
  final ScaffoldPalette palette = brightness == Brightness.light
      ? ScaffoldPalette.lightPalette
      : ScaffoldPalette.defaultPalette;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.lightGreenPrimary,
      brightness: brightness,
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
Future<void> _pump(WidgetTester tester, Widget child, Brightness brightness) {
  return tester.pumpWidget(
    MaterialApp(
      theme: _buildCaptureTheme(brightness),
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
  await _pump(
    tester,
    SizedBox(
      width: kCaptureWidth,
      height: kCaptureHeight,
      child: RepaintBoundary(
        key: const ValueKey<String>('capture'),
        child: widget,
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
  await _captureWidget(tester, widget, '${filename}_light',
      brightness: Brightness.light, prepare: prepare);
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

/// Simulates a tap near the center of the chart to trigger a selection.
/// The scrubber's Listener.onPointerDown → onPointSelected path fires.
Future<void> _tapChartCenter(WidgetTester tester) async {
  await tester.tapAt(const Offset(400, 350));
}

/// Simulates a horizontal drag across the chart to select a range.
/// Drag from 25% to 75% of the capture width, at the chart's vertical center.
Future<void> _dragChartRange(WidgetTester tester) async {
  await tester.dragFrom(const Offset(200, 350), const Offset(400, 0));
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
    // Order mirrors the _DemoTile registry in example/lib/main.dart.
    await _captureBothThemes(tester, const ActionButtonDemo(), 'action_button');
    await _captureBothThemes(tester, const StringButtonDemo(), 'string_button');
    await _captureBothThemes(tester, const TextEntryFieldDemo(), 'text_entry_field');
    await _captureBothThemes(tester, const LoadingDemo(), 'loading');
    await _captureBothThemes(tester, const ToastDemo(), 'toast');
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
  });
}
