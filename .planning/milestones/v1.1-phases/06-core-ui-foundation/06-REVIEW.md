---
phase: 06-core-ui-foundation
reviewed: 2026-08-14T00:00:00Z
depth: deep
files_reviewed: 52
files_reviewed_list:
  - lib/theme/scaffold_palette.dart
  - lib/theme/scaffold_dimens.dart
  - lib/theme/scaffold_theme.dart
  - lib/frontend_scaffold.dart
  - lib/utils/breakpoints.dart
  - lib/components/scaffold_motion.dart
  - lib/components/scaffold_surface.dart
  - lib/components/scaffold_touch_target.dart
  - lib/components/scaffold_focus_outline.dart
  - lib/components/scaffold_live_region.dart
  - lib/components/scaffold_overflow_fade.dart
  - lib/components/scaffold_scroll_edge_indicator.dart
  - lib/components/scaffold_responsive_visibility.dart
  - lib/components/scaffold_color_swatch.dart
  - lib/components/scaffold_badge.dart
  - lib/components/scaffold_status_indicator.dart
  - lib/components/scaffold_skeleton.dart
  - lib/components/scaffold_pressable.dart
  - lib/components/scaffold_disabled_overlay.dart
  - lib/components/scaffold_drag_handle.dart
  - lib/components/scaffold_resize_handle.dart
  - lib/components/scaffold_numeric_input.dart
  - lib/components/scaffold_selectable_surface.dart
  - lib/components/scaffold_draggable.dart
  - lib/components/scaffold_drop_target.dart
  - lib/components/scaffold_file_input_surface.dart
  - lib/components/scaffold_dashed_border.dart
  - lib/components/scaffold_card_cubit.dart
  - lib/components/scaffold_card_state.dart
  - lib/components/scaffold_state_view_cubit.dart
  - lib/components/scaffold_state_view_state.dart
  - lib/components/scaffold_search_bar_cubit.dart
  - lib/components/scaffold_search_bar_state.dart
  - lib/components/scaffold_card.dart
  - lib/components/scaffold_state_view.dart
  - lib/components/scaffold_search_bar.dart
  - lib/components/scaffold_formatted_value_number.dart
  - lib/components/scaffold_formatted_value_duration.dart
  - lib/components/scaffold_formatted_value_money.dart
  - lib/components/scaffold_formatted_value_percentage.dart
  - lib/components/scaffold_formatted_value_date.dart
  - lib/components/scaffold_formatted_value_time.dart
  - lib/components/scaffold_selection_indicator_checkbox.dart
  - lib/components/scaffold_selection_indicator_radio.dart
  - lib/components/scaffold_selection_indicator_toggle.dart
  - lib/components/scaffold_animated_display_fade.dart
  - lib/components/scaffold_animated_display_shake.dart
  - lib/components/toast/toast_manager.dart
  - templates/components/card.dart.jinja2
  - templates/components/card_cubit.dart.jinja2
  - templates/components/card_state.dart.jinja2
  - templates/components/search_bar_cubit.dart.jinja2
  - templates/components/search_bar_state.dart.jinja2
  - templates/components/state_view_state.dart.jinja2
  - templates/components/card_vars.json
  - pubspec.yaml
findings:
  critical: 1
  warning: 7
  info: 13
  total: 21
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-08-14
**Depth:** deep (per-file + cross-module call-chain / template-drift analysis)
**Files Reviewed:** 52
**Status:** issues_found

## Summary

Phase 6 delivers a well-structured, mostly-correct atom library. The theme-token
layer (`ScaffoldPalette` / `ScaffoldDimens`) is complete and internally
consistent — every new token is present in the constructor, `defaultPalette` /
`defaultDimens`, `copyWith`, and `lerp`. The hand-written atoms are broadly
faithful to the UI-SPEC.

However, there is one guaranteed runtime crash, a pervasive layout-inflation
bug in the canonical touch-target atom, and several correctness/a11y gaps. The
plain-Cubit conversion is only half-done: hydration was removed from the cubits
but the state classes retain dead `toJson`/`fromJson` plus stale "hydrated_bloc"
documentation, and the composites still create their Cubits *inside* their own
`build` (so the `variant`/`state` parameters are non-reactive and the cubits are
not drivable from the parent). The Jinja2 templates have a real drift defect —
they parameterize the class name but hardcode the import filenames.

