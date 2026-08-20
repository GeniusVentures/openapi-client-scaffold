---
phase: 09-text-code-primitives
plan: 04
subsystem: example-demos
tags: [demo, example-app, streaming-rich-text, code-block, selection-actions]
dependency_graph:
  requires: [09-01, 09-02, 09-03, 09-05]
  provides:
    - "D-07 demonstrability for the three Phase 9 base atoms (streaming rich text, code block, selection actions)"
    - "Consumer-facing reference for composing ScaffoldStreamingRichText + ScaffoldStreamingCopyButton"
    - "Consumer-facing reference for composing ScaffoldSelectionActions + ScaffoldSelectionCopyAction"
  affects:
    - "Plan 09-06 (main.dart registration sweep) — consumes these demo classes"
tech_stack:
  added: []
  patterns:
    - "chip_demo.dart demo pattern: numbered sections + private _Foo StatefulWidgets for interactive state"
    - "ScaffoldMotion(reducedMotion: true, ...) local-override pattern for reduced-motion sections"
    - "Theme(ThemeData.light().copyWith(extensions: [lightPalette, defaultDimens])) for light-palette sections"
key_files:
  created:
    - example/lib/demos/streaming_rich_text_demo.dart
    - example/lib/demos/code_block_demo.dart
    - example/lib/demos/selection_actions_demo.dart
  modified: []
decisions:
  - "Demo registration in example/lib/main.dart deferred to Plan 09-06 (single-writer rule)"
  - "Streaming demo uses Timer.periodic + a private cubit-owning StatefulWidget — demos are not bound by the no-arbitrary-duration rule that applies to tests"
  - "Streamed code demo drives ScaffoldCodeBlock.streamedLines via StreamController<List<ScaffoldCodeLine>> fed from Timer.periodic (matches D-04 contract)"
  - "ScaffoldStreamingCopyButton is wired into the response-action row (D-07); ScaffoldSelectionCopyAction is wired into the toolbarBuilder slot (D-07)"
metrics:
  duration_minutes: 8
  completed_date: 2026-08-20
  tasks_completed: 3
  files_created: 3
  files_modified: 0
---

# Phase 09 Plan 04: Text/Code Primitives Demos Summary

Shipped three example-app demos proving each Phase 9 base atom works end-to-end (D-07 demonstrability). Each demo wires the Plan 05 support part into its designated slot: `ScaffoldStreamingCopyButton` in the streaming response-action row, `ScaffoldSelectionCopyAction` in the selection toolbar.

## One-liner

Three runnable example-app demos (streaming rich text, code block, selection actions) proving D-07 demonstrability for the Phase 9 atoms and integrating the Plan 05 support parts into their designated slots.

## What was built

| File | Class | Sections |
|---|---|---|
| `example/lib/demos/streaming_rich_text_demo.dart` | `ScaffoldStreamingRichTextDemo` | 6: static spans, simulated streaming (80ms × 30 spans), citation toggle, response actions (Plan 05 copy button), reduced motion, light palette |
| `example/lib/demos/code_block_demo.dart` | `ScaffoldCodeBlockDemo` | 7: default dart, no line numbers, hand-highlighted spans (D-04 DI without tokenizer), horizontal overflow (~200 chars), streamed lines (100ms × 5), reduced motion, light palette |
| `example/lib/demos/selection_actions_demo.dart` | `ScaffoldSelectionActionsDemo` | 6: default auto placement, placement override below, selection reporter, empty toolbar builder, reduced motion, light palette |

## Key integrations (D-07)

- **`ScaffoldStreamingCopyButton`** appears in `streaming_rich_text_demo.dart` section 4 (response actions) — copies the full response text to the clipboard.
- **`ScaffoldSelectionCopyAction`** appears in `selection_actions_demo.dart` sections 1, 2, 5, 6 — wired via the toolbarBuilder's `String selectedPlainText` parameter and copies the active selection.

## Deviations from Plan

None — plan executed exactly as written. One fix-up loop occurred during verification: the initial draft used `ScaffoldTextSpan(text: ...)` named-arg form, but the actual `ScaffoldTextSpan` constructor takes positional `text`. Caught by `dart analyze` (Rule 1 — bug in generated code, fixed inline before commit). This is a first-pass correction during the same task, not a cross-task deviation.

## Verification

```
dart analyze example/lib/demos/streaming_rich_text_demo.dart \
              example/lib/demos/code_block_demo.dart \
              example/lib/demos/selection_actions_demo.dart \
              --fatal-infos
# No issues found!
```

All three demos:
- Use `package:frontend_scaffold/...` imports exclusively (no relative imports into `lib/`).
- Follow the `chip_demo.dart` pattern (StatelessWidget + numbered sections + small private StatefulWidgets for interactive state).
- Do NOT modify `example/lib/main.dart` or `lib/frontend_scaffold.dart` (Plan 09-06 scope).

## Commits

- `2b876fa` — feat(09-04): ship streaming_rich_text_demo.dart
- `f462194` — feat(09-04): ship code_block_demo.dart
- `c96d48c` — feat(09-04): ship selection_actions_demo.dart

## Self-Check: PASSED

- `example/lib/demos/streaming_rich_text_demo.dart` — exists, contains `class ScaffoldStreamingRichTextDemo extends StatelessWidget`, 6 numbered sections, `ScaffoldStreamingCopyButton(` in section 4.
- `example/lib/demos/code_block_demo.dart` — exists, contains `class ScaffoldCodeBlockDemo extends StatelessWidget`, 7 numbered sections, `showLineNumbers: false`, `ScaffoldMotion(reducedMotion: true`, `ScaffoldPalette.lightPalette`.
- `example/lib/demos/selection_actions_demo.dart` — exists, contains `class ScaffoldSelectionActionsDemo extends StatelessWidget`, 6 numbered sections, `toolbarBuilder:`, `ScaffoldToolbarPlacement.below`, `onSelectionChanged:`, `ScaffoldSelectionCopyAction(` in section 1.
- All three commit hashes verified via `git log`.
- `dart analyze --fatal-infos` exits 0 on all three files.
- No modifications to `STATE.md`, `ROADMAP.md`, `example/lib/main.dart`, or `lib/frontend_scaffold.dart`.
