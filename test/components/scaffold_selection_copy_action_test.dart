import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_selection_copy_action.dart';
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

  // Test 1 — renders Icons.copy 20px glyph inside a 48x48 hit area; label
  // via Semantics.
  testWidgets(
      'renders 20px copy glyph inside 48x48 hit area; label via Semantics',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionCopyAction(selectedText: 'snippet'),
    );

    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.copy));
    expect(icon.size, 20);

    final ScaffoldTouchTarget target = tester.widget<ScaffoldTouchTarget>(
      find.descendant(
        of: find.byType(ScaffoldSelectionCopyAction),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is ScaffoldTouchTarget && w.minWidth == 48 && w.minHeight == 48,
        ),
      ),
    );
    expect(target.minWidth, 48);
    expect(target.minHeight, 48);

    final Semantics buttonSemantics = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(ScaffoldSelectionCopyAction),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Copy',
        ),
      ),
    ).first;
    expect(buttonSemantics.properties.button, isTrue);
  });

  // Test 2 — onPressed calls Clipboard.setData with the selected text.
  testWidgets('onPressed writes selected text to clipboard', (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionCopyAction(selectedText: 'snippet'),
    );

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(capturedClipboardText, 'snippet');
  });

  // Test 3 — 300ms statusSuccess icon swap on copy, then revert.
  testWidgets('copied state swaps to statusSuccess check for 300ms then reverts',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldSelectionCopyAction(selectedText: 'snippet'),
    );

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    final Icon check = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(check.color, ScaffoldPalette.defaultPalette.statusSuccess);

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  // Test 4 — reduced-motion instant swap (zero-duration AnimatedSwitcher).
  testWidgets('reducedMotion yields zero-duration AnimatedSwitcher',
      (tester) async {
    await _pumpReducedMotion(
      tester,
      const ScaffoldSelectionCopyAction(selectedText: 'snippet'),
    );

    final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
  });

  // Test 5 — light palette renders without exception.
  testWidgets('renders under lightPalette without exception', (tester) async {
    await _pumpLight(
      tester,
      const ScaffoldSelectionCopyAction(selectedText: 'snippet'),
    );
    expect(find.byType(ScaffoldSelectionCopyAction), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });
}
