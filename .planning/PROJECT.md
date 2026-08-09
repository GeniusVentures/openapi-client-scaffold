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

## Current Milestone: v1.1 Widget Library

**Goal:** Ship widget implementations for templates that exist but have no `lib/` counterpart, plus MediaCard/MediaControls for genius-tube Phase 2 consumption.

**Target features:**
- ScaffoldCard widget (from card.dart.jinja2)
- ScaffoldStateView widget (from state.dart.jinja2)
- ScaffoldSearchBar widget (from search_bar.dart.jinja2)
- MediaCard template + widget (aspect ratio + badge slots + metadata)
- MediaControls widget (play/pause/seekbar/volume/fullscreen)
- WalletConnectSheet (Reown session UI, reusable by any consumer app)
- ScaffoldBadge widget (icon + label chip)

## Key Design Decisions

- **Font choice lives in theme** (`scaffold_theme.dart`), not in primitive widget wrappers
- **Image caching and localization are infrastructure**, not widgets
- **Media cards are generic** — configurable aspect ratio + badge slots + metadata builder; not app-specific
- **All widgets consume M3 `Theme.of(context)` only** — no Riverpod, no GeniusTheme dependency
- **Generated code is never committed** — D-16, CI regenerates and diffs
- **Templates use Jinja2 `StrictUndefined`** — missing variables fail loudly
- **Neutral generic package** — zero brand names in `lib/`/`example/`

## Active Requirements

_Will be populated by milestone v1.1 requirements._

## Out of Scope

- App-specific composites (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline)
- State management (providers/blocs/cubits — consumers own their state)
- Backend integration (API clients, sockets)
- Platform channels (FFI is the consuming app's concern)

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
*Last updated: 2026-08-09 — milestone v1.1 initialized*
