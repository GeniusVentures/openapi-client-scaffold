# OpenAPI Client Scaffold — API clients + M3 Jinja2 template rendering

Generates typed API clients from OpenAPI 3.1 specs **and** renders Material Design 3
Flutter widgets / HTML fragments from Jinja2 templates with a single,
self-contained CMake build. Add it as a submodule to any project that needs
either (or both) capabilities.

## What You Get

| Capability | CMake Target | Output |
|---|---|---|
| API client codegen (Dart, TS, JS) | `frontend_generate_api` | `generated/{lang}/{domain}/` |
| Standalone template rendering | `scaffold_generate_templates` | `{GENERATED_DIR}/scaffold/` |
| Flutter M3 component widgets | `generate_all_components` | `{GENERATED_DIR}/widgets/` (18 .dart files) |
| HTML M3 component fragments | `generate_all_components_html` | `{GENERATED_DIR}/html/` + `styles/` |

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
| `ENGINE_SCRIPT` | `scaffold/engine.py` | Jinja2 template engine |
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
├── cpp/             ← C++ interface templates (Phase 7)
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
├── card_cubit.dart        ← HydratedMixin Cubit (hydrated_bloc 11.x)
├── card_state.dart        ← plain Dart state (toJson/fromJson + copyWith)
├── ... (data_table, form_dialog, navigation, search_bar, state)
└── state_view_state.dart  ← special case: state component's state class
```

Generated code imports shared scaffold widgets (`Loading`, `showToast`) from
`package:frontend_scaffold/components/`.

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

## API Client Generation

```bash
# Generate all clients for all specs
python3 scripts/generate_api_clients.py

# Generate specific generator
python3 scripts/generate_api_clients.py -g typescript-axios

# Generate specific generator + spec
python3 scripts/generate_api_clients.py -g dart-dio -s gsm
```

### Prerequisites

```bash
pnpm install -g @openapitools/openapi-generator-cli
```

### Spec Location

Reads OpenAPI specs from `../api-specs/*_openapi.json` in the parent project.
Generated code is written to `generated/{language}/{domain}/` (gitignored).

### Supported Generators

| Generator | Output | Language |
|-----------|--------|----------|
| `dart-dio` | `generated/dart/{domain}/` | Dart (Dio HTTP client) |
| `typescript-axios` | `generated/typescript/{domain}/` | TypeScript (Axios) |
| `javascript` | `generated/javascript/{domain}/` | JavaScript (fetch/promises) |

Add new generators in `scripts/generate_api_clients.py` → `GENERATORS` dict.

## Architecture

```
your-project/
├── api-specs/                         ← project-specific OpenAPI specs
│   └── gsm_openapi.json
└── frontend/scaffold/  ← submodule ──► openapi-client-scaffold
    ├── CMakeLists.txt                 ← self-contained build orchestrator
    ├── engine.py                      ← Jinja2 template engine
    ├── design_tokens.json             ← M3 tokens single source of truth
    ├── generate_m3_tokens_css.py      ← tokens → CSS custom properties
    ├── templates/
    │   ├── base/                      ← standalone identity templates
    │   ├── components/                ← per-component Flutter + HTML templates
    │   ├── cpp/                       ← C++ interface templates (Phase 7)
    │   └── module/                    ← domain module templates
    ├── scripts/
    │   └── generate_api_clients.py    ← OpenAPI client codegen
    ├── generated/                     ← gitignored output
    │   ├── typescript/{domain}/
    │   ├── dart/{domain}/
    │   └── javascript/{domain}/
    └── openapitools.json
```
