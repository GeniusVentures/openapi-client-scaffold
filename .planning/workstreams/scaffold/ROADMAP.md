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

- ✅ **v1.0 Scaffold Shared Source** — Phase 5 (completed 2026-08-09): submodule established as the single shared widget/template source; `frontend_scaffold` package at v0.3.0

## Phases

- [x] **Phase 5: Scaffold Submodule Consolidation** — submodule is the single shared source for GeniusWallet bloc widgets and genius-tube C++ interface templates, consumable via pinned submodule (completed 2026-08-09)

## Phase Details

### Phase 5: Scaffold Submodule Consolidation
**Goal**: this submodule (openapi-client-scaffold) is the single shared source for both GeniusWallet bloc widgets and genius-tube C++ interface templates, consumable by any consuming repo via submodule
**Depends on**: parent frontend-templates v1.0 (existing scaffold submodule + identity-only templates directory)
**Requirements**: SUB-01, SUB-02, SUB-03
**Success Criteria** (what must be TRUE):
  1. A Flutter project that adds this submodule as a dependency can import and render GeniusWallet bloc widgets without copying files
  2. A C++ template render against `templates/` finds both the v1.0 identity templates AND the genius-tube Cubit-style interface templates side-by-side
  3. Cloning a consuming repo recursively pulls this submodule at a pinned commit; consumers build against the same widget/template sources
  4. The submodule's own template directory renders successfully (green build) through the v1.0 CMake pipeline from its location here (no regression)
**Plans**: 5 plans
**Plan list**:
- [x] 05-01 — copy engine + tokens + 6 component sets + base + module jinja2 into the submodule
- [x] 05-02 — re-point parent CMake + generate_domain_modules.py at the submodule, add duplicate-stamp guard, verify byte-identical render
- [x] 05-03 — create the `frontend_scaffold` Dart package (pubspec + lib/ barrel + 22 copied files + dart analyze)
- [x] 05-04 — pre-stage `templates/cpp/` README, rewrite `templates/README.md` per D5-15, bump parent submodule pointer
- [x] 05-05 — port GeniusWallet toast redesign (two-density, optional title, message-first API) into `frontend_scaffold` v0.3.0, preserving CR-02..04 lifecycle fixes; gate on upstream GW merge overridden — pinned to GW branch tip b4b63a5a, the scaffold is the toast authority
**UI hint**: no

**Phase artifacts**: see `phases/05-scaffold-submodule-consolidation/` (PLAN, RESEARCH, REVIEW, VERIFICATION, and the 05-05 toast-sync RESEARCH/REVIEW/SUMMARY).

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. Scaffold Submodule Consolidation | v1.0 | 5/5 | Complete | 2026-08-09 |

## Coverage

| Requirement | Phase |
|-------------|-------|
| SUB-01 | Phase 5 |
| SUB-02 | Phase 5 |
| SUB-03 | Phase 5 |

**Coverage: 3/3 requirements mapped.**

## Out of scope (owned by consuming repos)

- Parent-side build orchestration: CMake pipeline, `FLUTTER_TEMPLATE_STYLE` option, generated-module drivers (owned by genius-ai-boss `frontend-templates` workstream, Phases 6-8)
- Actual C++ Cubit template content for `templates/cpp/` (downstream consumer scope; placeholder carved out in 05-04)
- Per-consumer submodule wiring and version pinning policy (consumer repo scope)
