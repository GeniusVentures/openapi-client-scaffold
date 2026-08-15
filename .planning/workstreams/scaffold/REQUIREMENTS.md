---
workstream: scaffold
milestone: v1.0
status: active
---

# Requirements: Scaffold

The `frontend_scaffold` submodule (openapi-client-scaffold) is the single shared source for
GeniusWallet bloc widgets and genius-tube C++ interface templates, consumable by any
consuming repo via submodule. These requirements define the submodule's contract with its
consumers. They were originally tracked as SUB-01..03 in the parent's `frontend-templates`
workstream (Phase 5); they are extracted here so the scaffold owns its own planning record
and sibling projects (e.g. genius-tube) share it.

## Requirements

### Submodule (SUB)

- [x] **SUB-01**: GeniusWallet bloc-based widgets are copied into this submodule as a shared, consumable Flutter package (`frontend_scaffold`), importable by any Flutter project without copying files
- [x] **SUB-02**: genius-tube generic C++ Cubit-style interface templates are pre-staged in `templates/` alongside the existing identity templates (placeholder carved out; actual C++ template content is downstream consumer scope)
- [x] **SUB-03**: this submodule is consumable as a pinned git submodule at the same commit across consuming repos (genius-ai-boss, genius-tube) so all build against the same widget/template sources from one origin

## Requirements

### Widget Library (WIDG)

The Core UI Foundation — 28 generic, Material 3, composable widget atoms shipped in
Phase 6. Each is a plain Dart widget (runtime-parameterized) except the 4 template
candidates and 3 composites, which are Jinja2-template-generated. All consume only
`Theme.of(context)` via `context.palette`/`context.dimens`, with full accessibility
semantics and 48px minimum touch targets.

- [x] **WIDG-01**: `ScaffoldMotion` — shared durations/curves + reduced-motion propagation (utility + InheritedWidget)
- [x] **WIDG-02**: `ScaffoldSurface` — background/border/shape/radius/elevation/state-layer container
- [x] **WIDG-03**: `ScaffoldTouchTarget` — minimum 48×48 hit area + accessibility semantics
- [x] **WIDG-04**: `ScaffoldFocusOutline` — consistent keyboard/accessibility focus border
- [x] **WIDG-05**: `ScaffoldLiveRegion` — screen-reader status announcements
- [x] **WIDG-06**: `ScaffoldOverflowFade` — edge-fade for clipped content (per-edge + symmetric)
- [x] **WIDG-07**: `ScaffoldScrollEdgeIndicator` — marks scrollable edges
- [x] **WIDG-08**: `ScaffoldResponsiveVisibility` — show/hide/replace at breakpoints
- [x] **WIDG-09**: `ScaffoldFormattedValue` — number/money/percentage/date/time/duration (template-generated)
- [x] **WIDG-10**: `ScaffoldColorSwatch` — selectable/read-only color samples
- [x] **WIDG-11**: `ScaffoldBadge` — dot/count/icon/text over/adjacent to a child
- [x] **WIDG-12**: `ScaffoldStatusIndicator` — generic status via color/shape/icon + accessible label
- [x] **WIDG-13**: `ScaffoldSelectionIndicator` — radio/checkbox/toggle (template-generated)
- [x] **WIDG-14**: `ScaffoldImagePlaceholder` — loading/missing/empty/failed (template-generated)
- [x] **WIDG-15**: `ScaffoldSkeleton` — animated placeholder consuming ScaffoldMotion
- [x] **WIDG-16**: `ScaffoldAnimatedDisplay` — fade/pulse/scale/slide/rotate/shake/bounce (template-generated)
- [x] **WIDG-17**: `ScaffoldPressable` — pressed/hovered/focused/disabled states
- [x] **WIDG-18**: `ScaffoldDisabledOverlay` — interaction block with visual dim + reason
- [x] **WIDG-19**: `ScaffoldDragHandle` — reorder grip
- [x] **WIDG-20**: `ScaffoldResizeHandle` — horizontal/vertical/corner resize drag
- [x] **WIDG-21**: `ScaffoldNumericInput` — bounded/precision/step value with increment/decrement
- [x] **WIDG-22**: `ScaffoldSelectableSurface` — selected/focused/pressed/disabled surface
- [x] **WIDG-23**: `ScaffoldDraggable` — drag feedback/preview/state callbacks
- [x] **WIDG-24**: `ScaffoldDropTarget` — idle/accepted/rejected/dropped drag states
- [x] **WIDG-25**: `ScaffoldFileInputSurface` — file select/drop surface with validation
- [x] **WIDG-26**: `ScaffoldCard` — elevated/outlined/filled with header/body/action slots (template-generated)
- [x] **WIDG-27**: `ScaffoldStateView` — loading/empty/error/unavailable/success (template-generated)
- [x] **WIDG-28**: `ScaffoldSearchBar` — pill search with clear/loading/result hooks (template-generated)

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| SUB-01 | Phase 5 | Complete (05-03, hardened by review + 05-05) |
| SUB-02 | Phase 5 | Complete (05-04 placeholder) |
| SUB-03 | Phase 5 | Complete (pinned submodule; per-consumer wiring is consumer scope) |
| WIDG-01..10 | Phase 6 | Complete (Wave 0 — zero-dep foundations) |
| WIDG-11..21 | Phase 6 | Complete (Wave 1 — single-dep atoms) |
| WIDG-22..25 | Phase 6 | Complete (Wave 2 — multi-dep atoms) |
| WIDG-26..28 | Phase 6 | Complete (Wave 3 — template composites) |

## Notes

- **Provenance**: extracted from `genius-ai-boss/.planning/workstreams/frontend-templates/REQUIREMENTS.md` (SUB-01..03) on 2026-08-09. The parent workstream retains its own copy as the orchestration record for Phases 5-8.
- **Scope boundary**: this workstream owns the submodule's *contents* (widget package, templates). Parent-side build orchestration (CMake pipeline, `FLUTTER_TEMPLATE_STYLE`, generated-module drivers) is owned by the consuming repo's workstream, not here.
