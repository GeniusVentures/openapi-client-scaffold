---
phase: 08-supporting-atoms-table-cells-light-palette
reviewed: 2026-08-17T00:00:00Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - example/lib/demos/chip_demo.dart
  - example/lib/demos/composer_demo.dart
  - example/lib/demos/disclosure_demo.dart
  - example/lib/demos/trace_list_demo.dart
  - example/lib/main.dart
  - lib/components/scaffold_badge.dart
  - lib/components/scaffold_chip.dart
  - lib/components/scaffold_chip_group.dart
  - lib/components/scaffold_composer.dart
  - lib/components/scaffold_disclosure.dart
  - lib/components/scaffold_trace_list.dart
  - lib/frontend_scaffold.dart
  - templates/components/data_table.dart.jinja2
  - test/components/data_table_cell_builder_test.dart
  - test/components/scaffold_badge_test.dart
  - test/components/scaffold_chip_group_test.dart
  - test/components/scaffold_chip_test.dart
  - test/components/scaffold_composer_test.dart
  - test/components/scaffold_disclosure_test.dart
  - test/components/scaffold_trace_list_test.dart
  - test/theme/scaffold_palette_token_test.dart
findings:
  critical: 2
  warning: 5
  info: 4
  total: 11
status: resolved
resolution: 7 findings fixed (CR-01, CR-02, WR-01..WR-05) in commits 52314e2, f8ae5a8, 62a98a9, 2365b06, 64ba941, e78784b, b878d92; IN-01..IN-04 deferred (style/optional, non-blocking)
---

# Phase 8: Code Review Report

**Reviewed:** 2026-08-17
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

Phase 8 ships five supporting atoms (Badge, Chip, ChipGroup, Composer, Disclosure, TraceList), four demos, a data-table template cell-builder extension, and palette tests. The library atoms are generally well-structured — they consume `Theme.of(context)` extensions, use dimens tokens for spacing/radius, register appropriate semantics, and have solid test coverage with both default and light palettes.

However, two real correctness defects were found: the controlled-mode `ScaffoldDisclosure` demo is broken (state resets every rebuild), and `ScaffoldChipGroup` silently discards each chip's consumer-supplied `onPressed` callback. Several project-rule violations around magic numbers and dimens tokens also need cleanup, particularly the hardcoded `0.4` disabled opacity in `ScaffoldBadge` which duplicates an existing `dimens.disabledOverlayOpacity` token.

## Critical Issues

### CR-01: Disclosure demo controlled mode is broken — local variable resets every rebuild

**File:** `example/lib/demos/disclosure_demo.dart:81-97`
**Issue:** `bool expanded = false;` is declared *inside* the `StatefulBuilder` builder. Every time `setState` is invoked the builder re-executes, the local `expanded` is re-initialized to `false`, and the controlled disclosure immediately collapses back. Tapping the row fires the callback but the widget never stays expanded — the "Controlled" section of the demo is non-functional. This also teaches consumers an incorrect pattern for controlled widgets.

**Fix:**
Hoist the state out of the builder into a `StatefulWidget` (the same pattern used by `_SingleSelectGroup` and `_MultiSelectGroup` in `chip_demo.dart`):

```dart
class _ControlledDisclosure extends StatefulWidget {
  const _ControlledDisclosure();

  @override
  State<_ControlledDisclosure> createState() => _ControlledDisclosureState();
}

class _ControlledDisclosureState extends State<_ControlledDisclosure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ScaffoldDisclosure(
      title: 'Parent-owned state',
      expanded: _expanded,
      onExpandedChanged: (bool next) => setState(() => _expanded = next),
      body: Text(
        'Expansion truth lives in the parent — this row only fires the callback.',
        style: TextStyle(color: context.palette.textSecondary),
      ),
    );
  }
}
```

### CR-02: ScaffoldChipGroup silently discards each chip's consumer-supplied onPressed

**File:** `lib/components/scaffold_chip_group.dart:68-79`
**Issue:** `_wrapChipAtIndex` rebuilds every chip with a new `onPressed` that only invokes `_handleChipTap(index)`; the original `chip.onPressed` is never called. A consumer who supplies a per-chip `onPressed` (e.g., for logging, analytics, side effects) will find it never fires when the chip is placed inside a `ScaffoldChipGroup`. The DartDoc does not document this "your onPressed is ignored" contract. The chip_demo itself supplies `onPressed: () {}` callbacks on every chip in the group sections — those callbacks are dead code.

