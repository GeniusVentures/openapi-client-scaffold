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

`example/` is a runnable gallery with one demo screen per widget family.

## Develop

```bash
flutter pub get
dart analyze --fatal-infos    # must be clean
flutter test                  # 214 tests
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
├── test/                           ← 214 widget + token tests
│   ├── components/
│   └── theme/
├── example/                        ← runnable demo gallery
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
