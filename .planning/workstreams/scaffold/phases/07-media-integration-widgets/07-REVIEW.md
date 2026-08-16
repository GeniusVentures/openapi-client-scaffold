---
phase: 07-media-integration-widgets
reviewed: 2026-08-15T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - lib/components/media_card.dart
  - lib/components/media_controls.dart
  - lib/components/wallet_connect_sheet.dart
  - lib/frontend_scaffold.dart
  - templates/components/media_card.dart.jinja2
  - templates/components/media_card_vars.json
  - test/components/media_card_test.dart
  - test/components/media_controls_test.dart
  - test/components/wallet_connect_sheet_test.dart
  - example/lib/demos/media_card_demo.dart
  - example/lib/demos/media_controls_demo.dart
  - example/lib/demos/wallet_connect_sheet_demo.dart
  - example/lib/main.dart
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-08-15
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Reviewed the three new widgets (MediaCard, MediaControls, WalletConnectSheet), the barrel export, the media_card Jinja2 template + vars, three test files, three demo files, and the example app main. The widgets are correctly theme-token-driven in their outer shells, and the D-03 / D-05 design constraints are honored (no cubit, no QR dependency). However, there is one Critical a11y bug pattern repeated across all interactive controls, and several theme-token violations in WalletConnectSheet and MediaControls that contradict the "no hardcoded dimensions" rule. Demos contain one hardcoded color. Test for MediaControls has a subtle gesture-coordinate computation that works but is fragile.

## Critical Issues

### CR-01: Missing semantic labels on all icon-only buttons and on the seekbar

**Files:**
- `lib/components/media_controls.dart:200-205` (play/pause)
- `lib/components/media_controls.dart:230-237` (mute)
- `lib/components/media_controls.dart:238-245` (fullscreen)
- `lib/components/media_controls.dart:189-195` (slider)
- `lib/components/media_card.dart:154-160` (card pressable, no label)
- `lib/components/wallet_connect_sheet.dart:106-121` (Connect CTA — has text so OK)
- `lib/components/wallet_connect_sheet.dart:185-200` (Disconnect CTA — has text so OK)

**Issue:** Every interactive control in `MediaControls` is an icon-only `ScaffoldPressable` with no `Semantics(label:)`. Screen readers will announce these as "button" with no name, so a VoiceOver / TalkBack user cannot tell play from mute from fullscreen. The `Slider` also gets no `semanticFormatterCallback` or label, so its value is announced as a raw 0..1 fraction with no units. This is a hard WCAG 4.1.2 (Name, Role, Value) violation. The project goal of M3-quality widgets requires accessible names on every icon-only control.

`ScaffoldPressable` itself registers only `Semantics(button: true, enabled: ...)` — it has no `label` parameter, so callers cannot add a label without wrapping in another `Semantics`. The cleanest fix is to add an optional `semanticLabel` to `ScaffoldPressable` and pass it through.

**Fix:**
```dart
// In scaffold_pressable.dart — add to constructor + fields:
final String? semanticLabel;
// In build, replace:
Semantics(button: true, enabled: _enabled, child: content)
// with:
Semantics(
  button: true,
  enabled: _enabled,
  label: widget.semanticLabel,
  child: content,
)

// In media_controls.dart:
ScaffoldPressable(
  semanticLabel: widget.isPlaying ? 'Pause' : 'Play',
  onPressed: widget.onPlayPause,
  child: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow),
)
ScaffoldPressable(
  semanticLabel: widget.isMuted ? 'Unmute' : 'Mute',
  onPressed: widget.onToggleMute,
  ...
)
ScaffoldPressable(
  semanticLabel: widget.isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
  onPressed: widget.onToggleFullscreen,
  ...
)

// Slider:
Slider(
  value: ...,
  semanticFormatterCallback: (double v) {
    final Duration d = Duration(
      milliseconds: (v * widget.duration.inMilliseconds).round(),
    );
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  },
  ...
)

// MediaCard — add `semanticLabel` parameter and forward to ScaffoldPressable.
```

## Warnings

### WR-01: Hardcoded dimensions in WalletConnectSheet violate theme-token rule

**File:** `lib/components/wallet_connect_sheet.dart:105, 109-111, 122-124, 136-138, 141-143, 164-166, 187-190`

**Issue:** The sheet hardcodes `EdgeInsets.only(top: 16)`, `EdgeInsets.symmetric(horizontal: 16, vertical: 8)`, `EdgeInsets.symmetric(vertical: 24)`, `EdgeInsets.only(top: 8)`, `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`. The project rule is "no hardcoded colors or dimensions — only via `context.palette` / `context.dimens`". These should be `dimens.space8` (16), `dimens.space4` (8), `dimens.space12` (24). If a host app overrides `ScaffoldDimens` to a tighter or looser scale, this sheet will not adapt.

