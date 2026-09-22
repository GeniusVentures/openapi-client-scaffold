# Phase 8: Supporting Atoms, Table Cells & Light Palette — Pattern Map

**Mapped:** 2026-08-17
**Files analyzed:** 11 (5 new atoms + 2 modified + 1 barrel export + tests/demos)
**Analogs found:** 11 / 11 (all files have an existing in-repo analog)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/components/scaffold_chip.dart` | component (pressable atom) | request-response (render-only + onTap) | `lib/components/scaffold_selectable_surface.dart` + `scaffold_badge.dart` (pill surface) | role-match (no chip exists; selected-surface + badge geometry apply) |
| `lib/components/scaffold_chip_group.dart` | component (composite layout) | event-driven (selection callbacks out) | `lib/components/responsive_grid.dart` (layout-only) + `scaffold_selection_indicator_*.dart` (selection semantics) | role-match (no Wrap-based group exists) |
| `lib/components/scaffold_disclosure.dart` | component (composite, transient state) | event-driven (expand/collapse callbacks) | `lib/components/scaffold_search_bar.dart` (existing `AnimatedSize` + reduced-motion + slots) | exact |
| `lib/components/scaffold_trace_list.dart` | component (typed-model list) | request-response (one-way render) | `lib/components/scaffold_state_view.dart` (typed model → widget switch) + `scaffold_disclosure.dart` (item) | role-match (no ordered-list atom exists) |
| `lib/components/scaffold_composer.dart` | component (composite w/ typed slots) | event-driven (`onSubmit(String)`) | `lib/components/media_controls.dart` (typed slots + transient state) + `wallet_connect_sheet.dart` (column of sections + slots) | exact |
| `templates/components/data_table.dart.jinja2` (MODIFY) | codegen template | render-time | existing template — add `cellBuilder` column field | exact (self) |
| `templates/components/data_table_vars.json` (MODIFY) | codegen fixture | static | existing fixture — add a `cellBuilder`-exercising example column | exact (self) |
| `lib/components/scaffold_badge.dart` (MODIFY) | component | render-only | existing file — replace `Colors.white` with palette-resolved on-status color | exact (self) |
| `lib/theme/scaffold_palette.dart` (VERIFY only) | theme | static | existing file — verify token coverage, fill gaps only if found | exact (self) |
| `lib/frontend_scaffold.dart` (MODIFY) | barrel export | static | existing file — append exports in sorted position | exact (self) |
| `test/components/scaffold_{chip,chip_group,disclosure,trace_list,composer}_test.dart` | test | n/a | `test/components/scaffold_badge_test.dart`, `media_controls_test.dart` | exact |
| `example/lib/demos/{chip,disclosure,trace_list,composer}_demo.dart` + register in `example/lib/main.dart` | demo | n/a | `example/lib/demos/media_card_demo.dart`, `wallet_connect_sheet_demo.dart` | exact |

## Pattern Assignments

### `lib/components/scaffold_chip.dart` (component, pressable atom)

**Analog:** `lib/components/scaffold_selectable_surface.dart` (selected-surface contract) + `lib/components/scaffold_badge.dart` (pill shape).

**Library header + imports pattern** (mirror `scaffold_selectable_surface.dart` lines 1-14 and `scaffold_badge.dart` lines 1-24):

```dart
/// ScaffoldChip — M3 pill-shaped pressable atom.
///
/// Composes ScaffoldSurface (pill) + ScaffoldPressable + ScaffoldTouchTarget
/// (48px min height). Selected state is a 2px `palette.lightGreenPrimary`
/// BORDER (not fill — preserves the 60/30/10 contract). Optional leading
/// icon, trailing ScaffoldStatusIndicator. Disabled → ScaffoldDisabledOverlay
/// at `dimens.disabledOverlayOpacity`.
library;