**Fix:**
Either chain the consumer's callback into the rewritten `onPressed`, or document the swallow explicitly. Chaining is the safer contract:

```dart
Widget _wrapChipAtIndex(int index, ScaffoldChip chip) {
  final VoidCallback? chipOnPressed = chip.onPressed;
  return ScaffoldChip(
    label: chip.label,
    icon: chip.icon,
    status: chip.status,
    selected: selected.contains(index),
    disabled: chip.disabled,
    semanticLabel: chip.semanticLabel,
    onPressed: chipOnPressed == null
        ? null
        : () {
            chipOnPressed();
            _handleChipTap(index);
          },
  );
}
```

If the design intent really is "group owns all press behavior", then the doc comment must say so and the demo should stop passing dead `onPressed` callbacks.

## Warnings

### WR-01: ScaffoldBadge hardcodes `0.4` opacity instead of using `dimens.disabledOverlayOpacity`

**File:** `lib/components/scaffold_badge.dart:122`
**Issue:** `Opacity(opacity: 0.4, child: result)` uses a magic number. The project rule (CLAUDE.md, PROJECT.md) is "no magic numbers — spacing/radius via dimens tokens" and `ScaffoldDimens.disabledOverlayOpacity = 0.40` already exists at `lib/theme/scaffold_dimens.dart:133`. `ScaffoldChip` (via `ScaffoldPressable`) and `ScaffoldComposer` route through `ScaffoldDisabledOverlay` which uses the dimens token; `ScaffoldBadge` is the only atom that bypasses it. If a consumer overrides `disabledOverlayOpacity` in their theme extension, the badge will not respect the override.

**Fix:**
```dart
if (disabled) {
  result = Opacity(opacity: dimens.disabledOverlayOpacity, child: result);
}
```

### WR-02: ScaffoldChip hardcodes selected-border width `2.0` instead of using `dimens.focusRingWidth`

**File:** `lib/components/scaffold_chip.dart:97`
**Issue:** `Border.all(color: palette.lightGreenPrimary, width: 2.0)` — `2.0` is a magic number. The dimens token `focusRingWidth = 2.0` (`lib/theme/scaffold_dimens.dart:131`) is exactly the project's "2px accent stroke" constant. If a consumer adjusts `focusRingWidth` for accessibility (e.g., larger stroke for low-vision users), the chip's selected border will not follow.

**Fix:**
```dart
border: selected
    ? Border.all(
        color: palette.lightGreenPrimary,
        width: dimens.focusRingWidth,
      )
    : null,
```

### WR-03: ScaffoldComposer doc contradicts behavior — maxLines=null expands, not "defaults to 1"

**File:** `lib/components/scaffold_composer.dart:59-60, 103`
**Issue:** The DartDoc on `maxLines` reads "Maximum lines for the text field (defaults to 1 via [TextField])". But the field is passed straight through as `maxLines: widget.maxLines`, and `widget.maxLines` defaults to `null`. In Flutter, `TextField(maxLines: null)` does NOT mean "1 line" — it means "expand vertically to fit content" (multi-line auto-grow). The behavior contradicts the documentation, and consumers reading the doc will assume single-line input when in fact the field auto-expands.

**Fix:**
Either fix the doc or fix the default:

```dart
// Option A — match doc:
maxLines: widget.maxLines ?? 1,

// Option B — match behavior, fix the doc:
/// Maximum lines for the text field. When null (the default) the field
/// expands vertically to fit content (TextField auto-grow behavior).
final int? maxLines;
```

### WR-04: data_table.dart.jinja2 pagination uses magic number `999999` for clamp upper bound

**File:** `templates/components/data_table.dart.jinja2:201`
**Issue:** `(widget.items.length / _rowsPerPage).ceil().clamp(1, 999999)` — the `999999` upper clamp is an arbitrary magic number with no semantic meaning. The project prohibits magic numbers; this template will be copied into consumer apps, propagating the lint. The upper bound should either be derived from data or eliminated (the `ceil()` of a non-negative length is always `>= 0` and never realistically approaches 999999).

