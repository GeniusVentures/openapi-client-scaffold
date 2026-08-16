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
- ⬜ **v1.1 Widget Library** — Phases 6-7: ship 28 widget atoms + ScaffoldMotion utility + 3 template-generated composites as the Core UI Foundation (Phase 6), then media and integration widgets (Phase 7)

## Phases

- [x] **Phase 5: Scaffold Submodule Consolidation** — submodule is the single shared source for GeniusWallet bloc widgets and genius-tube C++ interface templates, consumable via pinned submodule (completed 2026-08-09)
- [x] **Phase 6: Core UI Foundation** — 28 widget atoms + ScaffoldMotion across 4 dependency-layered waves; atoms ship as plain Dart widgets (runtime-parameterized) except 4 template candidates (FormattedValue, SelectionIndicator, ImagePlaceholder, AnimatedDisplay) + 3 Jinja2-template-generated composites (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar) (completed 2026-08-14)
- [ ] **Phase 7: Media & Integration Widgets** — MediaCard (consumes ScaffoldBadge badge slots), MediaControls (consumes ScaffoldPressable + ScaffoldTouchTarget), WalletConnectSheet (built on existing BottomDrawer); new media_card.dart.jinja2 template

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

### Phase 6: Core UI Foundation

**Goal**: ship 28 widget atoms as the universal UI foundation, grouped into 4 dependency-layered waves — every consumer app builds its interfaces from these primitives; atoms are plain Dart widgets (runtime-parameterized) except where variant-driven code generation earns its keep; the 3 existing Jinja2 templates (card, state, search_bar) ship as pre-built composites consuming the atoms
**Depends on**: Phase 5 (the `frontend_scaffold` package must exist with its barrel export, theme infrastructure, and Breakpoints utility)
**Requirements**: WIDG-01 through WIDG-28
**Success Criteria** (what must be TRUE):

  1. **Wave 0 (10 widgets + ScaffoldMotion):** ScaffoldMotion exports shared durations/curves/reduced-motion rules; ScaffoldSurface renders any child with background/border/shape/radius/elevation/state-layer; ScaffoldTouchTarget enforces minimum 48×48 touch area + accessibility semantics; ScaffoldFocusOutline draws a consistent keyboard/accessibility focus border; ScaffoldLiveRegion announces status changes to screen readers; ScaffoldOverflowFade renders edge-fade for clipped content; ScaffoldScrollEdgeIndicator marks scrollable edges; ScaffoldResponsiveVisibility shows/hides/replaces at breakpoints; ScaffoldFormattedValue renders numbers/money/percentages/dates/times/durations via format-specific templates; ScaffoldColorSwatch displays selectable/read-only color samples
  2. **Wave 1 (11 widgets):** ScaffoldBadge renders dot/count/icon/text over/adjacent to a child; ScaffoldStatusIndicator shows generic status via color/shape/icon + accessible label; ScaffoldSelectionIndicator renders radio/checkbox/toggle states (template-generated per variant); ScaffoldImagePlaceholder renders loading/missing/empty/failed states (template-generated per variant); ScaffoldSkeleton shows animated placeholder consuming ScaffoldMotion; ScaffoldAnimatedDisplay applies fade/pulse/scale/slide/rotate/shake/bounce (template-generated per animation); ScaffoldPressable wraps any child with pressed/hovered/focused/disabled states consuming ScaffoldTouchTarget; ScaffoldDisabledOverlay blocks interaction with visual dim + optional reason tooltip; ScaffoldDragHandle renders the standard reorder grip; ScaffoldResizeHandle provides horizontal/vertical/corner resize drag; ScaffoldNumericInput accepts bounded/precision/step values with increment/decrement
  3. **Wave 2 (4 widgets):** ScaffoldSelectableSurface renders selected/focused/pressed/disabled states consuming ScaffoldPressable+ScaffoldSurface; ScaffoldDraggable wraps any child with drag feedback/preview/state callbacks consuming ScaffoldPressable+ScaffoldDragHandle; ScaffoldDropTarget accepts dragged content with idle/accepted/rejected/dropped states consuming ScaffoldSurface+ScaffoldStatusIndicator; ScaffoldFileInputSurface provides file select/drop surface with validation states consuming ScaffoldSurface+ScaffoldDropTarget+ScaffoldStatusIndicator
  4. **Wave 3 (3 composites):** ScaffoldCard renders elevated/outlined/filled variants consuming ScaffoldSurface+ScaffoldPressable with header/body/action slots (template-generated); ScaffoldStateView renders loading/empty/error/unavailable/success states composing different atom sets per variant (template-generated); ScaffoldSearchBar renders pill-shaped search with clear/loading/filtering/result hooks consuming ScaffoldSurface+ScaffoldPressable+ScaffoldStatusIndicator (template-generated)
  5. All 28 widgets + ScaffoldMotion exported from the `frontend_scaffold` barrel, consuming only `Theme.of(context)` and scaffold atoms (no Riverpod, no GeniusTheme, no app-specific logic); `dart analyze` passes with zero warnings across all waves

