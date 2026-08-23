# frontend_scaffold

Two things live in this repo, sharing one set of Material Design 3 design tokens:

1. **A shared Flutter widget library** (`lib/`) — the package you depend on.
   Theme primitives, generic blocs, breakpoints, and ~70 M3 atoms and
   composites. This is the main deliverable.
2. **A build-time codegen toolkit** (`tools/`, `templates/`, `CMakeLists.txt`) —
   generates typed API clients from OpenAPI 3.1 specs and renders M3 Flutter
   widgets / HTML fragments from Jinja2 templates, driven by CMake.

The Dart package is named `frontend_scaffold`; the repo is named
`openapi-client-scaffold` for historical reasons.

---

# Part 1 — The widget library

## Install

`publish_to: 'none'`, so depend on it by path (as a submodule) or by git:

```yaml
dependencies:
  frontend_scaffold:
    path: path/to/frontend/scaffold
```

## Use

```dart
import 'package:frontend_scaffold/frontend_scaffold.dart';

MaterialApp(
  // Theme extensions carry the M3 tokens the widgets read from.
  theme: ThemeData(extensions: scaffoldThemeExtensions),
  home: const ScaffoldCard(body: Text('hello')),
);
```

Every file under `lib/` is public API. The barrel
(`lib/frontend_scaffold.dart`) re-exports all of it, but consumers may also
import a single widget directly:

```dart
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
```

## What's in it

| Directory | Contents |
|---|---|
| `lib/components/` | ~70 widgets — surfaces, pressables, badges, skeletons, sliders, drag/drop, search bar, state views, toasts, animations, media |
| `lib/theme/` | `scaffold_theme` (extensions), `scaffold_palette`, `scaffold_colors`, `scaffold_dimens`, `scaffold_elevation` |
| `lib/utils/` | `breakpoints` |

Some widget families are **generated** from Jinja2 templates rather than
hand-written — one file per variant, no runtime enum/switch spanning variants:

| Family | Variants | Generator |
|---|---|---|
| `ScaffoldAnimatedDisplay*` | fade, pulse, scale, slide, rotate, shake, bounce | `generators.animated_display` |
| `ScaffoldFormattedValue*` | number, money, percentage, date, time, duration | `generators.formatted_value` |
| `ScaffoldImagePlaceholder*` | loading, missing, empty, failed | `generators.image_placeholder` |
| `ScaffoldSelectionIndicator*` | radio, checkbox, toggle | `generators.selection_indicator` |
| `ScaffoldCard` / `ScaffoldStateView` / `ScaffoldSearchBar` | + `_cubit` / `_state` companions | `generators.composites` |

**These files are committed, but the template is the source of truth.** Never
hand-edit a generated file — change `templates/components/*.jinja2` and
regenerate. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Demo app

```bash
cd example && flutter run -d macos    # or -d chrome
```

`example/` is a runnable gallery with 26 demo screens covering every
widget family and the v1.2 atoms. The component gallery below shows a
captured screenshot of each demo.

## Component gallery

### ActionButton
![ActionButton demo — dark](images/action_button_dark.png)
![ActionButton demo — light](images/action_button_light.png)
Enabled, disabled, and rotate-animation states.

### StringButton
![StringButton demo — dark](images/string_button_dark.png)
![StringButton demo — light](images/string_button_light.png)
Keypad-style button that emits its string value.

### TextEntryFieldWidget
![TextEntryFieldWidget demo — dark](images/text_entry_field_dark.png)
![TextEntryFieldWidget demo — light](images/text_entry_field_light.png)
M3 text field with scaffold styling.

### Loading
![Loading demo — dark](images/loading_dark.png)
![Loading demo — light](images/loading_light.png)
Loading indicators and skeleton states.

### Toast
![Toast demo — dark](images/toast_dark.png)
![Toast demo — light](images/toast_light.png)
Transient notification toasts.

### BottomDrawer / ResponsiveDrawer
![BottomDrawer / ResponsiveDrawer demo — dark](images/bottom_drawer_dark.png)
![BottomDrawer / ResponsiveDrawer demo — light](images/bottom_drawer_light.png)
Modal bottom drawer that becomes a side drawer on wide screens.

### Animations
![Animations demo — dark](images/animations_dark.png)
![Animations demo — light](images/animations_light.png)
ScaffoldAnimatedDisplay variants: fade, pulse, scale, shake, rotate.

