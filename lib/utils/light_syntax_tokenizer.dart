/// Light regex-based syntax tokenizer for ScaffoldCodeBlock (D-04 support
/// part).
///
/// Pure Dart — no third-party deps. Supports a small set of languages via
/// keyword / literal / comment / string patterns. Consumers wanting richer
/// highlighting should inject their own via
/// `ScaffoldCodeBlock.syntaxHighlighter`.
///
/// **Hardcoded colors note:** the palette below is fixed for this reference
/// implementation ONLY — it is the one place in scaffold where hardcoded
/// colors are permitted. Consumers SHOULD inject their own highlighter to
/// match their palette (see `ScaffoldCodeBlock.syntaxHighlighter`).
///
/// Coverage guarantee: concatenating `span.text` across the returned list
/// reconstructs the input string exactly (no gaps, no overlaps).
library;

import 'dart:ui' show Color;

import 'package:frontend_scaffold/components/scaffold_code_block.dart';

// ---------------------------------------------------------------------------
// Language enum
// ---------------------------------------------------------------------------

/// Languages the light tokenizer knows how to highlight.
enum ScaffoldLightLanguage {
  /// Dart — line comments, single/double/triple strings, full keyword set.
  dart,

  /// YAML — hash comments, single/double strings, `true|false|null`.
  yaml,

  /// JSON — no comments, single/double strings, `true|false|null`.
  json,

  /// Plaintext — returns the input as a single uncolored span.
  plaintext,
}

// ---------------------------------------------------------------------------
// Reference palette (VS Code dark defaults — reference implementation only)
// ---------------------------------------------------------------------------

/// Keyword color — VS Code dark blue.
const Color _kKeywordColor = Color(0xFF569CD6);

/// String color — VS Code dark orange-brown.
const Color _kStringColor = Color(0xFFCE9178);

/// Number color — VS Code dark light-green.
const Color _kNumberColor = Color(0xFFB5CEA8);

/// Comment color — VS Code dark muted green.
const Color _kCommentColor = Color(0xFF6A9955);

// ---------------------------------------------------------------------------
// Keyword tables
// ---------------------------------------------------------------------------

/// Dart language keywords recognized by the light tokenizer.
const Set<String> _kDartKeywords = <String>{
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
  'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'get', 'if', 'implements',
  'import', 'in', 'interface', 'is', 'late', 'library', 'mixin', 'new',
  'null', 'on', 'operator', 'part', 'required', 'rethrow', 'return', 'set',
  'show', 'static', 'super', 'switch', 'sync', 'this', 'throw', 'true',
  'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
};

/// YAML / JSON literals.
const Set<String> _kLiteralKeywords = <String>{'true', 'false', 'null'};

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Tokenizes [rawText] for [language] into a list of [ScaffoldCodeSpan].
///
/// The returned spans cover the input exactly — concatenating `span.text`
/// reconstructs [rawText] with no gaps or overlaps. Spans with `color: null`
/// fall back to the consumer's default body color (typically
/// `palette.textPrimary`).
List<ScaffoldCodeSpan> scaffoldLightTokenize(
  String rawText,
  ScaffoldLightLanguage language,
) {
  if (rawText.isEmpty) {
    return const <ScaffoldCodeSpan>[];
  }
  if (language == ScaffoldLightLanguage.plaintext) {
    return <ScaffoldCodeSpan>[ScaffoldCodeSpan(text: rawText)];
  }

  final _LanguageSpec spec = _specFor(language);
  return _tokenize(rawText, spec);
}

// ---------------------------------------------------------------------------
// Internals
// ---------------------------------------------------------------------------

/// Per-language tokenization rules.
final class _LanguageSpec {
  const _LanguageSpec({
    required this.keywords,
    required this.commentPrefix,
    required this.allowTripleQuoteStrings,
  });

  final Set<String> keywords;

  /// Single-line comment prefix; empty string disables comments.
  final String commentPrefix;

