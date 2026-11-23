# Requirements: Frontend Scaffold — v1.3 POS-General Interaction Primitives

**Defined:** 2026-10-01
**Core Value:** `frontend_scaffold` (openapi-client-scaffold) is the single shared source for Genius Network Flutter widgets, M3 theme infrastructure, and Jinja2 codegen templates — generic, M3-themed, zero app-specific business logic, consumable by any repo via pinned submodule

**Milestone goal:** Extend the pinned scaffold inventory (28 atoms + composites) with the POS-general interaction primitives the touch-pos operating surface consumes — surfaces/capture, input, selection/navigation, data-display, and status primitives — so touch-pos builds on the scaffold rather than growing a second design system. Gated by the SCF-POS-18 per-primitive test/demo/a11y bar.

**Provenance:** SCF-POS-01..18 routed to this submodule's own planning as the genius-ai-boss fulfillment+commercial-POS ingest follow-through (2026-10-01) — 18 of 302 ingested IDs; parent-repo source of record `.planning/intel/requirements.md` §B1 and `.planning/intel/MERGE-PLAN.md` §1.7; underlying doc `docs/commercial-pos-full-surface-roadmap-ingest.md` §1.2 (commercial-POS verbatim-ID traceability, §8.6).

**Decisions to ratify at discuss-phase:** DEC-TOA-02, DEC-TOA-03 (parent-repo ingest decisions, currently proposed).
**Sequencing:** independent — may start immediately (CN-15 #1).

## v1.3 Requirements

### Surfaces & Capture

- [ ] **SCF-POS-01** — Standard modal/dialog shell (title/subtitle, responsive width, scrollable body, primary/secondary/destructive actions, loading/disabled states, escape/back, focus trap/restoration, screen-reader labelling). source: §1.2
- [ ] **SCF-POS-04** — Signature capture (pointer/touch/stylus, clear/retry, accept/cancel, empty-state validation, caller-provided persistence seam, no POS payment logic). source: §1.2

### Input

- [ ] **SCF-POS-02** — Touch keypad (numeric/decimal/currency-minor-units/PIN-masked, clear/backspace, quick values, keyboard parity, 48px+ targets, spoken values). source: §1.2
- [ ] **SCF-POS-03** — Money input (currency-aware display, exact minor-unit state, keypad + keyboard entry, min/max, optional negatives, presets, validation/error slot). source: §1.2
- [ ] **SCF-POS-08** — Stepper (increment/decrement, direct input, min/max, disabled, unit label; guest count, qty, plating split, stock counts). source: §1.2

### Selection & Navigation

- [ ] **SCF-POS-05** — Select/autocomplete/multi-select family (search/typeahead, single+multi, grouped sections, disabled choices, keyboard/a11y, large targets). source: §1.2
- [ ] **SCF-POS-06** — Date/time/date-range picker (scheduled orders, menu schedules, discount availability, report filters, publishing schedules, shift edits). source: §1.2
- [ ] **SCF-POS-07** — Tabs/segmented switch (scrollable tabs + compact segmented; check tabs, Orders Hub tabs, config panes). source: §1.2
- [ ] **SCF-POS-09** — Reason picker (predefined reasons, required/optional, "Other" free text, optional manager-approval slot, returns typed ID+label+note; no hardcoded void/refund semantics in scaffold). source: §1.2
- [ ] **SCF-POS-15** — Navigation promotion (permission-filtered sections, nested destinations, tablet drawer/wide rail, location context, active route state, notification/status slots). source: §1.2

### Data Display & Listing

- [ ] **SCF-POS-10** — Query/filter bar (chips, search, date/time range, owner/server, status, source/channel, clear-all, saved/default filters). source: §1.2
- [ ] **SCF-POS-11** — Pagination/cursor list controller (cursor paging, refresh, next page, end state, retry, selection/scroll preservation). source: §1.2
- [ ] **SCF-POS-12** — Hierarchy/tree editor primitives (expandable rows, drag/reorder, move between parents, shared/reference + inherited/overridden indicator slots, bulk selection). source: §1.2
- [ ] **SCF-POS-13** — Data table promotion (sortable columns, custom cell builder, row selection, responsive h-scroll, empty/loading/error, pagination integration, export action slot). source: §1.2
- [ ] **SCF-POS-14** — Form dialog promotion (generated/runtime fields, validation, dirty state, save/cancel, destructive secondary actions, responsive layout, nested sections). source: §1.2
- [ ] **SCF-POS-17** — Master/detail responsive layout (split view wide, push narrow, preserved selection, resizable divider, action/header slots). source: §1.2

### Status

- [ ] **SCF-POS-16** — Connectivity/sync status primitive (online, internet unavailable, cloud unavailable, local-only, syncing, queued changes, conflicts) — visual/status only; touch-pos owns offline business behavior. source: §1.2

### Verification gate

- [ ] **SCF-POS-18** — Test/demo/a11y gate for EVERY new scaffold primitive: widget tests, keyboard interaction, a11y semantics, light/dark demos, 48px target checks, no app-specific strings/APIs/business models. source: §1.2

## Out of Scope

Explicitly excluded from v1.3. Documented to prevent scope creep.

| Feature | Reason |
|---|---|
| Offline business behavior (queue policy, retry semantics, sync reconciliation) | Consumer-owned — touch-pos/backend decide policy; SCF-POS-16 is visual/status only |
| POS payment semantics in primitives (void/refund/comp logic) | SCF-POS-09 returns typed reason IDs; business meaning stays in consumers |
| A second design system inside touch-pos | Constraint from the ingest routing — extend the pinned scaffold inventory instead |
| App-specific strings, APIs, or business models in any primitive | SCF-POS-18 gate; scaffold stays neutral/generic |
| Parent-repo build orchestration for new primitives | Consuming-repo scope (genius-ai-boss `frontend-templates` v3.0 Phase 10 owns generator/CMake integration) |