### AppScreenView / DesktopBodyContainer
![AppScreenView / DesktopBodyContainer demo — dark](images/page_chrome_dark.png)
![AppScreenView / DesktopBodyContainer demo — light](images/page_chrome_light.png)
Page-chrome scaffolding for app screens.

### ResponsiveGrid
![ResponsiveGrid demo — dark](images/responsive_grid_dark.png)
![ResponsiveGrid demo — light](images/responsive_grid_light.png)
Breakpoint-aware responsive grid layout.

### Tracer
![Tracer demo — dark](images/tracer_dark.png)
![Tracer demo — light](images/tracer_light.png)
Trace/debug overlay.

### Kitchen Sink
![Kitchen Sink demo — dark](images/kitchen_sink_dark.png)
![Kitchen Sink demo — light](images/kitchen_sink_light.png)
All atoms on one screen.

### Media card
![Media card demo — dark](images/media_card_dark.png)
![Media card demo — light](images/media_card_light.png)
Media thumbnail + metadata card consuming ScaffoldBadge slots.

### Media controls
![Media controls demo — dark](images/media_controls_dark.png)
![Media controls demo — light](images/media_controls_light.png)
Playback controls built from ScaffoldPressable + ScaffoldTouchTarget + ScaffoldSlider.

### Wallet connect sheet
![Wallet connect sheet demo — dark](images/wallet_connect_sheet_dark.png)
![Wallet connect sheet demo — light](images/wallet_connect_sheet_light.png)
Reown session presentation sheet.

### Chip / ChipGroup
![Chip / ChipGroup demo — dark](images/chip_dark.png)
![Chip / ChipGroup demo — light](images/chip_light.png)
Pressable token atoms and chip-group selection.

### Composer
![Composer demo — dark](images/composer_dark.png)
![Composer demo — light](images/composer_light.png)
Text-entry area with action and badge slots.

### Disclosure
![Disclosure demo — dark](images/disclosure_dark.png)
![Disclosure demo — light](images/disclosure_light.png)
Generic expand/collapse row.

### Trace list
![Trace list demo — dark](images/trace_list_dark.png)
![Trace list demo — light](images/trace_list_light.png)
Ordered list of disclosure items.

### Streaming rich text
![Streaming rich text demo — dark](images/streaming_rich_text_dark.png)
![Streaming rich text demo — light](images/streaming_rich_text_light.png)
Incremental rich text with citations and action slots.

### Code block
![Code block demo — dark](images/code_block_dark.png)
![Code block demo — light](images/code_block_light.png)
Syntax-highlighted code with line numbers and copy.

### Selection actions
![Selection actions demo — dark](images/selection_actions_dark.png)
![Selection actions demo — light](images/selection_actions_light.png)
Anchored toolbar over selectable content.

### Markdown to spans
![Markdown to spans demo — dark](images/markdown_to_spans_dark.png)
![Markdown to spans demo — light](images/markdown_to_spans_light.png)
Markdown source → typed span model.

### Light syntax tokenizer
![Light syntax tokenizer demo — dark](images/light_syntax_tokenizer_dark.png)
![Light syntax tokenizer demo — light](images/light_syntax_tokenizer_light.png)
Minimal syntax tokenizer for code block highlighting.

### Chart
![Chart demo — dark](images/chart_dark.png)
![Chart demo — light](images/chart_light.png)
Neutral-series chart via fl_chart.

### Chart Scrubber
![Chart Scrubber demo — dark](images/chart_scrubber_dark.png)
![Chart Scrubber demo — light](images/chart_scrubber_light.png)
Point-selection/scrubbing composing with the chart.

### Chart Range Selector
![Chart Range Selector demo — dark](images/chart_range_selector_dark.png)
![Chart Range Selector demo — light](images/chart_range_selector_light.png)
Drag-range selection + consumer-policy zoom.

## Coverage

Every component in the Beautiful UI yardstick is composable from
shipped scaffold atoms. Of the 19 components, **7 are ready** (existing
atoms compose them with no new primitives), **8 are thin** (compose
from existing atoms plus a small amount of consumer wiring), and **4
are primitive-enabled** (unlocked by the new v1.2 primitives).