  /// Whether triple-quoted strings (`'''...'''`, `"""..."""`) are recognized.
  final bool allowTripleQuoteStrings;
}

_LanguageSpec _specFor(ScaffoldLightLanguage language) {
  switch (language) {
    case ScaffoldLightLanguage.dart:
      return const _LanguageSpec(
        keywords: _kDartKeywords,
        commentPrefix: '//',
        allowTripleQuoteStrings: true,
      );
    case ScaffoldLightLanguage.yaml:
      return const _LanguageSpec(
        keywords: _kLiteralKeywords,
        commentPrefix: '#',
        allowTripleQuoteStrings: false,
      );
    case ScaffoldLightLanguage.json:
      return const _LanguageSpec(
        keywords: _kLiteralKeywords,
        commentPrefix: '',
        allowTripleQuoteStrings: false,
      );
    case ScaffoldLightLanguage.plaintext:
      // Handled above.
        return const _LanguageSpec(
        keywords: <String>{},
        commentPrefix: '',
        allowTripleQuoteStrings: false,
      );
  }
}

/// A single token identified during scanning.
final class _Token {
  const _Token({
    required this.start,
    required this.end,
    required this.color,
  });

  final int start;
  final int end;
  final Color color;
}

/// Left-to-right, non-overlapping scanner.
List<ScaffoldCodeSpan> _tokenize(String rawText, _LanguageSpec spec) {
  final List<_Token> tokens = <_Token>[];
  int cursor = 0;
  final int length = rawText.length;

  while (cursor < length) {
    // Skip whitespace quickly.
    final int codeUnit = rawText.codeUnitAt(cursor);
    final bool isWhitespace = codeUnit == 0x20 /* space */ ||
        codeUnit == 0x09 /* tab */ ||
        codeUnit == 0x0A /* \n */ ||
        codeUnit == 0x0D /* \r */;
    if (isWhitespace) {
      cursor++;
      continue;
    }

    // Try to match a token starting at cursor; pick the earliest-finishing
    // match to enforce left-to-right, non-overlapping precedence.
    final _Token? token = _matchAt(rawText, cursor, spec);
    if (token != null) {
      tokens.add(token);
      cursor = token.end;
      continue;
    }

    // No token matched — advance by one and let the gap filler pick it up.
    cursor++;
  }

  // Fill gaps with uncolored spans and emit the final ordered list.
  final List<ScaffoldCodeSpan> spans = <ScaffoldCodeSpan>[];
  int position = 0;
  for (final _Token token in tokens) {
    if (token.start > position) {
      spans.add(
        ScaffoldCodeSpan(text: rawText.substring(position, token.start)),
      );
    }
    spans.add(
      ScaffoldCodeSpan(
        text: rawText.substring(token.start, token.end),
        color: token.color,
      ),
    );
    position = token.end;
  }
  if (position < length) {
    spans.add(ScaffoldCodeSpan(text: rawText.substring(position)));
  }
  return spans;
}

