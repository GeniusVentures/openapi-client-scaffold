# Phase 9: Text & Code Primitives - Pattern Map

**Mapped:** 2026-08-20
**Files analyzed:** 12 (3 atoms × triple + 3 support parts + 3 demos + barrel)
**Analogs found:** 12 / 12

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/components/scaffold_streaming_rich_text.dart` | component (widget) | streaming (typed span tree) | `lib/components/scaffold_card.dart` (optional-cubit fallback) | exact pattern + role-match |
| `lib/components/scaffold_streaming_rich_text_cubit.dart` | cubit | streaming state | `lib/components/scaffold_card_cubit.dart` | exact |
| `lib/components/scaffold_streaming_rich_text_state.dart` | state | immutable copyWith | `lib/components/scaffold_card_state.dart` | exact |
| `lib/components/scaffold_code_block.dart` | component (widget) | request-response (static lines) + streamed line insertion | `lib/components/scaffold_chip.dart` (small stateless atom + slots) | role-match |
| `lib/components/scaffold_selection_actions.dart` | component (wrapper widget) | event-driven (selection changes → toolbar overlay) | `lib/components/scaffold_selectable_surface.dart` (selection wrap) + `lib/components/scaffold_disclosure.dart` (animated reveal) | role-match |
| `lib/utils/scaffold_rich_spans.dart` (typed span model — sealed classes) | model / utility | data-shape only | `TraceItem` in `lib/components/scaffold_trace_list.dart` (in-file DTO) | role-match |
| `lib/utils/markdown_to_spans.dart` (Markdown→span mapper, support part) | utility / transform | transform | none — greenfield (D-08 isolates the dep) | no analog |
| `lib/utils/light_syntax_tokenizer.dart` (light syntax tokenizer, support part) | utility / transform | transform | none — greenfield | no analog |
| `lib/utils/streaming_announce_policy.dart` (announce-policy hook + defaults) | utility / policy | event-driven (debounce + boundary detection) | `lib/components/scaffold_live_region.dart` (announcement sink) | role-match (sink only) |
| `lib/components/scaffold_streaming_copy_button.dart` (support copy action, optional) | component (small button) | request-response (transient "copied" state) | `lib/components/scaffold_chip.dart` icon-only variant + `scaffold_pressable.dart` | exact pattern |
| `lib/components/scaffold_selection_copy_action.dart` (support selection copy action, optional) | component (small button) | request-response | `lib/components/scaffold_chip.dart` icon-only variant | exact pattern |
| `lib/frontend_scaffold.dart` (barrel — add new exports) | barrel | static | existing barrel | exact |
| `test/components/scaffold_streaming_rich_text_test.dart` | test | widget test | `test/components/scaffold_chip_test.dart` | exact |
| `test/components/scaffold_code_block_test.dart` | test | widget test | `test/components/scaffold_chip_test.dart` | exact |
| `test/components/scaffold_selection_actions_test.dart` | test | widget test | `test/components/scaffold_chip_test.dart` + `scaffold_live_region_test.dart` | exact |
| `example/lib/demos/streaming_rich_text_demo.dart` | demo | composition | `example/lib/demos/chip_demo.dart` | exact |
| `example/lib/demos/code_block_demo.dart` | demo | composition | `example/lib/demos/chip_demo.dart` | exact |
| `example/lib/demos/selection_actions_demo.dart` | demo | composition | `example/lib/demos/chip_demo.dart` | exact |
| `example/lib/main.dart` (register demos) | demo index | static | existing `_DemoTile` entries | exact |
| `templates/components/streaming_rich_text.dart.jinja2` + `_cubit.dart.jinja2` + `_state.dart.jinja2` + `_vars.json` (optional, D-01 convenience variants) | template | codegen | `templates/components/card.dart.jinja2` family | exact |
| `templates/components/code_block.dart.jinja2` + `_vars.json` (optional) | template | codegen | `templates/components/card.dart.jinja2` family | exact |
| `templates/components/selection_actions.dart.jinja2` + `_vars.json` (optional) | template | codegen | `templates/components/card.dart.jinja2` family | exact |

---

## Pattern Assignments

### `lib/components/scaffold_streaming_rich_text.dart` (component, streaming)

**Analog:** `lib/components/scaffold_card.dart` (lines 45–236)

**Header / file docstring pattern** (lines 1–11 of scaffold_card.dart):
```dart
/// ScaffoldCard -- M3 card with configurable variant and content slots.
///
/// Generated from card.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/card.dart.jinja2
/// Generator version: 0.4.0
/// Composes ScaffoldSurface + ScaffoldPressable for elevated, outlined, or
/// filled variants with optional header, body, and actions slots.
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
/// Consumes ScaffoldCardCubit (in-memory).
library;
```
For Phase 9 handwritten atoms (NOT template-generated), drop the "Generated from" lines but keep the rest of the header block (one-line summary, what it composes, what it consumes, D-references).

**Imports pattern** (lines 13–21 of scaffold_card.dart):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

import 'scaffold_card_cubit.dart';
import 'scaffold_card_state.dart';
```
Relative imports for sibling cubit/state; package: imports for cross-cutting atoms and theme. Always include `flutter_bloc` only when the file is cubit-aware.

