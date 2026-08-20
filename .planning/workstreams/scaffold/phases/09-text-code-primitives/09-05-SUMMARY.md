---
phase: 09-text-code-primitives
plan: 05
subsystem: scaffold-text-code
tags: [markdown, syntax-highlighting, copy-action, support-parts, D-03, D-04, D-07, D-08]
requires:
  - lib/utils/scaffold_rich_spans.dart (Plan 01)
  - lib/components/scaffold_code_block.dart (Plan 02)
  - lib/components/scaffold_streaming_rich_text.dart (Plan 01)
  - lib/components/scaffold_selection_actions.dart (Plan 03)
  - lib/utils/streaming_announce_policy.dart (Plan 01)
provides:
  - lib/utils/markdown_to_spans.dart — scaffoldMarkdownToSpans(String) -> List<ScaffoldRichSpan> (D-03 support part)
  - lib/utils/light_syntax_tokenizer.dart — scaffoldLightTokenize(String, ScaffoldLightLanguage) -> List<ScaffoldCodeSpan> (D-04 support part)
  - lib/components/scaffold_streaming_copy_button.dart — ScaffoldStreamingCopyButton for the streaming response-action slot
  - lib/components/scaffold_selection_copy_action.dart — ScaffoldSelectionCopyAction for the selection toolbar builder
  - example/lib/demos/markdown_to_spans_demo.dart — end-to-end demo
  - example/lib/demos/light_syntax_tokenizer_demo.dart — end-to-end demo incl. DI wiring
affects:
  - pubspec.yaml (one new dependency: markdown ^7.3.0)
tech-stack:
  added:
    - markdown ^7.3.0 (pure-Dart Markdown parser; confined to lib/utils/markdown_to_spans.dart per D-08)
  patterns:
    - Support-part dependency isolation (D-08): package:markdown imported ONLY by lib/utils/markdown_to_spans.dart
    - Reference-implementation hardcoded palette for the light tokenizer (only permitted hardcoded colors in scaffold)
    - DI hook demonstrability (D-07): every Phase 9 DI hook now has a shipped concrete implementation
key-files:
  created:
    - lib/utils/markdown_to_spans.dart
    - lib/utils/light_syntax_tokenizer.dart
    - lib/components/scaffold_streaming_copy_button.dart
    - lib/components/scaffold_selection_copy_action.dart
    - test/utils/markdown_to_spans_test.dart
    - test/utils/light_syntax_tokenizer_test.dart
    - test/components/scaffold_streaming_copy_button_test.dart
    - test/components/scaffold_selection_copy_action_test.dart
    - example/lib/demos/markdown_to_spans_demo.dart
    - example/lib/demos/light_syntax_tokenizer_demo.dart
  modified:
    - pubspec.yaml (added markdown ^7.3.0 dependency)
decisions:
  - Citation convention: custom `[^id]: title | body` footnote-style syntax extracted in a pre-pass before Markdown parsing; inline `[^id]` references rewritten as ScaffoldCitationSpan entries. Documented as the demo's convention — not a scaffold-standard grammar.
  - Heading/emphasis flattening: heading + strong/em elements flatten to plain ScaffoldTextSpan with styleOverride=null; consumers wanting styled headings post-process the span list.
  - Reference palette for the light tokenizer is hardcoded VS Code dark colors (569CD6/CE9178/B5CEA8/6A9955) — explicitly documented as the ONLY permitted hardcoded colors in scaffold; consumers override via ScaffoldCodeBlock.syntaxHighlighter.
  - Selection toolbar copy action intentionally omits ScaffoldLiveRegion (per UI-SPEC "Code block copied confirmation" row: icon-only transient confirmation).
  - Streaming copy button defaults announceCopied=false; consumers opt in.
metrics:
  duration: ~25 minutes
  completed: 2026-08-20
  tasks: 4
  commits: 4
  files-created: 10
  files-modified: 1
  tests-added: 27
---

# Phase 09 Plan 05: Support-Library Parts Summary

Ships the Phase 9 support-library parts — Markdown→typed-span mapper (D-03), light regex-based syntax tokenizer (D-04), streaming copy button (D-07 demonstrability for the response-action slot), and selection copy action (D-07 demonstrability for the toolbar builder) — along with their tests, demos, and the single pubspec dependency that isolates `package:markdown` to `lib/utils/markdown_to_spans.dart` (D-08).

## What was built

