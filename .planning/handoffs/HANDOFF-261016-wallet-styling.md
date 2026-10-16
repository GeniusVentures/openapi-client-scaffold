# Handoff: give the scaffold components the GeniusWallet design

From a GeniusWallet session on 2026-10-14/15. Nothing has been changed in this repo yet; no branches, no PRs.

## Plan
Full write-up (findings, token map, steps): https://claude.ai/artifact/D3ZYqwd4vjwjMMGgd2Y7Ch

## What Braian decided
- Goal now: update the scaffold components to have the same design as the wallet. The wallet adopting the scaffold comes later, as separate work.
- `design_tokens.json` must be the single source of truth for both the Dart theme and the Jinja2/CSS templates, with no drift (generate one from the other and check it in CI or a test).
- We own the repo, as long as other apps that use it don't break.

## Apps that use the scaffold (checked 2026-10-14)
- GeniusCognitiveSystem: on current main; registers `ScaffoldPalette.lightPalette`, `defaultPalette` and `ScaffoldDimens.defaultDimens` as-is (`src/app/lib/theme/gcs_theme.dart`) and renders its chat templates from the scaffold's `design_tokens.json`. Changing the defaults changes GCS.
- GeniusSoftwareManager and genius-ai-boss: about 240 commits behind, CMake API codegen only, no Dart widgets.

## Recommended order
1. Refactor first: generate the Dart defaults from `design_tokens.json`, plus a drift check. Output must be byte-identical to today.
2. Full token map (wallet `GWColors`, spacing, radius, type, motion, shadows, gradients in GeniusWallet `lib/theme/`).
3. Add missing theme fields (themeable shadows with light/dark, typography, motion, gradients) with defaults equal to today's look.
4. Wallet look as an opt-in preset, so GCS is unaffected (recommended over changing the defaults).
5. Restyle components where tokens aren't enough.
6. Gates: WCAG AA both modes, golden screenshots of the defaults unchanged, GCS built against the branch.

## Answered 2026-10-16
- Preset name: `midnight`.
- The preset ships inside the scaffold as an opt-in (in `lib/`, generated from its own token file).
- GCS team: don't notify before step 1; notify when the preset lands.

## Environment
- Demo app runs on the Linux box `slave` at http://slave:8095 (static web build of `example/`, repo at `~/gnus/openapi-client-scaffold`; rebuild with `flutter build web` in `example/`). Full run permission on slave.
- Flutter SDK on this PC: `C:\Users\User\Documents\Projects\GNUS\flutter\flutter\bin` (not on PATH).
