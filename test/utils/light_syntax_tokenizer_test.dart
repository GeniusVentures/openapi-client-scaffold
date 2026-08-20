import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_code_block.dart';
import 'package:frontend_scaffold/utils/light_syntax_tokenizer.dart';

void main() {
  // Test 1 — dart keyword is colored as a keyword.
  test('dart keyword colored as keyword', () {
    final List<ScaffoldCodeSpan> spans =
        scaffoldLightTokenize('void main() {}', ScaffoldLightLanguage.dart);
    final ScaffoldCodeSpan keyword = spans.firstWhere(
      (ScaffoldCodeSpan s) => s.text == 'void',
    );
    expect(keyword.color, const Color(0xFF569CD6));
  });

  // Test 2 — string literal colored as string.
  test('dart string literal colored as string', () {
    final List<ScaffoldCodeSpan> spans =
        scaffoldLightTokenize("'hello'", ScaffoldLightLanguage.dart);
    expect(spans.length, 1);
    expect(spans[0].text, "'hello'");
    expect(spans[0].color, const Color(0xFFCE9178));
  });

  // Test 3 — comment colored as comment.
  test('dart line comment colored as comment', () {
    final List<ScaffoldCodeSpan> spans =
        scaffoldLightTokenize('// note', ScaffoldLightLanguage.dart);
    expect(spans.length, 1);
    expect(spans[0].text, '// note');
    expect(spans[0].color, const Color(0xFF6A9955));
  });

  // Test 4 — number colored as number.
  test('dart number colored as number', () {
    final List<ScaffoldCodeSpan> spans =
        scaffoldLightTokenize('42', ScaffoldLightLanguage.dart);
    expect(spans.length, 1);
    expect(spans[0].text, '42');
    expect(spans[0].color, const Color(0xFFB5CEA8));
  });

  // Test 5 — yaml key:value leaves both halves unhighlighted.
  test('yaml key/value remain unhighlighted', () {
    final List<ScaffoldCodeSpan> spans =
        scaffoldLightTokenize('name: value', ScaffoldLightLanguage.yaml);
    // Concatenation reconstructs the input.
    expect(
      spans.map((ScaffoldCodeSpan s) => s.text).join(),
      'name: value',
    );
    // No span carries a color — neither half matches a yaml keyword.
    for (final ScaffoldCodeSpan span in spans) {
      expect(span.color, isNull);
    }
  });

  // Test 6 — json literal colored as keyword.
  test('json true literal colored as keyword', () {
    final List<ScaffoldCodeSpan> spans =
        scaffoldLightTokenize('true', ScaffoldLightLanguage.json);
    expect(spans.length, 1);
    expect(spans[0].text, 'true');
    expect(spans[0].color, const Color(0xFF569CD6));
  });

  // Test 7 — plaintext returns a single span with color null.
  test('plaintext returns single uncolored span', () {
    const String input = 'plain text with // symbols and "quotes"';
    final List<ScaffoldCodeSpan> spans = scaffoldLightTokenize(
      input,
      ScaffoldLightLanguage.plaintext,
    );
    expect(spans.length, 1);
    expect(spans[0].text, input);
    expect(spans[0].color, isNull);
  });

  // Test 8 — round-trip: concatenating span.text reconstructs the input
  // exactly for a multi-line dart sample.
  test('round-trip: concatenated span text equals input', () {
    const String input = 'import \'dart:async\';\n'
        '\n'
        '/// Doc comment.\n'
        'void main() async {\n'
        '  final value = 42 + 3.14;\n'
        '  // trailing comment\n'
        '  print("hi \$value");\n'
        '}\n';
    final List<ScaffoldCodeSpan> spans =
        scaffoldLightTokenize(input, ScaffoldLightLanguage.dart);
    final String reconstructed =
        spans.map((ScaffoldCodeSpan s) => s.text).join();
    expect(reconstructed, input);

    // Sanity: keyword + comment + string + number spans are all present.
    expect(
      spans.any((ScaffoldCodeSpan s) => s.color == const Color(0xFF569CD6)),
      isTrue,
      reason: 'expected at least one keyword span',
    );
    expect(
      spans.any((ScaffoldCodeSpan s) => s.color == const Color(0xFF6A9955)),
      isTrue,
      reason: 'expected at least one comment span',
    );
    expect(
      spans.any((ScaffoldCodeSpan s) => s.color == const Color(0xFFCE9178)),
      isTrue,
      reason: 'expected at least one string span',
    );
    expect(
      spans.any((ScaffoldCodeSpan s) => s.color == const Color(0xFFB5CEA8)),
      isTrue,
      reason: 'expected at least one number span',
    );
  });
}
