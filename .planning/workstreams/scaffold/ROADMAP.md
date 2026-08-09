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
- ⬜ **v1.1 Widget Library** — Phases 6-8: ship Dart widget implementations for the three template-only components (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar), workspace-common integration widgets (ScaffoldBadge, WalletConnectSheet), and the media widget pair (MediaCard, MediaControls) that unblocks genius-tube Phase 2

## Phases

- [x] **Phase 5: Scaffold Submodule Consolidation** — submodule is the single shared source for GeniusWallet bloc widgets and genius-tube C++ interface templates, consumable via pinned submodule (completed 2026-08-09)
- [ ] **Phase 6: Core Template Widgets** — implement ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar from existing Jinja2 templates; three independent M3 atoms with no cross-deps
- [ ] **Phase 7: Integration Widgets** — ScaffoldBadge primitive + WalletConnectSheet composite (built on existing BottomDrawer); workspace-common, reusable by any consumer app
- [ ] **Phase 8: Media Widgets** — MediaCard (consumes ScaffoldBadge from Phase 7) + MediaControls; new template+widget pairs, critical path for genius-tube Phase 2

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

### Phase 6: Core Template Widgets
**Goal**: the three template-only widgets (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar) have shipped Dart implementations in `lib/components/` that consumers can import and render, each behaving exactly as its Jinja2 template envisions
**Depends on**: Phase 5 (the `frontend_scaffold` package must exist with its barrel export and theme infrastructure)
**Requirements**: WIDG-01, WIDG-02, WIDG-03
**Success Criteria** (what must be TRUE):
  1. A consumer app can construct a `ScaffoldCard` with header/body/actions slots and select elevated, outlined, or filled variants — the rendered card matches the M3 surface treatment each variant name promises
  2. A consumer app can render `ScaffoldStateView` in empty, loading, and error modes from a single variant-enum constructor — empty shows icon+headline+subtitle+optional CTA, loading shows skeleton rows, error shows an inline error card with message and retry button
  3. A consumer app can mount `ScaffoldSearchBar`, type a query, see the clear button appear, and observe a grouped results dropdown (each group under a labelled header) that hides on focus loss and fires `onResultTap` with the tapped item's id
  4. All three widgets are exported from the `frontend_scaffold` barrel and pass `dart analyze` with zero warnings; they consume only `Theme.of(context)` (no Riverpod, no GeniusTheme)
**Plans**: TBD
**UI hint**: yes

### Phase 7: Integration Widgets
**Goal**: the workspace-common primitives ScaffoldBadge and WalletConnectSheet exist as reusable widgets any Genius Network app can drop in — the badge is a generic chip atom, the wallet sheet is a Reown-session-presenting composite built on the existing BottomDrawer
**Depends on**: Phase 5 (package + BottomDrawer in `lib/components/bottom_drawer/`); Phase 6 is NOT a hard dependency, but executing 7 after 6 keeps the "ship atoms, then composites" rhythm
**Requirements**: WIDG-06, WIDG-07
**Success Criteria** (what must be TRUE):
  1. A consumer app can render a `ScaffoldBadge` with an icon, a label, a configurable background color, and a density (compact or card) — the badge sizes itself correctly in both densities
  2. `ScaffoldBadge` is exported from the barrel and is ready for MediaCard's badge slots to consume in Phase 8 (typed, theme-respecting, no app-specific logic)
  3. A consumer app can present `WalletConnectSheet` as a bottom sheet that shows the disconnected state (QR connect affordance) and the connected state (wallet address + network + disconnect action), with `onConnect`/`onDisconnect` callbacks firing as advertised
  4. `WalletConnectSheet` receives its session state externally (it does not own or mutate Reown session state internally), so two different consumer apps can drive it from their own state layer
  5. Both widgets consume only `Theme.of(context)` and pass `dart analyze` clean; `WalletConnectSheet` builds on the existing `BottomDrawer` rather than re-implementing sheet chrome
**Plans**: TBD
**UI hint**: yes

