// ScaffoldCodeBlock demo for Phase 9 Plan 04 (WIDG-37/38).
//
// Demonstrates default rendering with line numbers, hidden line numbers,
// consumer-supplied highlighted spans (D-04 DI slot), horizontal overflow
// with right-edge fade, streamed line insertion, reduced-motion gating,
// and light-palette rendering.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_code_block.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

const String _kDartSample = '''
import 'dart:async';

void main() async {
  final count = 42;
  print('count: \$count');
}
''';

const String _kLongLine =
    'final String veryLongValue = someFunction(argumentOne, argumentTwo, argumentThree, argumentFour, argumentFive, argumentSix, argumentSeven, argumentEight, argumentNine);';

/// Demo for [ScaffoldCodeBlock] (WIDG-37/38).
class ScaffoldCodeBlockDemo extends StatelessWidget {
  const ScaffoldCodeBlockDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;

    final List<ScaffoldCodeLine> dartLines = _kDartSample
        .split('\n')
        .where((String s) => s.isNotEmpty)
        .map((String s) => ScaffoldCodeLine(rawText: s))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldCodeBlock')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Default (dart) ---
            Text('Default (dart)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldCodeBlock(
              language: 'dart',
              filename: 'main.dart',
              lines: dartLines,
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. No line numbers ---
            Text('No line numbers',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldCodeBlock(
              language: 'dart',
              filename: 'main.dart',
              showLineNumbers: false,
              lines: dartLines,
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. Highlighted (consumer-supplied spans) ---
            Text('Highlighted (consumer-supplied spans)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _HandHighlightedExample(),

            SizedBox(height: dimens.itemSpacing),

            // --- 4. Horizontal overflow ---
            Text('Horizontal overflow',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const ScaffoldCodeBlock(
              language: 'dart',
              filename: 'long.dart',
              lines: <ScaffoldCodeLine>[
                ScaffoldCodeLine(rawText: _kLongLine),
              ],
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 5. Streamed lines ---
            Text('Streamed lines',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _StreamedCodeExample(),

            SizedBox(height: dimens.itemSpacing),

            // --- 6. Reduced motion ---
            Text('Reduced motion',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const ScaffoldMotion(
              reducedMotion: true,
              child: _StreamedCodeExample(),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 7. Light palette ---
            Text('Light palette',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            Theme(
              data: ThemeData.light().copyWith(
                extensions: const <ThemeExtension<dynamic>>[
                  ScaffoldPalette.lightPalette,
                  ScaffoldDimens.defaultDimens,
                ],
              ),
              child: Builder(
                builder: (BuildContext context) {
                  final List<ScaffoldCodeLine> lightLines = _kDartSample
                      .split('\n')
                      .where((String s) => s.isNotEmpty)
                      .map((String s) => ScaffoldCodeLine(rawText: s))
                      .toList(growable: false);
                  return ScaffoldCodeBlock(
                    language: 'dart',
                    filename: 'main.dart',
                    lines: lightLines,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hand-highlighted lines demonstrating the D-04 DI slot without requiring
/// the Plan 05 tokenizer support part.
class _HandHighlightedExample extends StatelessWidget {
  const _HandHighlightedExample();

  @override
  Widget build(BuildContext context) {
    final ScaffoldPalette palette = context.palette;
    final Color keyword = palette.lightGreenPrimary;
    final Color identifier = palette.textPrimary;
    final Color stringLiteral = palette.statusWarningText;

    return ScaffoldCodeBlock(
      language: 'dart',
      filename: 'hand_highlighted.dart',
      lines: <ScaffoldCodeLine>[
        ScaffoldCodeLine(
          rawText: "import 'dart:async';",
          spans: <ScaffoldCodeSpan>[
            ScaffoldCodeSpan(text: 'import ', color: keyword),
            ScaffoldCodeSpan(text: "'dart:async'", color: stringLiteral),
            ScaffoldCodeSpan(text: ';', color: identifier),
          ],
        ),
        const ScaffoldCodeLine(rawText: ''),
        ScaffoldCodeLine(
          rawText: 'void main() async {',
          spans: <ScaffoldCodeSpan>[
            ScaffoldCodeSpan(text: 'void ', color: keyword),
            ScaffoldCodeSpan(text: 'main', color: identifier),
            ScaffoldCodeSpan(text: '() ', color: identifier),
            ScaffoldCodeSpan(text: 'async ', color: keyword),
            ScaffoldCodeSpan(text: '{', color: identifier),
          ],
        ),
        ScaffoldCodeLine(
          rawText: "  print('hello');",
          spans: <ScaffoldCodeSpan>[
            ScaffoldCodeSpan(text: '  print', color: identifier),
            ScaffoldCodeSpan(text: '(', color: identifier),
            ScaffoldCodeSpan(text: "'hello'", color: stringLiteral),
            ScaffoldCodeSpan(text: ');', color: identifier),
          ],
        ),
        ScaffoldCodeLine(
          rawText: '}',
          spans: <ScaffoldCodeSpan>[
            ScaffoldCodeSpan(text: '}', color: identifier),
          ],
        ),
      ],
    );
  }
}

/// Streamed code example — emits one line every 100ms via a Timer feeding a
/// [StreamController]; the atom fades each line in with 150ms decelerate.
class _StreamedCodeExample extends StatefulWidget {
  const _StreamedCodeExample();

  @override
  State<_StreamedCodeExample> createState() => _StreamedCodeExampleState();
}

class _StreamedCodeExampleState extends State<_StreamedCodeExample> {
  static const Duration _kLineInterval = Duration(milliseconds: 100);
  static const List<String> _kStreamedLines = <String>[
    'void main() {',
    '  final a = 1;',
    '  final b = 2;',
    '  print(a + b);',
    '}',
  ];

  late StreamController<List<ScaffoldCodeLine>> _controller;
  Timer? _timer;
  int _emitted = 0;

  @override
  void initState() {
    super.initState();
    _controller = StreamController<List<ScaffoldCodeLine>>();
  }

  void _startStream() {
    _timer?.cancel();
    _emitted = 0;
    _timer = Timer.periodic(_kLineInterval, (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_emitted >= _kStreamedLines.length) {
        t.cancel();
        return;
      }
      final String raw = _kStreamedLines[_emitted];
      _emitted += 1;
      _controller.add(<ScaffoldCodeLine>[ScaffoldCodeLine(rawText: raw)]);
    });
  }

  void _reset() {
    _timer?.cancel();
    _emitted = 0;
    _controller.close();
    setState(() {
      _controller = StreamController<List<ScaffoldCodeLine>>();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ScaffoldCodeBlock(
          language: 'dart',
          filename: 'streamed.dart',
          streamedLines: _controller.stream,
          highlightNewLines: true,
        ),
        SizedBox(height: dimens.space8),
        Row(
          children: <Widget>[
            TextButton(onPressed: _startStream, child: const Text('Stream 5 lines')),
            SizedBox(width: dimens.space4),
            TextButton(onPressed: _reset, child: const Text('Reset')),
          ],
        ),
      ],
    );
  }
}
