# Phase 10 Discussion Log

**Date:** 2026-08-21
**Phase:** 10 — Chart & Scrubber
**Workstream:** scaffold
**Mode:** discuss

## Participants
- User (owner)
- GSD discuss-phase orchestrator

## Gray Areas Presented

### Gray Area 1: Chart engine — CustomPainter vs package
**Question:** Should the chart be a hand-rolled `CustomPainter` (zero deps, full control) or use a chart package?

**User answer:** "could use dart package, we should see what ../../GeniusWallet does for the charts, if a chart package, then we use that else probably a Custom paint"

**Investigation:**
- GeniusWallet `pubspec.yaml:36` — `fl_chart: ^1.2.0` (resolved `1.2.0`)
- 5 files in `GeniusWallet/lib/chart/` and `lib/dashboard/chart/` import fl_chart
- All charts are `LineChart` — no bar/pie/scatter in the codebase
- `chart_axis.dart` is a pure-function geometry library ported from a sketch's SVG logic

**Resolution:** fl_chart 1.2.0, isolated in `lib/utils/` support part (D-08 pattern). Base atoms stay dependency-free.

---

### Gray Area 2: Chart data contract shape
**Question:** Should `ScaffoldChart` take a generic `List<T>` with accessors, or a pre-baked chart-data struct?

**User answer:** "again look at the GeniusWallet project to decide what this will do"

**Investigation:**
- GeniusWallet's `CryptoLiveChart` takes `List<FlSpot>` directly (pre-baked)
- The seed contract in `atoms-v1.2-additions.md` specifies `series`, `xAccessor`, `yAccessor` — generic with accessors
- Pure geometry functions in `chart_axis.dart` operate on `List<FlSpot>`

**Resolution:** Generic `List<T>` with `xAccessor`/`yAccessor` per the seed contract. The atom maps to `List<FlSpot>` internally. This keeps the atom domain-neutral while the support part handles the fl_chart mapping.

---

### Gray Area 3: Scrub interaction model
**Question:** How does `ScaffoldChartScrubber` interact with the chart — gesture overlay, shared controller, or composed widget?

**User answer:** "again here too"

**Investigation:**
- GeniusWallet uses `LineTouchData.touchCallback` → `LineTouchResponse.lineBarSpots!.first` → `setState({_hoveredPrice, _hoveredX})`
- Touch indicator: `FlDotCirclePainter(radius: 5, strokeWidth: 4)` with `borderControl` color
- Tooltip suppressed — external header row shows the readout
- `PointerExitEvent` clears hover state

**Resolution:** Mirror GeniusWallet's pattern. `ScaffoldChartScrubber` composes with `ScaffoldChart` via shared geometry. Touch callback extracts nearest spot, maps back to consumer type `T`, fires `onPointSelected`. No floating tooltip; consumer renders readout externally.

---

### Gray Area 4: Axis/grid chrome
**Question:** How much axis/grid chrome should the base atom provide?

**Investigation (from GeniusWallet evidence):**
- Large chart: fl_chart `rightTitles` with nice-number ladder, `FlGridData` with theme colors
- Small chart (sparkline): `FlGridData(show: false)`, `FlTitlesData(show: false)`, axis-free
- X-axis: plain `Row` of `Text` widgets — **never** fl_chart `bottomTitles` ("anchors to `baselineX`, cannot be made to line up")
- Border: always `FlBorderData(show: false)`

**Resolution:** D-06/D-07 — X-axis as plain Row of Texts, Y-axis via fl_chart rightTitles on large charts, axis-free banded-bounds on small charts. Grid on large only, border always hidden. All colors from theme tokens.

---

## Decisions Recorded

| ID | Decision | Evidence |
|----|----------|----------|
| D-01 | fl_chart 1.2.0 as chart engine | GeniusWallet pubspec.yaml:36 |
| D-02 | fl_chart isolated in `lib/utils/` support part | D-08 precedent (markdown, tokenizer) |
| D-03 | Generic `List<T>` + accessors contract | atoms-v1.2-additions.md seed |
| D-04 | Pure geometry functions in `lib/utils/chart_geometry.dart` | GeniusWallet chart_axis.dart |
| D-05 | Scrub via LineTouchData touchCallback, no tooltip | GeniusWallet crypto_live_chart.dart:787-825 |
| D-06 | X-axis as plain Row of Texts, never fl_chart bottomTitles | GeniusWallet crypto_live_chart.dart:831-863 |
| D-07 | Grid on large only, border hidden, theme tokens only | GeniusWallet crypto_live_chart.dart:732-747 |

## Notes

- All 4 gray areas resolved from a single investigation of GeniusWallet's chart implementation
- GeniusWallet's chart code is production-tested (live price charts + sparklines) and carries detailed comments explaining *why* each choice was made — the reasoning ports directly
- The pure-function geometry pattern (`chart_axis.dart`) is the most valuable port: it makes chart math testable without rendering
