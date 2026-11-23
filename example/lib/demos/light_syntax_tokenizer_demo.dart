// scaffoldLightTokenize demo for Phase 9 Plan 05 (WIDG-37/38, D-04).
//
// Demonstrates the light regex-based syntax tokenizer feeding
// ScaffoldCodeBlock across dart / yaml / json samples, plus the D-04
// syntaxHighlighter DI hook firing through the atom.
//
// Palette note: the tokenizer's hardcoded colors are a REFERENCE
// IMPLEMENTATION ONLY. Consumers wanting palette-consistent highlighting
// should inject their own highlighter via `ScaffoldCodeBlock.syntaxHighlighter`.
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_code_block.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/utils/light_syntax_tokenizer.dart';

const String _kDartSample = '''
import 'dart:async';

/// Entry point.
void main() async {
  final count = 42; // a number
  print('count: \$count');
}
''';

const String _kYamlSample = '''
# comment
name: scaffold
version: 0.4.0
enabled: true
''';

const String _kJsonSample = '''
{
  "name": "scaffold",
  "version": "0.4.0",
  "enabled": true,
  "ports": [8000, 8001]
}
''';

/// Demo showing [scaffoldLightTokenize] across three languages plus the
/// D-04 syntaxHighlighter DI hook.
class ScaffoldLightSyntaxTokenizerDemo extends StatelessWidget {
  const ScaffoldLightSyntaxTokenizerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('scaffoldLightTokenize')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Dart sample ---
            Text('Dart', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _CodeSection(
              source: _kDartSample,
              language: ScaffoldLightLanguage.dart,
              languageTag: 'dart',
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. YAML sample ---
            Text('YAML', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _CodeSection(
              source: _kYamlSample,
              language: ScaffoldLightLanguage.yaml,
              languageTag: 'yaml',
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. JSON sample ---
            Text('JSON', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _CodeSection(
              source: _kJsonSample,
              language: ScaffoldLightLanguage.json,
              languageTag: 'json',
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 4. DI wiring demo (D-04 hook through the atom) ---
            Text('DI wiring (syntaxHighlighter callback)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldCodeBlock(
              language: 'dart',
              filename: 'di_wired.dart',
              syntaxHighlighter: (String raw) =>
                  scaffoldLightTokenize(raw, ScaffoldLightLanguage.dart),
              lines: _kDartSample
                  .split('\n')
                  .where((String s) => s.isNotEmpty)
                  .map((String s) => ScaffoldCodeLine(rawText: s))
                  .toList(growable: false),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 5. Light palette (reference colors only — see header) ---
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
              child: const _CodeSection(
                source: _kDartSample,
                language: ScaffoldLightLanguage.dart,
                languageTag: 'dart',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One [ScaffoldCodeBlock] whose body lines are pre-highlighted by
/// [scaffoldLightTokenize].
class _CodeSection extends StatelessWidget {
  const _CodeSection({
    required this.source,
    required this.language,
    required this.languageTag,
  });

  final String source;
  final ScaffoldLightLanguage language;
  final String languageTag;

  @override
  Widget build(BuildContext context) {
    final List<ScaffoldCodeLine> lines = source
        .split('\n')
        .map(
          (String raw) => ScaffoldCodeLine(
            rawText: raw,
            spans: raw.isEmpty ? null : scaffoldLightTokenize(raw, language),
          ),
        )
        .toList(growable: false);
    return ScaffoldCodeBlock(
      language: languageTag,
      lines: lines,
    );
  }
}
