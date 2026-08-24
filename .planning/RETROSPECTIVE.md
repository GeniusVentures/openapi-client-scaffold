# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.2 — Atom Extensions

**Shipped:** 2026-08-24
**Phases:** 4 (8-11) | **Plans:** 21 | **Timeline:** 2026-08-17 → 2026-08-24 (7 days)

### What Was Built
- Composition atoms: ScaffoldChip/ChipGroup, ScaffoldDisclosure/TraceList, ScaffoldComposer; `DataColumnConfig.cellBuilder`; light-mode ScaffoldPalette (Phase 8)
- Text & code primitives: ScaffoldStreamingRichText (incremental render, citations, action slots), ScaffoldCodeBlock, ScaffoldSelectionActions (Phase 9)
- Charts: ScaffoldChart (neutral series contract), ScaffoldChartScrubber, drag-range selection (Phase 10)
- Verification gate: zero-skip 454-test suite, reproducible dual-theme image-capture harness (26 demos → 52 PNGs), README gallery + 19-component coverage proof (Phase 11)

### What Worked
- Dependency-layered waves kept atom delivery incrementally mergeable, as in v1.1
- The Beautiful UI 19-component set as a coverage yardstick gave the verification phase a concrete exit criterion
- Captures-as-writer (no golden gating) kept CI deterministic while still producing human-viewable docs images

### What Was Inefficient
- REQUIREMENTS.md checkboxes/traceability rows drifted from actual delivery (8 requirements completed but never ticked — corrected at archival)
- The capture harness needed four post-review fixes (WR-03..WR-05 + the theme-animation freeze) — the rasterization/fake-async interaction was under-researched upfront
- Milestone completed without a formal `/gsd:audit-milestone` pass; relied on per-phase verification

### Patterns Established
- `tester.runAsync` interleaved with theme swaps requires `themeAnimationDuration: Duration.zero` — runAsync freezes in-flight AnimatedTheme tickers
- WR-03: keep AnimatedSize child widget type stable across state changes (swap inner content, not wrappers)
- Captures pin real fonts from `<flutter>/bin/cache/artifacts/material_fonts` by walking to filesystem root

### Key Lessons
1. Pixel-forensics (decode the PNG, count exact colors) settles "looks different" disputes faster than eyeballing or framework archaeology
2. Tick requirement checkboxes at phase transition, not at milestone close — drift compounds
3. Offscreen rasterization harnesses need their own research phase; fake-async + real-async boundaries are a known trap

### Cost Observations
- Model mix: not tracked this milestone
- Sessions: ~6 (one per phase plus verification/ship)
- Notable: capture-harness debugging consumed a full session on a single color-fidelity bug

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Days | Notes |
|-----------|--------|-------|------|-------|
| v1.1 | 2 | 10 | ~6 | 28 atoms + media/integration set |
| v1.2 | 4 | 21 | 7 | atoms + text/code + charts + verification gate |