**Fix:**
```dart
final int totalPages = widget.items.isEmpty
    ? 1
    : (widget.items.length / _rowsPerPage).ceil();
```
The `isEmpty` early-return at line 189 already guards the zero case, so the clamp lower bound is also redundant.

### WR-05: data_table_cell_builder_test does not exercise the actual template output

**File:** `test/components/data_table_cell_builder_test.dart:35-61`
**Issue:** `_CellHost` is a hand-written test-double that "mirrors the post-change template render path exactly". The test verifies the mirror, not the generated `DataTable` widget itself. If `templates/components/data_table.dart.jinja2` drifts from `_CellHost` (e.g., someone edits the template's cell-builder branch), these tests will still pass while the real template is broken. This is a reliability gap: the test gives false confidence about the generated code.

**Fix:**
Either:
1. Regenerate the data-table widget into a fixture under `test/fixtures/` in CI and test against the regenerated output (the same drift-check pattern used elsewhere in the repo, per `.planning/PROJECT.md`), or
2. Promote the cell-builder branch into a small reusable widget in `lib/` that both the template and the test consume directly.

At minimum, add a comment at the top of the template noting that the `_CellHost` test double must be kept in sync.

## Info

### IN-01: Disclosure constructor assert is phrased awkwardly

**File:** `lib/components/scaffold_disclosure.dart:40-44`
**Issue:** `assert(expanded == null || initiallyExpanded == false, ...)` is correct but harder to read than the negated form. Style only.

**Fix:** `assert(!(expanded != null && initiallyExpanded), '...')` — clearer De Morgan form.

### IN-02: Icon and badge sizes use raw literals (8, 16, 24) instead of named constants

**File:** `lib/components/scaffold_badge.dart:140-184`, `lib/components/scaffold_chip.dart:73, 85`
**Issue:** `Container(width: 8, height: 8)`, `Icon(icon, size: 16)`, `ScaffoldStatusIndicator(..., dotSize: 8)`, `Container(width: 24, height: 24)`. These are documented in DartDoc ("8px dot", "16px icon") but are not dimens tokens. The project rule targets "spacing/radius" specifically, so these may be intentional, but a shared `kBadgeDotSize`, `kBadgeIconSize`, `kChipIconSize` private constant would document intent and prevent drift if the design spec changes. Optional cleanup.

**Fix:** Add `static const double _kDotSize = 8;` etc. near the top of each file and reference them.

### IN-03: data_table.dart.jinja2 hardcodes EdgeInsets values (16.0 / 8.0)

**File:** `templates/components/data_table.dart.jinja2:216-219, 346-349, 361`
**Issue:** `EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)` and `EdgeInsets.symmetric(horizontal: 8.0)` — these match `dimens.space8` and `dimens.space4` but are written as raw doubles. The template's stated contract is "standalone M3 — consumes Theme.of(context) directly. No dependency on Riverpod, GeniusTheme, or api_client", and `frontend_scaffold` is a peer package, so pulling `ScaffoldDimens` in may be a deliberate choice. Still worth flagging: the data-table is the only composite that doesn't use the project's dimens tokens.

**Fix:** Either inject `ScaffoldDimens` as a template import (the consuming app already depends on `frontend_scaffold` for the toast/cubit) or add a comment explaining the standalone-M3 contract justifies the raw values.

### IN-04: composer_demo and chip_demo leave several `onPressed: () {}` no-ops

**File:** `example/lib/demos/composer_demo.dart:34, 48, 65, 86, 97`, `example/lib/demos/chip_demo.dart:32, 40, 47, 55, 65, 77, 125-127, 152-155`
**Issue:** Most demo chips and composers use no-op `onPressed`/`onSubmit` callbacks. For an example app whose purpose is teaching, an empty closure doesn't show the consumer *what* to do — particularly the chip-group section where (per CR-02) the per-chip callback is discarded anyway. Minor: a `debugPrint('tapped $index')` or counter would make the demo's interactivity visible.

**Fix:** Add a small visual echo (e.g., a counter or snackbar) to at least one chip / one composer so consumers see the callback contract in action. The `_SubmissionLogComposer` in composer_demo already does this well — extend the pattern.

---

_Reviewed: 2026-08-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
