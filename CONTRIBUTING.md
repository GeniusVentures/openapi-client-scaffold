# Contributing

## Setup

```bash
flutter pub get                    # Dart deps
python3 -m venv .venv              # Python codegen tooling
.venv/bin/pip install -e ".[dev]"
```

## The checks CI runs

```bash
dart analyze --fatal-infos   # must be clean — no infos, no warnings
flutter test                 # 214 tests
ruff check                   # Python lint
pytest                       # Python codegen tests
```

Both jobs are defined in `.github/workflows/ci.yaml`.

## Generated files: change the template, not the output

Several widget families under `lib/components/` are **rendered from Jinja2
templates and committed**. The template is the source of truth. Hand-editing a
generated file will be silently overwritten the next time anyone regenerates,
and drift has happened before.

Generated families and their drivers:

| Files | Driver |
|---|---|
| `scaffold_animated_display_*.dart` | `scaffold_codegen.generators.animated_display` |
| `scaffold_formatted_value_*.dart` | `scaffold_codegen.generators.formatted_value` |
| `scaffold_image_placeholder_*.dart` | `scaffold_codegen.generators.image_placeholder` |
| `scaffold_selection_indicator_*.dart` | `scaffold_codegen.generators.selection_indicator` |
| `scaffold_card*`, `scaffold_state_view*`, `scaffold_search_bar*` | `scaffold_codegen.generators.composites` |

To change one: edit `templates/components/<name>.jinja2` (and its `_vars.json`
if you are adding a variable), then regenerate and commit both.

### Manual pre-PR drift check

CI gates on analyze + test only — it does **not** yet regenerate and diff, so
this invariant (`.planning/PROJECT.md` D-16) is currently enforced by hand.
Run this before opening a PR that touches `templates/` or a generated file:

```bash
for g in animated_display composites formatted_value image_placeholder selection_indicator; do
  PYTHONPATH=tools python3 -m scaffold_codegen.generators.$g
done
git diff --exit-code lib/
```

A non-empty diff means the committed output and the templates disagree — commit
the regenerated files (or fix the template) before pushing.

## Commits

Commit messages follow the phase convention already in the history, e.g.
`fix(07): IN-04 correct semanticLabel on media_card`. Reference the requirement
ID where one applies.

There is no `CHANGELOG.md` — git history and `.planning/MILESTONES.md` are the
release record. Call out consumer-visible changes (a moved CMake CACHE default,
a widget API change) in the commit message, since three repos consume this
package as a submodule.

## Planning workflow

This repo uses the GSD workflow; records live in `.planning/`. See
[CLAUDE.md](CLAUDE.md) for the map, and `.planning/README.md` for how to run the
commands with this submodule as the project root.
