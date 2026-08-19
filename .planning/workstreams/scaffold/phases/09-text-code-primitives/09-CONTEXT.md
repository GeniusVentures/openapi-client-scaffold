# Phase 9: Text & Code Primitives - Context

**Gathered:** 2026-08-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship three text-centric generic atoms that close Beautiful UI gaps 3, 17, and 19:

- **ScaffoldStreamingRichText (WIDG-32..34)** — incrementally-updated rich text without rebuilding the full response, inline source/citation markers with expandable source slots, streaming cursor state, response-action slots (copy, retry, rate, follow-up), a11y announcements that do not reread the whole answer per token
- **ScaffoldCodeBlock (WIDG-37, 38)** — syntax-highlighted spans, line numbers, language/filename header, copy action, horizontal scrolling, streamed line insertion, reduced-motion behavior
- **ScaffoldSelectionActions (WIDG-39)** — wraps selectable content, reports `onSelectionChanged(TextSelection, String)`, positions an anchored action toolbar

All three are generic atoms: they know nothing about agents, prompts, sources, or AI domains. Consumers compose them into chat/streaming/code experiences.

</domain>

<decisions>
## Implementation Decisions

### Guiding meta-decision
- **D-01:** Every open behavior in this phase is delivered as **base typed atom + optional DI slots + optional template-generated composite variants + separate support-library parts**. The atoms stay dependency-free and typed; richer/convenience behavior (Markdown parsing, syntax highlighting, streaming controllers, a11y policies) is layered on via consumer-supplied DI, Jinja2 composite templates, or standalone `lib/` support parts — never baked into the base atom.

### Streaming input contract (ScaffoldStreamingRichText)
- **D-02:** Streaming input is flexible — any of `Stream` / `ValueListenable` / consumer-supplied controller (Cubit). Follow the established **optional-consumer-supplied-Cubit-with-internal-fallback** pattern (`ScaffoldCardCubit? cubit` + `_ownsCubit` in `scaffold_card.dart:99`): the atom accepts an optional external controller; when absent it owns an internal one. Base atom consumes the typed span model; a `streaming_rich_text` Jinja2 template emits convenience variants wired for specific input shapes.

### Rich text model (ScaffoldStreamingRichText)
- **D-03:** Base model is **typed spans** — the atom renders a typed span tree and knows nothing about Markdown. **Markdown parsing is a separate support-library part** (markdown→typed-span mapper) plus a template-generated composite variant for consumers who want to feed raw Markdown strings. The atom itself never parses Markdown.

### Code syntax highlighting (ScaffoldCodeBlock)
- **D-04:** Consumer supplies highlighting via **DI**: the atom takes pre-highlighted typed spans (pure slot, D-05 precedent) and/or a consumer-injected `syntaxHighlighter` callback. A **built-in light tokenizer** ships only as a separate support-library part (never a hard atom dependency). The atom renders whatever spans it's given.

### SelectionActions anchor + scope
- **D-05:** Anchoring and scope are **consumer-configurable**. The toolbar positions via an overlay follower at the selection by default; consumers can override placement. The widget wraps arbitrary selectable content (not only the Phase 9 atoms) — it's a generic wrapper taking child + `onSelectionChanged(TextSelection, String)` + a toolbar-builder slot.

### Streaming a11y announcements (WIDG-34)
- **D-06:** Announcement policy is delivered via **template + DI**: the atom exposes an announce-policy hook (consumer-injectable) and template variants encode concrete policies. Default policy must not reread the whole answer per token — debounce/block-boundary announcements via `ScaffoldLiveRegion` (existing atom), exact policy is a template/DI choice.

### Inherited Locked Patterns (Phases 6/7/8 — unchanged, apply to every Phase 9 atom)
- **Theme tokens only:** `context.palette` / `context.dimens` ThemeExtension lookups; no hardcoded colors/dimens.
- **Pure composability:** each atom does one thing; consumers compose; no convenience constructors baking multi-atom layout opinions into atoms.
- **Full a11y:** interactive atoms get `Semantics` with role/label; keyboard focus order + Enter/Space; focus outlines visible; live-region for value/streaming changes.
- **Stateless render + private transient state only:** atoms render from passed-in state; truth lives in the consumer. Private StatefulWidget may hold ONLY transient interaction state.
- **Typed slots, not escape hatches:** optional named parameters accepting typed atoms/callbacks.
- **Consumer-supplied renderers for external content (D-05):** scaffold gains no rendering dependencies.
- **Generated code never committed; Jinja2 `StrictUndefined`; generated-header convention; barrel export from `lib/frontend_scaffold.dart`; tests in `test/components/`; demos in `example/lib/demos/`; `dart analyze --fatal-infos` clean.**