Severity is reported as **BLOCKER / MAJOR / MINOR / COSMETIC** (mapped to the
canonical `critical` / `warning` / `info` tiers in the frontmatter).

---

## Critical Issues

### CR-01 [BLOCKER]: `ScaffoldMotion.of` throws with no ancestor, crashing the library's own composites

**File:** `lib/components/scaffold_motion.dart:55-64`
**Issue:** `ScaffoldMotion.of` throws `FlutterError` when no `ScaffoldMotion`
ancestor is present. Eight atoms call it with no fallback:
`scaffold_skeleton.dart:68` and all seven `scaffold_animated_display_*.dart`
(`fade:110`, `shake:107`, `scale:112`, `slide:115`, `pulse:110`, `bounce:107`,
`rotate:115`). The knock-on effect is that **`ScaffoldStateView` crashes in its
default loading state** — `scaffold_state_view.dart:154-156` renders
`ScaffoldSkeleton(width: 240, height: 128)`, which calls `ScaffoldMotion.of`
and throws. A consumer who drops `ScaffoldStateView(state: 'loading')` (or any
skeleton / animated-display atom) into a screen without an *undocumented*
`ScaffoldMotion` ancestor gets a hard `FlutterError`, not a graceful render.

This is inconsistent with the rest of the library's fallback philosophy:
`context.palette` / `context.dimens` fall back to `defaultPalette` /
`defaultDimens`, but `ScaffoldMotion` has no equivalent default.

**Fix:** Default to `reducedMotion: false` instead of throwing (matching the
theme-token fallback pattern):

```dart
static ScaffoldMotion of(BuildContext context) {
  return context
          .dependOnInheritedWidgetOfExactType<ScaffoldMotion>() ??
      const ScaffoldMotion(reducedMotion: false, child: SizedBox.shrink());
}
```

---

## Warnings

### WR-01 [MAJOR]: `ScaffoldTouchTarget` unconditionally inflates every child by 24px

**File:** `lib/components/scaffold_touch_target.dart:38-40`
**Issue:** The atom wraps `child` in `Padding(padding: EdgeInsets.all(touchTargetPadding))`
(12px) *inside* `ConstrainedBox(minWidth/minHeight: 48)`. The padding is applied
unconditionally, not "only when the child is smaller" as the UI-SPEC states.
Concrete failure: a 48px child becomes 72px; a full-width child gains 12px of
unrequested padding on every side. Because `ScaffoldPressable` always wraps its
child in `ScaffoldTouchTarget` (`scaffold_pressable.dart:113`), **every**
interactive atom and composite is affected — `ScaffoldCard(onTap: ...)` gets an
unexpected 12px inset around its surface, and `ScaffoldSelectableSurface`
renders its selected border 12px outside the actual content.

**Fix:** Enforce the minimum with `ConstrainedBox` alone and drop the
unconditional padding (or pad only the deficit). The `ConstrainedBox` already
guarantees the 48px hit area:

```dart
child: ConstrainedBox(
  constraints: BoxConstraints(
    minWidth: resolvedMinWidth,
    minHeight: resolvedMinHeight,
  ),
  child: child,
),
```

---

### WR-02 [MAJOR]: `ScaffoldBadge` renders every variant in a fixed 48×48 box

**File:** `lib/components/scaffold_badge.dart:86-91`
**Issue:** The badge visual is wrapped in
`SizedBox(width: minTouchTarget, height: minTouchTarget, child: Center(...))`.
The `BadgeVariant.dot` is documented as an 8px circle and the count variant as a
min-20px pill, but both now occupy a 48×48 footprint. When a consumer composes
`Stack` + `Positioned` (the documented pattern), the invisible 48×48 box overlaps
the underlying icon/avatar and pushes the visible dot/count 20px off the corner.
The badge is not interactive (no `onTap`), so a 48px "hit area" serves no
purpose.

**Fix:** Remove the `SizedBox(minTouchTarget)` wrapper; render `visual` directly
and let the caller position it. If an interactive badge is ever needed, it should
opt into `ScaffoldTouchTarget` explicitly.

---

### WR-03 [MAJOR]: `ScaffoldSearchBar._handleQueryChanged` emits on a closed cubit

**File:** `lib/components/scaffold_search_bar.dart:192-203`
**Issue:** After `await widget.onSearch?.call(value)`, the `catch` block calls
`cubit.failSearch(e.toString())` with no `mounted` / is-closed guard. If the
widget is disposed while `onSearch` is in flight (user navigates away), `dispose`
runs `_cubit.close()` (`:214`), and the late-failing future then calls `emit`
on a closed cubit — throwing `StateError('Cannot emit new states after calling
close')` as an unhandled async error.

