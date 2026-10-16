# Domain Pitfalls

**Domain:** Token codegen + new ThemeExtension fields + opt-in preset in a Flutter widget library consumed as a pinned submodule by 3 apps
**Milestone:** v1.4 Design Tokens & Midnight Preset
**Researched:** 2026-10-16
**Confidence:** HIGH for repo-specific findings (read from code, contrast computed); MEDIUM for Flutter behaviors cited from general knowledge (verify in plan-phase)

## Phase labels used below

Roadmap is not yet written. These labels are the suggested split; remap when the roadmap exists.

- **P1 Token pipeline:** extend `design_tokens.json`, Dart generator, drift gate (feature 1, 2)
- **P2 Theme fields:** shadows, typography, motion, gradients on the theme extensions (feature 3)
- **P3 Midnight preset:** `midnight` token file, generated preset, opt-in wiring (feature 4)
- **P4 Component restyles:** (feature 5)
- **P5 Gates:** WCAG, defaults-unchanged images, GCS build, handoff

## Critical Pitfalls

### 1. CRLF output from the Python writers on Windows (owner: P1)
**What goes wrong:** `engine.py:144` and `m3_tokens_css.py:279` use `Path.write_text(..., encoding="utf-8")` with no `newline=`. On Windows that converts `\n` to `\r\n`. There is no `.gitattributes` and `core.autocrlf` is `false`, so a generated `.dart` file made on Windows is committed with CRLF. Linux CI then regenerates LF and the drift diff fails, or worse, it passes locally and fails on CI only.
**Why it happens:** All current committed files are `i/lf w/lf`, so the problem has not shown up. Existing generators are only run on Linux/WSL-style shells by habit. The author machine is Windows 11.
**Consequences:** "Byte-identical" claim is false on the author machine. Whole-file diffs on every regenerate. Consumers' submodule pin shows noisy diffs.
**Prevention:**
- The new Dart emitter writes bytes: `path.write_bytes(text.encode("utf-8"))`, or `open(..., "w", newline="\n")`. Fix the shared writer in `engine.py`, do not add a second one.
- Add `.gitattributes` with `* text=auto eol=lf` (or at least `*.dart *.css *.json *.py text eol=lf`). This is the only protection against a CRLF checkout of `design_tokens.json` or fixtures.
- Drift test reads generated files with `read_bytes()` and asserts `b"\r" not in data`.
**Detection:** `git ls-files --eol lib/ | grep -v "i/lf *w/lf"` returns anything. `git diff --stat` after regenerate on Windows shows every line changed.

### 2. Drift gate that is not actually in CI (owner: P1)
**What goes wrong:** CONTRIBUTING.md says CI does not regenerate and diff; the D-16 check is manual and already failed once (commit `ed8859b`). A new token generator with a "manual pre-PR check" will drift the same way, and the drift now affects three consuming apps.
**Prevention:**
- Add a pytest (runs in the existing `python` CI job, `testpaths = ["tools/tests"]`) that regenerates the token-derived Dart into a temp dir and compares bytes to the committed files. Do not rely on a `git diff` step only, because the pytest also runs locally on Windows.
- Also add a CI step running the generators then `git diff --exit-code lib/` so the existing five families get covered too. Do this as its own small commit, before the token work (refactor first, then change behavior).
- The generator takes the token file path and output path as arguments so the same code serves the defaults and the `midnight` file.
**Detection:** Hand-edit a generated token file; CI must go red.

