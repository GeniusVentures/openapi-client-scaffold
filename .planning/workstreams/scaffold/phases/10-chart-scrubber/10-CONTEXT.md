# Phase 10: Chart & Scrubber - Context

**Gathered:** 2026-08-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship two chart atoms that close the Insight Cards gap:

- **ScaffoldChart (WIDG-35)** — neutral series chart rendering any consumer-supplied data via `series`, `xAccessor`, `yAccessor` — no domain knowledge in the widget
- **ScaffoldChartScrubber (WIDG-36)** — point selection/scrubbing composing with ScaffoldChart, exposing `selectedPoint` and firing `onPointSelected` on tap/drag

Both atoms are generic: they know nothing about prices, wallets, media, or any business domain. Consumers compose them into insight cards, dashboards, or any data-visualization surface.

</domain>

<decisions>
## Implementation Decisions

### Chart engine (gray area 1 — resolved from GeniusWallet evidence)

- **D-01:** Chart rendering uses **fl_chart 1.2.0**, matching GeniusWallet's `pubspec.yaml:36` (`fl_chart: ^1.2.0`, resolved `1.2.0`). This is the only chart package in the workspace; per the user's rule ("if a chart package, then we use that"), it is the engine.

- **D-02:** fl_chart is isolated in a **`lib/utils/` support part** (precedent: `markdown_to_spans.dart`, `light_syntax_tokenizer.dart` — D-08 pattern). The base atoms in `lib/components/` gain **no new pubspec dependencies**. The support part wraps fl_chart's `LineChart`/`LineChartData` API into a scaffold-neutral interface. Consumers who only want the typed atoms don't pay for fl_chart.

### Chart data contract (gray area 2 — resolved from GeniusWallet evidence)

- **D-03:** `ScaffoldChart` exposes the seed contract from `atoms-v1.2-additions.md`:
  ```dart
  ScaffoldChart({
    required List<T> series,
    required double Function(T) xAccessor,
    required double Function(T) yAccessor,
    T? selectedPoint,
    ValueChanged<T>? onPointSelected,
  })
  ```
  The atom maps `series` → `List<FlSpot>` internally via the accessors. No domain types cross the boundary.

- **D-04:** Chart geometry helpers are **pure, top-level functions** in a `lib/utils/chart_geometry.dart` support part — ported from GeniusWallet's `chart_axis.dart` pattern. Functions include:
  - `chartYBounds(List<FlSpot> data, {double? viewMinX, double? viewMaxX})` — visible-window Y range with 8% padding
  - `chartTickStep(double lo, double hi, int want)` — nice-number tick ladder (1, 1.5, 2, 2.5, 3, 4, 5, 10 multipliers)
  - `axisLabel(double value, double step)` — precision derived from step, not magnitude
  - `chartXLabelCount({required double plotWidth, required int sampleCount})` — clamped label count
  - `chartBandedBounds(...)` — axis-free small-chart label bands

### Scrub behavior (gray area 3 — resolved from GeniusWallet evidence)

- **D-05:** `ScaffoldChartScrubber` composes with `ScaffoldChart` via shared geometry, mirroring GeniusWallet's `LineTouchData` pattern:
  - `touchCallback: (FlTouchEvent, LineTouchResponse?)` → extract `lineBarSpots!.first` → map back to consumer type `T` via index → `onPointSelected?.call(point)`
  - Touch indicator: `FlDotCirclePainter(radius: 5, strokeWidth: 4)` with theme-token color
  - **No floating tooltip** — `LineTouchTooltipData` suppressed (`getTooltipItems: → null`, transparent). The consumer renders the readout externally (as GeniusWallet does with its header row).
  - `PointerExitEvent` clears selection (hover-exit pattern from GeniusWallet `_onHoverExit`)

- **D-06:** X-axis labels are a **plain `Row` of `Text` widgets**, never fl_chart `bottomTitles` — GeniusWallet explicitly rejects fl_chart's x-axis anchoring ("anchors to `baselineX`, cannot be made to line up"). Y-axis on large charts uses fl_chart `rightTitles` with the nice-number ladder; small charts use the axis-free banded-bounds scheme.

### Grid & chrome (gray area 4 — resolved from GeniusWallet evidence)

- **D-07:** Grid shown on large charts only (`FlGridData` with theme-token colors); sparkline/compact charts hide grid (`FlGridData(show: false)`). Border always hidden (`FlBorderData(show: false)`). All colors from `ScaffoldPalette` tokens — no new tokens needed; existing `borderControl`/`textSecondary` equivalents cover chart chrome.