import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
```

**Theme-token resolution pattern** (universal — every Phase 8 atom uses this):

```dart
@override
Widget build(BuildContext context) {
  final palette = context.palette;
  final dimens = context.dimens;
  final textTheme = Theme.of(context).textTheme;
  // …
}
```

**Pill surface + pressable + touch target pattern** (compose `ScaffoldSurface` with `radiusPill`, wrap in `ScaffoldPressable`; DO NOT roll padding arithmetic — `ScaffoldPressable` already wraps its child in `ScaffoldTouchTarget` via `scaffold_pressable.dart` line 120):

```dart
// Pill surface (ScaffoldSurface with radiusPill)
Widget chip = ScaffoldSurface(
  color: palette.deepBlueCardColor,
  borderRadius: BorderRadius.circular(dimens.radiusPill),
  border: selected
      ? Border.all(color: palette.lightGreenPrimary, width: 2.0)
      : null,
  padding: EdgeInsets.symmetric(
    horizontal: dimens.space4,
    vertical: dimens.space4,
  ),
  child: /* icon/label/status row */,
);

// Pressable wrapper supplies ScaffoldTouchTarget internally.
chip = ScaffoldPressable(
  onPressed: onPressed,
  disabled: disabled,
  semanticLabel: semanticLabel,  // REQUIRED for icon-only chips (D-03)
  child: chip,
);
```

**Internal layout — leading icon + label + status dot with `space2` gap** (mirrors the `Row` of slots pattern in `media_controls.dart` lines 209-282):

```dart
final List<Widget> rowChildren = <Widget>[];
if (icon != null) {
  rowChildren.add(Icon(icon, size: 16));
}
if (label != null) {
  if (rowChildren.isNotEmpty) {
    rowChildren.add(SizedBox(width: dimens.space2));
  }
  rowChildren.add(Text(label!, style: textTheme.labelMedium));
}
if (status != null) {
  if (rowChildren.isNotEmpty) {
    rowChildren.add(SizedBox(width: dimens.space2));
  }
  rowChildren.add(ScaffoldStatusIndicator(status: status!, dotSize: 8));
}
```

**Semantics + selected state pattern** (mirror `scaffold_selectable_surface.dart` line 82):

```dart
return Semantics(
  selected: selected,
  button: true,  // added via ScaffoldPressable; chip adds selected flag
  child: chip,
);
```

**A11y contract (D-03, UI-SPEC "Accessibility Contract"):** assert non-null `semanticLabel` when `label == null && icon != null`:

```dart
assert(
  label != null || semanticLabel != null,
  'Icon-only ScaffoldChip requires semanticLabel (WCAG 4.1.2)',
);
```

---

### `lib/components/scaffold_chip_group.dart` (component, selection-management layout)

**Analog:** `lib/components/responsive_grid.dart` (layout-only composite) for the children-in-a-container pattern; `lib/components/scaffold_selection_indicator_checkbox.dart` / `_radio.dart` for selection-mode semantics.

**Wrap layout pattern** (D-02 contract — `Wrap` with `space8`/`space4`):

```dart
@override
Widget build(BuildContext context) {
  final dimens = context.dimens;
  if (chips.isEmpty) {
    return const SizedBox.shrink();  // UI-SPEC "Empty state" contract
  }

  return Wrap(
    spacing: dimens.space8,      // 16px between chips
    runSpacing: dimens.space4,   // 8px between rows
    children: <Widget>[
      for (int i = 0; i < chips.length; i++)
        _wrapChipAtIndex(i, chips[i]),
    ],
  );
}
```

**Selection dispatch pattern (consumer-owned, D-02):** the group holds NO selection truth — it forwards each child's tap to `onSelectionChanged` after computing the next `Set<int>`:

```dart
Widget _wrapChipAtIndex(int index, ScaffoldChip chip) {
  final bool isSelected = selected.contains(index);
  return ScaffoldChip(
    // forward chip's slots
    label: chip.label,
    icon: chip.icon,
    status: chip.status,
    selected: isSelected,
    disabled: chip.disabled,
    semanticLabel: chip.semanticLabel,
    onPressed: chip.onPressed == null
        ? null
        : () => _handleChipTap(index),
  );
}

