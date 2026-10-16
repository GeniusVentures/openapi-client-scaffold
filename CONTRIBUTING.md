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
python -m scaffold_codegen.generators && git diff --exit-code lib/   # generator drift (CI runs this)
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
| `lib/theme/scaffold_palette.dart`, `lib/theme/scaffold_dimens.dart` (only the lines between the `// GENERATED` and `// END GENERATED` markers) | `scaffold_codegen.generators.theme_defaults` |

To change one: edit `templates/components/<name>.jinja2` (and its `_vars.json`
if you are adding a variable), then regenerate and commit both.

### Theme tokens

The defaults of `ScaffoldPalette` and `ScaffoldDimens` are generated from the
`scaffold` namespace of `design_tokens.json`.

- Source: `scaffold.palette.dark` feeds `ScaffoldPalette.defaultPalette`,
  `scaffold.palette.light` feeds `lightPalette`, and `scaffold.dimens` feeds
  `ScaffoldDimens.defaultDimens`. Keys are field names in constructor order.
- Formats: colors are uppercase `"0xAARRGGBB"` strings, or
  `{"value": "0xAARRGGBB", "dartRef": "ScaffoldColors.<name>"}` where the Dart
  source references a `ScaffoldColors` constant. `value` must equal what the
  reference resolves to; `test/theme/scaffold_tokens_parity_test.dart` checks
  this. Numbers are emitted with the digits written (`20.0`, `0.40`), and
  integers are rejected for double fields.
- Flow: edit the token, run `python -m scaffold_codegen.generators.theme_defaults`,
  commit both. `--check` exits 1 on drift and writes nothing.
- The M3 keys `color`, `typography`, `shape` and `elevation` are a frozen
  contract read by consumer templates under `StrictUndefined`. Add keys; never
  rename or move them.
- Dart generation always reads this repo's `design_tokens.json`. A CMake
  `DESIGN_TOKENS` override affects only the CSS and consumer-space templates.
- `tools/tests/fixtures/m3_tokens.css` is the committed `m3_tokens.css`
  snapshot. Changing an M3 key changes it. Regenerate it in the same commit with
  `python -m scaffold_codegen.m3_tokens_css --tokens design_tokens.json --output tools/tests/fixtures/m3_tokens.css`,
  and call it out as consumer-visible.

### Drift check

Run this before opening a PR that touches `templates/`, `design_tokens.json` or
a generated file:

```bash
PYTHONPATH=tools python3 -m scaffold_codegen.generators
git diff --exit-code lib/
```

CI runs exactly this, plus the `theme_defaults --check` and
`m3_tokens_css ... --check` commands, and fails on any diff. Use `python3` on
macOS and Linux, and `python` on Windows. A non-empty diff means the committed
output and its source disagree: commit the regenerated files (or fix the source)
before pushing.

### Line endings

Generators write LF on every OS and `.gitattributes` pins LF. A whole-file diff
after regenerating means a writer lacks `newline="\n"`;
`tools/tests/test_codegen_writes_lf.py` catches that.

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
