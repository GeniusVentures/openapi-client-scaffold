# Requirements: frontend_scaffold, v1.4 Design Tokens & Midnight Preset

**Defined:** 2026-10-16
**Core value:** one token source for the Dart theme and CSS, plus an opt-in `midnight` preset with the GeniusWallet look, without breaking consumers.
**Queued behind this milestone:** v1.3 POS-General Interaction Primitives. Its staged requirements are in `.planning/milestones/v1.3-REQUIREMENTS-queued.md`.
**Research:** `.planning/workstreams/scaffold/research/SUMMARY.md`

## v1.4 Requirements

### Token pipeline

- [x] **TOK-01**: `design_tokens.json` gains an additive `scaffold` namespace holding every value behind `ScaffoldPalette` (light and dark) and `ScaffoldDimens`. Existing M3 keys are unchanged.
- [x] **TOK-02**: The Python/Jinja2 codegen generates the default values in `scaffold_palette.dart` and `scaffold_dimens.dart` from `design_tokens.json`. At the refactor commit, the output is byte-identical to the hand-written code.
- [x] **TOK-03**: A drift check (pytest plus a `--check` mode) fails when the committed Dart or CSS differs from what regeneration produces.
- [x] **TOK-04**: All codegen writes LF line endings, and `.gitattributes` pins LF for generated files.

### Theme fields

- [x] **THM-01**: Shadows are themeable through a new `ThemeExtension`, with light and dark values whose defaults match today's output.
- [x] **THM-02**: Typography is themeable through a new `ThemeExtension`, with defaults matching today's output.
- [x] **THM-03**: Motion durations and curves come from tokens, with defaults equal to `ScaffoldMotion` today.
- [x] **THM-04**: Gradients are themeable through a new `ThemeExtension` (none by default).
- [x] **THM-05**: Accent, `borderControl` and on-surface brand tokens exist with defaults equal to today's colors.
- [x] **THM-06**: The `ScaffoldPalette` and `ScaffoldDimens` constructors and public field names are unchanged. New extensions fall back to defaults when an app doesn't register them.
- [x] **THM-07**: The hard-coded white in the text field and drawers is replaced with tokens. At this commit, the defaults reproduce today's output.

### Midnight preset

- [ ] **PRE-01**: A consumer can opt into `midnight` (light and dark) with one call, from a preset generated from its own token file in `lib/`.
- [ ] **PRE-02**: The preset reproduces the wallet token map (colors, spacing, radius, type, motion, shadows, gradients) documented in research/FEATURES.md, with no brand names in `lib/` or `example/`.
- [ ] **PRE-03**: The example app can switch between the default and midnight presets in both modes.

### Restyles

- [ ] **RST-01**: Components whose wallet look can't be reached with tokens alone are restyled behind the preset. The candidates are the 15 restyles in research/FEATURES.md. The defaults keep today's look.

### Accessibility and defaults

- [ ] **A11Y-01**: Default palettes pass WCAG AA in light and dark. The known failures to fix are the light focus ring, `gray500` and light `statusSuccess`. The captures are re-baselined in a dedicated commit.
- [ ] **A11Y-02**: The light-mode text field and drawer contrast bug is fixed in its own commit, followed by its own capture re-baseline commit.
- [ ] **A11Y-03**: An automated contrast test covers the default and midnight palettes in both modes.

### Release gates

- [ ] **GATE-01**: The capture harness gate re-runs the harness and diffs `images/`. Captures change only in the Phase 14 capture re-baseline commits listed in 14-COLOR-CHANGES.md.
- [ ] **GATE-02**: GeniusCognitiveSystem builds and passes its tests against the v1.4 develop head. Its team is told about the default color changes from A11Y-01.

## Future Requirements

- GeniusWallet adopting the scaffold and the preset (separate work in the wallet repo).

## Out of Scope

- Style Dictionary or the DTCG token format: needs Node 22 and a migration, and nothing consumes it.
- build_runner codegen: its Dart floor is above the repo's ^3.10.
- Driving Dart generation from the CMake `DESIGN_TOKENS` override: that override stays CSS-only.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TOK-01 | Phase 12 | Complete |
| TOK-02 | Phase 12 | Complete |
| TOK-03 | Phase 12 | Complete |
| TOK-04 | Phase 12 | Complete |
| THM-01 | Phase 13 | Complete |
| THM-02 | Phase 13 | Complete |
| THM-03 | Phase 13 | Complete |
| THM-04 | Phase 13 | Complete |
| THM-05 | Phase 13 | Complete |
| THM-06 | Phase 13 | Complete |
| THM-07 | Phase 13 | Complete |
| A11Y-01 | Phase 14 | Pending |
| A11Y-02 | Phase 14 | Pending |
| PRE-01 | Phase 15 | Pending |
| PRE-02 | Phase 15 | Pending |
| PRE-03 | Phase 15 | Pending |
| A11Y-03 | Phase 15 | Pending |
| RST-01 | Phase 16 | Pending |
| GATE-01 | Phase 17 | Pending |
| GATE-02 | Phase 17 | Pending |

**Coverage:** 20/20 v1.4 requirements mapped, each to exactly one phase. No orphans.

| Phase | Name | Requirements |
|-------|------|--------------|
| 12 | Token Pipeline | TOK-01..04 |
| 13 | Theme Fields | THM-01..07 |
| 14 | Default Accessibility Fixes | A11Y-01, A11Y-02 |
| 15 | Midnight Preset | PRE-01..03, A11Y-03 |
| 16 | Component Restyles | RST-01 |
| 17 | Release Gates | GATE-01, GATE-02 |
