# Architecture Patterns

**Domain:** Design-token generation, additive theme extensions and an opt-in preset in a Flutter widget library consumed as a pinned submodule
**Milestone:** v1.4 Design Tokens & Midnight Preset
**Researched:** 2026-10-16
**Confidence:** HIGH for integration points (read from the repo and from GCS `gcs_theme.dart`); MEDIUM for harness determinism across OSes (not run).

## Findings that shape everything

1. **`design_tokens.json` and the Dart defaults use different vocabularies.** The JSON is Material 3 (purple `primary #6750A4`, `color.roles`, `typography.scale`, `shape.corner`, `elevation.levelN`). `ScaffoldPalette.defaultPalette` / `lightPalette` and `ScaffoldDimens.defaultDimens` hold the deep-blue / green values (`0xFF0C0E14`, `lightGreenPrimary`, `space8` ...), and none of those values exist in the JSON. "Generate the Dart defaults from the JSON" therefore means adding a new section to the JSON, not mapping the existing M3 keys.
2. **The existing keys are a public contract.** GCS renders Jinja2 templates from `design_tokens.json` (`tokens.shape.corner.medium`, `tokens.elevation.level2.shadow`, ...) under `StrictUndefined`. Renaming, moving or retyping any existing key breaks it. Extra keys do not break it.
3. **`DESIGN_TOKENS` (CMake CACHE) and `scaffold_codegen.DESIGN_TOKENS` are not the same thing.** CMake passes `${DESIGN_TOKENS}` to the CSS step and to every consumer-space template render, so a consumer can point it at its own file. The Python constant is used by the committed-family generators and always points at the repo file.
4. **The Dart theme output is committed into `lib/theme/`.** It must be driven by the repo file (the Python constant), never by the CMake override. A consumer override file will not have the new section, so the CSS step and the templates must tolerate its absence.
5. **The capture harness is a writer.** `example/test/capture_images_test.dart` hardcodes `../images/` and a private `_buildCaptureTheme(Brightness)`. It asserts nothing (PROJECT.md key decision, no pixel gating in CI). The "goldens of defaults unchanged" gate is therefore `re-run the harness, then git diff --exit-code images/`, run per phase locally. It is not a CI gate.
6. **Consumer-facing constraint on constructors.** `ScaffoldPalette` and `ScaffoldDimens` constructors take every field as `required`. Adding a field to either breaks any app that constructs one directly. GCS only uses the static constants, so it would survive, but "other apps must not break" makes the safer rule: do not touch those constructors.

## Recommended Architecture

