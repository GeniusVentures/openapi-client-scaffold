# Phase 11: Verification & Coverage Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-22
**Phase:** 11-verification-coverage-gate
**Areas discussed:** Coverage document form, Gap handling during sweep, Human UAT depth, Sweep scope, Skipped test handling, Atom images in README, Branching strategy

---

## Coverage document form (WIDG-45)

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown coverage matrix in phase dir | A `11-COVERAGE.md`-style matrix mapping each of the 19 Beautiful UI components → its composing atoms, kept in the phase directory | |
| Package-root `COVERAGE.md` | Promote the matrix to a package-root doc linked from README | |
| **README.md section** | Put how-to-run-the-demo + the component gallery + the 19-component proof directly in the package-root README | ✓ |

**User's choice:** "package root README.md should show how to run the demo and the components."
**Notes:** README is the reader-facing surface; no separate coverage-matrix file. Captured as D-01.

---

## Atom images in README

| Option | Description | Selected |
|--------|-------------|----------|
| A — manual screenshot capture | Run the demo app, screenshot each atom screen by hand | |
| B — golden-file test harness | `matchesGoldenFile` so images are CI-reproducible (adds golden maintenance) | |
| C — reproducible capture harness (writer) | Pump each demo and write PNGs to `images/`, re-runnable, without golden-file *test* gating | ✓ |
| — scope: all atoms vs v1.2 only | Capture images for **all** atoms (26 demos), not just v1.2 | ✓ |

**User's choice:** "if we can have images for the atom widgets in root/images that are shown in the README.md that would be fantastic" + "D-02 should capture all atoms images for the README.md."
**Notes:** New `images/` dir at package root, one screenshot per atom/demo, embedded in README. Mechanism = capture harness (Option C, Claude's recommendation) — reproducible without golden-file test maintenance. Captured as D-02.

---

## Human UAT depth

| Option | Description | Selected |
|--------|-------------|----------|
| New human UAT pass | Phase 11 re-runs a Phase 7-style `UAT.md` human demo verification | |
| **No new UAT — automated gate** | Per-phase UAT through Phase 10 is the human bar; Phase 11's gate is the automated sweep + analyzer + README doc | ✓ |

**User's choice:** "not needed, it was all done in phases and as of phase 10 we did UAT coverage."
**Notes:** Captured as D-04.

---

## Sweep scope

| Option | Description | Selected |
|--------|-------------|----------|
| All atoms incl. v1.1 | Re-sweep the whole library | |
| **v1.2 atoms only** | Sweep only Phases 8–10 atoms (the ROADMAP "every new atom") | ✓ |

**User's choice:** "D-03 sweep scope is fine with only v1.2 atoms" (confirmed twice — image scope is all-atoms, but sweep scope stays v1.2).
**Notes:** Captured as D-03.

---

## Gap handling during the sweep

| Option | Description | Selected |
|--------|-------------|----------|
| **Fix inline** | Gaps the sweep surfaces are closed in this phase (gap-closure tasks) | ✓ |
| Defer to follow-up | Log gaps and handle later | |

**User's choice:** Recommended default accepted (implicit in D-05 framing; user did not object and directed a fix-forward posture).
**Notes:** Captured as D-05.

---

## Skipped test handling

| Option | Description | Selected |
|--------|-------------|----------|
| A — unskip + genuinely fix | Make the framework-flaky long-press SelectionArea smoke test run green | |
| B — keep skipped, gate explicit | Assert the skip is documented/intentional so the suite doesn't silently pass with a skip | |
| C — investigate root cause first | Decide A-feasibility after investigation | |
| **Delete the test** | Remove the redundant permanently-skipped test; suite runs zero-skip | ✓ |

**User's choice:** "Why even have the test then? since it seems to be a UAT test really." — i.e., delete it.
**Notes:** The test (`scaffold_selection_actions_test.dart:334-375`) is redundant — 18 non-skipped tests in the same file cover `onSelectionChanged`/selection via the deterministic `debugSimulateSelection` hook (25 references). It's a manual-QA probe, not a unit test. Captured as D-06.

---

## Branching strategy

| Option | Description | Selected |
|--------|-------------|----------|
| **Feature branch off develop** | Execute on `gsd/phase-11-verification-coverage-gate` cut from `develop`, PR back to `develop` | ✓ |
| Directly on develop | Work on develop (violates standing convention) | |

**User's choice:** "make sure to use branching strategy" (in the discuss-phase invocation).
**Notes:** Standing workstream convention reaffirmed. PRs target `develop`, never `main`. Captured as D-07.

---

## Claude's Discretion

- Exact README section layout / heading names and gallery placement relative to the existing "What's in it" table.
- Capture-harness implementation detail, PNG dimensions / device frame, image filenames.
- Whether the WIDG-45 19-component proof is an inline README table or a linked doc (keep reader-facing in README).
- Ordering of sweep vs. capture tasks (sweep first, then document).

## Deferred Ideas

- **Golden-file test assertions** (`matchesGoldenFile` gating CI on pixel drift) — out of scope for D-02; the capture harness is a writer, not a CI gate.
- **Fixing the flutter_test `SelectionArea` gesture flake** — the skipped test is deleted (D-06); real end-to-end selection coverage, if ever wanted, is a UAT/manual-QA item.
- **v1.1 atom re-sweep** — only v1.2 is swept (D-03); v1.1 atoms were gated at their own phases.
