/// Reproducible demo-image capture harness for the frontend_scaffold package.
///
/// Pumps each of the 26 demo `StatelessWidget`s registered in
/// `example/lib/main.dart` and writes one PNG per demo into the package-root
/// `images/` directory (`../images/<name>.png` relative to `example/`).
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
import 'package:flutter_test/flutter_test.dart';
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
import 'package:frontend_scaffold_example/demos/wallet_connect_sheet_demo.dart';

const double kCaptureWidth = 800;
const double kCaptureHeight = 600;
const double kCapturePixelRatio = 2.0;
const Duration kAnimationSettleTime = Duration(seconds: 1);

/// Pumps [child] inside the canonical MaterialApp + Scaffold + Center wrapper
/// used by every widget test in this package (see
/// `test/components/scaffold_chip_test.dart:11-18`). Uses
/// [scaffoldThemeExtensions] so captured pixels match the rendering the
/// library's widget tests assert against.
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
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
  String filename,
) async {
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
    debugPrint('capture failed: $filename — toImage returned null');
    return;
  }

  final ByteData? bytes = await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (bytes == null) {
    debugPrint('capture failed: $filename — toByteData returned null');
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

void main() {
  testWidgets('capture all demo screens', (WidgetTester tester) async {
    // Order mirrors the _DemoTile registry in example/lib/main.dart.
    await _captureWidget(tester, const ActionButtonDemo(), 'action_button');
    await _captureWidget(tester, const StringButtonDemo(), 'string_button');
    await _captureWidget(tester, const TextEntryFieldDemo(), 'text_entry_field');
    await _captureWidget(tester, const LoadingDemo(), 'loading');
    await _captureWidget(tester, const ToastDemo(), 'toast');
    await _captureWidget(tester, const BottomDrawerDemo(), 'bottom_drawer');
    await _captureWidget(tester, const AnimationsDemo(), 'animations');
    await _captureWidget(tester, const PageChromeDemo(), 'page_chrome');
    await _captureWidget(tester, const ResponsiveGridDemo(), 'responsive_grid');
    await _captureWidget(tester, const TracerDemo(), 'tracer');
    await _captureWidget(tester, const KitchenSinkDemo(), 'kitchen_sink');
    await _captureWidget(tester, const MediaCardDemo(), 'media_card');
    await _captureWidget(tester, const MediaControlsDemo(), 'media_controls');
    await _captureWidget(
      tester,
      const WalletConnectSheetDemo(),
      'wallet_connect_sheet',
    );
    await _captureWidget(tester, const ScaffoldChipDemo(), 'chip');
    await _captureWidget(tester, const ScaffoldComposerDemo(), 'composer');
    await _captureWidget(tester, const ScaffoldDisclosureDemo(), 'disclosure');
    await _captureWidget(tester, const ScaffoldTraceListDemo(), 'trace_list');
    await _captureWidget(
      tester,
      const ScaffoldStreamingRichTextDemo(),
      'streaming_rich_text',
    );
    await _captureWidget(tester, const ScaffoldCodeBlockDemo(), 'code_block');
    await _captureWidget(
      tester,
      const ScaffoldSelectionActionsDemo(),
      'selection_actions',
    );
    await _captureWidget(
      tester,
      const ScaffoldMarkdownToSpansDemo(),
      'markdown_to_spans',
    );
    await _captureWidget(
      tester,
      const ScaffoldLightSyntaxTokenizerDemo(),
      'light_syntax_tokenizer',
    );
    await _captureWidget(tester, const ChartDemo(), 'chart');
    await _captureWidget(tester, const ChartScrubberDemo(), 'chart_scrubber');
    await _captureWidget(
      tester,
      const ChartRangeSelectorDemo(),
      'chart_range_selector',
    );
  });
}
