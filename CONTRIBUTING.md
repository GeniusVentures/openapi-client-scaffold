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
