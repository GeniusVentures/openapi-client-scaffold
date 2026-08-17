# Phase 8: Supporting Atoms, Table Cells & Light Palette - Context

**Gathered:** 2026-08-17
**Status:** Ready for planning
**Source:** Extended from Phase 6/7 CONTEXT.md (owner direction: "context can be gleaned from phase 7, as this is an extension of atoms from that") + approved 08-UI-SPEC.md

<domain>
## Phase Boundary

Ship five low-dependency workstreams into the `frontend_scaffold` package:

- **ScaffoldChip / ScaffoldChipGroup (WIDG-40)** — pressable token atom (icon/text + optional status indicator); group layout + selection management
- **ScaffoldDisclosure / ScaffoldTraceList (WIDG-41)** — generic expand/collapse row; ordered trace of disclosure items
- **ScaffoldComposer (WIDG-42)** — text-entry composition area with action button slots and badge/attachment slots
- **DataColumnConfig&lt;T&gt; cellBuilder (WIDG-43)** — template extension to `data_table.dart.jinja2`: custom per-cell rendering without forking the table
- **Light default palette (WIDG-46)** — verify + complete light-palette coverage so every scaffold widget renders correctly under `ThemeData.light()` with no consumer overrides; includes the REQUIRED `ScaffoldBadge` hardcoded-`Colors.white` remediation (lines 105, 140 → palette-resolved on-status color, WCAG AA 4.5:1)

All atoms are generic, M3-themed, domain-agnostic (no agents/prompts/sources knowledge), consuming only `Theme.of(context)` + previously-shipped atoms. The visual/interaction contract is locked in `08-UI-SPEC.md` (approved, 6/6 dimensions).

</domain>

<decisions>
## Implementation Decisions

### Guiding Principle
- **D-00 (inherited, locked):** `frontend_scaffold` is a shareable generic widget library; consuming apps compose specialty widgets from scaffold atoms. Scaffold owns typed, generic contracts; app-specific rendering, state, and dependencies are pushed to consumers. (Phase 7 D-00, restated — unchanged.)

### Inherited Locked Patterns (Phase 6/7 — unchanged, apply to every Phase 8 atom)
- **Theme tokens only:** `context.palette` / `context.dimens` `ThemeExtension` lookups; no hardcoded colors/dimens (Phase 6 D-03; UI-SPEC enforces for light palette).
- **Pure composability:** each atom does one thing; consumers compose; no convenience constructors baking multi-atom layout opinions into atoms (Phase 6 D-04).
- **Full a11y:** interactive atoms get `Semantics` with role/label; keyboard focus order + Enter/Space; focus outlines visible in all states; live-region for value changes (Phase 6 D-02).
- **Stateless render + private transient state only:** atoms render from passed-in state; playback/selection truth lives in the consumer. Private `StatefulWidget` may hold ONLY transient interaction state (Phase 7 D-03 pattern).
- **Typed slots, not escape hatches:** optional named parameters accepting typed atoms (Phase 7 D-01); caller-supplied child lists laid out with theme spacing/overflow handled by the scaffold (Phase 7 D-02).
- **Consumer-supplied renderers for external content:** scaffold gains no rendering dependencies (Phase 7 D-05 qrBuilder precedent).
- **Generated code never committed; Jinja2 `StrictUndefined`; generated-header convention** (source schema + generator version; CI regenerates + diffs).
- **Barrel export from `lib/frontend_scaffold.dart`; tests in `test/components/`; demos in `example/lib/demos/`; `dart analyze --fatal-infos` clean.**

### ScaffoldChip / ScaffoldChipGroup (WIDG-40)
- **D-01 (UI-SPEC locked):** Chip = pill-radius surface + `ScaffoldPressable` + `ScaffoldTouchTarget` (48px min height from touch target, NOT padding arithmetic). Default internal padding `EdgeInsets.symmetric(horizontal: dimens.space4, vertical: dimens.space4)` (8h × 8v). Selected state = accent **border**, not fill (60/30/10 contract). `space3` (6px) only for the rare icon+status-dot internal glyph gap.
- **D-02:** ChipGroup selection is consumer-owned: `ScaffoldChipGroup` takes `selected: Set<T>` (or index set) + `onSelectionChanged` callback; single-select vs multi-select is a group-level mode parameter. No internal selection truth (Phase 7 D-03 pattern applied to selection).
- **D-03:** Icon-only chips REQUIRE `semanticLabel` (a11y contract from UI-SPEC).