void _handleChipTap(int index) {
  final Set<int> next = Set<int>.from(selected);
  if (multiSelect) {
    if (next.contains(index)) {
      next.remove(index);
    } else {
      next.add(index);
    }
  } else {
    next
      ..clear()
      ..add(index);
  }
  onSelectionChanged?.call(next);
}
```

**Group-level semantics (UI-SPEC "Accessibility Contract"):**

```dart
return Semantics(
  role: multiSelect ? SemanticsRole.group : SemanticsRole.radiogroup,
  child: wrap,
);
```

---

### `lib/components/scaffold_disclosure.dart` (component, expand/collapse)

**Analog:** `lib/components/scaffold_search_bar.dart` lines 309-335 — the existing `AnimatedSize` + `ScaffoldMotionDurations.medium` + `ScaffoldSurface` pattern.

**AnimatedSize body pattern** (locked by D-04):

```dart
// From scaffold_search_bar.dart — AnimatedSize honoring reduced motion.
final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;
final Duration expandDuration =
    reducedMotion ? Duration.zero : ScaffoldMotionDurations.medium;

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    headerRow,
    AnimatedSize(
      duration: expandDuration,
      curve: ScaffoldMotionCurves.standard,
      child: expanded
          ? Padding(
              padding: EdgeInsets.only(
                left: dimens.space6,   // 12px indent
                top: dimens.space4,    // 8px top
              ),
              child: body,
            )
          : const SizedBox.shrink(),
    ),
  ],
);
```

**Header row pattern — `ScaffoldPressable` + `Row(title Expanded, chevron)` with `space4` gap** (mirror the row-of-slots pattern in `media_controls.dart` lines 209-282):

```dart
final Widget headerRow = ScaffoldPressable(
  onPressed: () => onExpandedChanged?.call(!expanded),
  semanticLabel: title,
  child: Row(
    children: <Widget>[
      Expanded(
        child: Text(title, style: textTheme.labelMedium),
      ),
      SizedBox(width: dimens.space4),
      AnimatedRotation(
        turns: expanded ? 0.25 : 0.0,   // 0° → 90°
        duration: reducedMotion
            ? Duration.zero
            : ScaffoldMotionDurations.short,
        curve: ScaffoldMotionCurves.standard,
        child: Icon(
          Icons.chevron_right,
          size: 24,
          color: expanded && highlightWhenExpanded
              ? palette.lightGreenPrimary
              : palette.textSecondary,
        ),
      ),
    ],
  ),
);
```

**Controlled + uncontrolled hybrid (D-05)** — mirror Flutter's `initialValue` idiom; `expanded` overrides `initiallyExpanded` when non-null:

```dart
class ScaffoldDisclosure extends StatefulWidget {
  const ScaffoldDisclosure({
    super.key,
    required this.title,
    required this.body,
    this.expanded,                    // null → uncontrolled
    this.initiallyExpanded = false,   // used only when expanded == null
    this.onExpandedChanged,
    this.highlightWhenExpanded = false,
  });

  final String title;
  final Widget body;
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool highlightWhenExpanded;
}

class _ScaffoldDisclosureState extends State<ScaffoldDisclosure> {
  late bool _internalExpanded = widget.initiallyExpanded;

  bool get _effectiveExpanded => widget.expanded ?? _internalExpanded;

  void _toggle() {
    final bool next = !_effectiveExpanded;
    if (widget.expanded == null) {
      setState(() => _internalExpanded = next);
    }
    widget.onExpandedChanged?.call(next);
  }
}
```

**Semantics contract (UI-SPEC):**

```dart
return Semantics(
  expanded: _effectiveExpanded,
  label: title,
  child: column,
);
```

---

### `lib/components/scaffold_trace_list.dart` (component, typed-model list)

**Analog:** `lib/components/scaffold_state_view.dart` (typed model → widget switch) for the "model in, widget out" pattern; `scaffold_disclosure.dart` (the per-item atom).

**Typed model pattern** (mirror `SearchResult`/`SearchResultGroup` in `scaffold_search_bar.dart` lines 35-71):

```dart
/// A single trace item — domain-agnostic.
class TraceItem {
  const TraceItem({
    required this.title,
    required this.body,
    this.status,
    this.initiallyExpanded = false,
  });