/// Attempts to match a single token starting at [start]. Returns null when
/// no pattern matches.
_Token? _matchAt(String rawText, int start, _LanguageSpec spec) {
  final int length = rawText.length;

  // 1. Comments — highest priority. Scan to end of line.
  if (spec.commentPrefix.isNotEmpty &&
      rawText.startsWith(spec.commentPrefix, start)) {
    int end = start + spec.commentPrefix.length;
    while (end < length && rawText.codeUnitAt(end) != 0x0A) {
      end++;
    }
    return _Token(start: start, end: end, color: _kCommentColor);
  }

  // 2. Strings — triple-quoted first (dart only), then single/double.
  if (spec.allowTripleQuoteStrings) {
    if (rawText.startsWith("'''", start)) {
      final int end = _findClosing(rawText, start + 3, "'''");
      if (end > start) {
        return _Token(start: start, end: end, color: _kStringColor);
      }
    }
    if (rawText.startsWith('"""', start)) {
      final int end = _findClosing(rawText, start + 3, '"""');
      if (end > start) {
        return _Token(start: start, end: end, color: _kStringColor);
      }
    }
  }
  final int firstUnit = rawText.codeUnitAt(start);
  if (firstUnit == 0x27 /* ' */ || firstUnit == 0x22 /* " */) {
    final int end = _findClosingQuote(rawText, start);
    if (end > start) {
      return _Token(start: start, end: end, color: _kStringColor);
    }
  }

  // 3. Numbers — `\b\d+(\.\d+)?\b`. Treat as a token only when the digit is
  // not preceded by an identifier character. Non-keyword identifiers advance
  // one code unit at a time (the identifier fallback returns null), so when a
  // digit is reached mid-identifier (e.g. "sha256", "token2") the preceding
  // character is already an identifier part — skip number matching so the
  // digit stays uncolored as part of the identifier.
  if (_isDigit(rawText.codeUnitAt(start))) {
    if (start > 0 && _isIdentifierPart(rawText.codeUnitAt(start - 1))) {
      return null;
    }
    int end = start;
    while (end < length && _isDigit(rawText.codeUnitAt(end))) {
      end++;
    }
    if (end < length &&
        rawText.codeUnitAt(end) == 0x2E /* . */ &&
        end + 1 < length &&
        _isDigit(rawText.codeUnitAt(end + 1))) {
      end++;
      while (end < length && _isDigit(rawText.codeUnitAt(end))) {
        end++;
      }
    }
    return _Token(start: start, end: end, color: _kNumberColor);
  }

  // 4. Identifiers / keywords.
  if (_isIdentifierStart(rawText.codeUnitAt(start))) {
    int end = start + 1;
    while (end < length && _isIdentifierPart(rawText.codeUnitAt(end))) {
      end++;
    }
    final String word = rawText.substring(start, end);
    if (spec.keywords.contains(word)) {
      return _Token(start: start, end: end, color: _kKeywordColor);
    }
    // Non-keyword identifier — consume as a single unit so the gap filler
    // doesn't split it. Returned as an uncolored span via a null-color token
    // would require a fourth token kind; instead we return null and let the
    // scanner advance one code unit at a time, then merge adjacent
    // uncolored text in the gap-filling pass. To avoid N tokens for an
    // N-char identifier, we return a sentinel token with a private
    // "uncolored" marker by using the keyword color only when matched.
    return null;
  }

  return null;
}

/// Finds the end of a single/double-quoted string starting at [start]
/// (the opening quote position). Honors `\` escapes. Returns the index just
/// past the closing quote, or `start` when unterminated.
int _findClosingQuote(String rawText, int start) {
  final int quote = rawText.codeUnitAt(start);
  int i = start + 1;
  while (i < rawText.length) {
    final int unit = rawText.codeUnitAt(i);
    if (unit == 0x5C /* \ */) {
      i += 2;
      continue;
    }
    if (unit == quote) {
      return i + 1;
    }
    if (unit == 0x0A) {
      // Single/double-quoted strings cannot span newlines.
      return start;
    }
    i++;
  }
  return start;
}

/// Finds the end of a triple-quoted string. Returns the index just past the
/// closing triple quote, or `start - 3` (a value `< start`) when
/// unterminated.
int _findClosing(String rawText, int searchFrom, String delimiter) {
  final int idx = rawText.indexOf(delimiter, searchFrom);
  if (idx < 0) {
    return searchFrom - 3;
  }
  return idx + delimiter.length;
}

bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

bool _isIdentifierStart(int unit) =>
    (unit >= 0x41 && unit <= 0x5A) /* A-Z */ ||
    (unit >= 0x61 && unit <= 0x7A) /* a-z */ ||
    unit == 0x5F /* _ */ ||
    unit == 0x24 /* $ */;

bool _isIdentifierPart(int unit) =>
    _isIdentifierStart(unit) || _isDigit(unit);