**Fix:**
```dart
// At top of _childrenFor and _footerFor (or use Builder):
final dimens = context.dimens;

Padding(padding: EdgeInsets.only(top: dimens.space8), ...)
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: dimens.space8,
    vertical: dimens.space4,
  ),
  ...
)
Padding(padding: EdgeInsets.symmetric(vertical: dimens.space12), ...)
Padding(padding: EdgeInsets.only(top: dimens.space4), ...)
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: dimens.space8,
    vertical: dimens.space6,
  ),
  ...
)
```

### WR-02: Hardcoded `Container(height: 4.0)` for buffered layer in MediaControls

**File:** `lib/components/media_controls.dart:180-186`

**Issue:** The buffered bar's thickness is hardcoded to `4.0` logical pixels. Every other dimension in the widget goes through `dimens`. A host app that scales `ScaffoldDimens` (e.g., for TV / large-format) cannot scale the buffered bar. The played-position bar that the `Slider` paints is internally themed via `SliderTheme`, so the buffered layer's height must track the slider's track height for visual alignment — a hardcoded `4.0` only matches Material's default and will misalign if the host overrides `SliderThemeData.trackHeight`.

**Fix:** Add a `trackHeight` token to `ScaffoldDimens` (e.g., `mediaControlsTrackHeight`) and use it for both the `Container(height: ...)` and a `SliderTheme` override wrapping the `Slider`. At minimum, source it from `SliderTheme.of(context).trackHeight ?? 4.0` so it stays aligned with the active slider theme.

### WR-03: `WalletConnectSheet.show` passes the *caller's* `BuildContext` to `qrBuilder`

**File:** `lib/components/wallet_connect_sheet.dart:56-63, 102`

**Issue:** `_childrenFor(context, ...)` is invoked synchronously with the caller's `BuildContext` (the one the consumer passed into `show`), and that same context is forwarded into `qrBuilder(context, uri)`. The standard Flutter contract for sheet/dialog builders (see `showModalBottomSheet`, `showDialog`) is that the builder receives the **sheet's own** `BuildContext` — the one inside the modal route — so consumers can call `Navigator.of(ctx).pop()`, look up the modal's `Theme`, or read inherited widgets scoped inside the sheet. Here, a consumer's `qrBuilder` that calls `Navigator.of(context).pop()` will pop the *underlying* page, not the sheet. The demo at `example/lib/demos/wallet_connect_sheet_demo.dart:33` sidesteps this only because its `qrBuilder` does not use the context.

**Fix:** Build the children lazily inside the modal route. Change `ResponsiveDrawer.show` to accept a `Widget Function(BuildContext)` builder, or wrap the children in a `Builder` inside the sheet content:
```dart
return ResponsiveDrawer.show<T>(
  context: context,
  title: title,
  children: <Widget>[
    Builder(
      builder: (BuildContext sheetContext) {
        // ... invoke qrBuilder with sheetContext
        return Column(children: _childrenFor(sheetContext, ...));
      },
    ),
  ],
  ...
);
```

### WR-04: `_childrenFor` snapshots theme at `show()` time — stale on theme change

**File:** `lib/components/wallet_connect_sheet.dart:97, 116, 126, 145, 159`

**Issue:** `_childrenFor` reads `Theme.of(context).textTheme` once at `show()` time and embeds the resulting `TextStyle` into the `Text` widgets. If the host app toggles theme (light/dark, palette override) while the sheet is open, the sheet's text styles will not rebuild. Every other scaffold widget resolves theme inside `build()` so it tracks theme changes. Combined with WR-03 this is the same root cause — children are computed outside the modal's build lifecycle.

**Fix:** Same as WR-03 — defer child construction into a `Builder` inside the modal route so `Theme.of(sheetContext)` is re-evaluated on rebuild.

### WR-05: `MediaCard` test "disabled + onTap" asserts behavior owned by `ScaffoldPressable`

**File:** `test/components/media_card_test.dart:208-226`

**Issue:** The test name says "wraps in ScaffoldDisabledOverlay", but in the `onTap != null && disabled == true` path, `MediaCard` itself does NOT wrap in `ScaffoldDisabledOverlay` — it delegates to `ScaffoldPressable(disabled: true, ...)`, which internally applies the overlay. The test only passes because it uses `findsWidgets` (which matches zero or more) and because `ScaffoldPressable` happens to insert the overlay internally. If `ScaffoldPressable` were ever refactored to disable via `IgnorePointer` only, this test would silently still pass (zero matches satisfies `findsWidgets`) while the visible dim disappears. The assertion is too weak to catch a real regression.