**Optional-consumer-Cubit + `_ownsCubit` fallback (D-02)** (lines 92–131 of scaffold_card.dart):
```dart
class _ScaffoldCardState extends State<ScaffoldCard> {
  late ScaffoldCardCubit _cubit;
  late bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    _ownsCubit = widget.cubit == null;
    _cubit = widget.cubit ??
        ScaffoldCardCubit(
          instanceId: widget.instanceId,
          initialVariant: widget.variant,
        );
  }

  @override
  void didUpdateWidget(ScaffoldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool seedChanged = widget.instanceId != oldWidget.instanceId ||
        widget.variant != oldWidget.variant;
    if (widget.cubit != oldWidget.cubit || (_ownsCubit && seedChanged)) {
      if (_ownsCubit) {
        _cubit.close();
      }
      _ownsCubit = widget.cubit == null;
      _cubit = widget.cubit ??
          ScaffoldCardCubit(
            instanceId: widget.instanceId,
            initialVariant: widget.variant,
          );
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }
```
This is THE pattern to copy verbatim for `ScaffoldStreamingRichTextCubit? cubit`. Substitution rules: swap the constructor seed (`initialVariant`) for an initial empty span-tree state, and add a stream-subscription field when the widget is given a raw `Stream<…>` (the subscription lives in `_ScaffoldStreamingRichTextState` and is cancelled in `dispose` only when the cubit is internally owned).

**`BlocProvider.value` + `BlocBuilder` body pattern** (lines 134–234 of scaffold_card.dart):
```dart
return BlocProvider<ScaffoldCardCubit>.value(
  value: _cubit,
  child: BlocBuilder<ScaffoldCardCubit, ScaffoldCardState>(
    builder: (context, state) {
      final palette = context.palette;
      final dimens = context.dimens;
      // ... build slots from state ...
    },
  ),
);
```
Copy verbatim; the slot-assembly idiom (`final List<Widget> slotChildren = <Widget>[];` + `if (widget.X != null) slotChildren.add(...)`) applies directly to the streaming body + cursor + actions row.

**Builder/callback slot pattern (D-04 / D-05 / D-06 DI hooks)** (line 46 of wallet_connect_sheet.dart):
```dart
Widget Function(BuildContext context, String uri)? qrBuilder,
```
Named-optional `Widget Function(BuildContext, ...)` (or `T Function(...)`) parameters, typed, never `dynamic`. The same shape applies to `syntaxHighlighter` (code block), `toolbarBuilder` (selection actions), `announcePolicy` (streaming text), and `actions: List<Widget>?` (response-action row).

---

### `lib/components/scaffold_streaming_rich_text_cubit.dart` (cubit, streaming)

**Analog:** `lib/components/scaffold_card_cubit.dart` (full file — 53 lines) and `lib/components/scaffold_search_bar_cubit.dart` (full file — 74 lines).

**Cubit shape** (scaffold_card_cubit.dart lines 22–53):
```dart
class ScaffoldCardCubit extends Cubit<ScaffoldCardState> {
  ScaffoldCardCubit({
    this.instanceId = '',
    this.initialVariant = 'elevated',
  }) : super(ScaffoldCardState(cardVariant: initialVariant));

  final String instanceId;
  final String initialVariant;

  void selectVariant(String variant) {
    emit(state.copyWith(cardVariant: variant));
  }

  void recordAction(String action) {
    emit(state.copyWith(lastAction: action));
  }

  void reset() {
    emit(ScaffoldCardState(cardVariant: initialVariant));
  }
}
```

