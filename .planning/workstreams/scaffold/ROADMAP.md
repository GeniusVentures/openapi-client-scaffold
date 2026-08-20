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
- 🚧 **v1.2 Atom Extensions** — Phases 8-11 (in progress): streaming rich text, chart + scrubber, code block, selection actions, chips, disclosures, composer, extensible table cells, light palette; verified against the 19-component Beautiful UI set

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

### v1.2 Atom Extensions (Phases 8-11) — IN PROGRESS

- [x] **Phase 8: Supporting Atoms, Table Cells & Light Palette** (6/6 plans, completed 2026-08-17) — ScaffoldChip/ChipGroup, ScaffoldDisclosure/TraceList, ScaffoldComposer, DataColumnConfig cellBuilder extension, light default palette
- [ ] **Phase 9: Text & Code Primitives** — ScaffoldStreamingRichText (incremental render, citations, action slots, a11y), ScaffoldCodeBlock (syntax spans, line numbers, streamed lines), ScaffoldSelectionActions (anchored toolbar)
- [ ] **Phase 10: Chart & Scrubber** — ScaffoldChart (neutral series contract), ScaffoldChartScrubber (point selection composing with chart)
- [ ] **Phase 11: Verification & Coverage Gate** — per-atom tests/demos/barrel sweep, Beautiful UI 19-component coverage check

## Phase Details

### Phase 8: Supporting Atoms, Table Cells & Light Palette
**Goal**: Low-dependency composition atoms (chip, disclosure, composer) ship alongside the DataTable cell-builder extension and the light default palette — every consumer can build chip groups, trace rows, composition areas, custom table cells, and render correctly under a light theme.
**Depends on**: Phase 7 (v1.1 atoms — surface, pressable, badge, status_indicator are the composition inputs)
**Requirements**: WIDG-40, WIDG-41, WIDG-42, WIDG-43, WIDG-46
**Success Criteria** (what must be TRUE):
  1. `ScaffoldChip` renders a pressable token with icon/text and optional status indicator; `ScaffoldChipGroup` lays out a set of chips and reports selection changes
  2. `ScaffoldDisclosure` expands/collapses a row generically; `ScaffoldTraceList` renders an ordered list of disclosure items
  3. `ScaffoldComposer` provides a text-entry area with action button slots and badge/attachment slots
  4. A consumer passes `cellBuilder` on `DataColumnConfig<T>` and the generated data table renders that custom widget per cell without forking the table
  5. All scaffold widgets render correctly under a default light `ThemeData` with no consumer overrides (light palette ships with full token coverage)
**Plans:** 6 plans

Plans:
- [x] 08-01-PLAN.md — ScaffoldBadge on-status remediation + light palette token verification (WIDG-46)
- [x] 08-02-PLAN.md — DataColumnConfig<T> cellBuilder template extension (WIDG-43)
- [x] 08-03-PLAN.md — ScaffoldDisclosure + ScaffoldTraceList atoms (WIDG-41)
- [x] 08-04-PLAN.md — ScaffoldChip + ScaffoldChipGroup atoms (WIDG-40)
- [x] 08-05-PLAN.md — ScaffoldComposer atom (WIDG-42)
- [x] 08-06-PLAN.md — Barrel exports + demo registrations + final gates (WIDG-40, 41, 42 closure)
**UI hint**: yes

### Phase 9: Text & Code Primitives
**Goal**: Streaming rich text, syntax-highlighted code, and selection-anchored action toolbars ship as generic atoms — the three text-centric hard primitives that close the biggest Beautiful UI gaps.
**Depends on**: Phase 8 (composer + chips may be slotted into response actions; selection actions composes with streaming text and code block without hard-depending)
**Requirements**: WIDG-32, WIDG-33, WIDG-34, WIDG-37, WIDG-38, WIDG-39
**Success Criteria** (what must be TRUE):
  1. `ScaffoldStreamingRichText` renders incrementally-updated rich text without rebuilding the full response, with a visible streaming cursor state
  2. Inline source/citation markers expand into source slots within the streaming text
  3. Response-action slots (copy, retry, rate, follow-up) render below the streaming text, and accessibility announcements do not reread the whole answer per token
  4. `ScaffoldCodeBlock` renders syntax-highlighted spans with line numbers, a language/filename header, and a working copy action
  5. Code block supports horizontal scrolling, streamed line insertion, reduced-motion behavior, and `ScaffoldSelectionActions` wraps selectable content reporting `onSelectionChanged(TextSelection, String)` with an anchored action toolbar
