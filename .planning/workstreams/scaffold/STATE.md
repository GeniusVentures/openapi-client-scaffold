---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Atom Extensions
status: executing
stopped_at: Phase 9 wave 3 complete — 09-04 merged
last_updated: "2026-08-20T19:30:00.000Z"
last_activity: 2026-08-20 -- Phase 09 waves 1-3 done (09-01..09-05 merged); next 09-06 UAT
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 12
  completed_plans: 6
  percent: 25
---

# Project State

## Project Reference

See: .planning/workstreams/scaffold/ROADMAP.md

**Core value:** `frontend_scaffold` (openapi-client-scaffold) is the single shared source for Genius Network Flutter widgets, M3 theme infrastructure, and Jinja2 codegen templates — generic, M3-themed, zero app-specific business logic, consumable by any repo via pinned submodule
**Current focus:** Phase 09 — text-code-primitives

## Current Position

Phase: 09 (text-code-primitives) — EXECUTING
Plan: 5 of 6 complete (09-01, 09-02, 09-03, 09-05, 09-04 merged)
Status: Executing Phase 09 — wave 4 (09-06 UAT) remaining
Last activity: 2026-08-20 -- Phase 09 wave 3 merged (09-04 demos)

## v1.2 Milestone

**Goal:** Extend the scaffold's generic atom library so the primitives support arbitrary composable widgets — streaming text, charts, code, selection-driven actions, chips, disclosures, composers, and extensible table cells — verified against the 19-component Beautiful UI set as the coverage yardstick.

**Phase map:**

- Phase 8 — Supporting Atoms, Table Cells & Light Palette: ScaffoldChip/ChipGroup, ScaffoldDisclosure/TraceList, ScaffoldComposer, DataColumnConfig cellBuilder, light default palette (WIDG-40..43, 46)
- Phase 9 — Text & Code Primitives: ScaffoldStreamingRichText (incremental render, citations, action slots, a11y), ScaffoldCodeBlock (syntax spans, line numbers, streamed lines), ScaffoldSelectionActions (WIDG-32..34, 37..39)
- Phase 10 — Chart & Scrubber: ScaffoldChart (neutral series contract), ScaffoldChartScrubber (WIDG-35, 36)
- Phase 11 — Verification & Coverage Gate: per-atom tests/demos/barrel sweep + Beautiful UI 19-component coverage check (WIDG-44, 45)

**Coverage:** 16/16 v1.2 requirements mapped. No orphans.

## v1.1 Milestone (archive)

**Goal:** Ship the Core UI Foundation — 28 generic widget atoms consumed by every Genius Network app, plus 3 Jinja2-template-generated composites (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar) — then media and integration widgets in Phase 7.

**Phase map:**

- Phase 6 — Core UI Foundation: 28 widget atoms + ScaffoldMotion across 4 dependency-layered waves
  - Wave 0 (zero-dep, 10 widgets + ScaffoldMotion): Motion, Surface, TouchTarget, FocusOutline, LiveRegion, OverflowFade, ScrollEdgeIndicator, ResponsiveVisibility, FormattedValue, ColorSwatch
  - Wave 1 (single-dep, 11 widgets): Badge, StatusIndicator, SelectionIndicator, ImagePlaceholder, Skeleton, AnimatedDisplay, Pressable, DisabledOverlay, DragHandle, ResizeHandle, NumericInput
  - Wave 2 (multi-dep, 4 widgets): SelectableSurface, Draggable, DropTarget, FileInputSurface
  - Wave 3 (composites, 3 widgets): ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar (Jinja2-template-generated from existing templates)
- Phase 7 — Media & Integration Widgets: MediaCard, MediaControls, WalletConnectSheet (depends on Phase 6 atoms)

**Wave count:** 4 (intra-phase dependency layering — each wave builds only on previously shipped waves)
**Coverage:** 31/31 v1.1 requirements mapped. No orphans.

## Accumulated Context

### Key Decisions