**Plans**: 6 plans
**Plan list**:

- [x] 06-01-PLAN.md — Tracer: D-03 theme token expansion + ScaffoldMotion + ScaffoldSurface + ScaffoldTouchTarget + ScaffoldFocusOutline + tracer demo (WIDG-01..WIDG-04)
- [x] 06-02-PLAN.md — Wave 0 batch: ScaffoldLiveRegion + ScaffoldOverflowFade + ScaffoldScrollEdgeIndicator + ScaffoldResponsiveVisibility + ScaffoldFormattedValue + ScaffoldColorSwatch (WIDG-05..WIDG-10)
- [x] 06-03-PLAN.md — Wave 1 batch A: ScaffoldSkeleton + ScaffoldBadge + ScaffoldStatusIndicator + ScaffoldPressable + ScaffoldDisabledOverlay (WIDG-11,WIDG-12,WIDG-15,WIDG-17,WIDG-18)
- [x] 06-04-PLAN.md — Wave 1 batch B: ScaffoldSelectionIndicator + ScaffoldImagePlaceholder + ScaffoldAnimatedDisplay + ScaffoldDragHandle + ScaffoldResizeHandle + ScaffoldNumericInput (WIDG-13,WIDG-14,WIDG-16,WIDG-19,WIDG-20,WIDG-21)
- [x] 06-05-PLAN.md — Wave 2: ScaffoldSelectableSurface + ScaffoldDraggable + ScaffoldDropTarget + ScaffoldFileInputSurface (WIDG-22..WIDG-25)
- [x] 06-06-PLAN.md — Wave 3 composites + kitchen sink: ScaffoldCard + ScaffoldStateView + ScaffoldSearchBar + gallery demo (WIDG-26..WIDG-28)

**UI hint**: yes

### Phase 7: Media & Integration Widgets

**Goal**: ship the media widget pair (MediaCard consumes ScaffoldBadge badge slots, MediaControls consumes ScaffoldPressable + ScaffoldTouchTarget) plus WalletConnectSheet (built on existing BottomDrawer); new media_card.dart.jinja2 template ships alongside the widget
**Depends on**: Phase 6 (ScaffoldBadge for MediaCard badge slots, ScaffoldPressable + ScaffoldTouchTarget for MediaControls, ScaffoldSurface for sheet styling)
**Requirements**: WIDG-29, WIDG-30, WIDG-31
**Success Criteria** (what must be TRUE):

  1. A consumer app can mount a `MediaCard` at 16:9, 9:16, or 1:1 aspect ratio with a thumbnail from any `ImageProvider`, and see typed badge slots (top-left, top-right, bottom-right) populated with `ScaffoldBadge` instances
  2. A `MediaCard` renders a metadata row built from arbitrary caller-supplied children (title, subtitle, duration chip, etc.) without the scaffold knowing what media metadata is
  3. A consumer app can overlay `MediaControls` on a media surface and get play/pause toggle, a seekbar showing buffered amount, volume mute/unmute, and fullscreen enter/exit — all callbacks optional and no-op when null
  4. A new `templates/components/media_card.dart.jinja2` exists alongside the widget (Jinja2 `StrictUndefined`, source-schema header per the codegen conventions)
  5. A consumer app can present `WalletConnectSheet` as a bottom sheet that shows disconnected (QR connect) and connected (wallet address + network + disconnect) states, with `onConnect`/`onDisconnect` callbacks; session state passed in externally (no Reown session ownership)
  6. All three widgets exported from the barrel, consume only `Theme.of(context)` and Phase 6 atoms, and pass `dart analyze` clean

