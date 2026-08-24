# Phase 7: Media & Integration Widgets — Pattern Map

**Mapped:** 2026-08-15
**Files analyzed:** 7 new + 1 modified
**Analogs found:** 7 / 7 (barrel export included)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/components/media_card.dart` | component (composite) | request-response (render-only) | `lib/components/scaffold_card.dart` | exact (same composition, but stateless per D-06) |
| `lib/components/media_controls.dart` | component (composite, internal transient state) | event-driven (callbacks out) | `lib/components/scaffold_pressable.dart` + `scaffold_touch_target.dart` + `scaffold_formatted_value_duration.dart` | role-match (no existing "controls bar" — D-03 pattern) |
| `lib/components/wallet_connect_sheet.dart` | component (presentation wrapper) | request-response (returns `Future<T?>`) | `lib/components/bottom_drawer/bottom_drawer.dart` + `responsive_drawer.dart` | exact |
| `templates/components/media_card.dart.jinja2` | codegen template | render-time | `templates/components/card.dart.jinja2` | exact (minus cubit — D-06) |
| `templates/components/media_card_vars.json` | codegen fixture | static | `templates/components/card_vars.json` | exact |
| `test/components/media_card_test.dart` (and `_controls`, `_wallet_connect_sheet`) | test | n/a | `test/components/scaffold_card_test.dart`, `scaffold_badge_test.dart` | exact |
| `example/lib/demos/media_card_demo.dart`, `media_controls_demo.dart`, `wallet_connect_sheet_demo.dart` (one per widget) | demo | n/a | `example/lib/demos/bottom_drawer_demo.dart`, `kitchen_sink_demo.dart` | exact |
| `lib/frontend_scaffold.dart` (MODIFY) | barrel | static | existing file, append exports in sorted position | exact |

## Pattern Assignments

### `lib/components/media_card.dart` (component, render-only composite)

**Analog:** `lib/components/scaffold_card.dart` (D-06: drop the cubit — widget is `StatelessWidget` per CONTEXT.md D-06)

**Library header pattern** (lines 1-11 of `scaffold_card.dart`) — generated files carry source-schema + generator-version header. Handwritten MediaCard (per D-06) uses the same docstring shape but drops the "Generated from …" lines:

```dart
/// MediaCard -- M3 media card with thumbnail, typed badge slots, and metadata.
///
/// Composes ScaffoldSurface + ScaffoldPressable + ScaffoldBadge (WIDG-29).
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
```

**Theme-token resolution pattern** (lines 139-143 of `scaffold_card.dart`):

```dart
final palette = context.palette;
final dimens = context.dimens;

final BorderRadiusGeometry radius =
    BorderRadius.circular(dimens.borderRadiusCard);
```

**Slot composition + dimens-driven spacing pattern** (lines 146-187 of `scaffold_card.dart`) — this is exactly the pattern for the typed badge slots (D-01) and `metadataRow: List<Widget>` (D-02):

```dart
// Build the card interior — slots.
final List<Widget> slotChildren = <Widget>[];

if (widget.header != null) {
  slotChildren.add(widget.header!);
  if (widget.body != null || widget.actions != null) {
    slotChildren.add(SizedBox(height: dimens.space8));
  }
}
// ... repeat per slot

final Widget cardChild = Padding(
  padding: EdgeInsets.all(dimens.space8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: slotChildren,
  ),
);
```

For badge slots: use `Stack` + `Positioned` (per the badge docstring at `scaffold_badge.dart` lines 11-17: "The badge does NOT position itself — the consumer composes it with a `Stack` + `Positioned`").

**Conditional pressable/disabled wrap** (lines 221-231 of `scaffold_card.dart`):

```dart
if (widget.onTap != null) {
  return ScaffoldPressable(
    onPressed: widget.onTap,
    disabled: widget.disabled,
    child: surface,
  );
}
if (widget.disabled) {
  return ScaffoldDisabledOverlay(disabled: true, child: surface);
}
return surface;
```

**ScaffoldBadge API** (`scaffold_badge.dart` lines 24-36) — the typed slot's value type:

```dart
const ScaffoldBadge({
  super.key,
  this.variant = BadgeVariant.dot,
  this.count = 0,
  this.text,
  this.icon,
  this.badgeColor,
  this.label,
  this.child,
  this.disabled = false,
  this.maxDigits = 2,
});
```

---

### `lib/components/media_controls.dart` (component, event-driven composite)

**Analogs:** `scaffold_pressable.dart`, `scaffold_touch_target.dart`, `scaffold_formatted_value_duration.dart`, `scaffold_motion.dart`.

**D-03 pattern: private StatefulWidget holding only transient scrub state.** No cubit. Modeled on `_ScaffoldPressableState`'s minimal private state (lines 51-96 of `scaffold_pressable.dart`):

```dart
class MediaControls extends StatefulWidget {
  const MediaControls({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.buffered,
    this.onPlayPause,
    this.onSeek,
    this.onToggleMute,
    this.onToggleFullscreen,
    this.isMuted = false,
    this.isFullscreen = false,
    this.showTimeLabels = true,
  });
  // ... final fields, all callbacks optional (VoidCallback? / ValueChanged<Duration>?)

