---
gsd_state_version: 1.0
workstream: scaffold
milestone: v1.1
milestone_name: Widget Library
status: planning
last_updated: "2026-08-11T00:00:00.000Z"
last_activity: 2026-08-11 — Phase 6 context gathered (4 decisions locked: ScaffoldMotion dual-mode, full a11y, proactive theme tokens, pure composability)
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/workstreams/scaffold/ROADMAP.md

**Core value:** `frontend_scaffold` (openapi-client-scaffold) is the single shared source for Genius Network Flutter widgets, M3 theme infrastructure, and Jinja2 codegen templates — generic, M3-themed, zero app-specific business logic, consumable by any repo via pinned submodule
**Current focus:** v1.1 Widget Library — ship the Core UI Foundation (28 widget atoms + ScaffoldMotion) in Phase 6, then Media & Integration widgets in Phase 7

## Current Position

Phase: 06 (core-ui-foundation) — context gathered, ready for planning
Plan: 0 of 0 — no plans written yet for v1.1
Status: Phase 6 context gathered 2026-08-11: 4 implementation decisions locked (ScaffoldMotion dual-mode utility+InheritedWidget, full a11y on all 28 atoms, proactive theme token expansion in Wave 0, pure composability API philosophy). Ready for /gsd:plan-phase 6 --ws scaffold.
Last activity: 2026-08-11 — discuss-phase captured context; 06-CONTEXT.md and 06-DISCUSSION-LOG.md committed

## v1.1 Milestone

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

### Pending Todos

- `/gsd:plan-phase 6` — write plans for Core UI Foundation (28 atoms + composites across 4 waves)
- (Follow-up, out of v1.1 scope) light default palette to complement the dark-seeded ScaffoldPalette defaults — carried from v1.0
- (Future, post-v1.1) navigation component widgets, DataTable, FormDialog from their existing templates

### Consumer demand reference (from CONSUMERS.md)

- genius-tube needs: MediaCard, MediaControls, ScaffoldStateView, WalletConnectSheet, ScaffoldSearchBar
- genius-ai-boss needs: ScaffoldCard, ScaffoldSearchBar, ScaffoldStateView, form_dialog, data_table
- GeniusWallet needs: WalletConnectSheet (shared Reown session UI per genius-tube ADR-002)

### Blockers/Concerns

- None active. Reown (`reown_appkit` / `reown_walletkit`) version coordination with GeniusWallet is a Phase 7 planning concern, not a blocker.

## Session Continuity

**Last session:** 2026-08-11
**Stopped at:** Phase 6 context gathered — 4 decisions locked (ScaffoldMotion, a11y, theme tokens, API philosophy)
**Resume file:** .planning/workstreams/scaffold/phases/06-core-ui-foundation/06-CONTEXT.md
**Next action:** `/gsd:plan-phase 6 --ws scaffold` to decompose Core UI Foundation into executable plans across 4 waves
