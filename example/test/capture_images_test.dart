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
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';

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
import 'package:frontend_scaffold_example/demos/wallet_connect_sheet_demo.dart';

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
    await File('../images/$filename.png')
        .create(recursive: true)
        .then((File f) => f.writeAsBytes(bytes.buffer.asUint8List()));
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
  String filename,
) async {
  await _captureWidget(tester, widget, '${filename}_dark',
      brightness: Brightness.dark);
  await _captureWidget(tester, widget, '${filename}_light',
      brightness: Brightness.light);
}

/// Loads Roboto fonts from the Flutter SDK's bundled material_fonts directory
/// so captured images render real glyphs instead of the Ahem test font's
/// placeholder squares. The Ahem font is the flutter_test default — it renders
/// every character as a solid rectangle, which is fine for golden-file
/// comparison but useless for human-viewable demo images.
///
/// Loads Regular, Medium, and Bold weights. Call once in `setUpAll` before
/// any capture runs.
Future<void> _loadRealFonts() async {
  // Platform.resolvedExecutable in a flutter_test context points to the Dart
  // VM binary at <flutter>/bin/cache/dart-sdk/bin/dart. Walk up to find the
  // Flutter root by looking for the material_fonts directory.
  Directory dir = File(Platform.resolvedExecutable).parent;
  String? fontDir;
  for (int i = 0; i < 6; i++) {
    final String candidate = '${dir.path}/bin/cache/artifacts/material_fonts';
    if (Directory(candidate).existsSync()) {
      fontDir = candidate;
      break;
    }
    dir = dir.parent;
  }
  if (fontDir == null) {
    debugPrint('could not locate material_fonts directory — skipping font load');
    return;
  }

  // Register under all family names the widget library uses. 'Roboto' covers
  // text_entry_field_widget.dart; 'monospace' covers scaffold_code_block.dart
  // and scaffold_streaming_rich_text.dart. Roboto isn't monospace but at
  // least renders real glyphs instead of Ahem's placeholder squares.
  final Map<String, List<String>> fontFiles = <String, List<String>>{
    'Roboto-Regular.ttf': <String>['Roboto', 'monospace'],
    'Roboto-Medium.ttf': <String>['Roboto Medium'],
    'Roboto-Bold.ttf': <String>['Roboto Bold'],
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
    await _captureBothThemes(
      tester,
      const WalletConnectSheetDemo(),
      'wallet_connect_sheet',
    );
    await _captureBothThemes(tester, const ScaffoldChipDemo(), 'chip');
    await _captureBothThemes(tester, const ScaffoldComposerDemo(), 'composer');
    await _captureBothThemes(tester, const ScaffoldDisclosureDemo(), 'disclosure');
    await _captureBothThemes(tester, const ScaffoldTraceListDemo(), 'trace_list');
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
    await _captureBothThemes(tester, const ChartScrubberDemo(), 'chart_scrubber');
    await _captureBothThemes(
      tester,
      const ChartRangeSelectorDemo(),
      'chart_range_selector',
    );
  });
}