### Phase 8: Media Widgets
**Goal**: the MediaCard + MediaControls widget pair ships as generic, configurable media atoms — MediaCard renders any thumbnail at a chosen aspect ratio with typed badge slots and a metadata row, MediaControls overlays a full control bar — unblocking genius-tube Phase 2 media surfaces without pulling app-specific logic into the scaffold
**Depends on**: Phase 7 (ScaffoldBadge must exist so MediaCard's badge slots can consume it); Phase 5 package infrastructure
**Requirements**: WIDG-04, WIDG-05
**Success Criteria** (what must be TRUE):
  1. A consumer app can mount a `MediaCard` at 16:9, 9:16, or 1:1 aspect ratio with a thumbnail from any `ImageProvider`, and see typed badge slots (top-left, top-right, bottom-right) populated with `ScaffoldBadge` instances
  2. A `MediaCard` renders a metadata row built from arbitrary caller-supplied children (title, subtitle, duration chip, etc.) without the scaffold knowing what media metadata is
  3. A consumer app can overlay `MediaControls` on a media surface and get play/pause toggle, a seekbar showing buffered amount, volume mute/unmute, and fullscreen enter/exit — all callbacks optional and no-op when null so the widget renders correctly in a static/preview context
  4. A new `templates/components/media_card.dart.jinja2` exists alongside the widget (Jinja2 `StrictUndefined`, source-schema header per the codegen conventions) so future render-time variants stay codegen-driven
  5. Both widgets are exported from the barrel, consume only `Theme.of(context)`, and pass `dart analyze` clean; the scaffold ships zero app-specific media logic
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. Scaffold Submodule Consolidation | v1.0 | 5/5 | Complete | 2026-08-09 |
| 6. Core Template Widgets | v1.1 | 0/0 | Not started | - |
| 7. Integration Widgets | v1.1 | 0/0 | Not started | - |
| 8. Media Widgets | v1.1 | 0/0 | Not started | - |

## Coverage

| Requirement | Phase |
|-------------|-------|
| SUB-01 | Phase 5 |
| SUB-02 | Phase 5 |
| SUB-03 | Phase 5 |
| WIDG-01 | Phase 6 |
| WIDG-02 | Phase 6 |
| WIDG-03 | Phase 6 |
| WIDG-06 | Phase 7 |
| WIDG-07 | Phase 7 |
| WIDG-04 | Phase 8 |
| WIDG-05 | Phase 8 |

**Coverage: 10/10 requirements mapped (3 SUB + 7 WIDG); all 7 v1.1 requirements mapped.**

## Out of scope (owned by consuming repos)

- Parent-side build orchestration: CMake pipeline, `FLUTTER_TEMPLATE_STYLE` option, generated-module drivers (owned by genius-ai-boss `frontend-templates` workstream, Phases 6-8)
- Actual C++ Cubit template content for `templates/cpp/` (downstream consumer scope; placeholder carved out in 05-04)
- Per-consumer submodule wiring and version pinning policy (consumer repo scope)
- App-specific composites (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline) — built from scaffold atoms in the consuming app
- State management for WalletConnectSheet session state — consumers own the Reown session; the sheet only presents it

## Phase ordering rationale (v1.1)

The phases are ordered by dependency, not by the requirement numbering:

- **Phase 6 first** because WIDG-01/02/03 have existing Jinja2 templates and zero cross-widget dependencies — they are independent atoms and the fastest unblock for genius-ai-boss (ScaffoldCard, ScaffoldStateView) and genius-tube (ScaffoldStateView, ScaffoldSearchBar).
- **Phase 7 before Phase 8** because `MediaCard` (WIDG-04) has typed badge slots that consume `ScaffoldBadge` (WIDG-07). Shipping the badge primitive first means Phase 8 wires real badge instances rather than placeholders. `WalletConnectSheet` (WIDG-06) rides along in Phase 7 because it is also workspace-common and builds on the existing `BottomDrawer`.
- **Phase 8 last** because it is the genius-tube Phase 2 critical path and benefits from having both the badge atom (Phase 7) and the template conventions (Phase 6) settled before introducing a new template (`media_card.dart.jinja2`) plus widget pair.
