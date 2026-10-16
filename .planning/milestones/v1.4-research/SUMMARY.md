# Project Research Summary: v1.4 Design Tokens & Midnight Preset

Self-heal (#222): the synthesizer was blocked from writing this file. The orchestrator wrote it from the synthesizer's return and the four research files.

## Key Findings
- **Stack:** extend the existing Python/Jinja2 codegen (`tools/scaffold_codegen`) with a `generators/theme_defaults.py` driver and templates in `templates/theme/`. No new dependencies. build_runner is out (its Dart floor is above the repo's ^3.10). Style Dictionary is out (it needs Node 22 and a DTCG migration).
- **Token vocabularies differ:** `design_tokens.json` holds stock M3 purple keys, which GCS templates read. The Dart defaults (deep blue and green) are not in it. Add an additive `scaffold` namespace and freeze the existing keys.
- **Generation:** generate from the repo token file only, never the CMake `DESIGN_TOKENS` override. Splice into marked regions of `scaffold_palette.dart` and `scaffold_dimens.dart`, with a `--check` drift mode. Write LF line endings (`engine.py` and `m3_tokens_css.py` don't today) and add `.gitattributes`.
- **API:** the `ScaffoldPalette` and `ScaffoldDimens` constructors stay unchanged. Shadows, typography, motion and gradients become new `ThemeExtension`s with fallback defaults equal to today's look.
- **Wallet gap (FEATURES.md):** scaffold dark already matches wallet dark in most places. Missing: the accent system, `borderControl`, `brandPrimaryOnSurface`, and an `appBarHeight` difference. Shadows, type, motion and gradients aren't themeable. There are 15 component restyles.
- **Gates:** no golden gate exists, because the capture harness only writes images. The gate is to re-run the harness, then `git diff --exit-code images/`.

## Implications for Roadmap
1. Gates and token pipeline (baselines, byte-identical Dart generation, drift check, LF fix)
2. New theme fields (extensions with fallbacks)
3. Midnight preset plus an AA gate scoped to the preset
4. Component restyles
5. Release gates (captures unchanged, GCS builds against develop)

## Open Decisions
- **(a) WCAG AA:** some existing defaults fail AA (light focus ring 1.57:1, `gray500` at or below 4.4:1, light `statusSuccess` 3.36:1). Recommendation: gate only the preset and keep a dated exemption list for the defaults.
- **(b) Hard-coded white** in the text field and drawers: tokenize it with defaults equal to today's output, so captures stay unchanged. Fix the light-mode contrast bug in a separate commit that re-baselines the captures.

## Sources
STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md in this folder.
