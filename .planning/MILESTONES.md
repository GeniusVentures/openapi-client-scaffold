# Milestones: Frontend Scaffold

## v1.2 Atom Extensions — ✅ SHIPPED 2026-08-24

**Phases:** 8-11 | **Plans:** 21 | **PR:** [#11](https://github.com/GeniusVentures/openapi-client-scaffold/pull/11)

Extended the widget library with the composition atoms, text/code primitives,
and chart widgets needed by consumer apps, then closed out with a
verification & coverage gate against the 19-component Beautiful UI set.

**Key accomplishments:**

- Composition atoms: ScaffoldChip/ChipGroup, ScaffoldDisclosure, ScaffoldTraceList, ScaffoldComposer; `DataColumnConfig.cellBuilder` table-cell extension; light-mode `ScaffoldPalette` (Phase 8)
- Text & code primitives: ScaffoldStreamingRichText (incremental render, citations, action slots), ScaffoldCodeBlock (syntax spans, line numbers, streamed lines), ScaffoldSelectionActions (anchored toolbar) (Phase 9)
- Charts: ScaffoldChart (neutral series contract), ScaffoldChartScrubber (selection + keyboard + a11y), drag-range selection with consumer zoom policy (Phase 10)
- Verification gate: zero-skip test suite (454 tests), reproducible dual-theme image-capture harness (26 demos → 52 PNGs), README component gallery + 19-row WIDG-45 coverage proof (Phase 11)
- Post-verification fixes: capture-harness theme-animation determinism fix (dark captures had painted the light-scheme primary), palette text-color alignment in remaining demo/component text

**Requirements:** 15/15 v1.2 WIDG requirements complete (WIDG-32..46 minus v1.1 scope). No orphans.

**Known deferred items at close:** 1 (stale quick-task marker, see STATE.md Deferred Items)
**Known minor defect:** capture harness registers Roboto-Medium under its own family — w500 labels render Regular weight in generated images

**Archive:** [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md) · [v1.2-REQUIREMENTS.md](milestones/v1.2-REQUIREMENTS.md)

---

Historical record of shipped milestones for the `frontend_scaffold` submodule.

## v1.1 Widget Library — ✅ SHIPPED 2026-08-17

**Phases:** 6-7 | **Plans:** 10 | **PR:** [#6](https://github.com/GeniusVentures/openapi-client-scaffold/pull/6)

Shipped the Core UI Foundation (28 widget atoms + ScaffoldMotion across 4
dependency-layered waves, plus 3 Jinja2-template-generated composites) and the
media/integration widgets (MediaCard, MediaControls, WalletConnectSheet) that
compose them. All widgets are generic, M3-themed, and consume only
`Theme.of(context)` — zero app-specific logic.

**Key accomplishments:**

- 28 generic widget atoms + ScaffoldMotion utility across 4 dependency-ordered waves (Wave 0 foundations → Wave 3 composites)
- 3 template-generated composites (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar) consuming the atoms
- MediaCard, MediaControls (with composable ScaffoldSlider), WalletConnectSheet
- 214/214 widget tests passing; `dart analyze --fatal-infos` clean
- Phase 7 verified 6/6, UAT 7/7, code review 0 critical

**Requirements:** 34/34 complete (3 SUB + 31 WIDG). No orphans.

**Archive:** [v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md) · [v1.1-REQUIREMENTS.md](milestones/v1.1-REQUIREMENTS.md)

---

## v1.0 Scaffold Shared Source — ✅ SHIPPED 2026-08-09

**Phases:** 5 | **Plans:** 5

Established the `frontend_scaffold` submodule as the single shared source for
Genius Network Flutter widgets, M3 theme infrastructure, and Jinja2 codegen
templates; `frontend_scaffold` Dart package at v0.3.0. GeniusWallet toast
redesign ported in (the scaffold is the toast authority).