  @override
  State<MediaControls> createState() => _MediaControlsState();
}

class _MediaControlsState extends State<MediaControls> {
  Duration? _scrubbing; // ONLY transient state owned here (D-03)
  // setState only during drag; emit widget.onSeek on release.
}
```

**Button atom pattern** — every play/volume/fullscreen button is a `ScaffoldPressable` (which internally composes `ScaffoldTouchTarget` for 48×48 and registers `Semantics(button: true)`). From `scaffold_pressable.dart` lines 18-46:

```dart
ScaffoldPressable(
  onPressed: widget.onPlayPause,
  child: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow),
)
```

`ScaffoldPressable` already wraps content in `ScaffoldTouchTarget` (line 115) and provides `Semantics(button: true, enabled: …)` (lines 143-147) — so MediaControls buttons inherit Phase 6 D-02 a11y for free.

**Time-label pattern (D-04)** — from `scaffold_formatted_value_duration.dart` lines 17-26:

```dart
ScaffoldFormattedValueDuration(value: widget.position)
// ...
ScaffoldFormattedValueDuration(value: widget.duration)
```

The duration widget already wraps text in `ScaffoldLiveRegion` (line 44), satisfying the a11y requirement.

**Reduced-motion adherence (Phase 6 D-01)** — any opacity/scale animation must read `ScaffoldMotion` and use `ScaffoldMotionDurations.short` + `ScaffoldMotionCurves.standard` (see `scaffold_pressable.dart` lines 161-164 for the canonical `AnimatedOpacity` usage).

---

### `lib/components/wallet_connect_sheet.dart` (component, presentation wrapper)

**Analogs:** `bottom_drawer.dart`, `responsive_drawer.dart`, demo at `example/lib/demos/bottom_drawer_demo.dart`.

**BottomDrawer constructor API** (`bottom_drawer.dart` lines 4-14):

```dart
class BottomDrawer extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final Widget? footer;

  const BottomDrawer({
    super.key,
    required this.children,
    this.title,
    this.footer,
  });
```

**ResponsiveDrawer.show<T>() signature** (`responsive_drawer.dart` lines 5-14) — this is the WalletConnectSheet presentation entry point:

```dart
class ResponsiveDrawer {
  static const double _desktopBreakpoint = 800;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    Widget? footer,
    VoidCallback? onClose,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;
    // Desktop (>=800): right-anchored showDialog, width 400
    // Mobile  (<800):  showModalBottomSheet, isScrollControlled: true
  }
}
```

**WalletConnectSheet shape** — static `show` façade matching the demo pattern at `example/lib/demos/bottom_drawer_demo.dart` lines 7-35:

```dart
class WalletConnectSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required WalletConnectSessionState sessionState, // disconnected | connecting | connected
    // Disconnected:
    Widget Function(BuildContext context, String uri)? qrBuilder, // D-05
    String? uri,
    // Connected:
    String? address,
    String? networkName,
    // Actions:
    VoidCallback? onConnect,   // WIDG-31 — Connect CTA under the QR (disconnected state)
    VoidCallback? onDisconnect,
    VoidCallback? onClose,
  }) {
    return ResponsiveDrawer.show<T>(
      context: context,
      title: /* 'Connect Wallet' | address-truncated | etc. */,
      children: _buildChildren(context, ...), // switch on sessionState
      footer: /* Disconnect button when connected */,
      onClose: onClose,
    );
  }
}
```

The 800px desktop breakpoint is owned by `ResponsiveDrawer` — WalletConnectSheet does NOT re-implement it.

**Address truncation, network chip** — compose from existing atoms per "Claude's Discretion": `ScaffoldBadge(variant: BadgeVariant.text, text: networkName)` for the network chip; `Text` with `overflow: TextOverflow.ellipsis` + `maxLines: 1` (mirrors `scaffold_card.dart` line 184 pattern) for the truncated address.

---

### `templates/components/media_card.dart.jinja2` (codegen template)

**Analog:** `templates/components/card.dart.jinja2`.

**Generated-file header convention** (lines 1-11):

```jinja2
/// {{ widget_class_name }} -- M3 media card with thumbnail, badge slots, metadata.
///
/// Generated from media_card.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/media_card.dart.jinja2
/// Generator version: 0.4.0
/// Composes ScaffoldSurface + ScaffoldPressable + ScaffoldBadge (WIDG-29).
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
```

**D-06 deviation from card.dart.jinja2:** drop the `flutter_bloc` import, drop `_cubit.dart` / `_state.dart` imports, drop `StatefulWidget` + `_{{ widget_class_name }}State` + cubit ownership/didUpdateWidget/dispose logic (lines 92-131 of card.dart.jinja2). Generate a `StatelessWidget` directly:

```jinja2
class {{ widget_class_name }} extends StatelessWidget {
  const {{ widget_class_name }}({
    super.key,
    this.aspectRatio = {{ default_aspect_ratio }},
    this.thumbnail,
    this.topLeftBadge,
    this.topRightBadge,
    this.bottomRightBadge,
    this.metadataRow = const <Widget>[],
    this.onTap,
    this.disabled = false,
  });

