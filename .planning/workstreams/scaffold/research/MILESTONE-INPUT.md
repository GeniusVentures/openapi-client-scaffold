# Milestone context: v1.4 Design Tokens & Midnight Preset

Queued after v1.3 (POS-General Interaction Primitives). Start it with `/gsd-new-milestone --ws scaffold` once v1.3 is done, or earlier if Braian reprioritizes.

Source: `.planning/handoffs/HANDOFF-261016-wallet-styling.md`. Plan: https://claude.ai/artifact/D3ZYqwd4vjwjMMGgd2Y7Ch

## Goal
Give the scaffold components the GeniusWallet design as an opt-in preset, without changing the look of existing consumers.

## Target features
1. `design_tokens.json` is the single source for the Dart theme defaults and the Jinja2/CSS templates. The Dart defaults are generated from it with byte-identical output, and a test or CI step checks for drift.
2. A full token map from GeniusWallet `lib/theme/`: colors (`GWColors`), spacing, radius, typography, motion, shadows, gradients.
3. New theme fields: themeable shadows (light and dark), typography, motion, gradients. Their defaults equal today's look.
4. An opt-in `midnight` preset shipped in the scaffold (`lib/`), generated from its own token file.
5. Component restyles where tokens alone can't reach the wallet look.

## Constraints
- No brand names in `lib/` or `example/` (hence `midnight`).
- Other apps must not break. GeniusCognitiveSystem registers `ScaffoldPalette.lightPalette`, `defaultPalette` and `ScaffoldDimens.defaultDimens` and renders from `design_tokens.json`.
- Gates: WCAG AA in both modes, goldens of the defaults unchanged, GCS builds against the branch.
- Notify the GCS team when the preset lands, not before.

## Notes for kickoff (checked on develop 2026-10-16)
- `tools/scaffold_codegen/m3_tokens_css.py` already reads `design_tokens.json` to produce CSS. Feature 1 extends that path to Dart, so don't build a second one.
- v1.2 added the light `ScaffoldPalette` (Phase 8) and a dual-theme capture harness (Phase 11). Reuse that harness for the "goldens of defaults unchanged" gate.
