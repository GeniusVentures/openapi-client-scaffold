import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_copy_button.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Future<void> _pumpLight(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[
          ScaffoldPalette.lightPalette,
          ScaffoldDimens.defaultDimens,
        ],
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Future<void> _pumpReducedMotion(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: Center(
          child: ScaffoldMotion(reducedMotion: true, child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? capturedClipboardText;

  setUp(() {
    capturedClipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        capturedClipboardText =
            (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  // Test 1 — renders Icons.copy 20px glyph inside a 48x48 ScaffoldTouchTarget
  // with a labelMedium label.
  testWidgets(
      'renders 20px copy glyph inside 48x48 touch target with labelMedium label',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldStreamingCopyButton(textToCopy: 'payload'),
    );

    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.copy));
    expect(icon.size, 20);

    final ScaffoldTouchTarget target = tester.widget<ScaffoldTouchTarget>(
      find.descendant(
        of: find.byType(ScaffoldStreamingCopyButton),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is ScaffoldTouchTarget && w.minWidth == 48 && w.minHeight == 48,
        ),
      ),
    );
    expect(target.minWidth, 48);
    expect(target.minHeight, 48);

    final Text label = tester.widget<Text>(find.text('Copy'));
    final BuildContext ctx =
        tester.element(find.byType(ScaffoldStreamingCopyButton));
    expect(label.style, Theme.of(ctx).textTheme.labelMedium);
  });

  // Test 2 — onPressed writes to clipboard; icon swaps to check tinted
  // statusSuccess for 300ms, then reverts.
  testWidgets(
      'onPressed copies text and swaps icon to statusSuccess check for 300ms',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldStreamingCopyButton(textToCopy: 'payload'),
    );

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(capturedClipboardText, 'payload');
    final Icon check = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(check.color, ScaffoldPalette.defaultPalette.statusSuccess);

    // Step past the 300ms revert timer plus AnimatedSwitcher cross-fade.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  // Test 3 — armed=true tints the icon palette.lightGreenPrimary.
  testWidgets('armed=true tints icon lightGreenPrimary', (tester) async {
    await _pump(
      tester,
      const ScaffoldStreamingCopyButton(
        textToCopy: 'payload',
        armed: true,
      ),
    );

    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.copy));
    expect(icon.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);
  });

  // Test 4 — under reducedMotion the icon swap is a zero-duration
  // AnimatedSwitcher.
  testWidgets('reducedMotion yields zero-duration AnimatedSwitcher',
      (tester) async {
    await _pumpReducedMotion(
      tester,
      const ScaffoldStreamingCopyButton(textToCopy: 'payload'),
    );

    final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
  });

  // Test 5 — announceCopied=true wires a ScaffoldLiveRegion that announces
  // 'Copied' after press.
  testWidgets('announceCopied=true announces Copied via ScaffoldLiveRegion',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldStreamingCopyButton(
        textToCopy: 'payload',
        announceCopied: true,
      ),
    );

    ScaffoldLiveRegion region =
        tester.widget<ScaffoldLiveRegion>(find.byType(ScaffoldLiveRegion));
    expect(region.value, isNull);

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    region = tester.widget<ScaffoldLiveRegion>(find.byType(ScaffoldLiveRegion));
    expect(region.value, 'Copied');
  });

  // Test 6 — light palette renders without exception.
  testWidgets('renders under lightPalette without exception', (tester) async {
    await _pumpLight(
      tester,
      const ScaffoldStreamingCopyButton(textToCopy: 'payload'),
    );
    expect(find.byType(ScaffoldStreamingCopyButton), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });
}
