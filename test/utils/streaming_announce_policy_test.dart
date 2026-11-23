import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';
import 'package:frontend_scaffold/utils/streaming_announce_policy.dart';

void main() {
  const ScaffoldBlockBoundaryAnnouncePolicy policy =
      ScaffoldBlockBoundaryAnnouncePolicy();

  // Test 1 — a completed paragraph announces its full content, not just the
  // trailing '\n\n' boundary marker (D-06). markdown_to_spans emits a
  // paragraph as [content, '\n\n'], so returning only the tail would surface
  // whitespace instead of the paragraph text.
  test('announces full paragraph content, not the newline marker', () {
    const List<ScaffoldRichSpan> previous = <ScaffoldRichSpan>[];
    const List<ScaffoldRichSpan> next = <ScaffoldRichSpan>[
      ScaffoldTextSpan('hello world'),
      ScaffoldTextSpan('\n\n'),
    ];

    expect(policy.shouldAnnounce(previous, next), 'hello world\n\n');
  });

  // Test 2 — a partial block (no trailing newline) crosses no boundary.
  test('returns null when no block boundary is crossed', () {
    const List<ScaffoldRichSpan> previous = <ScaffoldRichSpan>[
      ScaffoldTextSpan('partial'),
    ];
    const List<ScaffoldRichSpan> next = <ScaffoldRichSpan>[
      ScaffoldTextSpan('partial wor'),
    ];

    expect(policy.shouldAnnounce(previous, next), isNull);
  });

  // Test 3 — no growth (append removed) crosses no boundary.
  test('returns null when span count does not grow', () {
    const List<ScaffoldRichSpan> previous = <ScaffoldRichSpan>[
      ScaffoldTextSpan('a'),
      ScaffoldTextSpan('b'),
    ];
    const List<ScaffoldRichSpan> next = <ScaffoldRichSpan>[
      ScaffoldTextSpan('a'),
    ];

    expect(policy.shouldAnnounce(previous, next), isNull);
  });
}
