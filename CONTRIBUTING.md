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
flutter test                 # 1464 tests
ruff check                   # Python lint
pytest                       # Python codegen tests, including the capture history gate
python -m scaffold_codegen.generators && git diff --exit-code lib/   # generator drift (CI runs this)
```

Both jobs are defined in `.github/workflows/ci.yaml`. The Python job checks out
the full history (`fetch-depth: 0`), because the capture gate walks it (see
[Capture gate](#capture-gate)).

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
| `lib/theme/scaffold_{palette,dimens,shadows,motion_theme,typography,gradients,color_roles,shapes}.dart` (only the lines between the `// GENERATED` and `// END GENERATED` markers) | `scaffold_codegen.generators.theme_defaults` |
| `lib/theme/presets/midnight_tokens.dart` (only the `// GENERATED` regions) | `scaffold_codegen.generators.theme_presets` |

To change one: edit `templates/components/<name>.jinja2` (and its `_vars.json`
if you are adding a variable), then regenerate and commit both.

### Theme tokens

The defaults of `ScaffoldPalette`, `ScaffoldDimens` and the six theme
extensions (shadows, motion, typography, gradients, color roles, shapes) are generated
from the `scaffold` namespace of `design_tokens.json`.

- Source: `scaffold.palette.dark` feeds `ScaffoldPalette.defaultPalette`,
  `scaffold.palette.light` feeds `lightPalette`, and `scaffold.dimens` feeds
  `ScaffoldDimens.defaultDimens`. Keys are field names in constructor order.
  The other token paths map to Dart targets like this:
  - `scaffold.shadows.dark` feeds the `ScaffoldShadows` constructor defaults
    (`defaultShadows`), and `scaffold.shadows.light` feeds `lightShadows`.
  - `scaffold.motion.durations` and `scaffold.motion.curves` feed
    `ScaffoldMotionTheme`.
  - `scaffold.typography.textStyles` and `scaffold.typography.fontFamilies` feed
    `ScaffoldTypography`.
  - `scaffold.gradients` feeds `ScaffoldGradients`.
  - `scaffold.colorRoles.dark` feeds the `ScaffoldColorRoles` defaults
    (`defaultColorRoles`), and `scaffold.colorRoles.light` feeds `lightColorRoles`.
  - `scaffold.shapes` feeds `ScaffoldShapes` (component geometry: focused field
    border width, sheet radius, checkbox radius and border width), read through
    `context.shapes`. One instance serves both modes, and it is not in
    `scaffoldThemeExtensions`.
  - The component restyle fields are nullable and null by default:
    `colorRoles` keys `surfaceEdge`, `hoverFill`, `hoverEdge`, `scrim`,
    `checkboxFill`, `checkboxMark`, `checkboxEdge`, `actionIcon`,
    `actionDisabledFill` and `actionDisabledForeground`; `shadows` key
    `elevated`; `gradients` key `surfaceSheen`; and `typography` style
    `numericStyle`.
- Null means built-in: a null token keeps the widget's built-in look, so the
  default theme renders as before. A `params` region accepts `null` for every
  value kind and emits `this.name,`. An `args` region rejects `null`, so the
  default `light` region omits the nullable keys and the light instance
  inherits null from the constructor. A widget switches on the value, not on
  the preset: any theme that registers the extension value gets the restyle.
- Region styles: `REGIONS` in `tools/scaffold_codegen/generators/theme_defaults.py`
  is the full list. An `args` region holds the arguments of a const constructor
  call (`name: value,`). A `params` region holds constructor parameter defaults
  (`this.name = value,`), so every parameter of the new extensions is optional
  and `const X()` is the default instance.
- Formats: colors are uppercase `"0xAARRGGBB"` strings, or
  `{"value": "0xAARRGGBB", "dartRef": "ScaffoldColors.<name>"}` where the Dart
  source references a `ScaffoldColors` constant. `value` must equal what the
  reference resolves to; `test/theme/scaffold_tokens_parity_test.dart` checks
  this. Numbers are emitted with the digits written (`20.0`, `0.40`), and
  integers are rejected for double fields.
