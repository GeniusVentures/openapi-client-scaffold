# OpenAPI Client Scaffolding

Generates typed API clients from OpenAPI 3.1 specs using `openapi-generator-cli`.

## Supported Generators

| Generator | Output | Language |
|-----------|--------|----------|
| `dart-dio` | `generated/dart/{domain}/` | Dart (Dio HTTP client) |
| `typescript-axios` | `generated/typescript/{domain}/` | TypeScript (Axios) |
| `javascript` | `generated/javascript/{domain}/` | JavaScript (fetch/promises) |

Add new generators in `scripts/generate_api_clients.py` → `GENERATORS` dict.

## Usage

```bash
# Generate all clients for all specs
python3 scripts/generate_api_clients.py

# Generate specific generator
python3 scripts/generate_api_clients.py -g typescript-axios

# Generate specific generator + spec
python3 scripts/generate_api_clients.py -g dart-dio -s gsm
```

## Prerequisites

```bash
pnpm install -g @openapitools/openapi-generator-cli
```

## Spec Location

Reads OpenAPI specs from `../api-specs/*_openapi.json` in the parent project.
Generated code is written to `generated/{language}/{domain}/` (gitignored).

## Architecture

```
parent-project/
├── api-specs/                    ← project-specific OpenAPI specs
│   └── gsm_openapi.json
└── frontend/  ──► submodule ──►  openapi-client-scaffolding
    ├── scripts/
    │   └── generate_api_clients.py
    ├── generated/                ← gitignored, never committed
    │   ├── typescript/gsm/
    │   ├── dart/gsm/
    │   └── javascript/gsm/
    └── openapitools.json
```
