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
- ✅ **v1.2 Atom Extensions** — Phases 8-11 (shipped 2026-08-24): composition atoms, text/code primitives, chart + scrubber, verification & coverage gate. See [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- ✅ **v1.4 Design Tokens & Midnight Preset** — Phases 12-17 (shipped 2026-10-16): token pipeline, themeable shadows/typography/motion/gradients, default AA fixes, opt-in `midnight` preset, component restyles, release gates. See [milestones/v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- 🕓 **v1.3 POS-General Interaction Primitives** — queued, next (created 2026-10-01): SCF-POS-01..18, gated by SCF-POS-18. Phases are numbered from 18 and broken down at kickoff.

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

<details>
<summary>✅ v1.2 Atom Extensions (Phases 8-11) — SHIPPED 2026-08-24</summary>

- [x] **Phase 8: Supporting Atoms, Table Cells & Light Palette** (6/6 plans, completed 2026-08-17) — ScaffoldChip/ChipGroup, ScaffoldDisclosure/TraceList, ScaffoldComposer, DataColumnConfig cellBuilder extension, light default palette
- [x] **Phase 9: Text & Code Primitives** (6/6 plans, completed 2026-08-20) — ScaffoldStreamingRichText (incremental render, citations, action slots, a11y), ScaffoldCodeBlock (syntax spans, line numbers, streamed lines), ScaffoldSelectionActions (anchored toolbar)
- [x] **Phase 10: Chart & Scrubber** (6/6 plans, completed 2026-08-22) — ScaffoldChart (neutral series contract), ScaffoldChartScrubber (point selection composing with chart)
- [x] **Phase 11: Verification & Coverage Gate** (3/3 plans, completed 2026-08-23) — per-atom tests/demos/barrel sweep, Beautiful UI 19-component coverage check

Full phase details, goals, and success criteria: [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)

</details>

<details>
<summary>✅ v1.4 Design Tokens & Midnight Preset (Phases 12-17) — SHIPPED 2026-10-16</summary>

- [x] **Phase 12: Token Pipeline** (3/3 plans, completed 2026-10-16) — Dart palette and dimens generate byte-identically from `design_tokens.json`, drift check, LF output
- [x] **Phase 13: Theme Fields** (5/5 plans, completed 2026-10-16) — themeable shadows, typography, motion, gradients, accent/border/on-surface tokens
- [x] **Phase 14: Default Accessibility Fixes** (6/6 plans, completed 2026-10-16) — default palettes pass WCAG AA; light text field and drawers legible; sanctioned capture re-baselines
- [x] **Phase 15: Midnight Preset** (7/7 plans, completed 2026-10-16) — opt-in `midnight` theme (light and dark), example-app switcher, contrast test
- [x] **Phase 16: Component Restyles** (8/8 plans, completed 2026-10-16) — midnight look where tokens alone cannot reach, defaults unchanged
- [x] **Phase 17: Release Gates** (3/3 plans, completed 2026-10-16) — capture history gate, GeniusCognitiveSystem consumer check

Full phase details, goals, and success criteria: [milestones/v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)

</details>

## Next Milestone: v1.3 — POS-General Interaction Primitives (queued, next)

**Created:** 2026-10-01 · **Status:** queued, next — v1.4 shipped 2026-10-16; phases are numbered from 18 and broken down at kickoff (discuss/plan)

**Goal:** Extend the pinned scaffold inventory (28 atoms + composites) with the POS-general interaction primitives the touch-pos operating surface consumes, so touch-pos builds on the scaffold instead of growing a second design system.

**Requirements:** SCF-POS-01..18 (18 IDs) — in `.planning/workstreams/scaffold/REQUIREMENTS.md`. **Gate:** SCF-POS-18 (test/demo/a11y bar for every new primitive).

**Constraints:**

- Extend/expose the pinned inventory — no parallel widget system for POS surfaces.
- Generic/neutral: no app-specific strings, APIs, or business models (SCF-POS-18).
- Offline primitives are visual/status only (SCF-POS-16); offline business behavior stays consumer-owned.

**Decisions to ratify at discuss-phase:** DEC-TOA-02, DEC-TOA-03 (parent-repo ingest decisions, currently proposed).
**Sequencing:** next after v1.4 (originally independent, CN-15 #1). Consumers: touch-pos v2.0 (SCF-POS-16 feeds Phase 22); frontend-templates v3.0 Phase 10 overlaps on generator/CMake/FFI needs (CN-15 #2).
**Provenance:** genius-ai-boss fulfillment+commercial-POS ingest follow-through (2026-10-01; 18 of 302 IDs) — parent `.planning/intel/MERGE-PLAN.md` §1.7 is the routing record.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. Scaffold Submodule Consolidation | v1.0 | 5/5 | Complete | 2026-08-09 |
| 6. Core UI Foundation | v1.1 | 6/6 | Complete | 2026-08-14 |
| 7. Media & Integration Widgets | v1.1 | 4/4 | Complete | 2026-08-15 |
| 8. Supporting Atoms, Table Cells & Light Palette | v1.2 | 6/6 | Complete | 2026-08-17 |
| 9. Text & Code Primitives | v1.2 | 6/6 | Complete | 2026-08-20 |
| 10. Chart & Scrubber | v1.2 | 6/6 | Complete | 2026-08-22 |
| 11. Verification & Coverage Gate | v1.2 | 3/3 | Complete | 2026-08-23 |
| 12. Token Pipeline | v1.4 | 3/3 | Complete | 2026-10-16 |
| 13. Theme Fields | v1.4 | 5/5 | Complete | 2026-10-16 |
| 14. Default Accessibility Fixes | v1.4 | 6/6 | Complete | 2026-10-16 |
| 15. Midnight Preset | v1.4 | 7/7 | Complete | 2026-10-16 |
| 16. Component Restyles | v1.4 | 8/8 | Complete | 2026-10-16 |
| 17. Release Gates | v1.4 | 3/3 | Complete | 2026-10-16 |

## Out of scope (owned by consuming repos)

- Parent-side build orchestration: CMake pipeline, `FLUTTER_TEMPLATE_STYLE` option, generated-module drivers (owned by genius-ai-boss `frontend-templates` workstream, Phases 6-8)
- Actual C++ Cubit template content for `templates/cpp/` (downstream consumer scope; placeholder carved out in 05-04)
- Per-consumer submodule wiring and version pinning policy (consumer repo scope)
- App-specific composites (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline) — built from scaffold atoms in the consuming app
- State management for WalletConnectSheet session state — consumers own the Reown session; the sheet only presents it
- AI composites (`lib/ai_components/` — loading state, thinking trace, streaming answer, approval card, tool chips, task rows, chat, prompt bar, etc.) — built as an extension inside the AI chat app consuming scaffold primitives; atoms stay domain-agnostic (owner decision 2026-08-17)
- Style Dictionary / DTCG token format, build_runner codegen, and driving Dart generation from the CMake `DESIGN_TOKENS` override (v1.4 out of scope; see milestones/v1.4-REQUIREMENTS.md)