**Plans:** 4/6 plans executed

Plans:
- [x] 09-01-PLAN.md — ScaffoldStreamingRichText atom + typed span model + announce-policy hook (WIDG-32, 33, 34)
- [x] 09-02-PLAN.md — ScaffoldCodeBlock atom with DI highlighting + streamed lines (WIDG-37, 38)
- [x] 09-03-PLAN.md — ScaffoldSelectionActions anchored toolbar wrapper (WIDG-39)
- [ ] 09-04-PLAN.md — Demos for the three atoms (D-07 demonstrability)
- [x] 09-05-PLAN.md — Support parts: markdown_to_spans + light_syntax_tokenizer + copy buttons + their demos/tests (D-03, D-04, D-07, D-08)
- [ ] 09-06-PLAN.md — Barrel exports + demo registration + final gates + human UAT (WIDG-32..34, 37..39 closure)
**UI hint**: yes

### Phase 10: Chart & Scrubber
**Goal**: A neutral chart primitive renders any consumer-supplied series and supports point scrubbing — closing the Insight Cards gap without domain knowledge leaking into the scaffold.
**Depends on**: Phase 8 (surface/motion/status atoms for chart chrome; does not depend on Phase 9)
**Requirements**: WIDG-35, WIDG-36
**Success Criteria** (what must be TRUE):
  1. `ScaffoldChart` renders a series supplied via a neutral data contract (`series`, `xAccessor`, `yAccessor`) with no domain knowledge in the widget
  2. `ScaffoldChartScrubber` composes with `ScaffoldChart` to expose `selectedPoint` and fire `onPointSelected` on tap/drag
  3. Chart + scrubber render correctly under both dark and light palettes with M3 theme tokens only
**Plans**: TBD
**UI hint**: yes

### Phase 11: Verification & Coverage Gate
**Goal**: Every v1.2 atom meets the v1.1 shipping bar (tests, demo, barrel export) and the 19-component Beautiful UI set is demonstrably composable from shipped scaffold atoms.
**Depends on**: Phases 8, 9, 10 (all atoms shipped)
**Requirements**: WIDG-44, WIDG-45
**Success Criteria** (what must be TRUE):
  1. Every new atom has widget tests passing, a demo in `example/`, and a barrel export — same bar as v1.1
  2. `dart analyze --fatal-infos` is clean across the package
  3. A coverage document demonstrates all 19 Beautiful UI components are composable from shipped scaffold atoms (7 ready + 8 thin + 4 primitive-enabled)
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. Scaffold Submodule Consolidation | v1.0 | 5/5 | Complete | 2026-08-09 |
| 6. Core UI Foundation | v1.1 | 6/6 | Complete | 2026-08-14 |
| 7. Media & Integration Widgets | v1.1 | 4/4 | Complete | 2026-08-15 |
| 8. Supporting Atoms, Table Cells & Light Palette | v1.2 | 6/6 | Complete | 2026-08-17 |
| 9. Text & Code Primitives | v1.2 | 4/6 | In Progress|  |
| 10. Chart & Scrubber | v1.2 | 0/? | Not started | - |
| 11. Verification & Coverage Gate | v1.2 | 0/? | Not started | - |

## Out of scope (owned by consuming repos)

- Parent-side build orchestration: CMake pipeline, `FLUTTER_TEMPLATE_STYLE` option, generated-module drivers (owned by genius-ai-boss `frontend-templates` workstream, Phases 6-8)
- Actual C++ Cubit template content for `templates/cpp/` (downstream consumer scope; placeholder carved out in 05-04)
- Per-consumer submodule wiring and version pinning policy (consumer repo scope)
- App-specific composites (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline) — built from scaffold atoms in the consuming app
- State management for WalletConnectSheet session state — consumers own the Reown session; the sheet only presents it
- AI composites (`lib/ai_components/` — loading state, thinking trace, streaming answer, approval card, tool chips, task rows, chat, prompt bar, etc.) — built as an extension inside the AI chat app consuming scaffold primitives; atoms stay domain-agnostic (owner decision 2026-08-17)