For streaming rich text the cubit is the append/announce policy host. Expected methods (translated):
```dart
void appendSpans(List<ScaffoldRichSpan> delta) { emit(state.copyWith(spans: <ScaffoldRichSpan>[...state.spans, ...delta])); }
void complete() { emit(state.copyWith(isStreaming: false)); }
void toggleCitation(String id) { /* toggle in state.expandedCitations */ }
void reset() { emit(const ScaffoldStreamingRichTextState()); }
```
Use `scaffold_search_bar_cubit.dart` (lines 38–68) as the template for richer transition methods with named methods per transition — never expose `emit` directly.

---

### `lib/components/scaffold_streaming_rich_text_state.dart` (state, immutable copyWith)

**Analog:** `lib/components/scaffold_card_state.dart` (full file — 50 lines) and `lib/components/scaffold_search_bar_state.dart` (full file — 65 lines).

**Immutable state + sentinel-based copyWith pattern** (scaffold_card_state.dart lines 19–49):
```dart
class ScaffoldCardState {
  const ScaffoldCardState({
    this.cardVariant = 'elevated',
    this.lastAction,
  });

  final String cardVariant;
  final String? lastAction;

  static const Object _unset = Object();

  ScaffoldCardState copyWith({
    String? cardVariant,
    Object? lastAction = _unset,
  }) {
    return ScaffoldCardState(
      cardVariant: cardVariant ?? this.cardVariant,
      lastAction: lastAction == _unset ? this.lastAction : lastAction as String?,
    );
  }
}
```

**Key requirement:** nullable fields use the `Object? field = _unset` sentinel so the consumer can explicitly set `null` (see `scaffold_search_bar_state.dart` lines 47–64 for a multi-field example). Apply verbatim for `expandedCitations`, `errorMessage`, and any optional streaming-cursor metadata.

---

### `lib/components/scaffold_code_block.dart` (component, request-response + streamed insertion)

**Primary analog:** `lib/components/scaffold_chip.dart` (full file — 121 lines) — small, mostly-stateless atom with slots and a constructor-time assert.
**Secondary analogs:** `lib/components/scaffold_surface.dart` (surface shape), `lib/components/scaffold_overflow_fade.dart` (right-edge fade), `lib/components/scaffold_motion.dart` (reduced-motion gating), `lib/components/scaffold_disclosure.dart` (AnimatedSize + reduced-motion zero-duration substitution).

**Constructor + a11y assert pattern** (scaffold_chip.dart lines 27–39):
```dart
const ScaffoldChip({
  super.key,
  this.label,
  this.icon,
  this.status,
  this.selected = false,
  this.disabled = false,
  this.semanticLabel,
  this.onPressed,
}) : assert(
        label != null || semanticLabel != null,
        'Icon-only ScaffoldChip requires semanticLabel (WCAG 4.1.2)',
      );
```
Apply the same shape for the code-block copy button: icon-only `Icons.copy` → required `copyTooltip` semantic label (default `"Copy"` per UI-SPEC). The constructor stays `const` — copy state is owned by a private `_isCopied` bool on a `StatefulWidget`, mirroring `ScaffoldComposer` (scaffold_composer.dart lines 74–109) for transient-only state.

**Surface + border + radius pattern** (scaffold_chip.dart lines 93–107):
```dart
final Widget surface = ScaffoldSurface(
  color: palette.deepBlueCardColor,
  borderRadius: BorderRadius.circular(dimens.radiusPill),
  border: selected
      ? Border.all(
          color: palette.lightGreenPrimary,
          width: dimens.focusRingWidth,
        )
      : null,
  padding: EdgeInsets.symmetric(
    horizontal: dimens.space4,
    vertical: dimens.space4,
  ),
  child: row,
);
```
For the code block substitute: `radiusMd` (not pill), `palette.borderSubtle` 1px border (always), `EdgeInsets.all(dimens.space8)` outer padding (per UI-SPEC).