**Plans**: 4 plans
**Plan list**:

- [x] 07-01-PLAN.md — MediaCard widget + media_card.dart.jinja2 template + fixture + tests + demo (WIDG-29)
- [x] 07-02-PLAN.md — MediaControls widget + tests + demo (WIDG-30)
- [x] 07-03-PLAN.md — WalletConnectSheet widget + tests + demo (WIDG-31)
- [x] 07-04-PLAN.md — Barrel export + demo registration + final analyze/test gate (WIDG-29, WIDG-30, WIDG-31)

**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. Scaffold Submodule Consolidation | v1.0 | 5/5 | Complete | 2026-08-09 |
| 6. Core UI Foundation | v1.1 | 6/6 | Complete    | 2026-08-14 |
| 7. Media & Integration Widgets | v1.1 | 4/4 | Complete    | 2026-08-15 |

## Coverage

| Requirement | Phase |
|-------------|-------|
| SUB-01 | Phase 5 |
| SUB-02 | Phase 5 |
| SUB-03 | Phase 5 |
| WIDG-01..WIDG-10 | Phase 6 (Wave 0 — zero-dep foundations) |
| WIDG-11..WIDG-21 | Phase 6 (Wave 1 — single-dep atoms) |
| WIDG-22..WIDG-25 | Phase 6 (Wave 2 — multi-dep atoms) |
| WIDG-26..WIDG-28 | Phase 6 (Wave 3 — template composites) |
| WIDG-29..WIDG-31 | Phase 7 (Media & Integration) |

**Coverage: 34/34 requirements mapped (3 SUB + 31 WIDG). No orphans.**

## Out of scope (owned by consuming repos)

- Parent-side build orchestration: CMake pipeline, `FLUTTER_TEMPLATE_STYLE` option, generated-module drivers (owned by genius-ai-boss `frontend-templates` workstream, Phases 6-8)
- Actual C++ Cubit template content for `templates/cpp/` (downstream consumer scope; placeholder carved out in 05-04)
- Per-consumer submodule wiring and version pinning policy (consumer repo scope)
- App-specific composites (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline) — built from scaffold atoms in the consuming app
- State management for WalletConnectSheet session state — consumers own the Reown session; the sheet only presents it

## Phase ordering rationale (v1.1)

**Phase 6 is the entire Core UI Foundation** — 28 atoms + composites across 4 waves, ordered by dependency layer so each wave builds only on waves that already shipped:

- **Wave 0 (zero-dep):** ScaffoldMotion + 10 widgets with no scaffold dependencies. Only consume `Theme.of(context)` and existing Breakpoints. Ships first so every other wave has foundations to build on.
- **Wave 1 (single-dep):** 11 widgets that depend on exactly one Wave 0 atom. Badge, indicators, skeleton, animations, pressable, handles, input. Four are template-generated where variant changes the code structure; seven are plain parameterized widgets.
- **Wave 2 (multi-dep):** 4 widgets that compose two or more Wave 0-1 atoms. Selectable, draggable, drop target, file input.
- **Wave 3 (composites):** ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar — generated from existing `templates/components/` Jinja2 templates, consuming atoms shipped in Waves 0-2. Templates encode the composition recipe; atoms are the ingredients.

**Phase 7 consolidates the remaining widgets** (MediaCard, MediaControls, WalletConnectSheet) that depend on Phase 6 atoms — MediaCard consumes ScaffoldBadge, MediaControls consumes ScaffoldPressable + ScaffoldTouchTarget.

**Template boundary:** A template exists whenever the composition of atoms varies by intent, not by runtime state. ScaffoldCard's elevated/outlined/filled variants wire different surface treatments at generate-time. ScaffoldStateView's empty/loading/error/success states compose different atom sets. Plain atoms like ScaffoldBadge or ScaffoldPressable take runtime parameters — a template would add indirection with no benefit.