### 3. Adding a required field to `ScaffoldPalette` / `ScaffoldDimens` breaks consumers (owner: P2)
**What goes wrong:** Both classes have all-`required` named constructor params and a `const` constructor. GCS registers `ScaffoldPalette.lightPalette`, `defaultPalette`, `ScaffoldDimens.defaultDimens`, which survive. But any app that calls `ScaffoldPalette(...)` or `ScaffoldDimens(...)` itself (grep their repos before deciding) stops compiling the moment a new `required` field is added. Public field renames break them the same way.
**Prevention:**
- New fields are non-required with a `const` default that equals today's look, or go in a new `ThemeExtension` (for example a shadows/typography/motion extension) so existing constructors are untouched. Prefer the new extension for shadows, typography, motion, gradients; those do not belong next to color roles.
- Never rename or reorder existing fields. Reordering is silent for named params but breaks positional use of `copyWith`-free subclasses and doc references.
- Keep every default `const` so `static const ScaffoldPalette defaultPalette` and `const List<ThemeExtension<dynamic>> scaffoldThemeExtensions` still compile. Default values must be const expressions: `Curves.*` constants are fine, `LinearGradient`, `BoxShadow`, `TextStyle` are fine, anything built with `.withValues()` or `static final` (like `ScaffoldColors.btnFilterSelected`) is not.
- Add a test that constructs the old API shape (a fixture file compiled against only today's constructor params). If it stops compiling, the contract broke.
- Before merge, build GCS and the other two apps against the branch (also gate G in P5).
**Detection:** `dart analyze` in a consumer shows "missing required argument".

### 4. `copyWith` / `lerp` / equality gaps on the new fields (owner: P2)
**What goes wrong:** Three hand-written members per extension must be updated for every field. Forgetting one compiles fine. Existing tests only check one field (`copyWith(focusRingColor:)`, `copyWith(minTouchTarget:)`), so a new field dropped from `copyWith` or `lerp` passes the suite. Theme switching (`themeAnimationDuration`) then flickers or snaps to defaults, and `copyWith(shadow: x)` silently returns the old value.
**Field-specific traps:**
- `List<BoxShadow>`: use `BoxShadow.lerpList` (handles different lengths). Do not index-lerp manually. Light and dark shadow lists will differ in length.
- `Gradient`: `Gradient.lerp` returns null in some combinations (null on either side, different gradient types). Do not `!` it. Fall back to snapping at `t >= 0.5`.
- `TextStyle`: `TextStyle.lerp` snaps `fontFamily` and interpolates inherit mismatches; wrap, don't hand-roll. Lerping a style with `inherit: true` against `inherit: false` asserts.
- `Curve` and `Duration`: curves do not lerp; snap at `t < 0.5 ? a : b`. Durations lerp via `Duration(microseconds: lerpInt)`, round explicitly.
- `lerp(null, t)` and `lerp(otherType, t)` currently `return this`. Keep that.
- `double` lerp: existing `a + (b-a)*t` is fine; do not mix with `lerpDouble` (nullable).
**Prevention:**
- Generate `copyWith`/`lerp`/`==`/`hashCode` from the same token schema as the fields (one source of truth), or at minimum write a reflection-style test that builds an instance where every field differs from default, then asserts `copyWith()` with every param round-trips, `lerp(a, b, 0)==a`, `lerp(a, b, 1)==b`, and `lerp(a,a,0.5)==a` for all fields. Adding a field without extending the test must fail it (compare the field count to the test's list).
- Tests do not need to touch `==`/`hashCode` unless the code defines them; if the class has none, theme equality uses identity. Do not add `==` to only some.
**Detection:** `lerp(a,b,1) != b` for any field.

### 5. Float and color formatting breaks byte-identity (owner: P1)
**What goes wrong:**
- JSON `8` is a Python `int`; the existing Dart source writes `8.0` (see `minTouchTarget: 48.0`). Generated output of `8` for a `double` field is valid Dart but not byte-identical, and `const double` vs `num` inference changes in some contexts.
- Python `repr(0.1)` is `0.1`, but `1e-05`, `-0.0`, `0.30000000000000004` (if any value is computed rather than read) are not the Dart literals a human wrote.
- Alpha to hex: Python `round()` is banker's rounding. `0.5*255 = 127.5` goes to 128 in Python, 128 in Dart `.round()`, but `0.3*255 = 76.5` goes to 76 in Python and 77 in Dart. Existing `Color(0x59000000)` (comment says "black @ 35%") is 89.25 so it hides the issue.
- Case: current source mixes `Color(0xFF0C0E14)`, `0xff0068ef` (colors.dart) and `Color.fromRGBO(0, 234, 174, 1)` (colors.dart). A generator emits one form. Pick it deliberately and migrate once (the diff of this migration is the only allowed one).
- `design_tokens.json` holds M3 baseline values (`#6750A4`), not the scaffold palette (`#0C0E14`...). The Dart defaults are not in that file today. Moving them in is new data entry; a typo is a visual regression no compiler catches.
**Prevention:**
- Store colors as ARGB hex strings in the token file (`"#59000000"`, `"#FF0C0E14"`) and emit them verbatim uppercased. Never compute alpha from a float in the generator. If opacity must be a token, store it as a string-typed hex alpha plus a separate double, and derive nothing.
- Store doubles as JSON floats always (`8.0`); validate in the generator: type must be `float` for double fields, else fail loudly (matches StrictUndefined policy). Emit with a single `_dart_double()` helper that uses `repr`, appends `.0` if there is no `.`/`e`, and rejects `nan`/`inf`/exponent form.
- Do the byte-identity migration in two steps: (1) generate output that is byte-identical to the current hand-written file (including comments, doc comments, and the em-dash characters: files are UTF-8 with non-ASCII, so read/write with explicit `utf-8`), commit; (2) only then extend. The first commit's drift test is the proof.
- Doc comments on fields live in the token file (`"doc"`) or the template, not hand-added later.
- Do not run `dart format` in the generator. Output must be stable independent of the Dart SDK version (CI pins Flutter 3.41, pubspec floor is Dart 3.10). If the generated text must be format-clean, emit canonical form directly and check with `dart format --set-exit-if-changed` only on the Linux CI.
**Detection:** The step-1 diff against the current hand-written files is non-empty.

### 6. WCAG AA gate collides with "defaults unchanged" (owner: P5, decided in P1)
**What goes wrong:** The current defaults already fail AA in places. Computed contrast (WCAG formula):

| Pair | Ratio | Needs | Result |
|------|-------|-------|--------|
| light `lightGreenPrimary` `#00EAAE` focus ring on `#FFFFFF` | 1.57 | 3:1 (1.4.11) | FAIL |
| same on light `grayPrimary` `#F1F3F5` | 1.41 | 3:1 | FAIL |
| light `statusSuccess` `#0AA06B` on `#FFFFFF` | 3.36 | 4.5:1 text | FAIL |
| `gray500` `#73788C` on `#FFFFFF` | 4.38 | 4.5:1 | FAIL (narrowly) |
| `gray500` on light `#F1F3F5` | 3.94 | 4.5:1 | FAIL |
| `gray500` on dark `#0C0E14` | 4.40 | 4.5:1 | FAIL (narrowly) |
| `blue500` `#0068EF` on dark `#0C0E14` | 3.88 | 4.5:1 text | FAIL as text |
| dark `textSecondary` `#8A8F9D` on `#0C0E14` | 5.97 | 4.5:1 | pass |
| light `textSecondary` `#5A6070` on `#F1F3F5` | 5.65 | 4.5:1 | pass |

A blanket "WCAG AA in both modes" test run on the defaults is red on day one. "Fix" it and the defaults change, which breaks the unchanged-defaults gate and the GCS look.
**Prevention:**
- Decide in P1 (written into the plan): the AA gate covers the `midnight` preset and the new tokens only. Existing defaults get a named, dated exemption list in the test with each failing pair and a follow-up ticket. Do not silently loosen thresholds.
- Never change `defaultPalette` / `lightPalette` values in this milestone. If a default needs fixing, that is a separate consumer-visible change called out in the commit message.
- Contrast check is a Dart unit test using the real `Color` values (`computeLuminance()` is WCAG-compatible; `Color.alpha` must be composited over the real background first, since `borderSubtle` `0x1FFFFFFF` and `dropZoneHighlight` `0x3300EAAE` are translucent). Text pairs 4.5:1 (large text 3:1), non-text/focus 3:1.
- The preset test iterates every declared (foreground, background) pair from a list kept next to the token file; a new token without a declared pair fails the test.
**Detection:** Red contrast test on defaults at first run (expected, handled by exemption list).

### 7. "Goldens of defaults unchanged" has no golden mechanism today (owner: P5, harness work in P1)
**What goes wrong:** PROJECT.md records the capture harness as "a WRITER, not an assertion; no golden pixel gating in CI." There are 52 committed PNGs in `images/`, but nothing compares against them. The harness also:
- loads Roboto from the local Flutter SDK dir `bin/cache/artifacts/material_fonts` (version-dependent; CI is pinned to 3.41, a dev machine may not be),
- renders text rasterized per platform (Windows author machine vs Linux CI differ at the pixel level in antialiasing),
- has a known open bug: Roboto-Medium is registered as family `'Roboto Medium'`, so `w500` renders Regular. Fixing it changes every PNG.
**Why it matters:** The gate as written cannot be passed or failed objectively. Anyone regenerating images on Windows will produce a diff that looks like a regression or hides one.
**Prevention:**
- Pick the gate form in P1, before restyling: (a) value-level gate: a test asserts `ScaffoldPalette.defaultPalette`/`lightPalette`/`defaultDimens` and the new default extension values equal frozen literals (`==` per field); and (b) render-level gate: `matchesGoldenFile` goldens captured on Linux CI only, for a small fixed set (one dark, one light of five or six key widgets), generated by the same harness fonts. Do not gate on the 52 gallery PNGs.
- Keep goldens in a separate `test/goldens/` directory, update them with an explicit `--update-goldens` commit, never in the same commit as a code change.
- Do not fix the Roboto-Medium bug in this milestone, or fix it first in its own commit and re-baseline. Carry it as a known-diff note.
- Deterministic settings: `themeAnimationDuration: Duration.zero`, fixed surface size, `devicePixelRatio = 1.0`, no running timers/animations (`ScaffoldMotion` durations: settle or disable via `TickerMode`/`MediaQuery.disableAnimations`), `Skeleton` shimmer and streaming-cursor widgets excluded.
- Goldens compare with a local-comparator tolerance of 0 only on Linux CI; on Windows, skip with a clear reason (test tag) rather than letting authors regenerate.
**Detection:** A golden test that passes on one OS and fails on the other.

## Moderate Pitfalls

### 8. Shadow tokens in dark mode (owner: P2, verified P4)
**What goes wrong:** `ScaffoldElevation.card` is a static dark-tuned shadow (black @ 35%, blur 16, dy 4) used by `toast_widget.dart` in two places. Making it themeable and "fixing" the light value changes the look for existing consumers; and black shadows on near-black surfaces (`#0C0E14`) are invisible, so the wallet look needs a border, a lighter glow, or a surface-tint step instead.
**Prevention:**
- Default light and default dark shadow lists both equal today's `ScaffoldElevation.card` so existing renders are identical. Keep `ScaffoldElevation.card` as a `static const` alias that points at the same data, do not delete (public contract).
- In midnight dark mode, express elevation as border plus lighter surface, not black alpha. Document in the token file with a `"mode"`.
- Resolve shadows by `Theme.brightness` or the registered extension, not by `MediaQuery.platformBrightness` (the example app uses `ThemeData` per brightness).
- `BoxShadow` with `blurStyle: normal` and large radii on Skia/Impeller render slightly differently; confirm in the one golden, not in many.

### 9. Gradients and contrast, banding, and lerp (owner: P2, P4)
**What goes wrong:** Text on a gradient must meet AA against the worst stop, not the average. Dark low-contrast gradients band visibly on 8-bit displays. A gradient with different stop counts, or `null` vs non-null, lerps unexpectedly (see pitfall 4).
**Prevention:**
- The contrast test samples each stop and a few interpolated points (0, 0.25, 0.5, 0.75, 1) for any declared text-on-gradient pair.
- Gradient tokens carry `begin`/`end` as alignment names, `colors` and `stops` as arrays; the generator validates `len(colors) == len(stops)` and that stops ascend. Defaults are `null` (no gradient), so today's flat looks are unchanged.
- Gradient direction is `AlignmentDirectional`, not `Alignment`, if RTL matters for the consumers. Decide in P2 and test once.

### 10. Font loading (owner: P3)
**What goes wrong:** `pubspec.yaml` has no `fonts:` section and the package is consumed as a git submodule. A `fontFamily: 'Foo'` in the preset only renders when the app or package declares the asset. Package-bundled fonts need the `packages/frontend_scaffold/Foo` family name. In tests the font is absent and falls back to Ahem unless the harness loads it, which changes glyph widths and layouts (overflows, `AutoSizeText` choices). Using `google_fonts` fetches at runtime and breaks offline/test.
**Prevention:**
- Preset typography sets the family name and `fontFamilyFallback: ['Roboto', ...]` only; it does not bundle font files in `lib/` unless the licence is checked and the weights are in the repo (another ship-size cost for 3 apps). Document the one line consumers add to their own `pubspec.yaml`.
- Key design decision already exists: font choice lives in `scaffold_theme.dart`, not in widgets. Keep it there; the preset restyles through `TextTheme`/the typography extension.
- Text-metric-dependent widget tests should use `Ahem` deliberately and assert on keys, not pixels. Only the capture harness uses real fonts.
- `TextStyle` tokens must keep `height` as a multiplier. `design_tokens.json` `lineHeight` is in px (the CSS generator appends `px`). Converting px to a Flutter `height` multiplier is `lineHeight / size`; getting it wrong silently changes vertical rhythm. Emit the ratio from a single helper and test it against the M3 table.

### 11. Breaking GCS' use of `design_tokens.json` (owner: P1)
**What goes wrong:** `m3_tokens_css.py` reads `color.roles`, `typography.scale`, `shape.corner`, `elevation` and uses `sorted()` and `.get(...)`. GCS renders from this file. Moving scaffold palette/dimension values into it by re-shaping existing keys, or by adding keys the CSS emitter now iterates (for example a new top-level `elevation` entry with the wrong shape), changes CSS output or crashes it.
**Prevention:**
- Additive only: new top-level namespaces (for example `scaffold`, `preset`), no changes to the four existing blocks. Keep the CSS output file byte-identical to the current one; add a pytest that renders the current `design_tokens.json` and compares against a frozen fixture (existing `test_m3_tokens_css.py` is the base to extend).
- Add a JSON-schema check (or a strict validator in the generator) that rejects unknown keys at the top level so typos do not silently disappear.
- Do not build a second path: extend `m3_tokens_css.py`'s module (loader, kebab helper) as the notes say; share the loader.
- The midnight preset gets its own token file, not new keys in `design_tokens.json`, so GCS' file stays untouched.

### 12. Brand names leaking into `lib/` and `example/` (owner: P3, P5)
**What goes wrong:** Token names copied from the wallet's `lib/theme/` (`GWColors`, `gw*`, brand-named gradients, the source repo name in a "generated from" header) end up in generated Dart or in the example app. Violates PROJECT.md rule.
**Prevention:** Token file keys use role names only. A pytest greps `lib/` and `example/` (and the generated headers) for a deny-list (brand, product, and repo names) and fails. Generated headers say "generated from `<token file name>`", with no absolute path (Windows paths with backslashes would also break byte-identity across machines).

### 13. Opt-in preset leaks into defaults (owner: P3)
**What goes wrong:** Registering the preset in `scaffoldThemeExtensions` or a `ThemeData` helper that existing apps already call changes their look. A new import in the barrel that pulls the preset in is harmless, but a default-argument change is not.
**Prevention:** `scaffoldThemeExtensions` stays byte-identical in value. The preset lives in a new file and is applied only through an explicit call (for example `ScaffoldMidnight.extensions`). A test asserts `scaffoldThemeExtensions` equals the frozen defaults. Do not add the preset to the example app default theme; offer a toggle.

## Minor Pitfalls

### 14. Stale numbers in docs and CI claims
CLAUDE.md and CONTRIBUTING.md say 214 tests; PROJECT.md says 454. Do not hard-code a test count in new gates or docs; assert "suite green" instead.

### 15. Python tooling differences on Windows
`python3` may not exist on PATH; the documented drift check uses `python3 -m`. Use `PYTHONPATH=tools python -m ...` through the pytest, not a shell loop, so the gate runs identically on both OSes. Do not embed `Path.resolve()` output or timestamps in generated headers.

### 16. Restyling tests asserting old pixels
Component restyles (P4) that change layout for the preset only must be behind the preset's values, not new defaults. A restyle that changes default metrics (padding, radius) fails pitfall 7 even if tokens are untouched. Add a "default look" widget test per restyled component that reads resolved sizes with default extensions.

## Phase-Specific Warnings

| Phase | Likely Pitfall | Mitigation |
|-------|---------------|------------|
| P1 Token pipeline | CRLF writes (1), drift gate not in CI (2), float/color formatting (5), breaking GCS JSON (11), golden mechanism missing (7) | Fix writer + `.gitattributes` first; step-1 byte-identical regeneration commit; additive JSON; decide gate form |
| P2 Theme fields | Required-field break (3), copyWith/lerp gaps (4), shadows (8), gradients (9) | Defaults const and optional or new extension; exhaustive field test; shadow defaults = today's |
| P3 Midnight preset | Fonts (10), brand names (12), preset leaks into defaults (13) | Family name only, deny-list test, explicit opt-in API |
| P4 Component restyles | Default look changes (16), dark shadows (8), gradient contrast (9) | Restyle behind preset values; default-look tests |
| P5 Gates | WCAG vs unchanged defaults (6), golden flakiness (7), GCS build, notify GCS only after preset lands | Exemption list for existing defaults; Linux-only goldens; build all three consumers against the branch |

## Research Flags

- P1: needs a short spike on whether `dart format` is needed on the generated output and on the exact first-pass byte-identical emitter (high leverage, small).
- P5: needs a decision on golden scope before P2 starts, because P2 changes get validated by it.
- P2: verify `Gradient.lerp` / `BoxShadow.lerpList` / `TextStyle.lerp` null and mismatch behavior against Flutter 3.41 source (MEDIUM confidence here, from general knowledge).
- Consumer grep (3 repos) for direct `ScaffoldPalette(` / `ScaffoldDimens(` construction: not done; only the GCS registrations are documented. Needed before P2.

## Sources

- `design_tokens.json`, `tools/scaffold_codegen/m3_tokens_css.py`, `tools/scaffold_codegen/engine.py` (write path)
- `lib/theme/scaffold_palette.dart`, `scaffold_dimens.dart`, `scaffold_elevation.dart`, `scaffold_theme.dart`, `scaffold_colors.dart`
- `example/test/capture_images_test.dart` (font loading, writer-not-assertion)
- `.planning/PROJECT.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `.github/workflows/ci.yaml`, `pyproject.toml`
- WCAG 2.x contrast formula (computed locally); 1.4.3 text 4.5:1, 1.4.11 non-text 3:1
- `git ls-files --eol` (all current files LF; no `.gitattributes`)