**Reduced-motion gating pattern** (scaffold_disclosure.dart lines 100–130):
```dart
final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;
// ...
AnimatedRotation(
  turns: _effectiveExpanded ? 0.25 : 0.0,
  duration: reducedMotion
      ? Duration.zero
      : ScaffoldMotionDurations.short,
  curve: ScaffoldMotionCurves.standard,
  // ...
)
```
Copy verbatim for: streamed-line insertion fade (150ms decelerate), copy-icon swap (300ms standard), new-line highlight fade (500ms standard, disabled entirely under reducedMotion).

**Horizontal scroll + overflow fade pattern** (scaffold_overflow_fade.dart lines 139–156):
```dart
final palette = context.palette;
final Color resolvedColor = backgroundColor ?? palette.deepBlueCardColor;

return ShaderMask(
  blendMode: BlendMode.dstOut,
  shaderCallback: (Rect bounds) {
    return ScaffoldOverflowFade.gradientFor(
      direction: fadeDirection,
      extent: fadeExtent,
      bounds: bounds,
      color: resolvedColor,
    ).createShader(bounds);
  },
  child: child,
);
```
Composition for code block: `SingleChildScrollView(scrollDirection: Axis.horizontal, child: body)` wrapped in `ScaffoldOverflowFade(direction: FadeDirection.right, fadeExtent: 24.0, backgroundColor: palette.deepBlueCardColor)` (per UI-SPEC).

---

### `lib/components/scaffold_selection_actions.dart` (component, event-driven)

**Primary analogs:**
- `lib/components/scaffold_selectable_surface.dart` (selection wrap + overlay)
- `lib/components/scaffold_disclosure.dart` (animated appear/disappear)
- `lib/components/wallet_connect_sheet.dart` (typed builder slot — `qrBuilder` line 46)

**Builder-slot pattern for toolbarBuilder** (wallet_connect_sheet.dart lines 43–53):
```dart
static Future<T?> show<T>({
  required BuildContext context,
  required WalletConnectSessionState sessionState,
  Widget Function(BuildContext context, String uri)? qrBuilder,
  // ...
})
```
For `ScaffoldSelectionActions`, `toolbarBuilder` is REQUIRED (per UI-SPEC "Default actions: None"). Same typed-shape but with `required`:
```dart
required Widget Function(BuildContext, TextSelection, String) toolbarBuilder,
```

**Transient internal state pattern** (scaffold_composer.dart lines 74–109):
```dart
class _ScaffoldComposerState extends State<ScaffoldComposer> {
  /// Transient state only — submission truth lives in the consumer (D-03).
  late final TextEditingController _controller;
  late FocusNode _textFieldFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _textFieldFocusNode = widget.focusNode ?? FocusNode();
  }
  // didUpdateWidget + dispose mirror scaffold_card's cubit pattern
}
```
For selection actions: `LayerLink _toolbarLink`, `OverlayEntry? _toolbarEntry`, and the most-recent `(TextSelection, String)` pair are the transient fields. Truth (selected text) is reported UP via `onSelectionChanged` — never retained as consumer state.

**Selection-wrap pattern** (scaffold_selectable_surface.dart lines 47–83):
```dart
Widget content = ScaffoldSurface(child: child);

if (selected) {
  content = Stack(
    children: <Widget>[
      content,
      Positioned.fill(
        child: IgnorePointer(
          child: ColoredBox(
            color: palette.lightGreenPrimary.withValues(alpha: 0.12),
          ),
        ),
      ),
    ],
  );
}
```
For `ScaffoldSelectionActions` the wrapper is a `SelectionArea` (or accepts a consumer-supplied `SelectableText`); the `Stack`/`Positioned.fill` idiom is reused when the toolbar overlay needs to be anchored via `CompositedTransformFollower`.

---

### `lib/utils/scaffold_rich_spans.dart` (model, data-shape only)

**Analog:** `TraceItem` class in `lib/components/scaffold_trace_list.dart` lines 19–39 (in-file DTO).

**Pattern:**
```dart
/// A single trace item — domain-agnostic, one-way data in.
class TraceItem {
  const TraceItem({
    required this.title,
    required this.body,
    this.status,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget body;
  final StatusVariant? status;
  final bool initiallyExpanded;
}
```

For typed spans, promote to a sealed-class hierarchy in its own file (per UI-SPEC "`ScaffoldRichSpan` sealed class hierarchy — `TextSpan`, `CitationSpan`, `LinkSpan`, `CodeInlineSpan`"). Each subtype is a `const` class with `final` fields — no methods, no behavior. The file lives in `lib/utils/` (NOT `lib/components/`) because it is data, not a widget.