| # | Beautiful UI Component | Coverage Tier | Shipped Scaffold Atoms That Compose It |
|---|------------------------|---------------|----------------------------------------|
| 1 | Loading State | Compose (8-thin) | `ScaffoldSkeleton` + `ScaffoldAnimatedDisplay*` (7 variants) + `ScaffoldFormattedValueDuration` + `ScaffoldSurface` |
| 2 | Thinking | Compose (8-thin) | `ScaffoldSurface` + `ScaffoldStatusIndicator` + `ScaffoldAnimatedDisplay*` + `ScaffoldDisclosure` (v1.2) + `ScaffoldTraceList` (v1.2) |
| 3 | Streaming Text | Add primitive (4-primitive) | `ScaffoldStreamingRichText` (v1.2) + `ScaffoldStreamingCopyButton` + `ScaffoldLiveRegion` (a11y announcements) |
| 4 | Approval Card | Ready (7-ready) | `ScaffoldCard` + `ScaffoldSelectionIndicatorRadio` + `TextEntryFieldWidget` + `ActionButton` |
| 5 | Tool Chips | Compose (8-thin) | `ScaffoldChip` (v1.2) + `ScaffoldChipGroup` (v1.2) + `ScaffoldBadge` + `ScaffoldStatusIndicator` + `ScaffoldPressable` |
| 6 | Task Rows | Ready (7-ready) | `ScaffoldStatusIndicator` + `ScaffoldFormattedValue*` + `ScaffoldAnimatedDisplay*` + `ScaffoldSurface` |
| 7 | Chat | Compose (8-thin) | `ScaffoldCard` + `ScaffoldAnimatedDisplay*` + `ScaffoldStateView` + `TextEntryFieldWidget` + `ScaffoldComposer` (v1.2) + `ScaffoldStreamingRichText` + `ScaffoldTraceList` |
| 8 | Prompt Bar | Compose (8-thin) | `TextEntryFieldWidget` + `ActionButton` + `ScaffoldBadge` + `ScaffoldPressable` + `ScaffoldComposer` (v1.2) + `ScaffoldChip` (v1.2) |
| 9 | Recommendation Card | Ready (7-ready) | `ScaffoldCard` + `ScaffoldFormattedValuePercentage` + `ScaffoldStatusIndicator` + `ActionButton` |
| 10 | Context Cards | Ready (7-ready) | `ScaffoldCard` + `ScaffoldBadge` + `ScaffoldFormattedValueNumber` + `ScaffoldImagePlaceholder*` (4 variants) |
| 11 | Diff Table | Compose (8-thin) | `templates/components/data_table.dart.jinja2` + `DataColumnConfig.cellBuilder` (v1.2 Phase 8 extension) |
| 12 | Records Table | Compose (8-thin) | `data_table.dart.jinja2` + `cellBuilder` + `ScaffoldChip` (tags) + `ScaffoldStatusIndicator` (status cells) |
| 13 | Filter Table | Compose (8-thin) | `data_table.dart.jinja2` + `ScaffoldChipGroup` (v1.2) + consumer Cubit deriving visible rows |
| 14 | Sidebar Nav | Ready (7-ready) | `templates/components/navigation.dart.jinja2` (Material drawer + nested groups + badges) + `ScaffoldSearchBar` |
| 15 | Search | Ready (7-ready) | `ScaffoldSearchBar` (live callbacks, grouped results, loading, filter actions) + `ScaffoldStateView` (empty state) |
| 16 | Insight Cards | Add primitive (4-primitive) | `ScaffoldChart` (v1.2) + `ScaffoldChartScrubber` (v1.2) + `ScaffoldChartRangeSelector` (v1.2) + `ScaffoldCard` |
| 17 | Code Block | Add primitive (4-primitive) | `ScaffoldCodeBlock` (v1.2) + `ScaffoldOverflowFade` + `ScaffoldSurface` |
| 18 | Fine-tune Card | Ready (7-ready) | `ScaffoldCard` + `ScaffoldNumericInput` + `ScaffoldColorSwatch` + `ScaffoldSelectionIndicatorToggle` + `StringButton` |
| 19 | Selection Actions | Add primitive (4-primitive) | `ScaffoldSelectionActions` (v1.2) + `ScaffoldSelectionCopyAction` + `ScaffoldComposer` |

## Develop

```bash
flutter pub get
dart analyze --fatal-infos    # must be clean
flutter test                  # 454 tests
```

---

# Part 2 — The codegen toolkit

## What You Get