- Formats of the new groups:
  - shadows: a list of `{color, blurRadius, offset}`, with `offset` a
    two-number list.
  - durations: integer milliseconds.
  - curves: `Curves.<name>`, or a four-number list for a `Cubic`.
  - text styles: an object with a subset of `fontFamily`, `fontSize`,
    `fontWeight` (100 to 900), `letterSpacing`, `lineHeight` (px, emitted as
    `height: lineHeight / fontSize`) and `tabularFigures` (`true` only).
  - font family names: letters, digits, space, underscore and hyphen.
  - gradients: `null`, or an object. A linear gradient has `type: "linear"`,
    `begin` and `end` (`Alignment` names such as `topLeft`), `colors` and
    optional `stops`. A radial gradient has `type: "radial"`, `center`
    (a two-number `[x, y]` list), `radius`, `colors` and optional `stops`.

  Every string format is validated by full match, and anything else fails the
  generator.
- Fallbacks: each extension has a `context.<name>` getter (`shadows`, `motion`,
  `typography`, `gradients`, `colorRoles`) that returns the registered extension
  or a default. `shadows` uses the light instance when `ThemeData.brightness`
  is light. With no `ScaffoldColorRoles` registered, `context.colorRoles` calls
  `ScaffoldColorRoles.fallbackForPalette` with the resolved palette and picks
  the light or dark roles from that palette's surfaces, not from
  `ThemeData.brightness`. A light theme with no registered palette therefore
  still gets readable roles for the dark default surfaces.
  `scaffoldThemeExtensions` deliberately still lists only the palette and
  dimens, so an app that registers nothing new renders as before.
- Compatibility: `ScaffoldElevation.card` and the static motion duration and
  curve classes stay as public constants, and tests pin them equal to the
  generated defaults. Widgets read the theme instead of these constants.
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
- Contrast: `test/theme/palette_contrast_test.dart` classifies every
  `scaffold.palette` and `scaffold.colorRoles` token as a surface, text (4.5:1 on
  every surface of its mode), non-text (3:1), decorative, or excluded with a
  reason. Translucent colors are composited over the surface first. A new token
  without a classification fails the test. A value change that fails it needs a
  different value, not a lower threshold.
  The same test also covers the midnight preset, dark and light, with
  `surfaceBase` and `surfaceSheet` as extra surfaces and the `preset.colors`
  classification. `test/theme/midnight_theme_contrast_test.dart` covers the
  midnight `ColorScheme` and component themes.
- Presets: a preset has its own token file, `tokens/midnight.json`. It uses the
  same `scaffold` schema plus a `preset` key for values with no extension field.
  `scaffold_codegen.generators.theme_presets` renders it with the same encoders
  into `lib/theme/presets/midnight_tokens.dart`, and `theme_presets --check`
  fails on drift. The CLI reads only that file. `design_tokens.json` never feeds
  a preset.
- Midnight component restyles: the preset sets the nullable fields above in
  `tokens/midnight.json`. The generated consts are `Midnight.darkShadows` and
  `lightShadows` (with `elevated`), `Midnight.darkScaffoldGradients` and
  `lightScaffoldGradients` (the `darkGradients` name is taken by
  `MidnightGradients`), `Midnight.shapes`, and the color roles and typography
  already registered by `midnightExtensions`. Where a value equals an existing
  preset token, `test/theme/midnight_token_map_test.dart` pins the equality.
