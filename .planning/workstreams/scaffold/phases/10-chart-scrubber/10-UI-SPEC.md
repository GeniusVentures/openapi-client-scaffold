---
phase: 10
slug: chart-scrubber
status: draft
shadcn_initialized: false
preset: none
created: 2026-08-21
---

# Phase 10 — Chart & Scrubber UI Design Contract

> Visual and interaction contract for the frontend_scaffold widget LIBRARY.
> The "users" of this contract are composing developers; the design surface
> is the widget API + rendered output + the example/ demos.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Flutter package — Material 3 primitives, no shadcn) |
| Preset | not applicable |
| Component library | Material 3 (flutter/material.dart) + existing `frontend_scaffold` atoms |
| Icon library | `material.icons` (built-in `Icons.*`) — no third-party icon set |
| Font | Inherited from host `ThemeData.textTheme` — atoms do NOT wrap fonts. Axis labels and data readouts use `fontFeatures: [FontFeature.tabularFigures()]` for numeric alignment. |

**Source of truth (existing, do NOT redefine):**
- `lib/theme/scaffold_colors.dart` — raw color constants (dark-seeded brand)
- `lib/theme/scaffold_palette.dart` — `ScaffoldPalette` ThemeExtension (dark `defaultPalette` + `lightPalette`)
- `lib/theme/scaffold_dimens.dart` — `ScaffoldDimens` ThemeExtension (spacing/radius/touch targets)
- `lib/theme/scaffold_theme.dart` — `ScaffoldThemeX` lookup extension

**Composition inputs already shipped (v1.1 + v1.2 Phases 8–9):**
- `ScaffoldSurface`, `ScaffoldPressable`, `ScaffoldTouchTarget`, `ScaffoldFocusOutline`, `ScaffoldDisabledOverlay`
- `ScaffoldBadge`, `ScaffoldStatusIndicator`, `ScaffoldMotion`, `ScaffoldOverflowFade`, `ScaffoldLiveRegion`
- `ScaffoldChip`, `ScaffoldChipGroup`, `ScaffoldDisclosure`, `ScaffoldTraceList`, `ScaffoldComposer`

**Phase 10 deliverables (new):**
- `ScaffoldChart` (WIDG-35)
- `ScaffoldChartScrubber` (WIDG-36)

**Chart engine (D-01, D-02):**
- `fl_chart: ^1.2.0` — isolated in `lib/utils/` support part. Base atoms in `lib/components/` gain NO new pubspec dependencies.

---

## Spacing Scale

Reuse the existing `ScaffoldDimens` scale (2px base step, named by step index).
**Do NOT introduce new spacing tokens.** Phase 10 widgets consume only the existing steps.

| Token | Value | Phase 10 Usage |
|-------|-------|----------------|
| `space2` | 4px | Gap between axis label glyphs and axis line; scrubber dot↔label gap |
| `space4` | 8px | Vertical gap between chart plot area and X-axis label row; internal padding of axis label texts |
| `space6` | 12px | Left/right inset of chart body inside its outer surface; gutter between Y-axis labels and plot area |
| `space8` | 16px | Outer padding of chart surface; vertical rhythm between chart and external readout row |
| `space12` | 24px | Minimum touch-target expansion around the scrub interaction area (beyond the visual plot bounds) |

**Chart-specific constants (not spacing tokens — geometry values):**
- Y-axis gutter width: 62px (right-side label reservation, from GeniusWallet `kChartAxisGutter`)
- X-axis label row height: 22px (from GeniusWallet `kChartTimeRowHeight`)
- Label band height (axis-free small charts): 17px (from GeniusWallet `kChartLabelBand`)
- Minimum plot height for framed (scheme B) chart: 220px (from GeniusWallet `kChartFrameMinHeight`)
- Fill fade stop: 0.62 (fraction of plot height where below-bar area reaches zero alpha, from GeniusWallet `kChartFillFadeStop`)

---

## Typography

Atoms consume the host `TextTheme` slots — no new font sizes, no font wrappers.

| Role | M3 Slot | Weight | Phase 10 Usage |
|------|---------|--------|----------------|
| Axis labels | `textTheme.labelSmall` | inherited (default 500) | X-axis time/value labels; Y-axis value labels. Always `fontFeatures: [FontFeature.tabularFigures()]` for numeric alignment. |
| Data readout | `textTheme.bodyMedium` | inherited (default 400) | External readout area (consumer-rendered; atom reserves slot position only) |
| Scrub value | `textTheme.titleSmall` | inherited (default 500) | Selected-point value when consumer renders it in the external readout |