**Fix:** Guard the post-await path:

```dart
} catch (e) {
  if (mounted && !cubit.isClosed) {
    cubit.failSearch(e.toString());
  }
}
```

---

### WR-04 [MAJOR]: Composites create their Cubit inside `build`, making params non-reactive and the cubit un-drivable

**File:** `lib/components/scaffold_card.dart:80-84`, `lib/components/scaffold_state_view.dart:127-131`
**Issue:** `BlocProvider(create: (_) => ScaffoldCardCubit(initialVariant: variant))`
is created *inside* the widget's own `build`. Two consequences:
1. `variant` / `state` / `instanceId` are captured once; a parent rebuild with a
   new `variant` (e.g. `'elevated'` → `'filled'`) is silently ignored because
   `create` only runs on first mount.
2. The cubit is a *descendant* of the widget, so the parent cannot
   `context.read<ScaffoldStateViewCubit>()` to drive `showLoading()` /
   `showError(...)` — the runtime state-flipping the docs advertise
   (`scaffold_state_view_cubit.dart:26-30`) is only reachable from *inside* the
   widget's own slot children.

`ScaffoldSearchBar` has the same shape but uses `BlocProvider.value`
(`scaffold_search_bar.dart:227`) with a `late final` cubit created in
`initState`, so its `instanceId` is equally frozen.

**Fix:** Accept an optional cubit (or `Bloc`) and use `BlocProvider.value` when
supplied, so parents can own and drive the cubit; otherwise keep `create:` but
add a `didUpdateWidget` path (or `key`) so parameter changes propagate.

---

### WR-05 [MAJOR]: Templates hardcode import filenames while parameterizing class names

**File:** `templates/components/card.dart.jinja2:22-23`, `templates/components/card_cubit.dart.jinja2:12`, `templates/components/search_bar_cubit.dart.jinja2:12`
**Issue:** The templates use `{{ widget_class_name }}` for the emitted class, but
the imports are hardcoded literals:

```jinja
import 'scaffold_card_cubit.dart';
import 'scaffold_card_state.dart';
```

Rendering `card.dart.jinja2` with `widget_class_name: "MyCard"` produces a
`MyCard` class that imports `scaffold_card_cubit.dart` — the wrong file, or a
missing one. The `widget_class_name` fixture variable is therefore a lie: the
template is only correct for exactly `ScaffoldCard` / `ScaffoldSearchBar`. This
is a drift trap for any future consumer or generated variant.

**Fix:** Derive the import paths from the fixture (e.g. a `file_stem` variable,
or lower-snake-case `widget_class_name`), and add a generation test that renders
a non-`Scaffold*` name and asserts the file compiles.

---

### WR-06 [MAJOR]: `ScaffoldNumericInput` focus state is dead and buttons are not keyboard-accessible

