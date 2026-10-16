/// Markdown -> typed-span mapper for ScaffoldStreamingRichText (D-03 support
/// part).
///
/// This is the ONLY scaffold file that imports `package:markdown`; consumers
/// who want typed atoms only do not pay for the dependency (D-08 isolation).
/// Pure function — no `BuildContext`, no widgets.
///
/// Citation convention (demo-only): the `markdown` package does not define
/// a citation syntax, so this mapper recognizes a footnote-style pre-pass:
///
/// ```text
/// [^1]: Source title | Source body
///
/// Some paragraph that cites the source [^1].
/// ```
///
/// `[^id]: title | body` definitions are extracted from the source before
/// parsing, and inline `[^id]` references are rewritten as
/// [ScaffoldCitationSpan] entries carrying the extracted title/body. The
/// definition block itself is stripped from the emitted span list.
///
/// Styling note: heading / strong / emphasis elements are FLATTENED to their
/// plain text — no style overrides are baked in here. Consumers wanting
/// styled headings should post-process the returned span list (the typed
/// span model leaves styling to the host `TextTheme`).
library;

import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';
import 'package:markdown/markdown.dart' as md;

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Maps [source] Markdown to a list of [ScaffoldRichSpan] entries consumable
/// by `ScaffoldStreamingRichText`.
///
/// Returns an empty list for empty input. Images are skipped (the typed span
/// model has no image subtype). See file-level doc for the citation
/// convention.
List<ScaffoldRichSpan> scaffoldMarkdownToSpans(String source) {
  if (source.isEmpty) {
    return const <ScaffoldRichSpan>[];
  }

  // Pre-pass: extract `[^id]: title | body` citation definitions and strip
  // them from the markdown source so the AST walker never sees them.
  final _CitationExtraction extraction = _extractCitations(source);
  final Map<String, _Citation> citations = extraction.citations;
  final String stripped = extraction.strippedSource;

  final md.Document document = md.Document();
  final List<md.Node> nodes = document.parse(stripped);

  final List<ScaffoldRichSpan> spans = <ScaffoldRichSpan>[];
  for (final md.Node node in nodes) {
    _walkNode(node, spans, citations);
  }
  return spans;
}

// ---------------------------------------------------------------------------
// AST walker
// ---------------------------------------------------------------------------

/// Recursively walks [node] and appends typed spans to [out].
void _walkNode(
  md.Node node,
  List<ScaffoldRichSpan> out,
  Map<String, _Citation> citations,
) {
  if (node is md.Text) {
    _emitTextWithCitations(node.text, out, citations);
    return;
  }
  if (node is! md.Element) {
    return;
  }

  switch (node.tag) {
    case 'p':
      _walkChildren(node, out, citations);
      // Paragraph boundary marker — the block-boundary announce policy
      // detects this trailing newline.
      out.add(const ScaffoldTextSpan('\n\n'));
      return;
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      // Flatten heading content to plain text — no style override baked in.
      _walkChildren(node, out, citations);
      out.add(const ScaffoldTextSpan('\n\n'));
      return;
    case 'code':
      out.add(ScaffoldCodeInlineSpan(node.textContent));
      return;
    case 'pre':
      // Emit each line as an inline code run followed by '\n'.
      final String text = node.textContent;
      final List<String> lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.isEmpty && i == lines.length - 1) {
          // Trailing newline at end of block — skip the empty tail.
          continue;
        }
        out.add(ScaffoldCodeInlineSpan(line));
        out.add(const ScaffoldTextSpan('\n'));
      }
      return;
    case 'a':
      final String href = node.attributes['href'] ?? '';
      final Uri? uri = Uri.tryParse(href);
      if (uri != null) {
        out.add(ScaffoldLinkSpan(text: node.textContent, uri: uri));
      } else {
        _walkChildren(node, out, citations);
      }
      return;
    case 'strong':
    case 'em':
      // Flatten emphasis — consumers wanting bold/italic post-process.
      _walkChildren(node, out, citations);
      return;
    case 'blockquote':
    case 'ul':
    case 'ol':
      _walkChildren(node, out, citations);
      return;
    case 'li':
      out.add(const ScaffoldTextSpan('• '));
      _walkChildren(node, out, citations);
      out.add(const ScaffoldTextSpan('\n'));
      return;
    case 'img':
      // The typed span model has no image subtype — skip.
      return;
    default:
      _walkChildren(node, out, citations);
      return;
  }
}

void _walkChildren(
  md.Element element,
  List<ScaffoldRichSpan> out,
  Map<String, _Citation> citations,
) {
  final List<md.Node>? children = element.children;
  if (children == null) {
    return;
  }
  for (final md.Node child in children) {
    _walkNode(child, out, citations);
  }
}

/// Emits [text] as a sequence of [ScaffoldTextSpan] and
/// [ScaffoldCitationSpan] entries, splitting on inline `[^id]` references.
void _emitTextWithCitations(
  String text,
  List<ScaffoldRichSpan> out,
  Map<String, _Citation> citations,
) {
  if (citations.isEmpty || !text.contains('[^')) {
    if (text.isNotEmpty) {
      out.add(ScaffoldTextSpan(text));
    }
    return;
  }

  final RegExp refPattern = RegExp(r'\[\^([^\]]+)\]');
  int cursor = 0;
  for (final RegExpMatch match in refPattern.allMatches(text)) {
    if (match.start > cursor) {
      out.add(ScaffoldTextSpan(text.substring(cursor, match.start)));
    }
    final String id = match.group(1)!;
    final _Citation? citation = citations[id];
    if (citation != null) {
      out.add(
        ScaffoldCitationSpan(
          id: id,
          marker: '[$id]',
          title: citation.title,
          body: citation.body,
        ),
      );
    } else {
      // Unknown reference — emit the literal text so content is not lost.
      out.add(ScaffoldTextSpan(match.group(0)!));
    }
    cursor = match.end;
  }
  if (cursor < text.length) {
    out.add(ScaffoldTextSpan(text.substring(cursor)));
  }
}

// ---------------------------------------------------------------------------
// Citation pre-pass
// ---------------------------------------------------------------------------

/// Internal citation record extracted from a `[^id]:` definition line.
final class _Citation {
  const _Citation({required this.title, required this.body});

  final String title;
  final String body;
}

/// Result of the citation pre-pass: the extracted definitions and the source
/// with the definition lines removed.
final class _CitationExtraction {
  const _CitationExtraction({
    required this.citations,
    required this.strippedSource,
  });

  final Map<String, _Citation> citations;
  final String strippedSource;
}

/// Scans [source] for lines matching `[^id]: title | body` and extracts them
/// into a citation map. Returns the remaining source with definition lines
/// removed.
_CitationExtraction _extractCitations(String source) {
  final RegExp defPattern = RegExp(
    r'^\[\^([^\]]+)\]:\s*(.+?)\s*\|\s*(.+?)\s*$',
    multiLine: true,
  );
  final Map<String, _Citation> citations = <String, _Citation>{};
  final List<String> keptLines = <String>[];
  for (final String line in source.split('\n')) {
    final RegExpMatch? match = defPattern.firstMatch(line);
    if (match != null) {
      citations[match.group(1)!] = _Citation(
        title: match.group(2)!,
        body: match.group(3)!,
      );
    } else {
      keptLines.add(line);
    }
  }
  return _CitationExtraction(
    citations: citations,
    strippedSource: keptLines.join('\n'),
  );
}
