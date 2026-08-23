# Phase 11: Verification & Coverage Gate - Context

**Gathered:** 2026-08-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Close out v1.2 by proving the atoms shipped in Phases 8–10 meet the v1.1
shipping bar, and make the library's coverage visible to a reader of the
package. Two requirement IDs:

- **WIDG-44** — every new (v1.2) atom ships with widget tests passing, a demo
  in `example/`, and a barrel export — same bar as v1.1.
- **WIDG-45** — Beautiful UI coverage check: all 19 components demonstrably
  composable from shipped scaffold atoms (7 ready + 8 thin + 4
  primitive-enabled).

This is a verification + documentation gate, **not** new feature work. The
scout confirms the v1.2 atom inventory is essentially complete (tests, demos,
and barrel exports all present); the phase proves it, fixes any gap the sweep
surfaces, and surfaces the result in the package README with per-atom images.

</domain>

<decisions>
## Implementation Decisions

### Coverage surface & images (gray areas 1 — resolved)

- **D-01:** The coverage surface is the package-root **`README.md`**, not a
  separate coverage-matrix file. The README gains a section showing **how to
  run the demo** (`cd example && flutter run -d macos` / `-d chrome`) and the
  **v1.2 component gallery**, plus the WIDG-45 19-component composability
  proof (the 7 ready / 8 thin / 4 primitive-enabled split from the seed).

- **D-02:** A new **`images/`** directory at package root holds **one
  screenshot per atom/demo screen** (26 demo screens / 27 registered entries —
  the full gallery, not just v1.2). Images are **embedded in the README** so
  readers see each component. Mechanism (Option C): a **reproducible capture
  harness** under `example/` that pumps each demo widget and writes a PNG per
  atom into `images/` — deterministic and re-runnable, **without** committing
  to golden-file *test* maintenance (no `matchesGoldenFile` assertions gating
  CI on pixel drift). Each demo is already a self-contained `StatelessWidget`,
  so a single harness can iterate the registry.

### Sweep scope & gap handling (gray areas 2, 4 — resolved)

- **D-03:** The verification sweep covers **v1.2 atoms only** (Phases 8–10):
  chip, chip_group, disclosure, trace_list, composer, streaming_rich_text,
  code_block, selection_actions, chart, chart_scrubber, chart_range_selector,
  plus the Phase 8 table-cell `cellBuilder` extension and light palette. v1.1
  atoms were already gated at their own phases; they are not re-swept.

- **D-05:** Gaps the sweep surfaces are **fixed inline** in this phase
  (gap-closure tasks in the plan), not deferred. The sweep + closure is one
  phase — that is the point of the gate.

### Verification depth (gray area 3 — resolved)

- **D-04:** **No new human UAT phase.** UAT was performed per-phase through
  Phase 10 (the per-phase `UAT.md` pattern, e.g. `07-UAT.md`). This phase's
  gate is the **automated sweep + `dart analyze --fatal-infos` clean + the
  README coverage doc** — no additional human demo-verification pass.

### Skipped test (user-directed)

- **D-06:** **Delete the permanently-skipped test** at
  `test/components/scaffold_selection_actions_test.dart:334-375` (the
  `skip: true` long-press `SelectionArea` smoke test, skipped 2026-08-20).
  Rationale (user): it is really a UAT/manual-QA probe, not a unit test, and
  it is **redundant** — 18 non-skipped tests in the same file already cover
  `onSelectionChanged` / selection behavior via the deterministic
  `debugSimulateSelection` hook (25 references). A permanently-skipped test is
  noise that makes the suite look green-with-asterisk. Remove the test (and
  its now-orphaned comment block) so the suite runs with **zero skips**. If
  the underlying framework flake is ever worth covering, it belongs in a UAT
  checklist, not the unit suite.

### Branching strategy (standing directive — reaffirmed)

- **D-07:** Execute Phase 11 on a **`gsd/phase-11-verification-coverage-gate`**
  branch cut from **`develop`**; open the PR **back to `develop`** (never
  `main`). No direct work on `develop`. This matches the standing workstream
  convention (memory: `gsd-phase-feature-branches`, `prs-target-develop`).

### Claude's Discretion

- Exact README section layout / heading names and where the gallery sits
  relative to the existing "What's in it" table.