  final double aspectRatio;
  final ImageProvider? thumbnail;
  final ScaffoldBadge? topLeftBadge;
  final ScaffoldBadge? topRightBadge;
  final ScaffoldBadge? bottomRightBadge;
  final List<Widget> metadataRow;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    // ... composition per the media_card.dart pattern above
  }
}
```

**Slot convention** (mirrors card.dart.jinja2 lines 149-172): each optional slot is null-checked; spacing inserted via `SizedBox(height: dimens.space8)` between populated slots.

### `templates/components/media_card_vars.json` (codegen fixture)

**Analog:** `templates/components/card_vars.json`.

```json
{
  "_comment": "Fixture variables for standalone rendering of media_card.dart.jinja2. widget_class_name is the generated class name; file_stem is the lower-snake-case filename stem; default_aspect_ratio seeds the default 16:9 aspect (1.777...).",
  "widget_class_name": "MediaCard",
  "file_stem": "media_card",
  "default_aspect_ratio": "16 / 9"
}
```

StrictUndefined (per project constraint): any template reference not present in this fixture must fail at codegen time.

---

### `test/components/media_card_test.dart` / `media_controls_test.dart` / `wallet_connect_sheet_test.dart`

**Analogs:** `test/components/scaffold_card_test.dart`, `scaffold_badge_test.dart`.

**Test harness pattern** (lines 1-22 of `scaffold_card_test.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/media_card.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
```

For widgets that touch motion (MediaControls show/hide): also wrap in `ScaffoldMotion(reducedMotion: false, child: …)` per `scaffold_card_test.dart` lines 14-20.

**Assertion pattern** — find the inner atom, assert against `ScaffoldPalette.defaultPalette` / `ScaffoldDimens.defaultDimens` (lines 25-47 of `scaffold_card_test.dart`, lines 37-69 of `scaffold_badge_test.dart`):

```dart
testWidgets('elevated variant renders ScaffoldSurface with elevation 4 + '
    'deepBlueCardColor', (tester) async {
  await _pump(tester, const ScaffoldCard(variant: 'elevated'));

  final ScaffoldSurface surface =
      tester.widget<ScaffoldSurface>(find.byType(ScaffoldSurface));
  expect(surface.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
  expect(surface.elevation, 4.0);
});
```

**Tap-callback pattern** (lines 60-76 of `scaffold_card_test.dart`):

```dart
int taps = 0;
await _pump(tester, ScaffoldCard(onTap: () => taps++, body: const Text('body')));
await tester.tap(find.byType(ScaffoldPressable));
await tester.pump();
expect(taps, 1);
```

No `sleep_for`. Use `tester.pump()` / `tester.pumpAndSettle()` only.

---

### `example/lib/demos/` — one demo per widget

Phase 7 ships three per-widget demo files: `media_card_demo.dart`, `media_controls_demo.dart`, and `wallet_connect_sheet_demo.dart`.

**Analog:** `example/lib/demos/bottom_drawer_demo.dart` (single-purpose) or `kitchen_sink_demo.dart` (gallery).

**Demo file header convention** (lines 1-16 of `kitchen_sink_demo.dart`) — every demo carries a top-of-file comment block showing how to wire it into `example/lib/main.dart`'s `HomePage` list.

**Demo body pattern** (lines 4-35 of `bottom_drawer_demo.dart`):

```dart
class MediaWidgetsDemo extends StatelessWidget {
  const MediaWidgetsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media widgets')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sections showing each of the three widgets
          ],
        ),
      ),
    );
  }
}
```

Import via the barrel: `import 'package:frontend_scaffold/frontend_scaffold.dart';` (line 2 of `bottom_drawer_demo.dart`) — never via individual component paths.

---

### `lib/frontend_scaffold.dart` (MODIFY)

**Pattern:** Append three lines in alphabetical order within the existing component export block (lines 22-65 of the current file). Components list is currently sorted — insert after `scaffold_live_region.dart` and before `scaffold_motion.dart`:

```dart
export 'components/media_card.dart';
export 'components/media_controls.dart';
```

`wallet_connect_sheet.dart` sorts between `scaffold_touch_target.dart` (line 65) and `desktop_body_container.dart` (line 66). Alphabetically, `wallet_*` comes after the `scaffold_*` group:

```dart
export 'components/wallet_connect_sheet.dart';
```

(Place after the `scaffold_touch_target.dart` line, before `desktop_body_container.dart` — preserves the existing "scaffold_ prefix cluster then un-prefixed widgets" grouping.)

---

## Shared Patterns

### Theme Token Resolution
**Source:** `lib/theme/scaffold_theme.dart`
**Apply to:** All three widgets + template output.

```dart
final palette = context.palette;
final dimens = context.dimens;
```

Never hardcode colors or pixel values. Palette tokens used in this phase: `deepBlueCardColor`, `surfaceElevated`, `borderSubtle`, `deepBlueTertiary`, `textPrimary`, `lightGreenPrimary`. Dimens tokens: `space8`, `borderRadiusCard`, `minTouchTarget`, `radiusPill`, `itemSpacing`.

### Pure Composability (Phase 6 D-04)
**Source:** `scaffold_badge.dart` lines 11-17 (badges don't position themselves), `scaffold_card.dart` lines 146-187 (slots, no layout knowledge).
**Apply to:** MediaCard (badge slots use `Stack` + `Positioned`), MediaControls (caller chooses where to overlay the bar), WalletConnectSheet (sheet body is `children: List<Widget>`).

### A11y Defaults (Phase 6 D-02)
**Source:** `scaffold_pressable.dart` lines 140-148 (`Semantics(button: true, enabled: …)`), `scaffold_touch_target.dart` lines 34-47 (`Semantics(container: true)`), `scaffold_formatted_value_duration.dart` lines 44-52 (`ScaffoldLiveRegion`).
**Apply to:** MediaControls is the most a11y-sensitive widget this phase. Interactive controls MUST be `ScaffoldPressable` (inherits Semantics + 48×48 + focus ring). Time labels MUST use `ScaffoldFormattedValueDuration` (inherits `ScaffoldLiveRegion`).

### Reduced Motion
**Source:** `scaffold_pressable.dart` lines 161-164.
**Apply to:** Any AnimatedOpacity / AnimatedScale in MediaControls.

```dart
AnimatedOpacity(
  opacity: opacity,
  duration: ScaffoldMotionDurations.short,
  curve: ScaffoldMotionCurves.standard,
  child: …,
)
```

### Test Harness
**Source:** `test/components/scaffold_card_test.dart` lines 10-22.
**Apply to:** All three new tests.

```dart
MaterialApp(
  theme: ThemeData(extensions: scaffoldThemeExtensions),
  home: Scaffold(body: Center(child: child)),
)
```

### Generated-File Header
**Source:** `scaffold_card.dart` lines 1-11, `card.dart.jinja2` lines 1-11.
**Apply to:** Generated MediaCard output from `media_card.dart.jinja2`. Handwritten `media_controls.dart` and `wallet_connect_sheet.dart` use the same library-level docstring shape minus the "Generated from …" lines.

## No Analog Found

None — every file has at least one exact-match analog.

## Metadata

**Analog search scope:** `lib/components/`, `lib/theme/`, `templates/components/`, `test/components/`, `example/lib/demos/`
**Files scanned:** 12
**Pattern extraction date:** 2026-08-15