  /// Item header text.
  final String title;

  /// Item body content (rendered inside the disclosure).
  final Widget body;

  /// Optional leading status indicator.
  final StatusVariant? status;

  /// Initial expansion state when uncontrolled.
  final bool initiallyExpanded;
}
```

**Column-of-disclosures with `space8` separation pattern** (D-04/UI-SPEC):

```dart
@override
Widget build(BuildContext context) {
  final dimens = context.dimens;
  if (items.isEmpty) {
    return const SizedBox.shrink();
  }

  final List<Widget> children = <Widget>[];
  if (groupHeader != null) {
    children
      ..add(Padding(
        padding: EdgeInsets.only(top: dimens.space12),
        child: Text(groupHeader!, style: Theme.of(context).textTheme.titleSmall),
      ))
      ..add(SizedBox(height: dimens.space8));
  }
  for (int i = 0; i < items.length; i++) {
    if (i > 0) {
      children.add(SizedBox(height: dimens.space8));
    }
    children.add(_buildItem(context, items[i]));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
}

Widget _buildItem(BuildContext context, TraceItem item) {
  // Compose optional leading ScaffoldStatusIndicator + title into the
  // disclosure's title slot — one-way data in (D-05).
  return ScaffoldDisclosure(
    title: item.title,
    body: item.body,
    initiallyExpanded: item.initiallyExpanded,
    // status slot handled via a custom title row inside disclosure if
    // needed — TraceList composes, it does not extend.
  );
}
```

---

### `lib/components/scaffold_composer.dart` (component, typed slots)

**Analog:** `lib/components/media_controls.dart` (typed slot list + `Row` of slots with `SizedBox(width: dimens.spaceN)` separators) + `lib/components/wallet_connect_sheet.dart` (column of typed sections with `EdgeInsets.only(top: dimens.spaceN)` separation) + `lib/components/scaffold_search_bar.dart` (text-input + focus + surface pattern).

**Library header pattern** (mirror `media_controls.dart` lines 1-21):

```dart
/// ScaffoldComposer — M3 text-composition area with badge and action slots.
///
/// Composes ScaffoldSurface + TextField + consumer-supplied action/badge
/// slots. Holds NO submission logic — `onSubmit(String)` is the only output
/// (D-07). Standalone widget consuming Theme.of(context) via
/// context.palette/dimens; no framework-specific state dependencies.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
```

**Slot-list + dimens-separated column pattern** (mirror `wallet_connect_sheet.dart` lines 116-191):

```dart
final List<Widget> rows = <Widget>[];

if (badgeRow != null && badgeRow!.isNotEmpty) {
  rows.add(Wrap(
    spacing: dimens.space4,
    runSpacing: dimens.space4,
    children: badgeRow!,
  ));
}

// Text-field row (always present).
if (rows.isNotEmpty) {
  rows.add(SizedBox(height: dimens.space4));
}
rows.add(textField);

if (actionRow != null && actionRow!.isNotEmpty) {
  rows.add(SizedBox(height: dimens.space4));
  rows.add(Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      for (int i = 0; i < actionRow!.length; i++) ...<Widget>[
        if (i > 0) SizedBox(width: dimens.space4),
        actionRow![i],
      ],
    ],
  ));
}

return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: rows,
);
```

**Surface + focus-outline + disabled-overlay wrapper** (mirror `scaffold_search_bar.dart` lines 309-335):

```dart
final Widget inner = Padding(
  padding: EdgeInsets.all(dimens.space8),
  child: columnOfRows,
);

Widget surface = ScaffoldSurface(
  color: palette.surfaceElevated,
  borderRadius: BorderRadius.circular(dimens.radiusMd),
  border: Border.all(color: palette.borderSubtle, width: 1),
  child: inner,
);

surface = ScaffoldFocusOutline(
  focusNode: _textFieldFocusNode,  // held by StatefulWidget
  borderRadius: BorderRadius.circular(dimens.radiusMd),
  child: surface,
);