---

### `lib/utils/markdown_to_spans.dart` and `lib/utils/light_syntax_tokenizer.dart` (support transforms)

**No codebase analog** — these are greenfield support parts (D-07/D-08). They MUST:

1. Live in `lib/utils/` (NOT `lib/components/`).
2. Carry their own dependencies (e.g. `markdown` package) — `lib/components/` MUST NOT import them (D-08).
3. Be exported from `lib/frontend_scaffold.dart` so the example app can demo them (D-07 demonstrability).
4. Have their own `test/utils/` test file.

**Pattern for the support-part function signature** — pure function, no widget, no BuildContext:
```dart
/// Maps a Markdown string to a typed span tree consumable by
/// [ScaffoldStreamingRichText].
///
/// This is a support part (D-07). It is the ONLY scaffold file that imports
/// the `markdown` package; consumers who want typed atoms only do not pay
/// for the dependency.
List<ScaffoldRichSpan> scaffoldMarkdownToSpans(String source) { /* ... */ }
```

---

### `lib/utils/streaming_announce_policy.dart` (announce-policy hook + defaults)

**Analog:** `lib/components/scaffold_live_region.dart` (the announcement sink — full file, 32 lines).

**Pattern for the policy abstraction:**
```dart
/// Announce-policy hook for [ScaffoldStreamingRichText] (D-06).
///
/// The atom calls [shouldAnnounce] on every span-tree update; the policy
/// returns the plain-text to pass to [ScaffoldLiveRegion] (or null to skip
/// this update). Policies MUST NOT reread the whole answer per token — the
/// default implementation announces at block boundaries (paragraph, code
/// block, heading) and debounces 300ms.
abstract class ScaffoldStreamingAnnouncePolicy {
  const ScaffoldStreamingAnnouncePolicy();

  String? shouldAnnounce(
    List<ScaffoldRichSpan> previous,
    List<ScaffoldRichSpan> next,
  );
}

/// Default block-boundary policy (D-06 default).
class ScaffoldBlockBoundaryAnnouncePolicy extends ScaffoldStreamingAnnouncePolicy {
  const ScaffoldBlockBoundaryAnnouncePolicy({
    this.debounce = const Duration(milliseconds: 300),
  });
  final Duration debounce;
  // ...
}
```

The debounce timer lives in the policy implementation, NOT in the widget — the widget just forwards `policy.shouldAnnounce(...)` output to a `ScaffoldLiveRegion(value: ...)` child.

---

### Barrel (`lib/frontend_scaffold.dart`)

**Analog:** existing barrel, lines 22–73.

**Pattern** (alphabetical-by-filename, `components/` then `theme/` then `utils/`):
```dart
export 'components/scaffold_badge.dart';
export 'components/scaffold_card.dart';
export 'components/scaffold_card_cubit.dart';
export 'components/scaffold_card_state.dart';
export 'components/scaffold_chip.dart';
// ...
export 'theme/scaffold_colors.dart';
// ...
export 'utils/breakpoints.dart';
```

Insert new exports in alphabetical order within their group:
- `components/scaffold_code_block.dart`
- `components/scaffold_selection_actions.dart`
- `components/scaffold_selection_copy_action.dart`
- `components/scaffold_streaming_copy_button.dart`
- `components/scaffold_streaming_rich_text.dart`
- `components/scaffold_streaming_rich_text_cubit.dart`
- `components/scaffold_streaming_rich_text_state.dart`
- `utils/light_syntax_tokenizer.dart`
- `utils/markdown_to_spans.dart`
- `utils/scaffold_rich_spans.dart`
- `utils/streaming_announce_policy.dart`

---

### Tests (`test/components/scaffold_*_test.dart`)

**Analog:** `test/components/scaffold_chip_test.dart` (full file, 240 lines).

**`_pump` helper pattern** (lines 11–32):
```dart
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

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
Every Phase 9 test file copies both helpers. Final test in each file is "renders under lightPalette without exception" (line 231).

**Token-assertion pattern** (lines 36–43, 58–81):
```dart
Container _chipContainer(WidgetTester tester) {
  return tester.widget<Container>(
    find.descendant(
      of: find.byType(ScaffoldSurface),
      matching: find.byType(Container),
    ),
  );
}
// ...
final BoxDecoration decoration =
    _chipContainer(tester).decoration! as BoxDecoration;
