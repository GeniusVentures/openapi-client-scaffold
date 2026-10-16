# Technology Stack: v1.4 Design Tokens & Midnight Preset

**Project:** frontend_scaffold
**Researched:** 2026-10-16
**Scope:** Only what is new for v1.4. Existing stack (Dart ^3.10, Flutter 3.41 in CI, Python >=3.11, Jinja2 3.1, pytest, ruff) is unchanged.
**Overall confidence:** HIGH (decision rests on the repo's own code; versions checked against npm and pub.dev registries on 2026-10-16)

## Recommendation

**Extend the existing Python/Jinja2 codegen. Add zero new dependencies.**

Add a `generators/theme_defaults.py` driver beside the five existing generators, plus Jinja2 templates under `templates/theme/`. It reads `design_tokens.json` (and `design_tokens_midnight.json`), renders committed Dart into `lib/theme/`, and is covered by a pytest drift test plus a CI step. Feature 1 of MILESTONE-CONTEXT says "extend that path, don't build a second one"; this is the only option that does.

## Recommended Stack

### Core (all already installed)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Python | >=3.11 (CI 3.11; local 3.12.10) | Run the generator | Already the codegen runtime; no new toolchain on CI or contributor machines. |
| Jinja2 | >=3.1 (3.1.6 current) | Render Dart | Already used with `StrictUndefined`; a missing token key fails loudly (project rule). Pure-function output is deterministic: same input gives same bytes. |
| `scaffold_codegen` (in-repo) | 0.4.0 | Driver, path constants, `create_environment`/`render_template` | Reuse `DESIGN_TOKENS`, `TEMPLATES_DIR`, `engine.py`. Add a `LIB_THEME_DIR` constant to `__init__.py` rather than recomputing paths. |
| pytest | >=8.0 (9.0.3 local) | Drift test | Existing runner and CI job. |
| ruff | >=0.6 | Lint the new driver | Existing. |

### New in-repo pieces (code, not dependencies)

| Piece | Location | Purpose |
|-------|----------|---------|
| Theme generator driver | `tools/scaffold_codegen/generators/theme_defaults.py` | Loads tokens, builds a Dart-ready context, renders templates. Same shape as `selection_indicator.py`. |
| Dart value filters | `tools/scaffold_codegen/dart_literals.py` (or inside the driver) | Pure functions: `#RRGGBB`/`#AARRGGBB` to `Color(0xFF...)`, double formatting (`4.0`, `-0.25`), `FontWeight.w500`, `Duration(milliseconds: n)`, `BoxShadow(...)`, `LinearGradient(...)`. Register as Jinja2 filters. One owner for each encoding rule. |
| Templates | `templates/theme/*.dart.jinja2` | One per ThemeExtension: palette, dimens, shadows, typography, motion, gradients. |
| Midnight token file | `design_tokens_midnight.json` (repo root, next to `design_tokens.json`) | Preset source. Output goes to `lib/theme/scaffold_midnight_*.dart`. |
| Drift test | `tools/tests/test_theme_codegen_drift.py` | Renders to a temp dir, compares bytes with the committed files in `lib/theme/`. |
| CI step | `.github/workflows/ci.yaml`, python job | Runs all generators then `git diff --exit-code lib/`. Closes the gap CONTRIBUTING.md admits ("CI does not yet regenerate and diff"). |

### Supporting libraries

None. Do not add any.

## Why this wins

| Criterion | Extend Python/Jinja2 | Dart `build_runner` | Style Dictionary (DTCG) |
|-----------|----------------------|---------------------|-------------------------|
| Reuses existing path (explicit milestone requirement) | Yes, same `design_tokens.json` reader, same engine, same drivers | No, second generator, second toolchain | No, third toolchain, would also need to replace `m3_tokens_css.py` to avoid two CSS paths |
| New dependencies | 0 | `build_runner` 2.17.1 (needs Dart `^3.11.0`; package floor is `^3.10.0`), `build`, `source_gen`/`code_builder`, `dart_style` 3.1.14 | Node >=22, `style-dictionary` 5.6.1, a Dart format plugin or custom format |
| CI cost | Python job already exists | Needs Flutter job to run `dart run build_runner build`, extra minutes, `.dart_tool` cache | Needs a Node job with setup-node |
| Byte-identical output | Trivial; Jinja2 is deterministic, no formatter involved | Output passes through `dart_style`, so bytes depend on formatter version and language version; Dart upgrade reformats every file | Output depends on custom format JS and Node/SD version |
| Generated file committed in `lib/` | Matches the 5 existing committed families | `build_runner` defaults to `.dart_tool`/part files; committing to `lib/` needs `build_to: source`, which is awkward and would also regenerate during consumers' builds if they ran it | Writes anywhere, fine |
| Stays out of consumers | Yes, dev-only and not in `pubspec.yaml` | Dev dependency leaks into the 3 submodule consumers' mental model and analyzer, and pulls a large transitive set into `pubspec.lock` | Yes |
| Handles shadows, gradients, motion curves | Yes, arbitrary Python | Yes | Awkward: DTCG 2025.10 types exist for shadow/gradient/duration/cubicBezier but SD needs custom transforms per target for Flutter |
| Fits CLAUDE.md DRY / KISS / YAGNI | Best | Adds a layer | Adds a layer and a format migration |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Generator | Python + Jinja2 (extend) | Dart `build_runner` 2.17.1 | See table. Main reasons: a second generator violates "don't build a second one"; formatter-dependent bytes make "byte-identical" fragile; raises SDK floor concerns (`^3.11.0` vs repo `^3.10.0`). |
| Generator | Python + Jinja2 | Style Dictionary 5.6.1 (Node >=22) | Introduces Node, an unused-elsewhere ecosystem, and requires converting `design_tokens.json` to DTCG (`$value`/`$type`). The existing Python CSS generator and 11 CMake/test references to the current shape would need migrating or running both. No Flutter output is built in; you write the Dart format yourself anyway, so SD saves nothing. |
| Token format | Keep current `design_tokens.json` shape, extend it | W3C DTCG 2025.10 format | The format is a good interchange standard but nothing here consumes DTCG (no Figma/Tokens Studio pipeline in scope). Migrating is churn with no consumer benefit. Revisit only if a design tool export becomes a requirement. |
| Dart formatting | Templates emit already-formatted code | Pipe output through `dart format` | Adds a Dart SDK dependency inside Python tests and makes bytes depend on SDK version. Instead author templates in the formatter's style, and add `dart format --output=none --set-exit-if-changed lib/theme` to the Dart CI job as a tripwire (Flutter is pinned at 3.41 there, so it is stable). |
| Drift check | pytest + `git diff --exit-code` in CI | `build_runner` `--verify`-style checks | Not available for this pipeline; pytest compare is simpler and local. |

## Integration points with existing codegen

1. **Token source.** `design_tokens.json` is M3-shaped (`color.roles.*.{light,dark}`, `typography.scale`, `shape.corner`, `elevation.levelN`). The wallet token map (spacing, radius, motion, shadows, gradients, scaffold semantic colors) has no home in it yet. Extend it with new top-level keys (`scaffold.palette`, `scaffold.dimens`, `shadow`, `motion`, `gradient`) and leave existing keys untouched. `m3_tokens_css.py` reads only `color`, `typography`, `shape`, `elevation` via `.get()`, so additions cannot change its output. Add a test that CSS output for the unchanged keys is identical before and after.
2. **Defaults must equal today's look.** `ScaffoldPalette.defaultPalette` (dark, GeniusWallet-flavoured hexes such as `0xFF00EAAE`) is hand-written and does NOT currently come from `design_tokens.json`. Step one is a behavior-preserving refactor: put today's literal values into the token file, generate the Dart, and prove the generated file equals the hand-written one semantically (existing `scaffold_palette_token_test.dart`, `scaffold_dimens_token_test.dart` already assert values). Only then add new fields. This follows the CLAUDE.md "refactor first, then change behavior" rule.
3. **Key order.** Do not use `sorted()` for emit order of Dart fields the way the CSS generator does. Field order in constructors and `copyWith`/`lerp` is part of the public API's readability. Use the order in the JSON file (Python dicts preserve insertion order) or an explicit order list in the template vars. Document the choice in the driver.
4. **Newlines and encoding.** Render with LF and UTF-8, and write with `newline="\n"`. `Path.write_text` on Windows (this repo is developed on win32) translates `\n` to `\r\n` unless `newline` is set, which would make drift tests fail on Windows and pass on Linux CI. Verify `engine.render_template` does not already do this; if it does not, fix it in the engine in a separate refactor commit. Add `* text=auto eol=lf` for `lib/**/*.dart` in `.gitattributes` if not present.
5. **Float formatting.** Python `repr(float)` is deterministic (shortest round-trip), but format explicitly in one filter (`0.0`, `4.0`, `-0.25`) so `0.05` never becomes `5e-05`.
6. **Palette registration contract.** GCS registers `ScaffoldPalette.lightPalette`, `defaultPalette`, and `ScaffoldDimens.defaultDimens`. The generator must keep emitting those exact static member names. A Dart test already referencing them guards this; add one that constructs each via the public names.
7. **Midnight preset.** Same templates, second token file, different output file names and class/const names (`ScaffoldPalette.midnightPalette`). The preset is data; no template fork. Zero brand names in output, including the `_comment` and file headers: the generated header must say "design_tokens_midnight.json", not any app name.
8. **Header comment.** Generated files carry a fixed header (`// GENERATED by scaffold_codegen.generators.theme_defaults from design_tokens.json -- do not edit.`). Never include timestamps or absolute paths (breaks byte-identity).
9. **CMake.** The existing `DESIGN_TOKENS` CACHE variable and `DEPENDS` lists stay as-is. The theme output is committed under `lib/`, not built via CMake, so do NOT add a CMake target for it. Add `design_tokens.json` as a dependency only if a CMake step later needs the Dart output (not in scope).
10. **Goldens gate.** The "goldens of defaults unchanged" gate reuses the Phase 11 dual-theme capture harness. That harness is a writer, not an assertion (PROJECT.md). The gate should compare capture bytes before and after (script or `git diff --exit-code images/`) rather than add golden gating to CI.

## Drift check design

Two layers, both cheap:

```python
# tools/tests/test_theme_codegen_drift.py (sketch)
def test_committed_theme_matches_generator(tmp_path):
    render_all(out_dir=tmp_path)
    for name in GENERATED_THEME_FILES:
        assert (tmp_path / name).read_bytes() == (LIB_THEME_DIR / name).read_bytes()
```

```yaml
# .github/workflows/ci.yaml, python job, after Test
- name: Generator drift check
  run: |
    for g in animated_display composites formatted_value image_placeholder selection_indicator theme_defaults; do
      PYTHONPATH=tools python -m scaffold_codegen.generators.$g
    done
    git diff --exit-code lib/
```

The CI step checks all families (fixing the known gap), the pytest guards theme output locally on every `pytest` run, including on Windows. Keep the driver list in one place (a `GENERATORS` tuple in `generators/__init__.py` that both CONTRIBUTING.md's loop and CI reuse) so a new generator cannot be forgotten.

## What NOT to add

| Do not add | Reason |
|------------|--------|
| `build_runner`, `source_gen`, `code_builder`, `build`, `dart_style` to `pubspec.yaml` | Second generator; formatter-coupled bytes; SDK floor mismatch (`build_runner` 2.17.1 needs `^3.11.0`); leaks into consumers' resolution. |
| `style-dictionary` / Node / `package.json` | New runtime and a format migration for no consumer. No Flutter target ships with it. |
| DTCG `$value`/`$type` migration | Defer until a design tool export is an actual requirement. |
| `dart format` call from Python | Couples generator output to the installed Dart SDK. |
| `mason`, `freezed`, `json_serializable` | Not needed; ThemeExtensions are small hand-shaped classes, copyWith/lerp come from the template. |
| `flex_color_scheme`, `theme_tailor` | `theme_tailor` is itself a `build_runner` generator for ThemeExtensions; same objections, plus it generates into `.g.dart` outside the token pipeline. |
| A second token file format per preset | One JSON shape, two files. |
| New Python deps (pydantic, jsonschema) | Validate token shape with a small explicit check in the driver (fail early, per project rules). Add `jsonschema` only if token files start being authored by other teams. |

## Installation

```bash
# No new packages. Existing setup:
python -m pip install -e ".[dev]"
```

## Version snapshot (checked 2026-10-16)

| Tool | Latest | Status here |
|------|--------|-------------|
| Jinja2 | 3.1.6 | In use, pin stays `>=3.1` |
| style-dictionary | 5.6.1 (Node >=22) | Rejected |
| build_runner | 2.17.1 (Dart ^3.11.0) | Rejected |
| dart_style | 3.1.14 | Not used from codegen |

## Open questions for planning

- Confirm `engine.render_template` writes LF on Windows (likely needs `newline="\n"`); fix before the first generated theme file is committed. LOW risk, high annoyance if missed.
- Confirm `dart` is on PATH for contributors (it was not in this shell); the tripwire step `dart format --set-exit-if-changed` runs on the Dart CI job, so contributors do not need it locally.
- Decide whether `ScaffoldPalette` keeps hand-written non-token members (e.g. doc comments, `lerp` helpers) or becomes fully generated. Recommendation: fully generated for token fields, so doc comments live in the token JSON (`"doc"` key) and are rendered into `///` lines.

## Sources

- Repo: `tools/scaffold_codegen/{__init__,engine,m3_tokens_css}.py`, `generators/selection_indicator.py`, `pyproject.toml`, `pubspec.yaml`, `.github/workflows/ci.yaml`, `CONTRIBUTING.md`, `MILESTONE-CONTEXT.md` (HIGH)
- npm registry `style-dictionary` latest = 5.6.1, engines node >=22 (HIGH, queried 2026-10-16)
- pub.dev API `build_runner` 2.17.1 (sdk ^3.11.0), `dart_style` 3.1.14 (HIGH, queried 2026-10-16)
- PyPI `jinja2` 3.1.6 (HIGH)
- Style Dictionary v5 DTCG 2025.10 conformance: not confirmed from primary sources (LOW); not decision-relevant since DTCG is rejected
