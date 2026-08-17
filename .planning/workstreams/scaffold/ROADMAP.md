# Roadmap: Scaffold

The `frontend_scaffold` submodule's own planning record. This workstream owns the
submodule's contents — the `frontend_scaffold` Dart widget package and the `templates/`
directory — so that every consuming repo (genius-ai-boss, genius-tube, and any sibling
project that adds this submodule) shares one source of truth for what the scaffold is and
what changed.

**Provenance**: extracted from `genius-ai-boss/.planning/workstreams/frontend-templates/`
on 2026-08-09. Phase 5 (the consolidation that made this submodule the shared source) is
re-homed here as this workstream's anchor phase. The parent workstream retains Phases 5-8
orchestration history (parent-side CMake/pipeline plans) and continues to own Phases 6-8
(bloc-aware templates, C++ interfaces, build-option wiring) which execute from the parent.

## Milestones

- ✅ **v1.0 Scaffold Shared Source** — Phase 5 (shipped 2026-08-09): submodule established as the single shared widget/template source; `frontend_scaffold` package at v0.3.0
- ✅ **v1.1 Widget Library** — Phases 6-7 (shipped 2026-08-17): 28 widget atoms + ScaffoldMotion + 3 template-generated composites (Phase 6), then media and integration widgets (Phase 7). See [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)

## Phases

<details>
<summary>✅ v1.0 Scaffold Shared Source (Phase 5) — SHIPPED 2026-08-09</summary>

- [x] **Phase 5: Scaffold Submodule Consolidation** (5/5 plans) — submodule is the single shared source for GeniusWallet bloc widgets and genius-tube C++ interface templates, consumable via pinned submodule (completed 2026-08-09)

</details>

<details>
<summary>✅ v1.1 Widget Library (Phases 6-7) — SHIPPED 2026-08-17</summary>

- [x] **Phase 6: Core UI Foundation** (6/6 plans) — 28 widget atoms + ScaffoldMotion across 4 dependency-layered waves; atoms ship as plain Dart widgets (runtime-parameterized) except 4 template candidates + 3 Jinja2-template-generated composites (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar) (completed 2026-08-14)
- [x] **Phase 7: Media & Integration Widgets** (4/4 plans) — MediaCard (consumes ScaffoldBadge badge slots), MediaControls (consumes ScaffoldPressable + ScaffoldTouchTarget + ScaffoldSlider), WalletConnectSheet (built on existing BottomDrawer); media_card.dart.jinja2 template (completed 2026-08-15)

Full phase details, goals, and success criteria: [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. Scaffold Submodule Consolidation | v1.0 | 5/5 | Complete | 2026-08-09 |
| 6. Core UI Foundation | v1.1 | 6/6 | Complete | 2026-08-14 |
| 7. Media & Integration Widgets | v1.1 | 4/4 | Complete | 2026-08-15 |

## Out of scope (owned by consuming repos)

- Parent-side build orchestration: CMake pipeline, `FLUTTER_TEMPLATE_STYLE` option, generated-module drivers (owned by genius-ai-boss `frontend-templates` workstream, Phases 6-8)
- Actual C++ Cubit template content for `templates/cpp/` (downstream consumer scope; placeholder carved out in 05-04)
- Per-consumer submodule wiring and version pinning policy (consumer repo scope)
- App-specific composites (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline) — built from scaffold atoms in the consuming app
- State management for WalletConnectSheet session state — consumers own the Reown session; the sheet only presents it