**File:** `lib/components/scaffold_numeric_input.dart:155`, `:176-202`
**Issue:** The control wraps itself in `ScaffoldFocusOutline(child: content)`
with **no `focusNode`**. `ScaffoldFocusOutline` creates an internal `FocusNode`
that nothing ever focuses (`scaffold_focus_outline.dart:46-47`), so
`_hasFocus` is always false and the "focused" ring can never render. The
increment/decrement buttons are `GestureDetector` + `Semantics(button:true)`
with no `Focus` wrapper, so they are not keyboard-focusable and do not respond
to Enter/Space — violating the a11y contract ("ScaffoldNumericInput |
spinButton | increasedValue/decreasedValue" and "participate in focus order").
No `SemanticsRole.spinButton` and no `increasedValue`/`decreasedValue`
semantics are set.

**Fix:** Give the buttons `Focus` nodes (or use `InkWell`/`IconButton`) and pass
a real `focusNode` to `ScaffoldFocusOutline`; add `SemanticsRole.spinButton`
with `increasedValue`/`decreasedValue`.

---

### WR-07 [MAJOR]: `ScaffoldPressable._enabled` requires `onPressed`, silently disabling long-press-only and drag sources

**File:** `lib/components/scaffold_pressable.dart:81`
**Issue:** `bool get _enabled => !widget.disabled && widget.onPressed != null;`
gates *all* interaction — including `onLongPress`. A consumer who supplies only
`onLongPress` (or `ScaffoldSelectableSurface(onLongPress: ...)`) gets a pressable
that does nothing, because every `GestureDetector` callback and the keyboard
handler are nulled by `!_enabled`. The same defect makes `ScaffoldDraggable`
render as a **disabled** button to screen readers: it wraps its
`LongPressDraggable` in `ScaffoldPressable(onLongPress: null)` with no
`onPressed` (`scaffold_draggable.dart:82`), so its `Semantics(button: true,
enabled: false)` announces "disabled" for a perfectly interactive drag source.

**Fix:** Split the gate: `bool get _enabled => !widget.disabled &&
(widget.onPressed != null || widget.onLongPress != null)`. Give `ScaffoldDraggable`
an explicit `enabled` semantics path rather than a disabled `ScaffoldPressable`.

---

## Info

### IN-01 [MINOR]: `ScaffoldBadge.maxDigits` is non-functional

**File:** `lib/components/scaffold_badge.dart:156-161`
**Issue:** `_truncatedCount` only truncates when `count > 99 && maxDigits == 2`.
The `maxDigits` parameter does nothing for any other value (e.g. `maxDigits: 3`
still returns `"1000"`; `maxDigits: 1` still returns `"10"`), and the threshold
`99` is hardcoded rather than derived (`10^maxDigits - 1`).

---

### IN-02 [MINOR]: NumericInput does not quantize increment results to `decimalPlaces`

**File:** `lib/components/scaffold_numeric_input.dart:72-88`
**Issue:** `onChanged(widget.value + widget.step)` emits the raw floating-point
sum. For `value: 0.1, step: 0.2`, the consumer receives `0.30000000000000004`
while the display shows `"0.3"` via `toStringAsFixed`. The emitted value drifts
from what is displayed. Consider quantizing to `decimalPlaces` (or snapping to
`step`) before firing `onChanged`.

---

### IN-03 [MINOR]: Selection indicators omit `SemanticsRole`

**File:** `lib/components/scaffold_selection_indicator_checkbox.dart:55-60`, `..._radio.dart:49-54`, `..._toggle.dart:51-56`
**Issue:** The a11y contract requires `SemanticsRole.checkbox` / `radio` /
`switch`. The generated code only sets `checked:` / `mixed:` /
`inMutuallyExclusiveGroup:` / `toggled:` flags — no `role:` — so screen readers
do not announce these as checkboxes/radios/switches.

---

### IN-04 [MINOR]: `ScaffoldScrollEdgeIndicator` ignores controller changes

**File:** `lib/components/scaffold_scroll_edge_indicator.dart:39-48`
**Issue:** The listener is attached in `initState` and removed in `dispose`, but
there is no `didUpdateWidget`. If a parent rebuilds with a different
`scrollController`, the new controller is never listened to and the old one keeps
a stale listener.

---

### IN-05 [MINOR]: `ScaffoldFocusOutline` leaks its internal node on external-node transition

**File:** `lib/components/scaffold_focus_outline.dart:53-61`, `:81-84`
**Issue:** When the widget transitions from an internal `FocusNode`
(`widget.focusNode == null`) to an external one, the internal node is dropped
without `dispose()` (`didUpdateWidget` only `removeListener`s it), leaking the
node. `dispose()` then skips disposal because `widget.focusNode != null`.
Additionally, the no-`focusNode` fallback node is never focusable, so the ring
can never show for callers that omit `focusNode` (this is why NumericInput's
focus state is dead — see WR-06).

---

### IN-06 [MINOR]: Hydration leftovers — dead `toJson`/`fromJson` and stale docs

**File:** `lib/components/scaffold_card_state.dart:7-9,48-64`, `..._state_view_state.dart:7-14,64-82`, `..._search_bar_state.dart:7-12,66-80`
**Issue:** The plain-Cubit conversion removed `hydrated_bloc` from the cubits,
but the state classes still generate `toJson`/`fromJson` (now dead code) and the
doc headers still claim "All fields are persisted via hydrated_bloc" /
"query is persisted via hydrated_bloc". The `instanceId` field on all three
cubits is likewise now vestigial (kept "for API compatibility"). The widget
templates still say "Consumes ... Cubit (hydrated_bloc)" (`card.dart.jinja2:10`,
`scaffold_card.dart:10`). Flag as documentation/code drift to clean up in the
templates (not hand-edit generated files).

---

### IN-07 [MINOR]: `copyWith` cannot reset nullable fields to null

**File:** `lib/components/scaffold_card_state.dart:38-46`, `..._state_view_state.dart:52-59`, `..._search_bar_state.dart:51-61`
**Issue:** All three use `field ?? this.field`. Because `lastAction`, `lastError`,
and `errorMessage` are nullable, there is no way to clear them once set. In
`ScaffoldSearchBarCubit`, a failed search leaves `errorMessage` sticky until
`clearQuery()`/`reset()` — `updateQuery` cannot clear it. The classic fix is a
sentinel (e.g. `Object? errorMessage = _unset`) or an explicit `clearX` method.

---

### IN-08 [MINOR]: FormattedValue variants deviate from the spec's formatting contract

**File:** `lib/components/scaffold_formatted_value_date.dart:56-76`, `..._duration.dart:56-65`, `..._percentage.dart:60-65`
**Issue:**
- Date: hardcoded English month abbreviations; no `locale`/`pattern` parameter
  (spec: "configurable locale/pattern").
- Duration: always renders `H:MM:SS`; the spec's "M:SS depending on magnitude"
  is not implemented, and negative durations produce garbage (`"-01:-30:00"`).
- Percentage: multiplies the input by 100, assuming a 0–1 ratio, but this
  convention is undocumented — passing `42.5` yields `"4250.0%"`.

---

### IN-09 [MINOR]: `ScaffoldDropTarget.acceptType` uses runtime-type equality

**File:** `lib/components/scaffold_drop_target.dart:72-76`
**Issue:** `data.runtimeType == acceptType` fails for interface/abstract types and
for `File` (whose runtime type is the private `_File`). `acceptType: File`
would never match a dropped `File`. `ScaffoldFileInputSurface` correctly avoids
this by using `acceptCondition: (d) => d is File`
(`scaffold_file_input_surface.dart:115`), so the `acceptType` knob is a
footgun rather than a usable API.

---

### IN-10 [MINOR]: Disabled atoms remain keyboard-focusable

**File:** `lib/components/scaffold_pressable.dart:138-150`, `lib/components/scaffold_disabled_overlay.dart:41-48`
**Issue:** `ScaffoldDisabledOverlay` uses `IgnorePointer`, which blocks pointer
input but not keyboard focus. A disabled `ScaffoldPressable` keeps its `Focus`
node in the traversal order (tab reaches it, Enter is ignored). The spec's
disabled contract ("block ... focus") is not met.

---

### IN-11 [MINOR]: Hardcoded user-facing strings in a "no hardcoded copy" library

**File:** `lib/components/scaffold_badge.dart:171`, `scaffold_drag_handle.dart:40`, `scaffold_resize_handle.dart:52`, `scaffold_card.dart:130`, `scaffold_state_view.dart:174/195`, `scaffold_file_input_surface.dart:84/170/184`, `scaffold_drop_target.dart:145-147/216-222`
**Issue:** Multiple atoms embed English strings: `"New item"`, `"Drag to reorder"`,
`"Drag to resize"`, `"No content"`, `"Retry"`, `"File is too large"`,
`"Valid file"` / `"Invalid file"`, `"Drop zone. ..."`. The copywriting contract
(UI-SPEC) requires Waves 0–2 atoms to contain no user-facing strings and error
copy to come from the consumer. A11y labels are the one sanctioned exception
(D-02), but validation messages and the `"Retry"` button label are not.

---

### IN-12 [MINOR]: Likely-orphaned dependencies after hydration removal

**File:** `pubspec.yaml:14-15`
**Issue:** `equatable: ^2.0.5` and `bloc_concurrency: ^0.3.0` have no usages in
`lib/` (grep found none). `hydrated_bloc` was correctly removed, but these two
appear to have become orphaned along with it. Verify before removing — they may
be consumed by a sibling package via the barrel.

---

### IN-13 [COSMETIC]: Degenerate `dashLength`/`gapLength` can hang the painter

**File:** `lib/components/scaffold_dashed_border.dart:84-93`
**Issue:** The `while (distance < metric.length)` loop advances by
`dashLength + gapLength`. If both are `0` (or the sum is `<= 0`), `distance`
never advances and the paint hangs. Defaults are safe, but there is no guard
against a consumer-supplied zero/negative value.

---

_Reviewed: 2026-08-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
