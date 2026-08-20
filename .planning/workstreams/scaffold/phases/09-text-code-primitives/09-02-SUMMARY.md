---
phase: 09-text-code-primitives
plan: 02
subsystem: components
tags: [scaffold, code-block, syntax-highlighting, WIDG-37, WIDG-38]
requires:
  - scaffold_surface
  - scaffold_overflow_fade
  - scaffold_pressable
  - scaffold_motion
provides:
  - ScaffoldCodeBlock atom
  - ScaffoldCodeLine DTO
  - ScaffoldCodeSpan DTO
  - ScaffoldCodeHighlighter DI typedef
affects:
  - consumers needing code display (chat responses, tool traces, source viewers)
tech-stack:
  added: []
  patterns:
    - "DI syntax highlighting: atom renders spans, consumer supplies tokenizer"
    - "Streamed line insertion via Stream<List<ScaffoldCodeLine>>"
    - "Reduced-motion gating via ScaffoldMotion.of(context).reducedMotion"
key-files:
  created:
    - lib/components/scaffold_code_block.dart
    - test/components/scaffold_code_block_test.dart
  modified: []
decisions:
  - "D-04: syntax highlighter is DI — atom never tokenizes raw text (D-08: no new pubspec deps)"
  - "Header + gutter + body layout with ScaffoldOverflowFade right-edge fade"
  - "AnimatedOpacity for streamed-line insertion (150ms decelerate, zero under reducedMotion)"
  - "Line-number gutter uses approximate monospace glyph width (8px) — documented as approximation"
metrics:
  duration: ~35m
  completed: 2026-08-20
---

# Phase 09 Plan 02: ScaffoldCodeBlock Atom Summary

Shipped the `ScaffoldCodeBlock` atom — a syntax-highlighted code display primitive with line numbers, language/filename header, copy-to-clipboard, horizontal scrolling with right-edge overflow fade, streamed line insertion, and full reduced-motion gating. Syntax highlighting is pure DI: the atom accepts pre-highlighted spans and/or a consumer-supplied `syntaxHighlighter` callback (D-04); the default tokenizer ships in plan 09-05, not here (D-08 keeps base atoms dependency-free).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Ship ScaffoldCodeBlock atom with DTOs and streamed-line support | 3b788a4 | lib/components/scaffold_code_block.dart |
| 2 | Widget tests for ScaffoldCodeBlock | c3c6468 | test/components/scaffold_code_block_test.dart |

## Deviations from Plan

None — plan executed exactly as written.

The only implementation-specific discoveries during testing (not plan deviations, just mechanical resolution):

- **AnimatedSwitcher timing in fake-async tests**: A single large `pump(Duration)` doesn't drive the cross-fade to completion. Tests pump in 350ms increments so intermediate frames let the swap finish. Test 4 uses three 350ms pumps (1050ms total) — past the 300ms revert timer + the 300ms swap-back.
- **Text.rich vs RichText inspection**: `Text.rich(textSpan)` stores the span on `Text.textSpan`, not `Text.style`. Tests 2, 7, 8 read `textSpan?.style` / `textSpan.children` instead of `style`.

## Verification Results

- `dart analyze lib/components/scaffold_code_block.dart --fatal-infos` → **clean**
- `dart analyze test/components/scaffold_code_block_test.dart --fatal-infos` → **clean**
- `flutter test test/components/scaffold_code_block_test.dart` → **10/10 passing**
- `pubspec.yaml` unchanged → **D-08 confirmed**

## Acceptance Criteria Check

- File contains `class ScaffoldCodeBlock extends StatefulWidget` — yes
- File contains `final class ScaffoldCodeSpan`, `final class ScaffoldCodeLine` — yes
- File contains `ScaffoldCodeHighlighter` typedef (`List<ScaffoldCodeSpan> Function(String rawText)`) — yes
- File contains `Clipboard.setData` — yes
- File contains `ScaffoldOverflowFade(`, `FadeDirection.right`, `fadeExtent: 24.0` — yes
- File contains `ScaffoldMotion.of(context).reducedMotion` — yes (used in `build` + `_onCopy` + `_onStreamedDelta`)
- File contains `copyTooltip = 'Copy'` — yes
- File contains `SingleChildScrollView(scrollDirection: Axis.horizontal` — yes
- File contains `ExcludeSemantics` wrapping the line-number gutter — yes
- File does NOT import `package:highlight`, `package:markdown`, or `package:flutter_highlight` — confirmed via grep
- Test file: 10 `testWidgets(` blocks, 0 `pumpAndSettle` calls, Clipboard mocked via `setMockMethodCallHandler(SystemChannels.platform, ...)` — all confirmed

## Requirements Satisfied

- **WIDG-37** (syntax highlighting + line numbers + header + copy): Tests 1, 2, 3, 4, 7
- **WIDG-38** (horizontal scroll + streamed lines + reduced-motion + DI): Tests 5, 6, 8

## Self-Check: PASSED

- File `lib/components/scaffold_code_block.dart` — FOUND
- File `test/components/scaffold_code_block_test.dart` — FOUND
- Commit `3b788a4` — FOUND
- Commit `c3c6468` — FOUND