| Capability | CMake Target | Output |
|---|---|---|
| API client codegen (Dart, TS, JS) | `frontend_generate_api` | `generated/{lang}/{domain}/` |
| Standalone template rendering | `scaffold_generate_templates` | `{GENERATED_DIR}/scaffold/` |
| Flutter M3 component widgets | `generate_all_components` | `{GENERATED_DIR}/widgets/` (18 .dart files) |
| HTML M3 component fragments | `generate_all_components_html` | `{GENERATED_DIR}/html/` + `styles/` |

Note the distinction: the 6 components below are rendered **into a consuming
project's build directory**, and are a different set from the widget library in
`lib/` described in Part 1.

## CMake Integration

Add one line to your project's `CMakeLists.txt`:

```cmake
add_subdirectory(path/to/frontend/scaffold scaffold)
```

That's it. The scaffold defines sensible defaults for all configuration points
so it works out of the box. Every target, custom command, and stamp file lives
inside the scaffold — your project never needs to duplicate the build
orchestrator.

### Configuration (CACHE variables)

Override any of these before `add_subdirectory` to point at your own files:

| Variable | Default (scaffold-local) | Purpose |
|---|---|---|
| `ENGINE_SCRIPT` | `scaffold/tools/scaffold_codegen/engine.py` | Jinja2 template engine |
| `DESIGN_TOKENS` | `scaffold/design_tokens.json` | M3 tokens single source of truth |
| `GENERATED_DIR` | `${CMAKE_BINARY_DIR}/generated` | Output root for rendered files |
| `FRONTEND_TARGET` | `flutter` | Codegen target — `flutter` or `html` |
| `TEMPLATES_DIR` | *(unset)* | Opt-in: consumer project's own M3 identity templates |

Example — your project overrides the output directory:

```cmake
set(GENERATED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ui/generated" CACHE STRING
    "Output directory for generated template output")
add_subdirectory(path/to/frontend/scaffold scaffold)
```

### Targets

| Target | What it builds |
|---|---|
| `frontend_generate_api` | Generate typed API clients from OpenAPI specs |
| `frontend_build_typescript` | Compile TypeScript client (tsc) |
| `frontend_build_javascript` | Bundle JavaScript client (esbuild) |
| `frontend_all` | API codegen + TypeScript build |
| `scaffold_generate_templates` | Render standalone identity templates (base/) |
| `generate_all_components` | Render all 6 M3 Flutter components (18 .dart files) |
| `generate_component_{name}` | Render a single Flutter component triple |
| `generate_all_components_html` | Render all 6 M3 HTML components + m3_tokens.css |
| `generate_component_{name}_html` | Render a single HTML component + CSS |

### Per-component selective rebuild

```bash
cmake --build build --target generate_component_data_table
cmake --build build --target generate_component_form_dialog_html
```

### Standalone build (no parent project)

```bash
cmake -B build -S path/to/scaffold
cmake --build build --target generate_all_components
```

## Template Rendering

The scaffold uses a stamp-file incremental build pattern: each template render
produces both the generated file and a `.stamp` marker. CMake only re-renders
when the template source, design tokens, engine script, or per-component
`_vars.json` file changes.

### Template directory structure

```
templates/
├── base/            ← standalone identity templates (design tokens only)
├── components/      ← per-component .dart / .html / .css Jinja2 templates
│   ├── card.dart.jinja2
│   ├── card_cubit.dart.jinja2
│   ├── card_state.dart.jinja2
│   ├── card_vars.json
│   ├── card.html.jinja2
│   ├── card.css.jinja2
│   └── ... (data_table, form_dialog, navigation, search_bar, state)
├── cpp/             ← reserved placeholder; content owned by consuming repo
└── module/          ← domain module templates (driver-injected vars)
```

### M3 Design Tokens

All rendering pulls from `design_tokens.json` — a Material Design 3 token set
in the `--md-sys-*` CSS custom property convention. Zero hardcoded hex/rgba
values in any template.

## Flutter Component Output (FRONTEND_TARGET=flutter)

Each of the 6 M3 components renders a 3-file triple:

```
{GENERATED_DIR}/widgets/
├── card.dart              ← bloc-aware widget (BlocProvider + BlocBuilder/BlocConsumer)
├── card_cubit.dart        ← Cubit; data_table/form_dialog/navigation add HydratedMixin
├── card_state.dart        ← plain Dart state (toJson/fromJson + copyWith)
├── ... (data_table, form_dialog, navigation, search_bar, state)
└── state_view_state.dart  ← special case: state component's state class
```