if (disabled) {
  surface = ScaffoldDisabledOverlay(disabled: true, child: surface);
}
```

**Text-field decoration pattern** (UI-SPEC: `InputDecoration(border: InputBorder.none, hintText: consumer-supplied)`; `bodyMedium` typography):

```dart
final Widget textField = TextField(
  controller: _controller,            // private transient — D-03
  focusNode: _textFieldFocusNode,
  style: textTheme.bodyMedium,
  decoration: InputDecoration(
    border: InputBorder.none,
    hintText: hintText,               // consumer-supplied — D-07
    hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
    isDense: true,
  ),
  minLines: 1,
  maxLines: maxLines,
  enabled: !disabled,
  onSubmitted: (String value) {
    onSubmit?.call(value);            // D-07: no internal submission logic
    _controller.clear();
  },
);
```

**Private transient state pattern (D-03)** — mirror `media_controls.dart` lines 93-100: ONLY `_controller` + `_textFieldFocusNode` are owned; submission truth stays in the consumer.

---

### `templates/components/data_table.dart.jinja2` (MODIFY — add `cellBuilder`)

**Analog:** the existing template itself — additive change to `DataColumnConfig` and the cell render path.

**`DataColumnConfig` field addition** (extend lines 55-71 of the template — keep constructor optional + backward compatible):

```jinja2
/// Immutable column configuration for [{{ widget_class_name }}].
class DataColumnConfig {
  const DataColumnConfig({
    required this.label,
    required this.accessor,
    this.sortable = true,
    this.cellBuilder,
  });

  final String label;
  final String accessor;
  final bool sortable;

  /// Optional custom cell renderer. When non-null, the cell renders
  /// `cellBuilder(context, item)` inside the default `DataCell`. Custom
  /// builders MUST NOT add their own outer padding — they inherit the
  /// DataTable's default cell padding so they align with string cells
  /// (WIDG-43 contract). Sort behavior is driven by [accessor] regardless
  /// of [cellBuilder] presence.
  final Widget Function(BuildContext context, {{ data_type_name }} item)?
      cellBuilder;
}
```

**Cell render path change** (template lines 307-311 — wrap the existing `Text` fallback with a `cellBuilder` branch; keep the checkbox cell first):

```jinja2
{% for col in columns %}
  DataCell(
    {% if col.cellBuilder is defined and col.cellBuilder %}
    Builder(
      builder: (BuildContext cellContext) =>
          widget.columns[{{ loop.index0 }}].cellBuilder!(cellContext, item),
    ),
    {% else %}
    Text(
      item.{{ col.accessor }}?.toString() ?? '',
      style: textTheme.bodyMedium,
    ),
    {% endif %}
  ),
{% endfor %}
```

> **Note on the `cellBuilder` template contract:** the `columns` list is injected at generation time, so the `cellBuilder` presence is decided per-column by the fixture. If the fixture schema cannot express a function value, follow D-09 — emit the `cellBuilder` field as an always-present `final ... cellBuilder` (default null), and verify the runtime branch in the widget test rather than forking the template's generated output. The template's `accessor` field is the compatibility anchor and does NOT change.

**`data_table_vars.json` fixture addition** (D-09 — additive; existing keys unchanged):

```json
{
  "widget_class_name": "GeniusDataTable",
  "data_type_name": "SampleItem",
  "columns": [
    {"label": "Name", "accessor": "name", "sortable": true},
    {"label": "Status", "accessor": "status", "sortable": true},
    {"label": "Created", "accessor": "createdAt", "sortable": false}
  ],
  "form_factor": "desktop"
}
```

(If the fixture format cannot express "this column exercises cellBuilder," keep the fixture as-is and exercise `cellBuilder` exclusively in the widget test — D-09 fallback.)

**Locked headers — do NOT touch** (template line 245):

```dart
style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
```

---

### `lib/components/scaffold_badge.dart` (MODIFY — WIDG-46 on-status color)

**Analog:** the existing file. Required remediation at lines 105 and 140 — replace hardcoded `Colors.white` with a palette-resolved on-status color.

**On-status resolution pattern (D-10 — Claude's discretion: simplest WCAG-AA mechanism):**

Use a luminance-threshold check on the resolved badge fill. Dark text on bright fills, light text on dark fills. Resolution lives INSIDE `ScaffoldBadge` (not consumer). Uses `palette.textPrimary` for the dark-side (which resolves to `#17191E` in `lightPalette`, `#FFFFFFFF` in `defaultPalette`) — but the safe choice for "on-bright-fill" is a fixed dark constant; for "on-dark-fill" a fixed light constant. Pick whichever side the fill's relative luminance dictates.