**Fix:** Strengthen the assertion:
```dart
expect(find.byType(ScaffoldDisabledOverlay), findsOneWidget);
expect(find.byType(IgnorePointer), findsWidgets);
```
And/or also assert that the `ScaffoldPressable` itself was built with `disabled: true`:
```dart
final ScaffoldPressable p = tester.widget(find.byType(ScaffoldPressable));
expect(p.disabled, isTrue);
```

### WR-06: `MediaControls` scrub test gesture math is fragile

**File:** `test/components/media_controls_test.dart:137-145`

**Issue:** The drag start offset is computed as
```dart
final Offset sliderTopLeft = tester.getTopLeft(find.byType(Slider));
final Offset sliderSize =
    tester.getSize(find.byType(Slider)).bottomCenter(Offset.zero) -
        sliderTopLeft;
```
`Size.bottomCenter(Offset.zero)` returns `Offset(width / 2, height)`. Subtracting `sliderTopLeft` (a global coordinate) from this produces a value that is no longer a clean size — it's `(width/2 - left, height - top)`. The subsequent `sliderSize.dx / 4` is therefore not "a quarter of the slider's width"; it's "half the width minus the left offset, divided by 4". The test happens to pass because the slider fills most of the harness width and the start offset is small, but this is a latent bug that will flake if the harness layout changes (e.g., adding padding).

**Fix:**
```dart
final Size sliderSize = tester.getSize(find.byType(Slider));
final Offset sliderTopLeft = tester.getTopLeft(find.byType(Slider));
final Offset start = sliderTopLeft + Offset(4, sliderSize.height / 2);
final TestGesture gesture = await tester.startGesture(start);
await gesture.moveBy(Offset(sliderSize.width / 4, 0));
```

## Info

### IN-01: MediaCard doc comment over-promises on `ScaffoldDisabledOverlay`

**File:** `lib/components/media_card.dart:25-26`

**Issue:** "When [onTap] is non-null the card is wrapped in a [ScaffoldPressable]; when [disabled] is true a [ScaffoldDisabledOverlay] blocks interaction." In the `onTap != null && disabled == true` path, MediaCard returns `ScaffoldPressable(disabled: true, ...)` directly — the overlay is applied by `ScaffoldPressable` internally, not by `MediaCard`. The comment is technically accurate about the *visual* outcome but misleads readers about which widget owns the behavior. Minor.

**Fix:** Rephrase: "When [disabled] is true, interaction is blocked — either via [ScaffoldPressable]'s internal disabled state (when [onTap] is set) or via an explicit [ScaffoldDisabledOverlay] wrapper."

### IN-02: `WalletConnectSheet` duplicates the address as both title and body

**File:** `lib/components/wallet_connect_sheet.dart:83-84, 154-161`

**Issue:** When connected and `address` is non-null, the address is shown twice — once as the sheet title (`_titleFor` returns `address`) and once as the body text. On mobile bottom sheets this is visually redundant and consumes vertical space. Consider returning a static label like `'Wallet'` or `'Connected'` from `_titleFor` and letting the body own the address.

**Fix:** Either return a static title for the connected state, or omit the body address when the title already shows it.

### IN-03: `WalletConnectSheetDemo` uses hardcoded `Colors.black12`

**File:** `example/lib/demos/wallet_connect_sheet_demo.dart:37`

**Issue:** The QR placeholder uses `Colors.black12`. Demos are illustrative, but the project rule against hardcoded colors is unqualified, and other demos consistently use `context.palette`. A light-theme user will see a barely-visible gray box; a dark-theme user will see a jarring near-black box.

**Fix:** Use `color: context.palette.borderSubtle` (or another palette token) for the placeholder.

### IN-04: MediaControls Demo note is stale — Plan 07-04 has already landed

**File:** `example/lib/demos/media_controls_demo.dart:25-28`

**Issue:** The comment says "Plan 07-04 owns the barrel export for media_controls. To keep this plan scoped to its own files, this demo imports the component directly." But `lib/frontend_scaffold.dart:46` already exports `media_controls.dart`, and this demo file already imports `frontend_scaffold/frontend_scaffold.dart` on line 30. The comment is stale — the demo is in fact using the barrel import.

**Fix:** Delete the stale comment block (lines 25-28).

---

_Reviewed: 2026-08-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