```
design_tokens.json  (root, location unchanged)
  color / typography / shape / elevation     <- existing M3 keys, FROZEN, read by CSS + templates + GCS
  scaffold                                   <- NEW namespace: palette.{dark,light}, dimens, shadows, motion, typography, gradients
tokens/midnight.json                         <- NEW, same `scaffold` schema, no M3 keys
        |                                                  |
        | tools/scaffold_codegen/m3_tokens_css.py          | tools/scaffold_codegen/theme_dart.py  (NEW)
        | (unchanged output in phases 1-4)                 |   reads `scaffold` section of any token file
        v                                                  v
  generated/styles/m3_tokens.css            lib/theme/scaffold_palette.dart   (marker regions spliced)
  (CMake, uses ${DESIGN_TOKENS})            lib/theme/scaffold_dimens.dart    (marker regions spliced)
                                            lib/theme/scaffold_shadows.dart ...  (new extensions, whole-file)
                                            lib/theme/presets/scaffold_midnight.dart (whole-file, from tokens/midnight.json)
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `design_tokens.json` | Single source of truth. M3 section is frozen. `scaffold` section is new. | CSS generator, Dart generator, Jinja2 templates, GCS |
| `tokens/midnight.json` | Preset values in the same `scaffold` schema | Dart generator only |
| `tools/scaffold_codegen/theme_dart.py` (new) | Render the Dart const data from a token file; `--check` mode diffs in memory and exits 1 on drift. Default token path is the `DESIGN_TOKENS` constant from `scaffold_codegen/__init__.py`. | `design_tokens.json`, `tokens/*.json`, `lib/theme/` |
| `m3_tokens_css.py` | Token file to CSS. Output unchanged until the optional last step. | `${DESIGN_TOKENS}` via CMake |
| `lib/theme/scaffold_palette.dart`, `scaffold_dimens.dart` | Hand-written class shape (fields, `copyWith`, `lerp`) plus generated const instances | widgets via `context.palette` / `context.dimens` |
| New extensions `ScaffoldShadows`, `ScaffoldTypography`, `ScaffoldMotionTheme`, `ScaffoldGradients` | Themeable shadow (light and dark instances), typography, motion, gradient tokens. Each has a `defaultX` const equal to today's look. | `scaffold_theme.dart` getters, widgets |
| `scaffold_theme.dart` | Add `context.shadows`, `.typography`, `.motion`, `.gradients`, each with `?? defaultX` fallback. `scaffoldThemeExtensions` stays unchanged. | all widgets |
| `lib/theme/presets/scaffold_midnight.dart` (new) | Deep-import-only preset: constants plus `extensions(Brightness)` | host apps that opt in |
| Capture harness | Profile-driven (theme builder + output dir). Default profile is today's behaviour. | `images/`, `images/midnight/` |
| `test/theme/` | Consumer-contract test, contrast test, defaults-equality tests | CI `flutter test` |

### Data Flow

Edit token JSON, run `python3 -m scaffold_codegen.theme_dart`, commit regenerated `lib/theme/*`. CI (and `pytest`) runs `theme_dart --check`. Widgets read `context.palette / dimens / shadows / ...` with a default fallback, so a host that registers nothing gets today's look. The CMake path (`DESIGN_TOKENS` override, CSS, templates) never touches the Dart theme generator.

## Public API compatibility (explicit)

| Symbol | Status |
|--------|--------|
| `ScaffoldPalette` (constructor, 22 required fields, `copyWith`, `lerp`, `defaultPalette`, `lightPalette`) | Unchanged. Constants stay `static const` members so `const <ThemeExtension<dynamic>>[ScaffoldPalette.lightPalette, ...]` in GCS still compiles. Values byte-identical. |
| `ScaffoldDimens` (constructor, fields, `defaultDimens`) | Unchanged |
| `ScaffoldColors`, `ScaffoldElevation.card`, `ScaffoldMotionDurations/Curves/ScaffoldMotion` | Unchanged. `ScaffoldColors` stays hand-written (mixed `0xff` / `fromRGBO` literals make it a poor byte-identical target; not needed by the goal). |
| `scaffoldThemeExtensions` | Unchanged. Do not append new extensions; getters fall back anyway. |
| `context.palette`, `context.dimens` | Unchanged |
| `design_tokens.json` existing keys | Frozen. Only `scaffold` is added. |
| CMake CACHE vars (`DESIGN_TOKENS` etc.) | Unchanged. No new required variable. |
| `m3_tokens.css` bytes | Unchanged through the restyle phase. Pin with a characterization test first. |
| Barrel `frontend_scaffold.dart` | New extensions exported (additive). Preset is NOT in the barrel; deep import only, so barrel users see nothing. |
| Preset naming | `midnight`, neutral names for all `GWColors` entries. No brand names in `lib/` or `example/`. |

Do not add fields to `ScaffoldPalette` or `ScaffoldDimens` for the new groups. New `ThemeExtension`s keep constructors, `const` usage and registrations in other apps untouched. `ScaffoldMotionTheme` is named to avoid colliding with the existing `ScaffoldMotion` InheritedWidget (reduced-motion).

## Patterns to Follow

### Pattern 1: Marker-region splice for hand-written classes
**What:** Keep the class body hand-written. Generate only the const instances between markers.
**When:** `scaffold_palette.dart`, `scaffold_dimens.dart`. A full-file template would force a doc string per field into the token schema and re-implement `copyWith` / `lerp` in Jinja for no benefit.
**Why safe:** The Dart compiler already enforces that token keys match constructor params (a missing required argument or an unknown named argument is a compile error).
```dart
  // <gen:default-palette tokens="design_tokens.json#scaffold.palette.dark">
  static const ScaffoldPalette defaultPalette = ScaffoldPalette( ... );
  // </gen:default-palette>
```
Adding the marker comments is the only hand edit, done in the same commit as the generator and verified by the generator reproducing the rest byte-for-byte.

### Pattern 2: Value plus optional alias for byte-identity
**What:** Token color entries store the resolved value and an optional Dart alias, e.g. `{"value": "0xFF00EAAE", "dartAlias": "ScaffoldColors.lightGreenPrimary"}`. The generator emits the alias when present, otherwise `Color(0x...)` in the exact casing used today. A pytest asserts alias target value equals `value`.
**Why:** Current output mixes `ScaffoldColors.x` references and literals; byte-identical output requires reproducing both. CSS can still use `value`.

### Pattern 3: New data goes in new extensions with default fallback
**What:** `context.shadows` is `Theme.of(this).extension<ScaffoldShadows>() ?? ScaffoldShadows.defaultShadows`, same shape as `context.palette`.
**Light and dark shadows:** two const instances (`defaultShadows` equals `ScaffoldElevation.card` values, `lightShadows`), registered per `ThemeData` exactly like the palette. No brightness switch inside the class.
**Gradients / typography defaults:** defaults must reproduce what widgets draw today (for typography, "inherit from `Theme.textTheme`", i.e. nullable overrides, so text is untouched).

### Pattern 4: Generator reads the default file by constant, preset by flag
`python3 -m scaffold_codegen.theme_dart` (no args) regenerates the default theme files from the `DESIGN_TOKENS` constant. `--preset midnight` reads `tokens/midnight.json` and writes `lib/theme/presets/scaffold_midnight.dart`. Same schema, same renderer; preset is data, not a second code path. Follows the existing `generators/<name>.py` driver convention and `scaffold_codegen` path constants; document the new family in the CONTRIBUTING.md table and drift-check loop.

### Pattern 5: Profile-driven capture harness
Hoist the theme builder and output dir into a `CaptureProfile`. Default profile = current `_buildCaptureTheme` and `../images`. Add a `midnight` profile writing to `../images/midnight/`. Allow `SCAFFOLD_CAPTURE_DIR` to override the output dir so a baseline can be written outside the repo and compared byte for byte.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Re-keying `design_tokens.json` to "unify" M3 and scaffold values
**Why bad:** Breaks GCS templates under `StrictUndefined`. **Instead:** add a `scaffold` namespace and leave M3 keys alone.

### Anti-Pattern 2: Driving the Dart generator from `${DESIGN_TOKENS}`
**Why bad:** A consumer override file lacks `scaffold`; committed `lib/` output would change per build. **Instead:** repo constant only; the generator fails loudly if `scaffold` is missing in the file it was asked to read, while CSS and templates use `.get` and keep working.

### Anti-Pattern 3: A second generation path
The milestone note says extend the existing CSS path rather than build another. In practice: share the token loading, kebab/case helpers and `--tokens` CLI conventions from `m3_tokens_css.py` (extract `load_tokens()` to `scaffold_codegen/tokens.py` in phase 1, behaviour-preserving), but keep Dart rendering in its own module. CSS and Dart emitters are different outputs of one source, not two sources.

### Anti-Pattern 4: Mixing refactor and restyle in one diff
CLAUDE.md core rule. Each phase below is gated before the next starts.

### Anti-Pattern 5: "Fixing" default colors to pass WCAG
Defaults are frozen. The AA gate applies to the preset (both modes). If a default pair fails AA, record it, do not change it.

## Build Order (refactor first, then fields, then preset, then restyles)

Each phase ends with: `dart analyze --fatal-infos`, `flutter test`, `ruff check && pytest`, `theme_dart --check`, and a capture re-run with `git diff --exit-code images/` (or hash compare against a baseline).

**Phase 0 (inside phase 1, first tasks): baselines.** Run the harness on the executing machine and confirm `git diff --exit-code images/` is clean. If not (font rasterization differs by OS; harness comments reference macOS font paths), write a baseline set to a directory outside the repo via `SCAFFOLD_CAPTURE_DIR` and compare against that instead. Add a pytest that snapshots current `m3_tokens.css` bytes for the committed `design_tokens.json`. Add `test/theme/consumer_contract_test.dart` that compiles the exact const list GCS uses. Do not fix the Roboto-Medium capture bug in this milestone, because it would change baselines.

**Phase 1: Byte-identical generation (refactor only).**
1. Extract `scaffold_codegen/tokens.py` (load/validate); `m3_tokens_css.py` uses it; CSS bytes unchanged (snapshot test).
2. Add the `scaffold.palette.{dark,light}` and `scaffold.dimens` sections to `design_tokens.json`, transcribed from the current Dart.
3. Add marker regions to `scaffold_palette.dart` and `scaffold_dimens.dart`; `theme_dart.py` splices them; `--check` mode.
4. Tests: pytest asserts regenerated files equal committed bytes; Dart `defaultPalette`/`lightPalette`/`defaultDimens` equality tests. Wire `theme_dart --check` into the `python` CI job. Update CONTRIBUTING.md.
Exit: zero diff in `lib/` values and `images/`, consumer-contract test green.

**Phase 2: Full token map and new fields (behaviour-identical defaults).**
1. Add the GeniusWallet token map (colors, spacing, radius, typography, motion, shadows, gradients) to `tokens/midnight.json` as data only (neutral names). No Dart yet.
2. Add `ScaffoldShadows`, `ScaffoldTypography`, `ScaffoldMotionTheme`, `ScaffoldGradients` extensions and `scaffold_theme.dart` getters. Defaults sourced from `design_tokens.json#scaffold.*` and equal to today's hard-coded values (`ScaffoldElevation.card`, `ScaffoldMotionDurations`, existing gradient and text-style usage).
3. Migrate widgets that hard-code those values (toast `boxShadow: ScaffoldElevation.card`, motion durations, `ScaffoldOverflowFade` gradients, `text_entry_field` Roboto) to read via context, one component family at a time. Template-generated families: edit the template and regenerate, never the `.dart`.
4. Defaults-equality tests (each `defaultX` equals the old constant). Export new extensions from the barrel.
Exit: harness diff clean; GCS (registers only palette and dimens) compiles and renders identically through fallbacks.
Does not depend on phase 3. Depends on phase 1 (schema and generator).

**Phase 3: Midnight preset.**
1. `theme_dart --preset midnight` renders `lib/theme/presets/scaffold_midnight.dart` (palette dark and light, dimens, shadows light and dark, typography, motion, gradients, `extensions(Brightness)`); `--check` covers it.
2. Contrast test (WCAG AA, text/background and status/background pairs, dark and light) on the preset only.
3. Harness `midnight` profile writes `images/midnight/`; the default profile output stays untouched.
4. Barrel does not export it; README documents the deep import.
Exit: preset opt-in only; defaults diff clean; AA green. GCS build check against the branch here; notify the GCS team only after this phase merges.

**Phase 4: Component restyles (preset only where tokens cannot reach).**
Each restyle must read new values from extensions and keep the default extension values producing today's pixels. Gate is harness: default images unchanged, `midnight` images change as intended. Restyles that would alter default rendering are out of scope for this milestone or must be preset-conditional through extension values (for example a radius or border token whose default equals the old literal), never `if (preset)` branches in widgets.

**Phase 5 (optional, last): CSS emission of the `scaffold` namespace.** Appending `--sc-*` custom properties changes `m3_tokens.css` bytes for all CMake consumers, so it is additive-only, gated by the section existing in the token file, and left until the snapshot test is deliberately updated. Skip if no consumer needs it.

### Research flags

- Phase 1: byte-identical Dart formatting (`dart format` line wrapping, `0xFF` vs `0xff` casing per entry). Needs a careful plan; standard otherwise.
- Phase 2: inventory of hard-coded shadows, gradients, durations and text styles across ~15.5k LOC (18 `TextStyle(` sites, several `ScaffoldElevation.card` uses) before planning.
- Phase 3: mapping from `GWColors` to the 22 palette fields plus new fields needs the GeniusWallet `lib/theme/` source and a design decision on semantic names.
- Phase 4: likely needs per-component discussion; scope depends on what tokens cannot reach.

## Scalability Considerations

| Concern | One preset | A few presets | Many apps overriding |
|---------|-----------|---------------|---------------------|
| Preset files | One `tokens/midnight.json` | One file per preset, same renderer | Apps ship their own token file and call `theme_dart --tokens` in their repo |
| Drift check | One `--check` run | Loop over `tokens/*.json` | Not scaffold's concern |
| Harness runtime | Two profiles x 26 demos | Add profile per preset (consider a subset) | n/a |

## Sources

- Repo (HIGH): `design_tokens.json`, `CMakeLists.txt` lines 88 and 365-385, `tools/scaffold_codegen/__init__.py`, `m3_tokens_css.py`, `generators/selection_indicator.py`, `lib/theme/*.dart`, `lib/frontend_scaffold.dart`, `example/test/capture_images_test.dart`, `.github/workflows/ci.yaml`, `CONTRIBUTING.md`, `CLAUDE.md`, `.planning/PROJECT.md`, `MILESTONE-CONTEXT.md`.
- GeniusCognitiveSystem `src/app/lib/theme/gcs_theme.dart` via `gh api` (HIGH): registers `ScaffoldPalette.lightPalette`, `ScaffoldPalette.defaultPalette`, `ScaffoldDimens.defaultDimens` in `const` extension lists.
- Not read: GeniusWallet `lib/theme/` (needed for Phase 2/3 token map).