**Tabular figures rule:** ALL numeric chart labels MUST use `fontFeatures: [FontFeature.tabularFigures()]` — proportional-width digits cause label jitter as values change during scrub. This is not optional.

---

## Color

Reuse the existing `ScaffoldPalette` — do NOT introduce new tokens. Phase 10 must render correctly under both `defaultPalette` (dark) and `lightPalette` (light) with no consumer overrides.

| Role | Token | Dark | Light | Phase 10 Usage |
|------|-------|------|-------|----------------|
| Dominant 60% | `palette.surfaceElevated` | `#0C0E14` | `#FFFFFF` | Chart card container fill |
| Chart line | `palette.lightGreenPrimary` | `#00EAAE` | `#00EAAE` (shared) | Default series line color (consumer-overridable) |
| Chart fill | `palette.lightGreenPrimary` at gradient | `#00EAAE` → transparent | same | Below-bar area fill, fading to zero alpha at 62% of plot height |
| Scrub line | `palette.borderControl` | `#3A3F4E` | `#C8CCD4` | Vertical rule at scrub position (WCAG 1.4.11 3:1 contrast — `borderControl` clears 3.30:1 dark / 3.10:1 light per GeniusWallet audit) |
| Scrub dot | `palette.lightGreenPrimary` | `#00EAAE` | `#00EAAE` | Touched-spot indicator circle (radius 5, strokeWidth 4, strokeColor = line color at 26% alpha) |
| Axis labels | `palette.textSecondary` | `#8A8F9D` | `#5A6070` | X-axis and Y-axis label text |
| Grid lines | `palette.borderSubtle` | `#1FFFFFFF` | `#1F000000` | Horizontal gridlines (large charts only) |
| Up-trend | `palette.statusSuccess` | `#00E67A` | `#0E9F5B` | Positive-direction series color (consumer opts in) |
| Down-trend | `palette.statusError` | `#FF4D4D` | `#D13438` | Negative-direction series color (consumer opts in) |

**Accent (`lightGreenPrimary`) reserved for — exclusive list:**
1. Default series line color
2. Below-bar area fill gradient (start color)
3. Scrub dot fill color
4. Up-trend override when consumer passes `trendColor: TrendColor.up`

**Accent is NEVER used for:** axis labels, grid lines, chart card fill, scrub vertical rule, border colors.

---

## Copywriting Contract

Atoms are domain-agnostic (locked constraint). Atoms ship with NO hardcoded copy; consumers provide all visible strings via parameters.

| Element | Copy | Owner |
|---------|------|-------|
| Chart semantics label | `"Chart"` (default, consumer-overridable via `semanticsLabel`) | atom default |
| Scrub semantics label | `"Chart scrubber"` (default, consumer-overridable via `scrubberSemanticsLabel`) | atom default |
| Selected point announcement | Consumer-provided format string (e.g. `"Value: {value}"`) passed to `ScaffoldLiveRegion` | consumer |
| Axis label text | Derived from data via consumer-supplied `xLabelFormatter` / `yLabelFormatter` callbacks | consumer |
| Empty state | `SizedBox.shrink()` when `series` is empty | atom behavior |

**Rule:** Any user-visible string in a Phase 10 widget MUST be a required-or-optional constructor parameter. Atoms ship with empty/zero defaults, never with placeholder English text. The only atom-default strings are the two semantics labels above (`"Chart"`, `"Chart scrubber"`), which are accessibility affordances and MUST remain consumer-overridable.

---

## Widget-Specific Visual Contracts

### ScaffoldChart (WIDG-35)