### Inherited Locked Patterns (Phases 6–9 — unchanged, apply to every Phase 10 atom)

- **Theme tokens only:** `context.palette` / `context.dimens` ThemeExtension lookups; no hardcoded colors/dimens.
- **Pure composability:** each atom does one thing; consumers compose; no convenience constructors baking multi-atom layout opinions into atoms.
- **Full a11y:** interactive atoms get `Semantics` with role/label; keyboard focus order + Enter/Space; focus outlines visible; live-region for value changes.
- **Stateless render + private transient state only:** atoms render from passed-in state; truth lives in the consumer. Private StatefulWidget may hold ONLY transient interaction state (hover position).
- **Typed slots, not escape hatches:** optional named parameters accepting typed atoms/callbacks.
- **Consumer-supplied renderers for external content (D-05):** scaffold gains no rendering dependencies in base atoms.
- **Generated code never committed; Jinja2 `StrictUndefined`; generated-header convention; barrel export from `lib/frontend_scaffold.dart`; tests in `test/components/`; demos in `example/lib/demos/`; `dart analyze --fatal-infos` clean.**

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & roadmap
- `.planning/workstreams/scaffold/REQUIREMENTS.md` — WIDG-35, WIDG-36 definitions
- `.planning/workstreams/scaffold/ROADMAP.md` §Phase 10 — goal, success criteria (3 must-haves)

### Design seed (user-authored, authoritative for intent)
- `.planning/atoms-v1.2-additions.md` §"The four hard gaps" — ScaffoldChart/ScaffoldChartScrubber seed contract, Insight Cards gap

### GeniusWallet chart implementation (evidence for D-01..D-07)
- `GeniusNetwork/GeniusWallet/pubspec.yaml:36` — `fl_chart: ^1.2.0`
- `GeniusNetwork/GeniusWallet/lib/chart/crypto_live_chart.dart` — full LineChart + LineTouchData + touch indicator + axis config
- `GeniusNetwork/GeniusWallet/lib/chart/crypto_simple_chart.dart` — sparkline (axis-free) variant
- `GeniusNetwork/GeniusWallet/lib/chart/chart_axis.dart` — pure geometry functions (chartYBounds, chartTickStep, axisMoneyLabel, chartXLabelCount, chartBandedBounds, visibleExtremes)

### Prior-phase decisions (carry forward)
- `.planning/workstreams/scaffold/phases/09-text-code-primitives/09-CONTEXT.md` — D-08 support-part isolation pattern, D-05 consumer-renderer precedent, inherited locked patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scaffold_surface.dart` — chart card container
- `scaffold_motion.dart` — `ScaffoldMotion.of(context).reducedMotion`; chart animations must respect it
- `scaffold_pressable.dart` — touch target compliance for chart interaction area
- `scaffold_live_region.dart` — a11y announcements for scrub value changes

### Established Patterns
- **Support-part isolation** (`lib/utils/markdown_to_spans.dart`, `lib/utils/light_syntax_tokenizer.dart`): the concrete pattern for D-02 fl_chart isolation
- **Optional-consumer-Cubit + internal fallback** (`scaffold_card.dart:99`): pattern if chart needs a Cubit for animation state
- **Builder/callback slots** (`qrBuilder` in `wallet_connect_sheet.dart:46`): pattern for custom chart renderers

### Integration Points
- `lib/frontend_scaffold.dart` — barrel export for `ScaffoldChart` + `ScaffoldChartScrubber` + geometry utils
- `example/lib/demos/` — chart demo showing series + scrubbing
- `pubspec.yaml` — fl_chart added as dependency (isolated to support part, not base atoms)

</code_context>

<specifics>
## Specific Ideas

- User directive: "could use dart package, we should see what ../../GeniusWallet does for the charts, if a chart package, then we use that else probably a Custom paint" — fl_chart confirmed as the chart package.
- GeniusWallet's chart_axis.dart is a proven, tested pattern for pure geometry functions — port the logic, not the SVG, and keep functions top-level and pure for testability.
- X-axis as plain Row of Texts is deliberate — fl_chart's baselineX anchoring cannot express epoch-second sample positions.

</specifics>

<deferred>
## Deferred Ideas

- Bar/pie/scatter chart types — only LineChart is needed for v1.2 Insight Cards; other types can be added to the support part when a concrete consumer needs them
- HTML template parity for chart atoms — reserved for a future version (Flutter only for v1.2, per PROJECT.md)
- Built-in chart animations (enter/exit transitions) — reduced-motion behavior is required, but rich enter animations are a consumer concern

</deferred>

---

*Phase: 10-chart-scrubber*
*Context gathered: 2026-08-21*