```dart
/// Luminance threshold (WCAG AA 4.5:1) — fills brighter than this resolve to
/// dark on-status text; darker fills resolve to light on-status text.
static const double _kOnStatusLuminanceThreshold = 0.40;

/// Fixed on-status colors (palette-independent — chosen to pass WCAG AA
/// against every status fill in BOTH palettes):
///   - dark:  Color(0xFF17191E) (matches lightPalette.textPrimary)
///   - light: Color(0xFFFFFFFF) (matches defaultPalette.textPrimary)
static const Color _kOnStatusDark = Color(0xFF17191E);
static const Color _kOnStatusLight = Color(0xFFFFFFFF);

/// Resolves the "on-status" foreground color for the given [fill]. Bright
/// fills (lightGreenPrimary, statusSuccess, statusWarningText) return dark;
/// dark fills (statusError, blue500, defaultPalette surfaces) return light.
Color _resolveOnStatusColor(Color fill) {
  return fill.computeLuminance() > _kOnStatusLuminanceThreshold
      ? _kOnStatusDark
      : _kOnStatusLight;
}
```

**Replace line 105** (was `color: Colors.white`):

```dart
final TextStyle? labelStyle = textTheme.labelSmall?.copyWith(
  color: _resolveOnStatusColor(resolvedBadgeColor),
);
```

**Replace line 140** (was `Icon(icon, size: 16, color: Colors.white)`):

```dart
child: Icon(icon, size: 16, color: _resolveOnStatusColor(resolvedBadgeColor)),
```

**Acceptance check** — the planner's widget test should assert:
- For `badgeColor: palette.lightGreenPrimary` (`#00EAAE`, luminance ~0.62), label/icon color resolves to `_kOnStatusDark`.
- For `badgeColor: palette.statusError` (dark `#FF4D4D` luminance ~0.21 / light `#D13438` luminance ~0.13), label/icon color resolves to `_kOnStatusLight`.
- Test under BOTH `defaultPalette` and `lightPalette`.

---

### `lib/theme/scaffold_palette.dart` (VERIFY only — no modification unless gap found)

**Analog:** the existing file. Phase 8 does not redesign the palette — it VERIFIES that every widget consumes tokens (no hardcoded colors) and that all 22 tokens have light values.

**Existing `lightPalette` verification:** the file at lines 132-155 already defines `lightPalette` with values for every token. The Phase 8 widget test (`scaffold_palette_token_test.dart`) is the verification harness — the planner should EXTEND that test, not modify the palette, unless a token is discovered missing.

**Pattern for the token test** (mirror the existing `test/components/scaffold_palette_token_test.dart` style — assert every `lightPalette` field is non-null and differs from the corresponding `defaultPalette` field where a light variant is expected):

```dart
test('lightPalette covers all 22 tokens', () {
  const ScaffoldPalette light = ScaffoldPalette.lightPalette;
  const ScaffoldPalette dark = ScaffoldPalette.defaultPalette;
  expect(light.deepBlueCardColor, isNotNull);
  expect(light.lightGreenPrimary, isNotNull);
  // … one expect per token; assert the surfaces flip
  expect(light.surfaceElevated, isNot(equals(dark.surfaceElevated)));
  expect(light.textPrimary, isNot(equals(dark.textPrimary)));
});
```

---

### `lib/frontend_scaffold.dart` (MODIFY — append exports in sorted position)

**Analog:** existing barrel. Insertion order is alphabetical within `components/`.

**Additions (sorted into the existing list):**