| Property | Contract |
|----------|----------|
| Data contract | `ScaffoldChart<T>({required List<T> series, required double Function(T) xAccessor, required double Function(T) yAccessor, T? selectedPoint, ValueChanged<T>? onPointSelected})` — generic, no domain types |
| Internal mapping | Atom maps `series` → `List<FlSpot>` via accessors, then delegates to the fl_chart support part (`lib/utils/scaffold_chart_renderer.dart`) |
| Render surface | `ScaffoldSurface` with `palette.surfaceElevated` fill, no border, `dimens.radiusMd` corner radius. Outer padding `EdgeInsets.all(dimens.space8)` (16px). |
| Chart type | `LineChart` only for v1.2 — no bar/pie/scatter. `isCurved: false` (straight segments between points). `dotData: FlDotData(show: false)` (no dots on data points). |
| Below-bar fill | `BarAreaData(show: true, gradient: LinearGradient(colors: [lineColor.withAlpha(0.26), lineColor.withAlpha(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, kChartFillFadeStop]))` |
| Y-axis (large) | fl_chart `rightTitles` with `reservedSize: 62`. Nice-number tick ladder via `chartTickStep()`. `minIncluded: false, maxIncluded: false`. Label style: `textTheme.labelSmall` + `palette.textSecondary` + tabular figures. |
| Y-axis (small) | Axis-free — `chartBandedBounds()` widens the Y window to reserve label bands. No fl_chart titles. |
| X-axis | Plain `Row` of `Text` widgets, `mainAxisAlignment: MainAxisAlignment.spaceBetween`, `EdgeInsets.only(right: kChartAxisGutter)`. NEVER fl_chart `bottomTitles` (cannot align to epoch-second sample positions). Label count via `chartXLabelCount()`. Label style: `textTheme.labelSmall` + `palette.textSecondary` + tabular figures. |
| Grid (large) | `FlGridData(show: true, drawVerticalLine: false, horizontalInterval: step, getDrawingHorizontalLine: → FlLine(color: palette.borderSubtle, strokeWidth: 0.5))` |
| Grid (small) | `FlGridData(show: false)` |
| Border | `FlBorderData(show: false)` — always |
| Y bounds | `chartYBounds(data, viewMinX:, viewMaxX:)` — 8% padding over visible window, flat-series fallback to ±1% of value |
| Empty state | `SizedBox.shrink()` when `series` is empty |
| Semantics | `Semantics(label: semanticsLabel ?? 'Chart')` on outer container |
| Size variants | **Large (scheme B):** plot height ≥ 220px — framed with right Y-axis + bottom X-axis labels. **Small (scheme A):** plot height < 220px — axis-free with banded bounds. Selection is automatic via `chartUsesFrame(plotHeight)`. |

### ScaffoldChartScrubber (WIDG-36)

| Property | Contract |
|----------|----------|
| Composition | Wraps `ScaffoldChart` or receives shared geometry. Exposes `selectedPoint: T?` and `onPointSelected: ValueChanged<T>?` |
| Touch handling | `LineTouchData(enabled: true, handleBuiltInTouches: true, touchCallback: (FlTouchEvent, LineTouchResponse?) → extract lineBarSpots!.first → map to T via index → onPointSelected?.call(point))` |
| Touch indicator | `getTouchedSpotIndicator: → TouchedSpotIndicatorData(FlLine(color: palette.borderControl, strokeWidth: 1), FlDotData(getDotPainter: → FlDotCirclePainter(radius: 5, color: lineColor, strokeWidth: 4, strokeColor: lineColor.withAlpha(0.26))))` |
| Tooltip | SUPPRESSED — `LineTouchTooltipData(getTooltipColor: → Colors.transparent, tooltipBorder: BorderSide.none, tooltipPadding: EdgeInsets.zero, getTooltipItems: → null)` — no floating tooltip; consumer renders readout externally |
| Hover exit | `PointerExitEvent` clears selection (`selectedPoint = null`, `onPointSelected?.call(null)`) |
| External readout | Atom does NOT render a readout. The consumer composes a readout widget below/above the chart using `selectedPoint` state. |
| a11y announcement | On `selectedPoint` change, consumer may pass the formatted value to `ScaffoldLiveRegion(value: ...)`. Atom provides the hook; announcement content is consumer-supplied. |
| Semantics | `Semantics(label: scrubberSemanticsLabel ?? 'Chart scrubber')` on the touch interaction area |
| Keyboard | Scrub interaction area is keyboard-focusable. ArrowLeft/ArrowRight move selection to previous/next data point. Enter confirms selection (fires `onPointSelected`). Escape clears selection. |

---

## Motion Contract (applies to all Phase 10 atoms)

| Animation | Duration | Curve | Reduced-motion fallback |
|-----------|----------|-------|------------------------|
| Scrub dot appear | `ScaffoldMotionDurations.short` (150ms) | `ScaffoldMotionCurves.decelerate` | Instant appear |
| Scrub dot disappear | `ScaffoldMotionDurations.short` (150ms) | `ScaffoldMotionCurves.decelerate` | Instant disappear |
| Below-bar fill reveal | `ScaffoldMotionDurations.medium` (300ms) | `ScaffoldMotionCurves.standard` | Instant render |

**Rule:** Every animation reads `ScaffoldMotion.of(context).reducedMotion` and substitutes the fallback. No animation may be unconditionally applied.

