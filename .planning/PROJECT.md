# Project: Frontend Scaffold

**Alias:** `frontend_scaffold` (pub package name)
**Type:** Shared Flutter widget library + Jinja2 codegen templates
**Repository:** `src/scaffold` (git submodule consumed by Genius Network apps)

## Core Value

The single shared source for Genius Network Flutter widgets, M3 theme infrastructure, Jinja2 code-generation templates, and workspace-common UI components. Any Genius Network app consumes scaffold via pinned git submodule — widgets are generic, M3-themed, and carry zero app-specific business logic.

## What This Is

- A **library** of reusable M3 Flutter widgets (`lib/components/`)
- A **theme system** with design tokens, colors, dimens, breakpoints (`lib/theme/`)
- A **Jinja2 template engine** for generating widgets, screens, and modules (`engine.py`, `templates/`)
- A **code generator** for OpenAPI 3.1 → typed API clients (Dart/Dio, TypeScript/Axios, JS)
- A **single source of truth** for shared UI patterns consumed by genius-tube, genius-ai-boss, and potentially GeniusWallet

## What This Is NOT

- **NOT** an application — no `main()`, no app lifecycle
- **NOT** app-specific — no Genius Tube DRM logic, no ai-boss SaaS panel logic
- **NOT** a state management framework — providers/blocs live in consuming apps
- **NOT** a backend — no server-side code, no database

## Current State

**Shipped: v1.1 Widget Library (2026-08-17)** — [archive](milestones/v1.1-ROADMAP.md) · [MILESTONES.md](MILESTONES.md)

The full generic widget library is live: 28 atoms + ScaffoldMotion across 4 dependency waves, 3 template-generated composites (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar), and the media/integration set (MediaCard, MediaControls + composable ScaffoldSlider, WalletConnectSheet). 214/214 widget tests, `dart analyze --fatal-infos` clean. All widgets consume only `Theme.of(context)` — no Riverpod, no GeniusTheme, zero app-specific logic.

**Codebase:** `lib/components/` (~30 widgets), `lib/theme/` (tokens, palette, dimens, breakpoints), `templates/components/` (Jinja2 + StrictUndefined fixtures), `example/` (per-widget demos + kitchen sink).

## Current Milestone: v1.2 Atom Extensions

**Goal:** Extend the scaffold's generic atom library so the primitives support arbitrary composable widgets — streaming text, charts, code, selection-driven actions, chips, disclosures, composers, and extensible table cells — verified against the 19-component Beautiful UI set as the coverage yardstick.

**Target features** (all generic, in `lib/components/`):

- New primitives: `ScaffoldStreamingRichText`, `ScaffoldChart` + `ScaffoldChartScrubber`, `ScaffoldCodeBlock`, `ScaffoldSelectionActions`
- Smaller additions: `ScaffoldChip`/`ScaffoldChipGroup`, `ScaffoldDisclosure`/`ScaffoldTraceList`, `ScaffoldComposer`, extensible `ScaffoldDataTable` cell builders (`DataColumnConfig<T>` with `cellBuilder`)

**Out of scope for v1.2:** AI-specific composites (`lib/ai_components/` — built in the AI chat app, not the scaffold); HTML generator parity (deprecated, Flutter only).

Seed analysis: [.planning/atoms-v1.2-additions.md](atoms-v1.2-additions.md) — 7/19 Beautiful UI components ready via existing atoms, 8 via thin composites, 4 enabled by the new primitives.

## Validated Requirements

- ✓ SUB-01..03 — submodule as single shared source (v1.0)
- ✓ WIDG-01..28 — 28 atoms + ScaffoldMotion + 3 composites (v1.1, Phase 6)
- ✓ WIDG-29..31 — MediaCard, MediaControls, WalletConnectSheet (v1.1, Phase 7)

## Key Design Decisions

- **Font choice lives in theme** (`scaffold_theme.dart`), not in primitive widget wrappers
- **Image caching and localization are infrastructure**, not widgets
- **Media cards are generic** — configurable aspect ratio + badge slots + metadata builder; not app-specific
- **All widgets consume M3 `Theme.of(context)` only** — no Riverpod, no GeniusTheme dependency
- **Generated code is never committed** — D-16, CI regenerates and diffs
- **Templates use Jinja2 `StrictUndefined`** — missing variables fail loudly
- **Neutral generic package** — zero brand names in `lib/`/`example/`
- **Atoms are primitives, composites are recipes** — composites are template-generated compositions of atoms (v1.1)
- **Composable base widgets over monoliths** — ScaffoldSlider extracted so MediaControls composes rather than embeds slider logic (v1.1, Phase 7 UAT)

## Active Requirements

_Populated during milestone v1.2 requirement definition (this session)._

## Out of Scope

- App-specific composites (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline)
- State management (providers/blocs/cubits — consumers own their state)
- Backend integration (API clients, sockets)
- Platform channels (FFI is the consuming app's concern)
- Business-domain widgets in atoms — AI composites accept typed models/slots; atoms know nothing about agents, prompts, or sources (v1.2 boundary)

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-08-17 — milestone v1.2 Atom Extensions started*