```dart
export 'components/scaffold_chip.dart';
export 'components/scaffold_chip_group.dart';
export 'components/scaffold_composer.dart';
export 'components/scaffold_disclosure.dart';
export 'components/scaffold_trace_list.dart';
```

**Insertion positions** (alphabetical, between existing entries):

- `scaffold_chip.dart` + `scaffold_chip_group.dart` — between `scaffold_card_state.dart` and `scaffold_color_swatch.dart`.
- `scaffold_composer.dart` — between `scaffold_color_swatch.dart` and `scaffold_dashed_border.dart`.
- `scaffold_disclosure.dart` — between `scaffold_disabled_overlay.dart` and `scaffold_drag_handle.dart`.
- `scaffold_trace_list.dart` — between `scaffold_touch_target.dart` and `wallet_connect_sheet.dart`.

---

### Tests (one per new atom) — `test/components/scaffold_{chip,chip_group,disclosure,trace_list,composer}_test.dart`

**Analog:** `test/components/scaffold_badge_test.dart` (simple atom) + `test/components/media_controls_test.dart` (composite with callbacks + a11y).

**Pump helper pattern** (universal — every Phase 8 widget test uses this):

```dart
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
```

**Light-palette variant (D-11 — required for every Phase 8 widget):**

```dart
Future<void> _pumpLight(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[
          ScaffoldPalette.lightPalette,
          ScaffoldDimens.defaultDimens,
        ],
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
```

**Per-widget minimum test matrix** (drawn from `scaffold_badge_test.dart` + `media_controls_test.dart`):

| Test | Chip | ChipGroup | Disclosure | TraceList | Composer |
|---|---|---|---|---|---|
| Renders under default (dark) palette | ✓ | ✓ | ✓ | ✓ | ✓ |
| Renders under `lightPalette` (D-11) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Tap fires callback exactly once | ✓ | ✓ | ✓ | n/a | ✓ (submit) |
| Selected state visuals (border/fill) | ✓ | ✓ | n/a | n/a | n/a |
| Disabled state dims + blocks | ✓ | ✓ | ✓ | n/a | ✓ |
| Empty → `SizedBox.shrink()` | n/a | ✓ | n/a | ✓ | n/a |
| Semantics role/label registered | ✓ | ✓ (radiogroup/group) | ✓ (expanded) | ✓ | ✓ |
| Icon-only requires `semanticLabel` (D-03 assert) | ✓ | n/a | n/a | n/a | n/a |
| Reduced-motion respected | n/a | n/a | ✓ | ✓ | n/a |
| Multi vs single select | n/a | ✓ | n/a | n/a | n/a |