---

## Interaction States (applies to scrub interaction area)

| State | Visual | Source |
|-------|--------|--------|
| Default | No overlay | `ScaffoldPressable` baseline |
| Hover | Scrub dot + vertical rule visible | fl_chart `LineTouchData` |
| Touch/drag | Scrub dot + vertical rule follows finger | fl_chart `LineTouchData` |
| Focus | 2px `palette.focusRingColor` ring via `ScaffoldFocusOutline` | `ScaffoldFocusOutline` existing |
| Disabled | 40% opacity `ScaffoldDisabledOverlay` | `ScaffoldDisabledOverlay` existing |

---

## Accessibility Contract

| Element | Requirement |
|---------|-------------|
| ScaffoldChart | Outer `Semantics(label: semanticsLabel ?? 'Chart')`. Chart is NOT a live region — value announcements flow through `ScaffoldLiveRegion` only. |
| ScaffoldChartScrubber | Touch area: `Semantics(label: scrubberSemanticsLabel ?? 'Chart scrubber')`. Keyboard: ArrowLeft/ArrowRight navigate points, Enter selects, Escape clears. |
| Touch targets | Scrub interaction area meets 48x48 via `ScaffoldTouchTarget` expansion beyond visual plot bounds. |
| Focus visibility | Scrub area shows `ScaffoldFocusOutline` 2px ring using `palette.focusRingColor`. |
| Reduced motion | Every animation respects `ScaffoldMotion.of(context).reducedMotion` per the Motion Contract table above. |
| Tabular figures | All numeric labels use `fontFeatures: [FontFeature.tabularFigures()]` to prevent layout jitter during scrub. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none — Flutter package, no shadcn | not required |
| Third-party | fl_chart 1.2.0 (pub.dev) | isolated in `lib/utils/` support part |

**Package dependencies used by Phase 10 (Flutter pub):**
- `flutter/material.dart`, `flutter/rendering.dart` — built-in
- Existing `frontend_scaffold` atoms (in-repo)
- `fl_chart: ^1.2.0` — **support part only** (`lib/utils/scaffold_chart_renderer.dart`), NOT a base-atom dependency (D-02/D-08)

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

---

## Source Citations

| Decision | Source |
|----------|--------|
| fl_chart engine | GeniusWallet `pubspec.yaml:36` — `fl_chart: ^1.2.0` |
| LineChart config | GeniusWallet `crypto_live_chart.dart:698-748` — `isCurved: false`, `dotData: FlDotData(show: false)`, below-bar gradient |
| Touch/scrub pattern | GeniusWallet `crypto_live_chart.dart:787-825` — `LineTouchData`, `getTouchedSpotIndicator`, suppressed tooltip |
| Scrub indicator colors | GeniusWallet `crypto_live_chart.dart:795-815` — `borderControl` WCAG 3:1 audit, `FlDotCirclePainter` |
| X-axis as Row of Texts | GeniusWallet `crypto_live_chart.dart:831-863` — explicit rejection of fl_chart `bottomTitles` |
| Y-axis right titles | GeniusWallet `crypto_live_chart.dart:748-790` — `rightTitles`, `chartTickStep()`, `axisMoneyLabel()` |
| Pure geometry functions | GeniusWallet `chart_axis.dart` — `chartYBounds`, `chartTickStep`, `chartXLabelCount`, `chartBandedBounds`, `visibleExtremes` |
| Geometry constants | GeniusWallet `chart_axis.dart` — `kChartAxisGutter` (62), `kChartTimeRowHeight` (22), `kChartLabelBand` (17), `kChartFrameMinHeight` (220), `kChartFillFadeStop` (0.62) |
| Spacing tokens | `lib/theme/scaffold_dimens.dart` — existing `ScaffoldDimens` (space2/4/6/8/12 = 4/8/12/16/24) |
| Color tokens | `lib/theme/scaffold_palette.dart` — existing `ScaffoldPalette` (dark `defaultPalette` + `lightPalette`) |
| Motion durations/curves | `lib/components/scaffold_motion.dart` — `ScaffoldMotionDurations` short/medium/long, `ScaffoldMotionCurves` standard/decelerate |
| Focus outline | `lib/components/scaffold_focus_outline.dart` — 2px ring via `palette.focusRingColor` |
| Touch target | `lib/components/scaffold_touch_target.dart` — 48x48 minimum hit area |
| Live region | `lib/components/scaffold_live_region.dart` — `ScaffoldLiveRegion(label:, value:)` |