### Support-library parts (demonstrability requirement)
- **D-07:** The example app must be able to *show* the convenience layers working — Markdown rendering, syntax highlighting, streaming input — not just the raw typed atoms. That means the Markdown→span mapper and the syntax tokenizer must ship as **real, runnable support parts** of the scaffold (a Dart part in `lib/`, or a C++ part in the native core if the consumer's stack calls for it), each with its own demo. A DI slot that no shipped part implements is not acceptable — every DI hook in D-02/D-04/D-06 must have at least one concrete support-part implementation demonstrated in the example app.
- **D-08:** The base atoms in `lib/components/` gain **no new pubspec dependencies** (per D-05 no-rendering-dependencies). Support-library parts that need a package (e.g. a Markdown parser) isolate that dependency in the support part, so consumers who only want the typed atoms don't pay for it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & roadmap
- `.planning/workstreams/scaffold/REQUIREMENTS.md` — WIDG-32..34, 37..39 definitions
- `.planning/workstreams/scaffold/ROADMAP.md` §Phase 9 — goal, success criteria (5 must-haves)

### Design seed (user-authored, authoritative for intent)
- `.planning/atoms-v1.2-additions.md` §"The four hard gaps" (ScaffoldStreamingRichText, ScaffoldCodeBlock, ScaffoldSelectionActions) and §architecture note (streaming input via Stream/ValueListenable/consumer Cubit; atoms know nothing about agents)

### Prior-phase decisions (carry forward)
- `.planning/workstreams/scaffold/phases/08-supporting-atoms-table-cells-light-palette/08-CONTEXT.md` — inherited locked patterns, D-05 consumer-renderer precedent, D-07 consumer-owns-logic

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scaffold_live_region.dart` — a11y live-region announcements; the vehicle for D-06 streaming-announcement policies
- `scaffold_motion.dart` — `ScaffoldMotion.of(context).reducedMotion`; code block + streaming cursor must respect it (WIDG-38)
- `scaffold_overflow_fade.dart` — horizontal-scroll fade for code block overflow (WIDG-38)
- `scaffold_selectable_surface.dart` — existing selection surface; reference for ScaffoldSelectionActions wrap behavior
- `scaffold_surface.dart`, `scaffold_pressable.dart`, `scaffold_badge.dart`, `scaffold_status_indicator.dart` — composition inputs for headers, action rows, citation/source slots

### Established Patterns
- **Optional-consumer-Cubit + internal fallback** (`scaffold_card.dart:99`, `_ownsCubit`): the concrete DI pattern for D-02 streaming controller
- **Builder/callback slots** (`qrBuilder` in `wallet_connect_sheet.dart:46`): the concrete DI pattern for D-04 syntax highlighter and D-05 toolbar builder
- **Jinja2 composite templates** (`templates/components/card.*`, `search_bar.*`, `state_view.*`): the vehicle for D-02/D-03/D-06 convenience variants (Markdown-parsing streaming text, announce-policy variants)
- **Widget/Cubit/State file triple** (`scaffold_card.dart` + `_cubit.dart` + `_state.dart`): the shape of any stateful composite this phase generates

### Integration Points
- `lib/frontend_scaffold.dart` — barrel export for the three atoms + any support-library parts
- `example/lib/main.dart` + `example/lib/demos/` — demo registration for each atom
- `templates/components/` — new `streaming_rich_text` / `code_block` / `selection_actions` template families if template variants are generated

</code_context>

<specifics>
## Specific Ideas

- User directive: every flexible behavior in this phase can be delivered as "any of them" — built into the atom, via template, or via DI — and support libraries (e.g. Markdown, syntax tokenizer) live as separate scaffold parts so consumers pick their option.
- Base models stay typed (typed spans); Markdown and highlighting are layered, never baked in.

</specifics>

<deferred>
## Deferred Ideas

- Built-in multi-language syntax tokenizer as a first-party part (beyond the DI hook) — only if a concrete consumer needs it; the DI hook + separate support part is the Phase 9 contract
- HTML template parity for the three new atoms — reserved for a future version (Flutter only for v1.2, per PROJECT.md)

</deferred>

---

*Phase: 9-text-code-primitives*
*Context gathered: 2026-08-19*
