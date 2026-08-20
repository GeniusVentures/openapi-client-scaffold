import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/utils/markdown_to_spans.dart';
import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';

void main() {
  // Test 1 — plain paragraph flattens to a text span + paragraph-boundary
  // newline marker.
  test('plain paragraph yields text + boundary newline', () {
    final List<ScaffoldRichSpan> spans = scaffoldMarkdownToSpans('hello world');
    expect(spans.length, 2);
    expect(spans[0], isA<ScaffoldTextSpan>());
    expect((spans[0] as ScaffoldTextSpan).text, 'hello world');
    expect(spans[1], isA<ScaffoldTextSpan>());
    expect((spans[1] as ScaffoldTextSpan).text, '\n\n');
  });

  // Test 2 — strong emphasis flattens to plain text (no styling baked in).
  test('strong emphasis flattens to plain text', () {
    final List<ScaffoldRichSpan> spans = scaffoldMarkdownToSpans('**bold**');
    final ScaffoldTextSpan first = spans.firstWhere(
      (ScaffoldRichSpan s) => s is ScaffoldTextSpan && s.text.isNotEmpty,
    ) as ScaffoldTextSpan;
    expect(first.text, 'bold');
    expect(first.styleOverride, isNull);
  });

  // Test 3 — inline code produces a ScaffoldCodeInlineSpan.
  test('inline code produces ScaffoldCodeInlineSpan', () {
    final List<ScaffoldRichSpan> spans = scaffoldMarkdownToSpans('`code`');
    expect(
      spans.any(
        (ScaffoldRichSpan s) =>
            s is ScaffoldCodeInlineSpan && s.code == 'code',
      ),
      isTrue,
    );
  });

  // Test 4 — link produces ScaffoldLinkSpan with parsed URI.
  test('link produces ScaffoldLinkSpan with parsed URI', () {
    final List<ScaffoldRichSpan> spans =
        scaffoldMarkdownToSpans('[text](https://x.com)');
    final ScaffoldLinkSpan link = spans.firstWhere(
      (ScaffoldRichSpan s) => s is ScaffoldLinkSpan,
    ) as ScaffoldLinkSpan;
    expect(link.text, 'text');
    expect(link.uri, Uri.parse('https://x.com'));
  });

  // Test 5 — heading flattens to text + paragraph-boundary newline.
  test('heading yields text + boundary newline', () {
    final List<ScaffoldRichSpan> spans = scaffoldMarkdownToSpans('# Title');
    expect(spans.length, 2);
    expect((spans[0] as ScaffoldTextSpan).text, 'Title');
    expect((spans[1] as ScaffoldTextSpan).text, '\n\n');
  });

  // Test 6 — citation pre-pass: `[^1]:` definition extracted; inline `[^1]`
  // rewritten as a ScaffoldCitationSpan carrying id '1'.
  test('citation definition + reference produces ScaffoldCitationSpan', () {
    const String source = '[^1]: Source One | Body text\n'
        '\n'
        'A paragraph citing the source [^1].';
    final List<ScaffoldRichSpan> spans = scaffoldMarkdownToSpans(source);
    final ScaffoldCitationSpan citation = spans.firstWhere(
      (ScaffoldRichSpan s) => s is ScaffoldCitationSpan,
    ) as ScaffoldCitationSpan;
    expect(citation.id, '1');
    expect(citation.marker, '[1]');
    expect(citation.title, 'Source One');
    expect(citation.body, 'Body text');
    // The definition line itself does not leak into the rendered spans.
    expect(
      spans.any(
        (ScaffoldRichSpan s) =>
            s is ScaffoldTextSpan && s.text.contains('[^1]:'),
      ),
      isFalse,
    );
  });

  // Test 7 — empty string returns an empty list.
  test('empty string returns empty list', () {
    expect(scaffoldMarkdownToSpans(''), isEmpty);
  });
}