**Existing badge test modification** — extend `test/components/scaffold_badge_test.dart` to assert the on-status resolution:
- Default `lightGreenPrimary` fill → label color is `_kOnStatusDark` (or matches the helper's dark branch).
- `badgeColor: palette.statusError` → label color is `_kOnStatusLight`.
- Repeat under `lightPalette`.

---

### Demos — `example/lib/demos/{chip,disclosure,trace_list,composer}_demo.dart`

**Analog:** `example/lib/demos/media_card_demo.dart` (composition showcase) + `wallet_connect_sheet_demo.dart` (interactive state demo).

**Demo file shape** (mirror `media_card_demo.dart` lines 16-94):

```dart
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Demo showing [ScaffoldChip] in default / selected / disabled / status
/// compositions. Sectioned vertically with `dimens.itemSpacing` separators.
class ScaffoldChipDemo extends StatelessWidget {
  const ScaffoldChipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldChip')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Default', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const ScaffoldChip(label: 'Chip', /* onPressed: () {} */),
            // …one section per state per the UI-SPEC contract
          ],
        ),
      ),
    );
  }
}
```

**Demo registration** — append entries to `example/lib/main.dart`'s demo list (mirror the existing registration for `media_card_demo`).

---

## Shared Patterns

### Theme token consumption (ALL Phase 8 widgets)

**Source:** every existing atom — `scaffold_badge.dart` lines 67-70, `scaffold_selectable_surface.dart` lines 42-43, `scaffold_surface.dart` lines 43-44.

```dart
final palette = context.palette;
final dimens = context.dimens;
final textTheme = Theme.of(context).textTheme;
```

Apply to: every new component file, every test, every demo. NO hardcoded colors/dimens anywhere in Phase 8 (Phase 6 D-03 + UI-SPEC enforcement).

### Pressable + touch-target + disabled overlay (Chip, Disclosure header, Composer actions)

**Source:** `scaffold_pressable.dart` lines 116-160 — the full composition stack.

```dart
// ScaffoldPressable internally wraps its child in:
//   ScaffoldTouchTarget → Stack(state layer) → MouseRegion/GestureDetector
//   → ScaffoldFocusOutline → Focus → Semantics(button: true)
// Then, if disabled, wraps the whole thing in ScaffoldDisabledOverlay.
//
// Consumers pass only: onPressed, onLongPress, disabled, semanticLabel, child.
ScaffoldPressable(
  onPressed: onPressed,
  disabled: disabled,
  semanticLabel: semanticLabel,
  child: content,
);
```

Apply to: `ScaffoldChip`, `ScaffoldDisclosure` header, `ScaffoldComposer` action slots.

### Reduced-motion substitution (Disclosure, TraceList)

**Source:** `scaffold_animated_display_fade.dart` lines 110-121 + `scaffold_search_bar.dart` lines 309-312.

```dart
final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;
final Duration effectiveDuration =
    reducedMotion ? Duration.zero : ScaffoldMotionDurations.medium;
```

Apply to: any `AnimatedSize`, `AnimatedRotation`, `AnimatedContainer` in the disclosure/trace-list path.

### Empty state → `SizedBox.shrink()` (ChipGroup, TraceList)

**Source:** `scaffold_badge.dart` lines 72-75.

```dart
if (items.isEmpty) {
  return const SizedBox.shrink();
}
```

Apply to: `ScaffoldChipGroup` when `chips.isEmpty`, `ScaffoldTraceList` when `items.isEmpty` (UI-SPEC Copywriting Contract).

### Typed slot lists with dimens separators (ChipGroup, TraceList, Composer)

**Source:** `media_controls.dart` lines 209-282 (row-of-slots), `wallet_connect_sheet.dart` lines 116-191 (column-of-sections).

```dart
final List<Widget> children = <Widget>[];
for (int i = 0; i < slots.length; i++) {
  if (i > 0) {
    children.add(SizedBox(width: dimens.space4));  // or height for column
  }
  children.add(slots[i]);
}
```

Apply to: all three. This is THE established way to lay out consumer-supplied slot lists in the scaffold library — do NOT use `Wrap.separated` / `ListView.separated` / custom dividers.

### Private transient state only (Composer, Disclosure uncontrolled mode)

**Source:** `media_controls.dart` lines 93-100 (D-03 precedent).

```dart
class _FooState extends State<Foo> {
  /// ONLY transient state — controller, focus node, in-progress scrub value.
  /// Persistent/domain truth stays in the consumer.
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
```

Apply to: `ScaffoldComposer` (text controller + focus node), `ScaffoldDisclosure` (uncontrolled-mode `bool`).

### Library header + imports convention (every new component)

**Source:** `media_controls.dart` lines 1-21 (hand-written composite), `scaffold_search_bar.dart` lines 1-12 (generated composite).

Hand-written atoms (all Phase 8 atoms are hand-written per D-06 inheritance):

```dart
/// ScaffoldChip — M3 <role> atom.
///
/// Composes <existing atoms>. <Key contracts>.
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_<x>.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
```

Apply to: every new file in `lib/components/`. Generated files (only the data-table template is touched) keep the `// Auto-generated from …` header.

## No Analog Found

All Phase 8 files have an in-repo analog. No file requires falling back to RESEARCH.md patterns.

| File | Reason |
|---|---|
| (none) | — |

## Metadata

**Analog search scope:** `lib/components/`, `lib/theme/`, `templates/components/`, `test/components/`, `example/lib/demos/`
**Files scanned:** 60+ components, 5 theme files, 30+ templates, 35+ tests, 14+ demos
**Pattern extraction date:** 2026-08-17
