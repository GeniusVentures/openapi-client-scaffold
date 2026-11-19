---
phase: 11
slug: verification-coverage-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-22
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (bundled with Flutter SDK) |
| **Config file** | none — `flutter_test` defaults |
| **Quick run command** | `dart analyze --fatal-infos` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `dart analyze --fatal-infos`
- **After every plan wave:** Run `flutter test` (full suite)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | WIDG-44 (D-06) | — | N/A | deletion + analyzer + test | `dart analyze --fatal-infos && flutter test test/components/scaffold_selection_actions_test.dart` | ✅ | ⬜ pending |
| 11-01-02 | 01 | 1 | WIDG-44 (D-06) | — | N/A | grep sweep (zero-skip gate) | `grep -rn "skip: true" test/` returns 0 lines | ✅ (after 11-01-01) | ⬜ pending |
| 11-02-01 | 02 | 1 | WIDG-44 (D-02) | — | N/A | capture harness (writer, not golden assert) | `flutter test example/test/capture_images_test.dart` | ❌ W0 | ⬜ pending |
| 11-02-02 | 02 | 1 | WIDG-44 (D-02) | — | N/A | image count sweep | `ls images/ \| wc -l` → 26 | ❌ W0 (created by harness) | ⬜ pending |
| 11-03-01 | 03 | 2 | WIDG-44 + WIDG-45 (D-01) | — | N/A | README content sweep | `grep -c "ScaffoldChip\|ScaffoldDisclosure\|ScaffoldComposer\|ScaffoldStreamingRichText\|ScaffoldCodeBlock\|ScaffoldSelectionActions\|ScaffoldChart" README.md` ≥ threshold; README contains gallery + WIDG-45 table + corrected counts (454 tests, 26 demos) | ❌ W1 (README edit) | ⬜ pending |
| 11-03-02 | 03 | 2 | WIDG-44 + WIDG-45 | — | N/A | phase gate | `dart analyze --fatal-infos` clean + `flutter test` → all passed with zero skips + `ls images/ \| wc -l` → 26 | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `example/test/capture_images_test.dart` — the capture harness itself (the only new test file; a PNG writer, not a golden assertion)
- [ ] `images/` directory at package root (created by harness first run)

*(Existing test infrastructure fully covers WIDG-44 — no new atom tests needed; the sweep is file-existence + analyzer + test-run, per the RESEARCH sweep matrix.)*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README renders correctly with embedded images and the 19-component table reads as a credible composability proof | WIDG-45 | Documentation/visual quality is human-judged | Open README.md; confirm the gallery images load and the 19-component table maps each Beautiful UI component to shipped atoms |

*(All other phase behaviors have automated verification.)*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (capture harness + images/)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