- Capture-harness implementation detail (script vs. a non-asserting golden
  writer), PNG dimensions / device frame, and image filenames.
- Whether the WIDG-45 19-component proof is a table inline in the README or a
  linked `images/`-adjacent doc — keep it reader-facing in the README.
- Order of sweep vs. capture tasks (sweep first, then document).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & roadmap
- `.planning/workstreams/scaffold/REQUIREMENTS.md` — WIDG-44 (line 39), WIDG-45 (line 40) definitions; mapping table (lines 83–84)
- `.planning/workstreams/scaffold/ROADMAP.md` §Phase 11 — goal + 3 success criteria

### Coverage yardstick (authoritative for WIDG-45)
- `.planning/atoms-v1.2-additions.md` — the 19-component Beautiful UI table (7 ready / 8 thin / 4 primitive-enabled), the four hard gaps, the four smaller additions. This is the source of truth for what "composable" means per component.

### v1.1 verification bar (the pattern to match)
- `.planning/workstreams/scaffold/phases/07-media-integration-widgets/07-VERIFICATION.md` — verification artifact shape
- `.planning/workstreams/scaffold/phases/07-media-integration-widgets/07-UAT.md` — the per-phase UAT pattern D-04 references

### Prior-phase decisions (carry forward)
- `.planning/workstreams/scaffold/phases/10-chart-scrubber/10-CONTEXT.md` — inherited locked patterns (theme tokens only, atoms stay generic, barrel/demo/test conventions, `dart analyze --fatal-infos` clean)
- `.planning/workstreams/scaffold/phases/09-text-code-primitives/09-CONTEXT.md` — support-part isolation, generated-code conventions

### Repo conventions
- `CLAUDE.md` — generated-file rule, public-contract surface, before-you-finish gates
- `README.md` — the file being extended (D-01/D-02); current structure to preserve

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `example/lib/main.dart` — the demo registry: 27 `_DemoTile` entries each mapping a title/subtitle to a self-contained demo `StatelessWidget`. This registry is the capture set for D-02 and the sweep's demo-presence evidence for D-03.
- `example/lib/demos/*.dart` (26 files) — each a self-contained demo widget; the capture harness pumps these.
- `lib/frontend_scaffold.dart` — the barrel; 14 v1.2 exports already present (atoms + chart renderer support part).

### Established Patterns
- **Demo-per-atom**: one demo file per widget family, registered in `main.dart` — the v1.1 bar WIDG-44 references.
- **Per-phase verification artifacts** (`07-VERIFICATION.md` / `07-UAT.md`): the shape of the gate evidence this phase produces.
- **Deterministic selection testing** (`debugSimulateSelection`): the hook that makes the skipped long-press test redundant (D-06).

### Integration Points
- `README.md` — package root; gains the demo-run instructions, component gallery, image embeds, and the WIDG-45 coverage proof.
- `images/` — NEW package-root directory for the captured per-atom PNGs.
- `test/components/scaffold_selection_actions_test.dart` — remove the skipped test block (lines 334–375).
- `example/` — home of the image-capture harness (D-02).

</code_context>

<specifics>
## Specific Ideas

- User: "package root README.md should show how to run the demo and the components." → D-01.
- User: "if we can have images for the atom widgets in root/images that are shown in the README.md that would be fantastic" → D-02 (all atoms, embedded in README).
- User: "Why even have the test then? since it seems to be a UAT test really." → D-06 (delete the redundant skipped test rather than unskip-and-fix or keep-and-document).
- User confirmed D-03 sweep scope stays v1.2-only even though D-02 images span all atoms.

</specifics>

<deferred>
## Deferred Ideas

- **Golden-file *test* assertions** (`matchesGoldenFile` gating CI on pixel drift) — explicitly out of scope for D-02; the capture harness is a writer, not a CI gate. Could be adopted later if visual-regression testing becomes a goal.
- **Fixing the underlying flutter_test `SelectionArea` gesture flake** — the skipped test is deleted (D-06); if real end-to-end selection coverage is ever wanted, it is a UAT/manual-QA item, not a unit test.
- **v1.1 atom re-sweep** — v1.1 atoms were gated at their own phases; only v1.2 is swept here (D-03).

</deferred>

---

*Phase: 11-verification-coverage-gate*
*Context gathered: 2026-08-22*