- **Atoms are the primitives, composites are the recipes** — ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar are Jinja2-template-generated compositions of atoms. The template encodes which atoms to wire together for each variant; the atoms are the ingredients.
- **Template boundary: composition-by-intent vs configuration-by-state** — A template exists when the composition of atoms varies by intent (elevated/outlined/filled card wiring), not by runtime state (is the item selected?). Atoms like ScaffoldBadge are plain parameterized widgets; templates would add indirection with no benefit.
- **Four template candidates in Wave 1** — ScaffoldFormattedValue, ScaffoldSelectionIndicator, ScaffoldImagePlaceholder, ScaffoldAnimatedDisplay generate from templates because each variant (number vs date vs money, radio vs checkbox vs toggle, loading vs missing vs failed, fade vs pulse vs scale) changes the widget tree structure and imports. The other 7 Wave 1 widgets are plain Dart.
- **Dependency layering determines wave ordering** — Wave 0 ships zero-dep foundations (Surface, TouchTarget, Motion); Wave 1 ships atoms with a single Wave 0 dep; Wave 2 composites 2+ Wave 0-1 atoms; Wave 3 composites atoms into generated widgets. Execution is strictly sequential within Phase 6.
- **Phase 7 consolidates what was Phases 7-8** — MediaCard, MediaControls, and WalletConnectSheet all depend on Phase 6 atoms and can execute together in one phase.
- **All v1.1 widgets consume only `Theme.of(context)`** — no Riverpod, no GeniusTheme, no app-specific logic; exported via the `frontend_scaffold` barrel
- **Inherited from v1.0 (still locked):** neutral generic package (zero brand names); font choice lives in theme; image caching and localization are infrastructure not widgets; generated code is never committed (CI regenerates + diffs); templates use Jinja2 `StrictUndefined`
- **v1.2 phase boundary: text/code primitives together, chart separate** — streaming rich text, code block, and selection actions all share text-selection/anchored-toolbar machinery, so they batch into Phase 9; chart + scrubber are a self-contained visualization pair in Phase 10 that does not depend on Phase 9 (owner decision encoded in roadmap 2026-08-17)
- **v1.2 verification gate is its own phase** — WIDG-44 (per-atom tests/demos/barrel) and WIDG-45 (Beautiful UI coverage) execute as a final sweep over all atoms shipped in Phases 8-10, matching the v1.1 Phase 7 UAT/verification pattern

### Pending Todos

- [x] `/gsd:plan-phase 6` — wrote plans for Core UI Foundation (28 atoms + composites across 4 waves); executed + verified 28/28
- [x] `/gsd:plan-phase 7` — wrote plans for Media & Integration Widgets (4 plans, 2 waves: MediaCard, MediaControls, WalletConnectSheet, barrel+demos+gate); checker passed 7/7 decisions
- [ ] `/gsd:plan-phase 8` — Supporting Atoms, Table Cells & Light Palette
- [ ] `/gsd:plan-phase 9` — Text & Code Primitives
- [ ] `/gsd:plan-phase 10` — Chart & Scrubber
- [ ] `/gsd:plan-phase 11` — Verification & Coverage Gate
- (Future, post-v1.2) navigation component widgets, DataTable, FormDialog from their existing templates (TMPL-01..03)
- (Future, post-v1.2) HTML template parity with the Flutter atom library (HTML-01)

### Consumer demand reference (from CONSUMERS.md)

- genius-tube needs: MediaCard, MediaControls, ScaffoldStateView, WalletConnectSheet, ScaffoldSearchBar
- genius-ai-boss needs: ScaffoldCard, ScaffoldSearchBar, ScaffoldStateView, form_dialog, data_table
- GeniusWallet needs: WalletConnectSheet (shared Reown session UI per genius-tube ADR-002)

### Blockers/Concerns

- None active.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260820-fix | Source A parent template-dir flag: list expansion + self-reference guard (cherry-picked to develop 1762a45) | 2026-08-20 | 9037950 | — |
| 260818-oe8 | CMakeLists Source A/B stamp targets missing make_directory | 2026-08-19 | 7c598a7 | [260818-oe8](./quick/260818-oe8-cmakelists-txt-source-a-source-b-templat/) |

## Session Continuity

**Last session:** 2026-08-20T16:26:56.203Z
**Stopped at:** Phase 9 UI-SPEC approved
**Resume file:** .planning/workstreams/scaffold/phases/09-text-code-primitives/09-UI-SPEC.md
**Next action:** `/gsd:plan-phase 9 --ws scaffold` to plan Text & Code Primitives (ScaffoldStreamingRichText, ScaffoldCodeBlock, ScaffoldSelectionActions — WIDG-32..34, 37..39)