Generated code imports shared scaffold widgets (`Loading`, `showToast`) from
`package:frontend_scaffold/components/`.

**Consumer dependency:** the `data_table`, `form_dialog`, and `navigation`
cubits are generated with `HydratedMixin` and
`import 'package:hydrated_bloc/hydrated_bloc.dart'`. That is a dependency of
**your** app, not of `frontend_scaffold` — add `hydrated_bloc` to the consuming
project's `pubspec.yaml` and initialize `HydratedBloc.storage` before use.
This package itself depends only on `flutter_bloc`.

### Consumer validation

A `consumer_test` package at `{GENERATED_DIR}/consumer_test/` imports all
18 generated files and gates the output with `flutter analyze --fatal-infos`.

## HTML Component Output (FRONTEND_TARGET=html)

```
{GENERATED_DIR}/
├── styles/
│   └── m3_tokens.css      ← shared M3 custom properties
└── html/
    ├── card.html
    ├── card.css
    └── ... (one HTML + CSS pair per component)
```

> **Known issue:** the HTML component targets currently fail under
> `StrictUndefined`. The `*.html.jinja2` templates reference variables
> (`has_header`, `result_groups`, …) that the shared `*_vars.json` fixtures do
> not define — those fixtures carry the Dart-oriented variable set. The
> `flutter` target is unaffected.

## API Client Generation

The Python tooling is the `scaffold_codegen` package under `tools/`. Either
install it (`pip install -e .`) or put `tools/` on `PYTHONPATH`:

```bash
# Generate all clients for all specs
python3 -m scaffold_codegen.api_clients

# Generate specific generator
python3 -m scaffold_codegen.api_clients -g typescript-axios

# Generate specific generator + spec
python3 -m scaffold_codegen.api_clients -g dart-dio -s gsm
```

### Prerequisites

```bash
pnpm install -g @openapitools/openapi-generator-cli
```

### Spec Location

Reads OpenAPI specs from `../api-specs/*_openapi.json` in the parent project.
Generated code is written to `generated/{language}/{domain}/` (gitignored).

The one spec committed here, `json/identity_openapi.json`, belongs to the
autonomous identity submodule, which has its own build pipeline — it is not
read by `frontend_generate_api`.

### Supported Generators

| Generator | Output | Language |
|-----------|--------|----------|
| `dart-dio` | `generated/dart/{domain}/` | Dart (Dio HTTP client) |
| `typescript-axios` | `generated/typescript/{domain}/` | TypeScript (Axios) |
| `javascript` | `generated/javascript/{domain}/` | JavaScript (fetch/promises) |

Add new generators in `tools/scaffold_codegen/api_clients.py` → `GENERATORS` dict.

---

## Repository layout

```
openapi-client-scaffold/            ← package `frontend_scaffold`
├── pubspec.yaml                    ← Dart package manifest
├── analysis_options.yaml           ← flutter_lints (dart analyze --fatal-infos)
├── pyproject.toml                  ← Python codegen package + pytest/ruff config
├── CMakeLists.txt                  ← self-contained build orchestrator
├── design_tokens.json              ← M3 tokens single source of truth
├── lib/                            ← THE WIDGET LIBRARY (Part 1)
│   ├── frontend_scaffold.dart      ← barrel export
│   ├── components/                 ← ~70 M3 widgets
│   ├── theme/                      ← theme extensions, palette, dimens, elevation
│   └── utils/                      ← breakpoints
├── test/                           ← 454 widget + token tests
│   ├── components/
│   └── theme/
├── example/                        ← runnable demo gallery
├── images/                         ← per-demo screenshots (gallery above)
├── templates/                      ← Jinja2 templates (base, components, module, cpp)
├── tools/
│   ├── scaffold_codegen/           ← Python build tooling
│   │   ├── engine.py               ← Jinja2 engine (StrictUndefined)
│   │   ├── m3_tokens_css.py        ← tokens → CSS custom properties
│   │   ├── api_clients.py          ← OpenAPI client codegen
│   │   └── generators/             ← per-widget-family drivers
│   └── tests/                      ← pytest suite for the codegen
├── json/                           ← identity submodule's OpenAPI spec
├── .planning/                      ← GSD workflow records (see CLAUDE.md)
└── generated/                      ← gitignored codegen output
```

## License

Proprietary and internal. See [LICENSE](LICENSE).
