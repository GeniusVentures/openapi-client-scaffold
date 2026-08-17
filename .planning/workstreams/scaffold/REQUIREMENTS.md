# Requirements: Frontend Scaffold — v1.2 Atom Extensions

**Defined:** 2026-08-17
**Core Value:** `frontend_scaffold` (openapi-client-scaffold) is the single shared source for Genius Network Flutter widgets, M3 theme infrastructure, and Jinja2 codegen templates — generic, M3-themed, zero app-specific business logic, consumable by any repo via pinned submodule

**Milestone goal:** Extend the scaffold's generic atom library so the primitives support arbitrary composable widgets — streaming text, charts, code, selection-driven actions, chips, disclosures, composers, and extensible table cells — verified against the 19-component Beautiful UI set as the coverage yardstick.

Seed analysis: `.planning/atoms-v1.2-additions.md` (7/19 Beautiful UI components ready via existing atoms, 8 via thin composites, 4 enabled by the new primitives).

## v1.2 Requirements

### New Primitives

- [ ] **WIDG-32**: `ScaffoldStreamingRichText` renders incrementally-updated rich text without rebuilding the full response
- [ ] **WIDG-33**: `ScaffoldStreamingRichText` supports inline source/citation markers with expandable source slots and streaming cursor state
- [ ] **WIDG-34**: `ScaffoldStreamingRichText` exposes response-action slots (copy, retry, rate, follow-up) and accessibility announcements that don't reread the whole answer per token
- [ ] **WIDG-35**: `ScaffoldChart` renders a series via a neutral data contract (`series`, `xAccessor`, `yAccessor`) with no domain knowledge
- [ ] **WIDG-36**: `ScaffoldChartScrubber` provides point selection/scrubbing (`selectedPoint`, `onPointSelected`) composing with `ScaffoldChart`
- [ ] **WIDG-37**: `ScaffoldCodeBlock` renders syntax-highlighted code spans with line numbers, language/filename header, and copy action
- [ ] **WIDG-38**: `ScaffoldCodeBlock` supports horizontal scrolling, streamed line insertion, and reduced-motion behavior
- [ ] **WIDG-39**: `ScaffoldSelectionActions` wraps selectable content and reports `onSelectionChanged(TextSelection, String)` with an anchored action toolbar

### Supporting Atoms

- [ ] **WIDG-40**: `ScaffoldChip` renders a pressable token atom (icon/text + optional status indicator); `ScaffoldChipGroup` lays out and manages chip sets
- [ ] **WIDG-41**: `ScaffoldDisclosure` provides generic expand/collapse of rows; `ScaffoldTraceList` renders an ordered trace of disclosure items
- [ ] **WIDG-42**: `ScaffoldComposer` provides a text-entry composition area with action button slots and badge/attachment slots

### DataTable Extension

- [ ] **WIDG-43**: `DataColumnConfig<T>` gains a `cellBuilder` (`Widget Function(BuildContext, T item)?`) so consumers render custom cells without forking the table

### Theme

- [ ] **WIDG-46**: Light default palette complementing the dark-seeded `ScaffoldPalette` defaults — full token coverage so widgets render correctly under a light `ThemeData` without consumer overrides (carried from v1.0)

### Verification & Polish

- [ ] **WIDG-44**: Each new atom ships with widget tests, a demo in `example/`, and barrel export (same bar as v1.1)
- [ ] **WIDG-45**: Beautiful UI coverage check — all 19 components demonstrably composable from shipped scaffold atoms (7 ready + 8 thin + 4 primitive-enabled)

## Future Requirements

Deferred to future milestones. Tracked but not in the v1.2 roadmap.

### HTML Template Parity

- **HTML-01**: HTML/CSS templates mirror the Flutter atom library (the current HTML generator covers only card, data table, form dialog, navigation, search bar, and state). Reserved for a future version — NOT deprecated.

### Existing Template Widget Forms

- **TMPL-01**: Navigation component widget from `navigation.dart.jinja2`
- **TMPL-02**: DataTable widget from `data_table.dart.jinja2` (beyond the WIDG-43 cell-builder extension)
- **TMPL-03**: FormDialog widget from `form_dialog.dart.jinja2`

## Out of Scope

Explicitly excluded from v1.2. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| AI composites (`lib/ai_components/` — loading state, thinking trace, streaming answer, approval card, tool chips, task rows, chat, prompt bar, etc.) | Built as an extension inside the AI chat app, consuming scaffold primitives; atoms must stay domain-agnostic (owner decision 2026-08-17) |
| Domain knowledge in atoms (agents, prompts, sources, suppliers) | Violates the scaffold's neutral-generic-package constraint; composites accept typed models + slots in the consuming app |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| WIDG-32 | Phase 9 | Pending |
| WIDG-33 | Phase 9 | Pending |
| WIDG-34 | Phase 9 | Pending |
| WIDG-35 | Phase 10 | Pending |
| WIDG-36 | Phase 10 | Pending |
| WIDG-37 | Phase 9 | Pending |
| WIDG-38 | Phase 9 | Pending |
| WIDG-39 | Phase 9 | Pending |
| WIDG-40 | Phase 8 | Pending |
| WIDG-41 | Phase 8 | Pending |
| WIDG-42 | Phase 8 | Pending |
| WIDG-43 | Phase 8 | Pending |
| WIDG-44 | Phase 11 | Pending |
| WIDG-45 | Phase 11 | Pending |
| WIDG-46 | Phase 8 | Pending |

**Coverage:**
- v1.2 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-08-17*
*Last updated: 2026-08-17 after v1.2 roadmap creation*