expect(decoration.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
```
Always assert against `ScaffoldPalette.defaultPalette.X` / `ScaffoldDimens.defaultDimens.X` constants — never hardcoded hex/numbers.

**Semantics assertion pattern** (lines 185–228):
```dart
final Semantics buttonSemantics = tester.widgetList<Semantics>(
  find.descendant(
    of: find.byType(ScaffoldChip),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is Semantics &&
          w.properties.button == true &&
          w.properties.label == 'Close',
    ),
  ),
).first;
expect(buttonSemantics.properties.label, 'Close');
```

For streaming rich text, additionally use the `scaffold_live_region_test.dart` pattern (lines 26–45) to assert the `ScaffoldLiveRegion` Semantics node updates on span-tree changes:
```dart
Semantics _semanticsOf(WidgetTester tester) {
  return tester.widget<Semantics>(
    find
        .descendant(
          of: find.byType(ScaffoldLiveRegion),
          matching: find.byType(Semantics),
        )
        .first,
  );
}
```

---

### Demos (`example/lib/demos/*_demo.dart`)

**Analog:** `example/lib/demos/chip_demo.dart` (full file, 171 lines).

**Pattern** (lines 14–107):
```dart
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
            // --- 1. Default ---
            Text('Default', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldChip(label: 'Chip', onPressed: () {}),
            // ... one labelled section per state/variant ...
          ],
        ),
      ),
    );
  }
}
```
Each demo is a single `StatelessWidget` with numbered/labelled sections (`--- 1. Default ---`, `--- 2. Selected ---`, ...). One section per UI-SPEC row (default / highlighted / streamed / reduced-motion / empty / light-mode). For stateful interactions (streaming append, selection change), use small private `_Foo` StatefulWidgets (see `_SingleSelectGroup` / `_MultiSelectGroup` in chip_demo.dart lines 111–170).

**Demo registration** — `example/lib/main.dart` lines 216–230:
```dart
_DemoTile(
  title: 'Chip / ChipGroup',
  subtitle: 'Pill pressable atom + selection group',
  builder: (_) => const ScaffoldChipDemo(),
),
```
Add three new `_DemoTile` entries for the three Phase 9 atoms, plus separate tiles for the Markdown and tokenizer support parts (D-07 demonstrability requirement).

---

### Jinja2 templates (`templates/components/{streaming_rich_text,code_block,selection_actions}.*`)

**Analog:** `templates/components/card.dart.jinja2` + `card_cubit.dart.jinja2` + `card_state.dart.jinja2` + `card_vars.json`.

**Template header pattern** (card.dart.jinja2 lines 1–11):
```jinja2
/// {{ widget_class_name }} -- M3 card with configurable variant and content slots.
///
/// Generated from card.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/card.dart.jinja2
/// Generator version: 0.4.0
/// Composes ScaffoldSurface + ScaffoldPressable for elevated, outlined, or
/// filled variants with optional header, body, and actions slots.
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
/// Consumes {{ widget_class_name }}Cubit (in-memory).
library;
```

**Template placeholders** (card.dart.jinja2 lines 45–90):
```jinja2
class {{ widget_class_name }} extends StatefulWidget {
  const {{ widget_class_name }}({
    this.instanceId = '',
    this.variant = '{{ card_variant }}',
    this.header,
    this.body,
    this.actions,
    this.onTap,
    this.disabled = false,
    this.cubit,
    super.key,
  });
  // ...
  final {{ widget_class_name }}Cubit? cubit;
```

**Vars fixture** (card_vars.json):
```json
{
  "_comment": "Fixture variables for standalone rendering of card.dart.jinja2. ...",
  "widget_class_name": "ScaffoldCard",
  "file_stem": "scaffold_card",
  "card_variant": "elevated"
}
```

Apply verbatim to the three Phase 9 template families. Variables needed:
- `widget_class_name` (e.g. `ScaffoldStreamingRichText`)
- `file_stem` (e.g. `scaffold_streaming_rich_text`)
- one variant-specific seed per family (e.g. `default_announce_policy`, `default_language`, `default_toolbar_placement`)

All templates MUST use `StrictUndefined` (per project constraint); missing vars fail loudly.

---

## Shared Patterns

### Theme tokens (every Phase 9 widget)

**Source:** `lib/theme/scaffold_theme.dart` + `lib/components/scaffold_chip.dart` lines 66–69.
**Apply to:** every Phase 9 file.
```dart
final palette = context.palette;
final dimens = context.dimens;
final textTheme = Theme.of(context).textTheme;
```
Never hardcode colors, dims, or text styles. The Phase 9 UI-SPEC "Spacing Scale" and "Color" tables map every token by name; reference them directly.

### Reduced-motion gating (every animation)

**Source:** `lib/components/scaffold_disclosure.dart` lines 89, 102–105, 118–119.
**Apply to:** streaming cursor blink, streamed-line fade, new-line highlight fade, copy-icon swap, citation expansion, toolbar appear/hide.
```dart
final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;
// then for each animation:
duration: reducedMotion ? Duration.zero : ScaffoldMotionDurations.<short|medium|long>,
curve: ScaffoldMotionCurves.<standard|decelerate>,
```

### ScaffoldPressable + ScaffoldTouchTarget (every pressable)

**Source:** `lib/components/scaffold_pressable.dart` lines 117–160.
**Apply to:** citation markers, code-block copy button, selection-toolbar actions, response-action slots.
The Pressable already supplies: 8%/12% opacity state layers, focus outline, Enter/Space activation, 48x48 hit area, Semantics(button: true). Phase 9 MUST NOT re-implement any of these — pass `semanticLabel` and `onPressed` only.

### ScaffoldSurface + 1px borderSubtle (every card-like container)

**Source:** `lib/components/scaffold_composer.dart` lines 182–187.
**Apply to:** code block surface, citation source slot, selection toolbar card.
```dart
ScaffoldSurface(
  color: palette.surfaceElevated,    // or deepBlueCardColor per UI-SPEC
  borderRadius: BorderRadius.circular(dimens.radiusMd),
  border: Border.all(color: palette.borderSubtle, width: 1),
  child: padded,
)
```

### ScaffoldLiveRegion (every announcement)

**Source:** `lib/components/scaffold_live_region.dart` (full file).
**Apply to:** streaming text announcements (D-06), copy confirmation (when consumer opts in).
```dart
ScaffoldLiveRegion(
  value: announceText,    // plain-text block at the boundary
  child: const SizedBox.shrink(),
)
```
The atom NEVER wraps its main output in `Semantics(liveRegion: true)`; announcements flow through this dedicated child only (UI-SPEC Accessibility Contract).

### Imports ordering (every file)

**Source:** `lib/components/scaffold_card.dart` lines 13–21, `lib/components/scaffold_chip.dart` lines 16–20.
**Apply to:** every Phase 9 file.
```dart
import 'package:flutter/material.dart';           // Flutter SDK first
import 'package:flutter/services.dart';           // (when Clipboard / LogicalKeyboardKey needed)
import 'package:flutter_bloc/flutter_bloc.dart';  // external packages
import 'package:frontend_scaffold/components/...';// scaffold atoms
import 'package:frontend_scaffold/theme/...';     // scaffold theme

import 'scaffold_X_cubit.dart';                   // relative siblings last
import 'scaffold_X_state.dart';
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/utils/markdown_to_spans.dart` | utility / transform | transform | No transform utility exists in scaffold today; `lib/utils/` only holds `breakpoints.dart`. The pattern is greenfield — follow the support-part rules in the Pattern Assignments section above. |
| `lib/utils/light_syntax_tokenizer.dart` | utility / transform | transform | Same — greenfield. Keep the tokenizer regex-based and small (~150 LOC target); if it grows past that, split per-language. |
| `lib/utils/streaming_announce_policy.dart` | policy / hook | event-driven | The `ScaffoldLiveRegion` sink exists, but no policy abstraction. Define the abstract class per the Pattern Assignments section; default impl is `ScaffoldBlockBoundaryAnnouncePolicy`. |

For these three, the planner should treat the prose patterns above as the binding contract — there is no prior art to copy from.

---

## Metadata

**Analog search scope:** `lib/components/`, `lib/theme/`, `lib/utils/`, `test/components/`, `templates/components/`, `example/lib/demos/`
**Files scanned:** 74 components + 5 theme + 1 utils + 30 tests + 25 templates + 19 demos = 154
**Pattern extraction date:** 2026-08-20