### ScaffoldDisclosure / ScaffoldTraceList (WIDG-41)
- **D-04 (UI-SPEC locked):** Disclosure = header row (chevron + title slot + optional status/badge slot) + `AnimatedSize` body, medium duration, respects `ScaffoldMotion.of(context).reducedMotion`. Body indent 12px left, 8px top. Chevron rotates on expand; accent color when expanded-and-active.
- **D-05:** Expanded state is consumer-owned (`expanded: bool` + `onExpandedChanged`) with an optional `initiallyExpanded` convenience for uncontrolled use — matching Flutter's controlled/uncontrolled idiom. `ScaffoldTraceList` renders an ordered `List` of disclosure items from a typed model (icon/status slot + title + body), one-way data in; no trace-domain knowledge.

### ScaffoldComposer (WIDG-42)
- **D-06 (UI-SPEC locked):** Composer = `ScaffoldSurface` + 3 named rows: badge/attachment row (optional slot), text-entry row (uses existing `TextEntryFieldWidget`), action row (button slots). 8px vertical gap between rows. Focus ring on text field from palette `focusRingColor`. Armed-action tint (accent) only on the primary send/action slot when enabled.
- **D-07:** Composer holds NO submission logic — `onSubmit(String)` callback out; attachments/badges are typed slots rendered by the scaffold, supplied by the consumer (Phase 7 D-05 precedent: no new dependencies).

### DataColumnConfig&lt;T&gt; cellBuilder (WIDG-43)
- **D-08 (UI-SPEC locked):** Add `cellBuilder: Widget Function(BuildContext context, T item)?` to `DataColumnConfig` in `data_table.dart.jinja2`. Null → existing string-`Text` cell path (unchanged, backward compatible). Custom builders MUST NOT add outer padding (inherit `DataCell` default 16h × 8v) and SHOULD use `bodyMedium` for visual alignment with string cells. Sort behavior is driven by `accessor` regardless of `cellBuilder` presence. `labelLarge` w600 column headers stay locked to the existing template (NOT reused by any new Phase 8 widget).
- **D-09:** Template + vars fixture updated together (`data_table_vars.json` gains a cellBuilder-exercising example column if the fixture format allows; otherwise the generated-output contract is verified in the widget test). Generated code is never committed — CI regenerate + diff remains the guard.

### Light Default Palette (WIDG-46)
- **D-10 (UI-SPEC locked):** `lightPalette` already exists in `scaffold_palette.dart` — Phase 8 VERIFIES every widget consumes palette tokens (no hardcoded colors) and COMPLETES coverage where gaps exist. The known required remediation: `ScaffoldBadge` label/icon color hardcoded `Colors.white` (lines 105, 140) → palette-resolved on-status color (dark text on bright fills like `lightGreenPrimary`/`statusSuccess`/`statusWarningText`; light text on dark fills like `statusError`/`blue500`), resolution logic inside `ScaffoldBadge`, WCAG AA 4.5:1 across every `BadgeVariant` × status fill × both palettes.
- **D-11:** Light-palette verification is per-widget under `ThemeData.light()` in widget tests (no golden-file infra in repo — Phase 7 IN-06 deferral stands).

### Claude's Discretion
- Internal layout details of chip/disclosure/composer beyond the UI-SPEC contract (icon choice, row ordering within slots) — follow M3 idioms and existing atom patterns.
- Exact on-status color resolution mechanism inside `ScaffoldBadge` (luminance check vs explicit token) — pick the simplest approach meeting WCAG AA.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 8 Artifacts
- `.planning/workstreams/scaffold/phases/08-supporting-atoms-table-cells-light-palette/08-UI-SPEC.md` — **approved design contract (6/6); spacing, color, typography, widget contracts are locked here**
- `.planning/workstreams/scaffold/ROADMAP.md` — Phase 8 goal, success criteria 1-5
- `.planning/workstreams/scaffold/REQUIREMENTS.md` — WIDG-40, 41, 42, 43, 46 requirement text
- `.planning/atoms-v1.2-additions.md` — seed analysis; DataColumnConfig signature sketch; owner scope notes (atoms domain-agnostic; HTML parity deferred-not-deprecated; AI composites live in the AI chat app)

