import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_code_block.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_overflow_fade.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
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

/// Locates the OUTER [Container] backing the [ScaffoldSurface] that wraps
/// the code block (the one with the BoxDecoration carrying color+border).
Container _surfaceContainer(WidgetTester tester) {
  return tester.widgetList<Container>(
    find.descendant(
      of: find.byType(ScaffoldSurface),
      matching: find.byWidgetPredicate(
        (Widget w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).border != null,
      ),
    ),
  ).first;
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

  // Test 1 — surface + header (WIDG-37).
  testWidgets('surface renders deepBlueCardColor fill + borderSubtle border + header texts',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldCodeBlock(
        language: 'dart',
        filename: 'foo.dart',
        lines: <ScaffoldCodeLine>[
          ScaffoldCodeLine(rawText: 'void main() {}'),
        ],
      ),
    );

    final BoxDecoration decoration =
        _surfaceContainer(tester).decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
    final Border border = decoration.border! as Border;
    expect(border.top.color, ScaffoldPalette.defaultPalette.borderSubtle);
    expect(border.top.width, 1);

    final Text langText = tester.widget<Text>(find.text('dart'));
    final BuildContext ctx = tester.element(find.byType(ScaffoldCodeBlock));
    expect(
      langText.style?.color,
      ScaffoldPalette.defaultPalette.textSecondary,
    );
    expect(langText.style?.fontSize,
        Theme.of(ctx).textTheme.labelMedium?.fontSize);

    final Text fileText = tester.widget<Text>(find.text('foo.dart'));
    expect(fileText.style?.color, ScaffoldPalette.defaultPalette.textPrimary);
    expect(fileText.style?.fontSize,
        Theme.of(ctx).textTheme.titleSmall?.fontSize);
  });

  // Test 2 — line numbers + monospace body (WIDG-37).
  testWidgets('line-number gutter renders 1..N right-aligned monospace bodyMedium (matching body size); body is bodyMedium monospace height 1.5; gutter excluded from semantics',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldCodeBlock(
        showLineNumbers: true,
        lines: <ScaffoldCodeLine>[
          ScaffoldCodeLine(rawText: 'a'),
          ScaffoldCodeLine(rawText: 'b'),
          ScaffoldCodeLine(rawText: 'c'),
        ],
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    final Text one = tester.widget<Text>(find.text('1'));
    expect(one.style?.fontFamily, 'monospace');
    expect(one.style?.color, ScaffoldPalette.defaultPalette.textSecondary);
    expect(one.style?.height, 1.5);

    // Gutter MUST match the body font size (bodyMedium) so line numbers stay
    // vertically aligned with their code lines.
    final BuildContext gutterCtx =
        tester.element(find.byType(ScaffoldCodeBlock));
    final double? expectedGutterSize =
        Theme.of(gutterCtx).textTheme.bodyMedium?.fontSize;
    expect(one.style?.fontSize, expectedGutterSize);

    // Gutter column alignment is right-aligned.
    final Column gutterColumn = tester.widget<Column>(
      find.ancestor(of: find.text('1'), matching: find.byType(Column)).first,
    );
    expect(gutterColumn.crossAxisAlignment, CrossAxisAlignment.end);

    // Body texts render bodyMedium with monospace and height 1.5 — the body
    // is built via Text.rich so the style lives on textSpan, not on style.
    final BuildContext ctx = tester.element(find.byType(ScaffoldCodeBlock));
    final double? expectedSize =
        Theme.of(ctx).textTheme.bodyMedium?.fontSize;
    final Text body = tester.widget<Text>(find.text('a'));
    final TextStyle? bodyStyle = body.textSpan?.style;
    expect(bodyStyle?.fontFamily, 'monospace');
    expect(bodyStyle?.height, 1.5);
    expect(bodyStyle?.fontSize, expectedSize);
    expect(bodyStyle?.color, ScaffoldPalette.defaultPalette.textPrimary);

    // Gutter excluded from semantics tree.
    expect(find.byType(ExcludeSemantics), findsWidgets);
  });

  // Test 3 — line numbers hidden when showLineNumbers=false.
  testWidgets('showLineNumbers=false hides the gutter', (tester) async {
    await _pump(
      tester,
      const ScaffoldCodeBlock(
        showLineNumbers: false,
        lines: <ScaffoldCodeLine>[
          ScaffoldCodeLine(rawText: 'a'),
          ScaffoldCodeLine(rawText: 'b'),
        ],
      ),
    );

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
  });

  // Test 4 — copy action: clipboard receives raw text; icon swaps to check
  // then reverts after 300ms (WIDG-37).
  testWidgets('copy button writes concatenated rawText to clipboard; icon swaps and reverts',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldCodeBlock(
        lines: <ScaffoldCodeLine>[
          ScaffoldCodeLine(rawText: 'void main() {}'),
        ],
      ),
    );

    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(capturedClipboardText, 'void main() {}');
    // Immediately after tap: _isCopied=true so the check icon enters the tree
    // (cross-fade keeps both icons visible for the swap duration).
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Past the 300ms revert timer + AnimatedSwitcher cross-fade — the check
    // is fully gone and only copy remains. Step the clock so the swap has
    // intermediate frames to complete.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  // Test 5 — horizontal scroll + overflow fade (WIDG-38).
  testWidgets('body is wrapped in horizontal SingleChildScrollView + ScaffoldOverflowFade(right)',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldCodeBlock(
        lines: <ScaffoldCodeLine>[
          ScaffoldCodeLine(rawText: 'x'),
        ],
      ),
    );

    final SingleChildScrollView scroll = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(ScaffoldCodeBlock),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(scroll.scrollDirection, Axis.horizontal);

    final ScaffoldOverflowFade fade = tester.widget<ScaffoldOverflowFade>(
      find.descendant(
        of: find.byType(ScaffoldCodeBlock),
        matching: find.byType(ScaffoldOverflowFade),
      ),
    );
    expect(fade.fadeDirection, FadeDirection.right);
    expect(fade.fadeExtent, 24.0);
  });

  // Test 6 — streamed line insertion + reduced-motion instant insertion (WIDG-38).
  testWidgets('streamedLines append lines after pump; reduced-motion yields zero-duration AnimatedOpacity',
      (tester) async {
    final StreamController<List<ScaffoldCodeLine>> controller =
        StreamController<List<ScaffoldCodeLine>>.broadcast(sync: true);

    await _pump(
      tester,
      ScaffoldCodeBlock(
        lines: const <ScaffoldCodeLine>[
          ScaffoldCodeLine(rawText: 'line1'),
        ],
        streamedLines: controller.stream,
      ),
    );

    expect(find.text('line2'), findsNothing);

    controller.add(const <ScaffoldCodeLine>[
      ScaffoldCodeLine(rawText: 'line2'),
    ]);
    await tester.pump();
    expect(find.text('line2'), findsOneWidget);
    // Drive past the 150ms fade.
    await tester.pump(const Duration(milliseconds: 200));

    await controller.close();

    // Reduced-motion branch: AnimatedOpacity duration is zero.
    final StreamController<List<ScaffoldCodeLine>> controller2 =
        StreamController<List<ScaffoldCodeLine>>.broadcast(sync: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: Scaffold(
          body: Center(
            child: ScaffoldMotion(
              reducedMotion: true,
              child: ScaffoldCodeBlock(
                lines: const <ScaffoldCodeLine>[
                  ScaffoldCodeLine(rawText: 'a'),
                ],
                streamedLines: controller2.stream,
              ),
            ),
          ),
        ),
      ),
    );

    controller2.add(const <ScaffoldCodeLine>[
      ScaffoldCodeLine(rawText: 'b'),
    ]);
    await tester.pump();
    expect(find.text('b'), findsOneWidget);

    final AnimatedOpacity opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('b'),
        matching: find.byType(AnimatedOpacity),
      ).first,
    );
    expect(opacity.duration, Duration.zero);

    await controller2.close();
  });

  // Test 7 — pre-highlighted spans render with their own color; null color
  // falls back to palette.textPrimary.
  testWidgets('pre-highlighted spans render with supplied color; null falls back to textPrimary',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldCodeBlock(
        showLineNumbers: false,
        lines: <ScaffoldCodeLine>[
          ScaffoldCodeLine(
            rawText: 'void main',
            spans: <ScaffoldCodeSpan>[
              ScaffoldCodeSpan(text: 'void', color: Colors.blue),
              ScaffoldCodeSpan(text: ' main'),
            ],
          ),
        ],
      ),
    );

    // Find the Text.rich widget for the body and inspect its textSpan
    // directly — Text.rich keeps children on the root TextSpan.
    final List<Text> textWidgets = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ScaffoldCodeBlock),
            matching: find.byType(Text),
          ),
        )
        .toList();
    Text? body;
    for (final Text t in textWidgets) {
      final InlineSpan? span = t.textSpan;
      if (span is TextSpan && span.toPlainText() == 'void main') {
        body = t;
        break;
      }
    }
    expect(body, isNotNull);
    final TextSpan root = body!.textSpan! as TextSpan;
    final List<InlineSpan> children = root.children!;
    expect(children.length, 2);

    final TextSpan first = children[0] as TextSpan;
    final TextSpan second = children[1] as TextSpan;
    expect(first.text, 'void');
    expect(first.style?.color, Colors.blue);
    expect(second.text, ' main');
    expect(second.style?.color, ScaffoldPalette.defaultPalette.textPrimary);
  });

  // Test 8 — syntaxHighlighter DI: a line with no spans calls the highlighter.
  testWidgets('syntaxHighlighter DI callback supplies spans for lines without pre-highlighted spans',
      (tester) async {
    await _pump(
      tester,
      ScaffoldCodeBlock(
        showLineNumbers: false,
        syntaxHighlighter: (String raw) => <ScaffoldCodeSpan>[
          ScaffoldCodeSpan(text: raw, color: Colors.red),
        ],
        lines: const <ScaffoldCodeLine>[
          ScaffoldCodeLine(rawText: 'hello'),
        ],
      ),
    );

    // Find the Text.rich widget for the body and inspect its textSpan
    // directly — Text.rich keeps children on the root TextSpan.
    final List<Text> textWidgets = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ScaffoldCodeBlock),
            matching: find.byType(Text),
          ),
        )
        .toList();
    Text? body;
    for (final Text t in textWidgets) {
      final InlineSpan? span = t.textSpan;
      if (span is TextSpan && span.toPlainText() == 'hello') {
        body = t;
        break;
      }
    }
    expect(body, isNotNull);
    final TextSpan bodySpan = body!.textSpan! as TextSpan;
    expect(bodySpan.children, isNotNull);
    final TextSpan child = bodySpan.children!.single as TextSpan;
    expect(child.text, 'hello');
    expect(child.style?.color, Colors.red);
  });

  // Test 9 — empty lines collapse the body to SizedBox.shrink but header still renders.
  testWidgets('empty lines collapse the body; header still renders', (tester) async {
    await _pump(
      tester,
      const ScaffoldCodeBlock(
        language: 'dart',
        filename: 'empty.dart',
        lines: <ScaffoldCodeLine>[],
      ),
    );

    expect(find.text('dart'), findsOneWidget);
    expect(find.text('empty.dart'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    // No scroll view / overflow fade / gutter when body is empty.
    expect(
      find.descendant(
        of: find.byType(ScaffoldCodeBlock),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  // Test 10 — light palette renders without exception.
  testWidgets('renders under lightPalette without exception', (tester) async {
    await _pumpLight(
      tester,
      const ScaffoldCodeBlock(
        language: 'dart',
        filename: 'foo.dart',
        lines: <ScaffoldCodeLine>[
          ScaffoldCodeLine(rawText: 'void main() {}'),
        ],
      ),
    );
    expect(find.byType(ScaffoldCodeBlock), findsOneWidget);
    expect(find.text('foo.dart'), findsOneWidget);
  });
}