| Artifact | Purpose |
|---|---|
| `lib/utils/markdown_to_spans.dart` | `scaffoldMarkdownToSpans(String) -> List<ScaffoldRichSpan>` — walks the `markdown` package AST and emits typed spans. Recognizes a custom `[^id]: title \| body` citation pre-pass for the demo. Sole `package:markdown` importer. |
| `lib/utils/light_syntax_tokenizer.dart` | `scaffoldLightTokenize(String, ScaffoldLightLanguage) -> List<ScaffoldCodeSpan>` — left-to-right non-overlapping scanner; covers dart / yaml / json / plaintext. Round-trip property: concatenating `span.text` reconstructs the input exactly. |
| `lib/components/scaffold_streaming_copy_button.dart` | Label + icon copy button for `ScaffoldStreamingRichText.actions`. Armed tint via `palette.lightGreenPrimary`; transient `statusSuccess` check swap; optional `ScaffoldLiveRegion` "Copied" announce. |
| `lib/components/scaffold_selection_copy_action.dart` | Icon-only copy action for `ScaffoldSelectionActions.toolbarBuilder`. Same copy mechanics; no live region (per UI-SPEC). |
| `test/utils/markdown_to_spans_test.dart` | 7 tests — paragraph, emphasis flatten, inline code, link, heading, citation pre-pass, empty input. |
| `test/utils/light_syntax_tokenizer_test.dart` | 8 tests — dart keyword/string/comment/number, yaml unhighlighted, json literal, plaintext fallback, multi-line round-trip. |
| `test/components/scaffold_streaming_copy_button_test.dart` | 6 tests — glyph, hit area, clipboard write, 300ms revert, armed tint, reduced-motion zero-duration switcher, live region, light palette. |
| `test/components/scaffold_selection_copy_action_test.dart` | 6 tests — glyph, hit area, semantics label, clipboard write, 300ms revert, reduced-motion, light palette. |
| `example/lib/demos/markdown_to_spans_demo.dart` | 4 sections — Markdown input, seeded cubit rendering, custom `[Demo]`-prefixed announce policy (proves D-06 hook), light palette. |
| `example/lib/demos/light_syntax_tokenizer_demo.dart` | 5 sections — Dart / YAML / JSON pre-highlighted samples, DI wiring via `syntaxHighlighter:` callback (proves D-04 hook), light palette with reference-colors note. |
| `pubspec.yaml` | One new dependency: `markdown: ^7.3.0`. Resolved to 7.3.1. |

## Verification

- `dart analyze --fatal-infos` exits 0 on all 6 touched source files (4 lib + 2 demo).
- `flutter test test/utils/ test/components/scaffold_streaming_copy_button_test.dart test/components/scaffold_selection_copy_action_test.dart` — all 27 tests pass.
- D-08 grep gate: `grep -rE "^import 'package:markdown" lib/components/ lib/theme/` returns zero matches.
- Dependencies block in pubspec.yaml grew by exactly 1 entry (`markdown`).

## Commits

| Hash | Type | Description |
|---|---|---|
| `b741fd3` | feat | ship markdown_to_spans + light_syntax_tokenizer support parts |
| `160c3a2` | test | add tests for markdown_to_spans + light_syntax_tokenizer |
| `8f09b2e` | feat | ship streaming + selection copy action support buttons |
| `4edd20c` | feat | add demos for markdown_to_spans + light_syntax_tokenizer |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Multiple ScaffoldTouchTarget matches in copy-button tests**
- **Found during:** Task 3 (test authoring)
- **Issue:** The plan's widget spec wraps the glyph in `ScaffoldTouchTarget(minWidth:48, minHeight:48)`; `ScaffoldPressable` internally supplies its own default `ScaffoldTouchTarget`. `find.byType(ScaffoldTouchTarget)` matched both and threw `StateError: Too many elements`.
- **Fix:** Test predicates narrowed to `w is ScaffoldTouchTarget && w.minWidth == 48 && w.minHeight == 48` (the explicit outer target). Library code unchanged — the explicit outer target remains because the plan's spec calls for it.
- **Files modified:** test/components/scaffold_streaming_copy_button_test.dart, test/components/scaffold_selection_copy_action_test.dart
- **Commit:** `8f09b2e`

No other deviations. Plan executed as written.

## Self-Check: PASSED

- FOUND: lib/utils/markdown_to_spans.dart
- FOUND: lib/utils/light_syntax_tokenizer.dart
- FOUND: lib/components/scaffold_streaming_copy_button.dart
- FOUND: lib/components/scaffold_selection_copy_action.dart
- FOUND: test/utils/markdown_to_spans_test.dart
- FOUND: test/utils/light_syntax_tokenizer_test.dart
- FOUND: test/components/scaffold_streaming_copy_button_test.dart
- FOUND: test/components/scaffold_selection_copy_action_test.dart
- FOUND: example/lib/demos/markdown_to_spans_demo.dart
- FOUND: example/lib/demos/light_syntax_tokenizer_demo.dart
- FOUND: pubspec.yaml contains `  markdown: ^7.3.0`
- FOUND: commit b741fd3
- FOUND: commit 160c3a2
- FOUND: commit 8f09b2e
- FOUND: commit 4edd20c
