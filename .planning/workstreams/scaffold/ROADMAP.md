# Roadmap: Scaffold

The `frontend_scaffold` submodule's own planning record. This workstream owns the
submodule's contents — the `frontend_scaffold` Dart widget package and the `templates/`
directory — so that every consuming repo (genius-ai-boss, genius-tube, and any sibling
project that adds this submodule) shares one source of truth for what the scaffold is and
what changed.

**Provenance**: extracted from `genius-ai-boss/.planning/workstreams/frontend-templates/`
on 2026-08-09. Phase 5 (the consolidation that made this submodule the shared source) is
re-homed here as this workstream's anchor phase. The parent workstream retains Phases 5-8
orchestration history (parent-side CMake/pipeline plans) and continues to own Phases 6-8
(bloc-aware templates, C++ interfaces, build-option wiring) which execute from the parent.

## Milestones

- ✅ **v1.0 Scaffold Shared Source** — Phase 5 (shipped 2026-08-09): submodule established as the single shared widget/template source; `frontend_scaffold` package at v0.3.0
- ✅ **v1.1 Widget Library** — Phases 6-7 (shipped 2026-08-17): 28 widget atoms + ScaffoldMotion + 3 template-generated composites (Phase 6), then media and integration widgets (Phase 7). See [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Atom Extensions** — Phases 8-11 (shipped 2026-08-24): composition atoms, text/code primitives, chart + scrubber, verification & coverage gate. See [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- 🚧 **v1.4 Design Tokens & Midnight Preset** — Phases 12-17 (active, started 2026-10-16): one token source for the Dart theme and CSS, themeable shadows/typography/motion/gradients, default AA fixes, opt-in `midnight` preset, component restyles, release gates. 20 requirements.
- 🕓 **v1.3 POS-General Interaction Primitives** — queued behind v1.4 (created 2026-10-01): SCF-POS-01..18, gated by SCF-POS-18. Phases are numbered and broken down at kickoff, after v1.4 closes.

## Phases

<details>
<summary>✅ v1.0 Scaffold Shared Source (Phase 5) — SHIPPED 2026-08-09</summary>

- [x] **Phase 5: Scaffold Submodule Consolidation** (5/5 plans) — submodule is the single shared source for GeniusWallet bloc widgets and genius-tube C++ interface templates, consumable via pinned submodule (completed 2026-08-09)

</details>

<details>
<summary>✅ v1.1 Widget Library (Phases 6-7) — SHIPPED 2026-08-17</summary>

- [x] **Phase 6: Core UI Foundation** (6/6 plans) — 28 widget atoms + ScaffoldMotion across 4 dependency-layered waves; atoms ship as plain Dart widgets (runtime-parameterized) except 4 template candidates + 3 Jinja2-template-generated composites (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar) (completed 2026-08-14)
- [x] **Phase 7: Media & Integration Widgets** (4/4 plans) — MediaCard (consumes ScaffoldBadge badge slots), MediaControls (consumes ScaffoldPressable + ScaffoldTouchTarget + ScaffoldSlider), WalletConnectSheet (built on existing BottomDrawer); media_card.dart.jinja2 template (completed 2026-08-15)

Full phase details, goals, and success criteria: [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)

</details>

<details>
<summary>✅ v1.2 Atom Extensions (Phases 8-11) — SHIPPED 2026-08-24</summary>

- [x] **Phase 8: Supporting Atoms, Table Cells & Light Palette** (6/6 plans, completed 2026-08-17) — ScaffoldChip/ChipGroup, ScaffoldDisclosure/TraceList, ScaffoldComposer, DataColumnConfig cellBuilder extension, light default palette
- [x] **Phase 9: Text & Code Primitives** (6/6 plans, completed 2026-08-20) — ScaffoldStreamingRichText (incremental render, citations, action slots, a11y), ScaffoldCodeBlock (syntax spans, line numbers, streamed lines), ScaffoldSelectionActions (anchored toolbar)
- [x] **Phase 10: Chart & Scrubber** (6/6 plans, completed 2026-08-22) — ScaffoldChart (neutral series contract), ScaffoldChartScrubber (point selection composing with chart)
- [x] **Phase 11: Verification & Coverage Gate** (3/3 plans, completed 2026-08-23) — per-atom tests/demos/barrel sweep, Beautiful UI 19-component coverage check

Full phase details, goals, and success criteria: [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)

</details>

### 🚧 v1.4 Design Tokens & Midnight Preset (Phases 12-17) — ACTIVE

- [x] **Phase 12: Token Pipeline** - Dart default palette and dimens generate byte-identically from `design_tokens.json`, with a drift check and LF output (completed 2026-10-16)
- [x] **Phase 13: Theme Fields** - Shadows, typography, motion, gradients and accent tokens become themeable with defaults equal to today (completed 2026-10-16)
- [ ] **Phase 14: Default Accessibility Fixes** - Default palettes pass WCAG AA and the light text field and drawers are legible, as two re-baselined commits
- [ ] **Phase 15: Midnight Preset** - Opt-in `midnight` theme (light and dark) in one call, with an example-app switcher and a contrast test over all palettes
- [ ] **Phase 16: Component Restyles** - Components take the midnight look where tokens alone cannot reach it, with default rendering unchanged
- [ ] **Phase 17: Release Gates** - Captures change only in the sanctioned re-baseline commits and GeniusCognitiveSystem builds and passes against develop

## Phase Details

### Phase 12: Token Pipeline

**Goal**: A maintainer edits one token file and the default Dart palette and dimens regenerate from it, with no change to anything a consumer sees.
**Depends on**: Nothing (first phase of v1.4; v1.2 Phase 11 complete)
**Requirements**: TOK-01, TOK-02, TOK-03, TOK-04
**Success Criteria** (what must be TRUE):

  1. `design_tokens.json` has a `scaffold` namespace holding every light and dark `ScaffoldPalette` value and every `ScaffoldDimens` value, while its existing M3 keys and the generated `m3_tokens.css` bytes are unchanged.
  2. Running the Dart generator reproduces the default values in `scaffold_palette.dart` and `scaffold_dimens.dart` byte-for-byte: after regeneration `git diff` on `lib/theme/` is empty.
  3. Changing a token value without regenerating, or hand-editing the generated Dart, makes both pytest and the generator's `--check` mode fail; regenerating clears the failure.
  4. Regenerating on Windows leaves LF line endings in every generated file and produces no whole-file diff, because `.gitattributes` pins LF for them.
  5. Re-running the capture harness leaves `images/` unchanged, and the const extension list GeniusCognitiveSystem registers (`ScaffoldPalette.lightPalette`, `defaultPalette`, `ScaffoldDimens.defaultDimens`) still compiles.

**Plans**: 3 plans

Plans:

- [x] 12-01-PLAN.md — (wave 1) `scaffold` token namespace + `theme_defaults` driver: palette and dimens defaults generated byte-identically, `--check`, Dart parity test
- [x] 12-02-PLAN.md — (wave 1) LF writes in engine and CSS generator, `.gitattributes`, committed CSS snapshot with `m3_tokens_css --check`
- [x] 12-03-PLAN.md — (wave 2) generator runner + CI drift step, docs, consumer contract test, capture-harness gate

### Phase 13: Theme Fields

**Goal**: An app can theme shadows, typography, motion, gradients and the accent, border-control and on-surface brand colors, and an app that registers none of them sees exactly today's output.
**Depends on**: Phase 12
**Requirements**: THM-01, THM-02, THM-03, THM-04, THM-05, THM-06, THM-07
**Success Criteria** (what must be TRUE):

  1. An app registering its own shadow, typography, motion and gradient extensions in `ThemeData` sees widgets that draw those values (toast shadow, motion durations and curves, overflow-fade gradient, text-field font) pick up the registered values.
  2. An app registering none of the new extensions renders as before: defaults equal today's `ScaffoldElevation.card`, `ScaffoldMotion` durations and curves, and text styles; gradients are none; accent, `borderControl` and on-surface brand tokens default to today's colors.
  3. `ScaffoldPalette` and `ScaffoldDimens` keep their constructors and public field names, and a consumer-contract test that compiles the const extension list used by GeniusCognitiveSystem passes.
  4. The text field and the drawers read the colors they used to hard-code as white from tokens, and with default values the light and dark captures are pixel-identical to before.
  5. Template-generated families touched by the migration were changed in `templates/components/*.jinja2` and regenerated, and the generator drift check is clean.

**Plans**: 5 plans

Plans:

- [x] 13-01-PLAN.md — (wave 1) tracer: ScaffoldShadows from token to toast; ScaffoldMotionTheme and ScaffoldTypography generated from `scaffold` tokens, with `context` getters
- [x] 13-02-PLAN.md — (wave 2) ScaffoldColorRoles and ScaffoldGradients; text field, drawer and overflow fade on tokens; consumer contract covers new getters
- [x] 13-03-PLAN.md — (wave 2) hand-written components read `context.motion` and the mono family
- [x] 13-04-PLAN.md — (wave 2) animated_display, search_bar and selection_indicator templates read `context.motion`, regenerated
- [x] 13-05-PLAN.md — (wave 3) docs, full CI gate, same-machine capture comparison against b618159, GCS harness

### Phase 14: Default Accessibility Fixes

**Goal**: The default light and dark palettes meet WCAG AA, and the default light-mode text field and drawers are legible, each fixed in its own commit with re-baselined captures.
**Depends on**: Phase 12, Phase 13
**Requirements**: A11Y-01, A11Y-02
**Success Criteria** (what must be TRUE):

  1. An automated contrast check over the default palettes passes in light and dark, including the three known failures: the light focus ring, `gray500`, and light `statusSuccess`.
  2. In the default light theme, text typed into the text field and the drawer title, close icon and divider are readable (dark on light), fixed in a commit separate from the palette fix.
  3. After each of the two fixes, re-running the harness changes only the captures those fixes affect, and those images are re-baselined in that same commit; no other capture moves.
  4. Both fixes are token-value changes: the regenerated Dart matches the token file and the drift check is clean.
  5. Every default color that changed is recorded with its old and new value, so the GeniusCognitiveSystem notice in Phase 17 can be written from that record.

**Plans**: TBD

### Phase 15: Midnight Preset

**Goal**: An app can switch to the midnight look, light and dark, with one call, and the example app shows it, while apps that do not opt in see no change.
**Depends on**: Phase 13, Phase 14
**Requirements**: PRE-01, PRE-02, PRE-03, A11Y-03
**Success Criteria** (what must be TRUE):

  1. One call (deep import, not exported from the barrel) returns the midnight `ThemeData` and extensions for light or dark, generated from its own token file in `lib/`, and the generator's `--check` mode covers that file.
  2. The preset reproduces the documented wallet token map: cyan, mint and purple accents, the surface ladder, spacing, radius, type, motion, shadows and gradients; a grep finds no brand names in `lib/` or `example/`.
  3. The example app switches between the default and midnight presets in both light and dark, and the default captures stay unchanged.
  4. An automated contrast test passes for both the default and midnight palettes in light and dark, covering text, status, control-border and focus-ring pairs.

**Plans**: TBD
**UI hint**: yes

### Phase 16: Component Restyles

**Goal**: Under the midnight preset, components that tokens alone cannot restyle show the wallet look, and under the defaults they look exactly as they do today.
**Depends on**: Phase 15
**Requirements**: RST-01
**Success Criteria** (what must be TRUE):

  1. With midnight active in light and dark, the component restyles chosen from the candidate list in research/FEATURES.md (card and surface, hover treatment, buttons, input, sheets and drawers, selection indicators and accent call sites, toast) visibly take the wallet look in the midnight captures.
  2. With the default preset, re-running the capture harness leaves every existing capture unchanged; restyles are driven by extension values, with no preset check inside widgets.
  3. Restyles of template-generated families were made in `templates/components/*.jinja2` and regenerated, and the drift check is clean.
  4. The contrast test from Phase 15 still passes for midnight in both modes after the restyles.

**Plans**: TBD
**UI hint**: yes

### Phase 17: Release Gates

**Goal**: v1.4 is shown to be non-breaking: default captures changed only in the two sanctioned re-baseline commits, and GeniusCognitiveSystem builds and passes against develop.
**Depends on**: Phase 16
**Requirements**: GATE-01, GATE-02
**Success Criteria** (what must be TRUE):

  1. Re-running the capture harness on the v1.4 develop head and diffing `images/` shows differences only from the A11Y-01 and A11Y-02 re-baseline commits; history shows no other commit touched an existing capture.
  2. GeniusCognitiveSystem builds and passes its tests against the v1.4 develop head of the scaffold.
  3. The GeniusCognitiveSystem team has a written notice listing each changed default color with its old and new value.
  4. At the same head, `dart analyze --fatal-infos`, `flutter test`, `ruff check`, `pytest` and the generator `--check` all pass.

**Plans**: TBD

### v1.4 sequencing notes

- **Order is refactor, then behavior.** Phase 12 is refactor only. Phases 13 and 15-16 change behavior only through new or opt-in values. Phase 14 is the one place default output is allowed to change, and only in two separate re-baseline commits (A11Y-01, A11Y-02). This follows the CLAUDE.md rule of never mixing a structural change and a behavior change in one diff.
- **A11Y-01 and A11Y-02 supersede "defaults are frozen".** research/ARCHITECTURE.md Anti-Pattern 5 and open decision (a) in research/SUMMARY.md recommended gating only the preset. The v1.4 requirements decided otherwise: the defaults are fixed, and the re-baselines are the sanctioned exceptions that GATE-01 allows.
- **A11Y-03 spans two phases.** Phase 14 needs a contrast check over the default palettes to prove A11Y-01. Phase 15 extends that same test to midnight, which completes A11Y-03.
- **Preset-only items ship with the preset.** The `ThemeData` builder and the preset-only parts of the restyle list (R7 dividers, R14 `ThemeData` assembly, R15 `ColorScheme` outline and error choices) need no widget code. They are part of the one-call preset in Phase 15 (PRE-01, PRE-02). Phase 16 covers the restyles that change component code.
- **The per-phase capture check is not a new requirement.** From Phase 12 on, each phase ends with a harness re-run and `git diff --exit-code images/`. If the executing machine's fonts rasterize differently from the committed captures, write a baseline outside the repo (`SCAFFOLD_CAPTURE_DIR`) and compare against that. GATE-01 in Phase 17 is the milestone-wide confirmation.
- **Research flags for planning.** Phase 12: byte-identical `dart format` output and `0xFF` vs `0xff` casing per entry. Phase 13: inventory of hard-coded shadows, gradients, durations and text styles before planning. Phase 15: the mapping from the wallet colors to the 22 palette fields needs the wallet `lib/theme/` values and a decision on the five unspecified text slots. Phase 16: likely needs a discuss step, since scope depends on what tokens cannot reach.

## Planned Milestone: v1.3 — POS-General Interaction Primitives (queued behind v1.4)

**Created:** 2026-10-01 · **Status:** queued behind v1.4 — phases are numbered and broken down at kickoff (discuss/plan), after v1.4 closes

**Goal:** Extend the pinned scaffold inventory (28 atoms + composites) with the POS-general interaction primitives the touch-pos operating surface consumes, so touch-pos builds on the scaffold instead of growing a second design system.

**Requirements:** SCF-POS-01..18 (18 IDs) — staged in `.planning/milestones/v1.3-REQUIREMENTS-queued.md`. **Gate:** SCF-POS-18 (test/demo/a11y bar for every new primitive).

**Constraints:**

- Extend/expose the pinned inventory — no parallel widget system for POS surfaces.
- Generic/neutral: no app-specific strings, APIs, or business models (SCF-POS-18).
- Offline primitives are visual/status only (SCF-POS-16); offline business behavior stays consumer-owned.

**Decisions to ratify at discuss-phase:** DEC-TOA-02, DEC-TOA-03 (parent-repo ingest decisions, currently proposed).
**Sequencing:** queued behind v1.4 (originally independent, CN-15 #1). Consumers: touch-pos v2.0 (SCF-POS-16 feeds Phase 22); frontend-templates v3.0 Phase 10 overlaps on generator/CMake/FFI needs (CN-15 #2).
**Provenance:** genius-ai-boss fulfillment+commercial-POS ingest follow-through (2026-10-01; 18 of 302 IDs) — parent `.planning/intel/MERGE-PLAN.md` §1.7 is the routing record.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 5. Scaffold Submodule Consolidation | v1.0 | 5/5 | Complete | 2026-08-09 |
| 6. Core UI Foundation | v1.1 | 6/6 | Complete | 2026-08-14 |
| 7. Media & Integration Widgets | v1.1 | 4/4 | Complete | 2026-08-15 |
| 8. Supporting Atoms, Table Cells & Light Palette | v1.2 | 6/6 | Complete | 2026-08-17 |
| 9. Text & Code Primitives | v1.2 | 6/6 | Complete | 2026-08-20 |
| 10. Chart & Scrubber | v1.2 | 6/6 | Complete | 2026-08-22 |
| 11. Verification & Coverage Gate | v1.2 | 3/3 | Complete | 2026-08-23 |
| 12. Token Pipeline | v1.4 | 0/3 | Planned | - |
| 13. Theme Fields | v1.4 | 0/5 | Planned | - |
| 14. Default Accessibility Fixes | v1.4 | 0/TBD | Not started | - |
| 15. Midnight Preset | v1.4 | 0/TBD | Not started | - |
| 16. Component Restyles | v1.4 | 0/TBD | Not started | - |
| 17. Release Gates | v1.4 | 0/TBD | Not started | - |

## Out of scope (owned by consuming repos)

- Parent-side build orchestration: CMake pipeline, `FLUTTER_TEMPLATE_STYLE` option, generated-module drivers (owned by genius-ai-boss `frontend-templates` workstream, Phases 6-8)
- Actual C++ Cubit template content for `templates/cpp/` (downstream consumer scope; placeholder carved out in 05-04)
- Per-consumer submodule wiring and version pinning policy (consumer repo scope)
- App-specific composites (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline) — built from scaffold atoms in the consuming app
- State management for WalletConnectSheet session state — consumers own the Reown session; the sheet only presents it
- AI composites (`lib/ai_components/` — loading state, thinking trace, streaming answer, approval card, tool chips, task rows, chat, prompt bar, etc.) — built as an extension inside the AI chat app consuming scaffold primitives; atoms stay domain-agnostic (owner decision 2026-08-17)
- Style Dictionary / DTCG token format, build_runner codegen, and driving Dart generation from the CMake `DESIGN_TOKENS` override (v1.4 out of scope; see REQUIREMENTS.md)
