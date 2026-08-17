# CLAUDE.md

Guidance for agents working in this repo.

## What this repo is

The Dart package `frontend_scaffold` (note: the *repo* is named
`openapi-client-scaffold`, a historical mismatch). Two deliverables:

- `lib/` — a shared Flutter M3 widget library. **This is the main deliverable.**
- `tools/`, `templates/`, `CMakeLists.txt` — build-time codegen (Jinja2 + OpenAPI).

It is consumed as a git submodule by three repos, so treat anything under
`lib/` and the CMake CACHE variables as a public contract.

## Before you finish

```bash
dart analyze --fatal-infos   # must be clean
flutter test                 # 214 tests
ruff check && pytest         # Python codegen (needs .venv, see CONTRIBUTING.md)
```

## The rule that bites: generated files

Several widget families in `lib/components/` are Jinja2 output **that is
committed**. Editing the `.dart` file directly is wrong — it will be
overwritten, and this drift has already happened once (commit `ed8859b`).
Change `templates/components/*.jinja2` and regenerate.

The families, drivers, and the manual drift check are listed in
[CONTRIBUTING.md](CONTRIBUTING.md). Read it before touching anything matching
`scaffold_{animated_display,formatted_value,image_placeholder,selection_indicator}_*`
or `scaffold_{card,state_view,search_bar}*`.

> Note a documented inconsistency: `.planning/PROJECT.md` states "Generated code
> is never committed — D-16, CI regenerates and diffs." That holds for the
> OpenAPI client output and the consumer-space component output (both
> gitignored under `generated/`), but **not** for the widget families above,
> which are deliberately committed. CI does not currently run the diff.

## Where the conventions live

`.planning/` is a ~9,700-line GSD workflow record — larger than the code, and
the only place several decisions are written down. Start here:

| File | What it holds |
|---|---|
| `.planning/PROJECT.md` | "Key Design Decisions" — the architectural rules |
| `.planning/workstreams/scaffold/STATE.md` | "Accumulated Context" — current position, session continuity |
| `.planning/README.md` | Scope boundary; run GSD commands with `--ws scaffold` |
| `.planning/workstreams/scaffold/REQUIREMENTS.md` | `SUB-*` / `WIDG-*` requirement IDs referenced in commits |
| `.planning/workstreams/scaffold/CONSUMERS.md` | Which consuming app needs which widget |
| `.planning/MILESTONES.md` | Release history (there is no CHANGELOG by design) |

Load-bearing design rules from `PROJECT.md`, repeated here because they are
easy to violate:

- All widgets consume M3 `Theme.of(context)` only — no Riverpod, no app-specific theme.
- Templates use Jinja2 `StrictUndefined` — missing variables must fail loudly.
- Neutral generic package — zero brand names in `lib/` or `example/`.
- Atoms are primitives; composites are template-generated compositions of atoms.
- Font choice lives in `scaffold_theme.dart`, not in widget wrappers.

## Layout notes

- `lib/` is flat (no `lib/src/`) — every file is public API, and consumers deep-import
  (`package:frontend_scaffold/components/scaffold_badge.dart`). Do not "fix" this
  without coordinating across the three consuming repos.
- Python lives in `tools/scaffold_codegen/` (package config in `pyproject.toml`).
  Repo-relative paths come from the constants in its `__init__.py` — use those
  rather than recomputing `Path(__file__).parents[n]`.
- `test/` mirrors `lib/` (`test/components/`, `test/theme/`).
- Widget filenames are mostly `scaffold_`-prefixed; a set of older ones
  (`action_button.dart`, `media_card.dart`, `wallet_connect_sheet.dart`, …) are not.
  Leave the legacy names alone — renaming breaks consumer imports.

## Known broken

The `FRONTEND_TARGET=html` CMake targets fail under `StrictUndefined`: the
`*.html.jinja2` templates want `has_header` / `result_groups`, which the shared
`*_vars.json` fixtures (Dart-oriented) do not define. Pre-existing; the
`flutter` target is fine.