### Prior Phase Decisions (locked patterns to reuse)
- `.planning/workstreams/scaffold/phases/06-core-ui-foundation/06-CONTEXT.md` — D-01 ScaffoldMotion, D-02 full a11y, D-03 token expansion, D-04 pure composability
- `.planning/workstreams/scaffold/phases/07-media-integration-widgets/07-CONTEXT.md` — D-00 guiding principle, D-01 typed slots, D-02 caller-supplied children, D-03 stateless+transient, D-05 consumer-supplied renderers, D-06 widget-only template pattern
- `.planning/workstreams/scaffold/phases/07-media-integration-widgets/07-PATTERNS.md` — analog files + code excerpts for Phase 7 widgets

### Existing Code (read before writing any widget)
- `lib/frontend_scaffold.dart` — barrel export pattern
- `lib/theme/scaffold_palette.dart` — `defaultPalette` (dark) + `lightPalette`; all token names
- `lib/theme/scaffold_dimens.dart` — space2/3/4/6/8/12 = 4/6/8/12/16/24, radiusPill, minTouchTarget=48
- `lib/theme/scaffold_theme.dart` — `context.palette` / `context.dimens` extensions
- `lib/components/scaffold_pressable.dart` — hover/press/focus/disabled wrapper (chip + composer actions)
- `lib/components/scaffold_touch_target.dart` — 48×48 hit-area enforcement (chip min height)
- `lib/components/scaffold_surface.dart` — surface treatment (chip pill, composer container)
- `lib/components/scaffold_badge.dart` — badge atom (chip status dot, composer badges); **lines 105, 140 hardcode `Colors.white` — WIDG-46 remediation target**
- `lib/components/scaffold_status_indicator.dart` — status dot (chip status, trace item status)
- `lib/components/scaffold_motion.dart` — durations/curves + reduced-motion (disclosure AnimatedSize)
- `lib/components/text_entry_field_widget.dart` — existing text entry (composer text row)
- `templates/components/data_table.dart.jinja2` — table template; `DataColumnConfig` (label/accessor/sortable); **line 245: `labelLarge` w600 headers (locked)**; cell render path to extend
- `templates/components/data_table_vars.json` — fixture schema

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **ScaffoldSurface + radiusPill** — chip pill shape, composer container
- **ScaffoldPressable + ScaffoldTouchTarget** — chip interaction + 48px min height; composer action buttons
- **ScaffoldBadge / ScaffoldStatusIndicator** — chip status dot, trace item status, composer badge slots
- **ScaffoldMotion** — disclosure expand/collapse animation respecting reduced-motion
- **TextEntryFieldWidget** — composer text row (existing, themed)
- **lightPalette** — already seeded; Phase 8 verifies/completes rather than creates

### Established Patterns
- Controlled/uncontrolled state idiom: consumer-owned state + callbacks; private transient state only
- Typed named slots over generic builders/maps
- Barrel export + test + demo per widget (v1.1 shipping bar)
- Template change = template + vars fixture together; generated code never committed
- `dart analyze --fatal-infos` + `flutter test` gates green

### Integration Points
- New atoms in `lib/components/`: `scaffold_chip.dart`, `scaffold_chip_group.dart`, `scaffold_disclosure.dart`, `scaffold_trace_list.dart`, `scaffold_composer.dart`
- Modified: `templates/components/data_table.dart.jinja2` (+ vars), `lib/components/scaffold_badge.dart` (on-status color), possibly `lib/theme/scaffold_palette.dart` (gap completion only)
- Barrel exports in `lib/frontend_scaffold.dart`
- Tests in `test/components/`; demos in `example/lib/demos/` registered in `example/lib/main.dart`

</code_context>

<specifics>
## Specific Ideas

- Beautiful UI consumers of Phase 8 atoms (per seed): Tool Chips, Filter Table → chip/group; Thinking traces → disclosure/trace list; Chat, Prompt Bar → composer; Diff/Records/Filter Tables → cellBuilder.
- `DataColumnConfig<T>` sketch from seed: `label`, `value: Object? Function(T item)`, `cellBuilder: Widget Function(BuildContext, T item)?`, `sortable = true` — the planner should reconcile the seed's `value` accessor with the existing template's `accessor` field (existing template wins for compatibility; `cellBuilder` is the additive change).

</specifics>

<deferred>
## Deferred Ideas

- Golden-file test infrastructure for visual regression (Phase 7 IN-06 deferral stands — no golden infra in repo).
- HTML template parity for the new atoms (HTML-01, future milestone — deferred, not deprecated).
- DataTable virtualization for large datasets (seed note, not a v1.2 requirement).

</deferred>

---

*Phase: 8-Supporting Atoms, Table Cells & Light Palette*
*Context gathered: 2026-08-17*