- Captures: the default run writes the 52 images in `images/` and must leave
  them byte-identical. The midnight run writes `images/midnight/`, including a
  midnight-only `restyles_{dark,light}.png` capture of a card, a hovered
  pressable, a focused field and the checkbox states. Re-baseline midnight
  captures in a separate `chore` commit that touches only `images/midnight/`.
  Any re-baseline of an existing capture also needs a manifest entry, or pytest
  fails (see [Capture gate](#capture-gate)).
- Brand names: `tools/tests/test_no_brand_names.py` scans the text files under
  `lib/`, `example/` and `tokens/` for organization and product names. It skips
  the platform runner folders of the example app, whose bundle identifiers are
  build metadata.

### Drift check

Run this before opening a PR that touches `templates/`, `design_tokens.json` or
a generated file:

```bash
PYTHONPATH=tools python3 -m scaffold_codegen.generators
git diff --exit-code lib/
```

CI runs exactly this, plus the `theme_defaults --check`, `theme_presets --check`
and `m3_tokens_css ... --check` commands, and fails on any diff. Use `python3` on
macOS and Linux, and `python` on Windows. A non-empty diff means the committed
output and its source disagree: commit the regenerated files (or fix the source)
before pushing.

### Line endings

Generators write LF on every OS and `.gitattributes` pins LF. A whole-file diff
after regenerating means a writer lacks `newline="\n"`;
`tools/tests/test_codegen_writes_lf.py` catches that.

## Capture gate

`tools/capture_gate.py history` walks git history from the v1.4 base
(`e67e00c`, recorded in `tools/capture_rebaselines.json`) to HEAD. It fails
when:

- a commit changes an existing PNG under `images/` and is not listed in
  `tools/capture_rebaselines.json`;
- a listed commit touches anything other than `images/`, or its scope does not
  match its folder (`default` for `images/*.png`, `midnight` for
  `images/midnight/*.png`), or its subject or first parent differs from the entry;
- `images/` holds a file that is not a PNG.

Commits that only add new captures need no entry. `pytest` runs the gate
(`tools/tests/`), so CI needs the full history: the `python` job uses
`fetch-depth: 0`. A shallow clone fails the test.

Manifest entry fields, with a real entry:

```json
{
  "sha": "f4207f79c9ca8bb132853dc506ee2fc07cf62e8f",
  "subject": "chore(14-02): re-baseline captures for A11Y-01",
  "scope": "default",
  "follows": "0f79aaae12a9c7715be85836ac091f2fcb7cee88",
  "record": "v1.4 14-COLOR-CHANGES.md A11Y01_CAPTURES"
}
```

`sha` and `follows` are full 40-character SHAs. `follows` is the first parent
of the capture commit, and `subject` must equal the commit's subject line.
`record` points at the written reason for the change.

Re-baselining a capture:

1. Commit the code or token change that moves the pixels.
2. Re-render and commit only the changed PNGs, in a `chore` commit that touches
   nothing else (midnight captures in their own commit).
3. Add the manifest entry for that commit in a third commit, and write the
   reason in the record it points to.

`pytest` fails between steps 2 and 3, so do not push in between.

Merge `develop` into `main` with a merge commit. A squash or rebase merge
rewrites the SHAs and the manifest no longer matches, so the gate fails.

Two commands:

```bash
python tools/capture_gate.py history   # the check pytest runs
python tools/capture_gate.py render    # flutter on PATH; re-renders into a scratch dir and diffs images/
```

`render` is local only. Rasterization differs across machines, so CI cannot
compare bytes. On a different machine from the one that rendered the committed
captures, render a known-good commit into a directory of your own
(`SCAFFOLD_CAPTURE_DIR=<dir> flutter test test/capture_images_test.dart` from
`example/`) and compare your working tree against that instead of `images/`.

## Consumer check (GeniusCognitiveSystem)

`tools/consumer_check/gcs_check.sh` builds and tests a consuming app against a
ref of this repo:

```bash
PATH="<flutter>/bin:$PATH" bash tools/consumer_check/gcs_check.sh <gcs-app-dir> <scaffold-ref>
```

Prerequisites: a checkout of the app that holds the scaffold submodule (it has
`scaffold/` and `templates/components/`), `flutter` and `python` on PATH, and a
clean submodule. `<scaffold-ref>` is a branch, tag or commit of this repo.

It fetches this repo into the app's `scaffold` submodule and checks the ref out
detached, deletes and re-renders the gitignored `lib/generated/chat`, then runs
`pub get`, `dart analyze` and `flutter test`. It never commits in the app, and on exit
the submodule returns to the commit it started on.

Expected on a healthy ref: 0 codegen failures of 12, `pub get` exit 0, 0 analyze
issues in app code (`lib/`, `test/`), and all tests passing. Analyze errors
under `scaffold/example` are expected noise (the example package does not
resolve inside the consumer).

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
