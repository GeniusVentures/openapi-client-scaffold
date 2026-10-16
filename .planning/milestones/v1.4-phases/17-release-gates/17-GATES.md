# Phase 17 Release Gate Record (v1.4)

Gate head: f6b99d3b818a0ff314b5b9b12c07d3fc94fe73fd

Date: 2026-10-16. Tree clean (`git status --porcelain` empty) before and after every check. Commits
after the gate head touch only `.planning/`.

## GATE-01: capture gate

Reading of "existing capture" (PD-07): the 52 default PNGs present at e67e00c. The midnight captures
did not exist at the base; they were added and re-baselined only in isolated chore commits sanctioned
by the manifest.

Every commit since e67e00c that touched `images/` (14 commits, all in `tools/capture_rebaselines.json`):

| Commit | Scope | Subject | Record |
|---|---|---|---|
| d9342ff | default | chore(14-01): re-render captures on this machine, no code change | v1.4 14-COLOR-CHANGES.md BASELINE |
| b9145a8 | default | chore(14-01): re-baseline text field and drawer captures for the harness change | v1.4 14-COLOR-CHANGES.md COVERAGE_CAPTURES |
| f4207f7 | default | chore(14-02): re-baseline captures for A11Y-01 | v1.4 14-COLOR-CHANGES.md A11Y01_CAPTURES |
| 015d521 | default | chore(14-03): re-baseline light text field and drawer captures for A11Y-02 | v1.4 14-COLOR-CHANGES.md A11Y02_CAPTURES |
| 4b406e5 | default | chore(14-05): re-baseline light captures for the accent fix | v1.4 14-COLOR-CHANGES.md ACCENT_CAPTURES |
| bc8d692 | midnight | chore(15-06): midnight captures, 26 demos in light and dark (PRE-03) | v1.4 15-06-SUMMARY MIDNIGHT_CAPTURES |
| 8ba7e91 | midnight | chore(16-01): re-baseline midnight captures after the elevated shadow (RST-01) | v1.4 16-RESTYLES.md (16-01) |
| d878e80 | midnight | chore(16-02): re-baseline midnight captures after the card sheen and hairline (RST-01) | v1.4 16-RESTYLES.md (16-02) |
| 8edd140 | midnight | chore(16-03): re-baseline midnight captures after the hover treatment (RST-01) | v1.4 16-RESTYLES.md (16-03) |
| 2e59178 | midnight | chore(16-04): re-baseline midnight captures after the focused field border (RST-01) | v1.4 16-RESTYLES.md (16-04) |
| dfe9732 | midnight | chore(16-05): re-baseline midnight captures after the drawer restyle (RST-01) | v1.4 16-RESTYLES.md (16-05) |
| 292d5ba | midnight | chore(16-06): re-baseline midnight captures after the checkbox restyle (RST-01) | v1.4 16-RESTYLES.md (16-06) |
| 75f7a04 | midnight | chore(16-07): re-baseline midnight captures after the ActionButton restyle (RST-01) | v1.4 16-RESTYLES.md (16-07) |
| 5d783f3 | midnight | chore(16-07): re-baseline midnight captures after tabular figures (RST-01) | v1.4 16-RESTYLES.md (16-07) |

`python tools/capture_gate.py history`: exit 0, `14 capture commits, 14 sanctioned, 0 violations`.

Default captures moved only in the five 14-COLOR-CHANGES.md commits
(`git log --format='%h %s' e67e00c..HEAD -- images ':!images/midnight'`):

```
4b406e5 chore(14-05): re-baseline light captures for the accent fix
015d521 chore(14-03): re-baseline light text field and drawer captures for A11Y-02
f4207f7 chore(14-02): re-baseline captures for A11Y-01
b9145a8 chore(14-01): re-baseline text field and drawer captures for the harness change
d9342ff chore(14-01): re-render captures on this machine, no code change
```

`PATH="$FLUTTER_BIN:$PATH" python tools/capture_gate.py render`: exit 0.

```
rendered 52 default and 54 midnight PNGs
0 differences
```

## GATE-02: GCS consumer check

`PATH="$FLUTTER_BIN:$PATH" bash tools/consumer_check/gcs_check.sh <GCS>/src/app f6b99d3b818a0ff314b5b9b12c07d3fc94fe73fd`:

```
== scaffold at f6b99d3
== SUMMARY ref=f6b99d3b818a0ff314b5b9b12c07d3fc94fe73fd
codegen failures (of 12): 0
pub get exit: 0
analyze:      57 error  | 57 issues found. (ran in 2.0s)
analyze issues in scaffold/example (baseline noise): 57
analyze issues in app code (lib/test): 0
test: 00:01 +60 ~1: All tests passed!
submodule restored to 8ada743
```

Comparison with the UN-03 baseline (codegen 0 of 12, pub get 0, 57 analyze errors all in
scaffold/example, 0 app-code issues, 60 tests pass): identical.

GCS left as found: submodule HEAD 8ada743fbb61aecf727dbb78acc9cf29cbc54ff5 before and after;
`git status --porcelain` in the GCS repo empty before and after. Nothing committed, pushed or filed.

## SC4: checks at the gate head

| Command | Result |
|---|---|
| `dart analyze --fatal-infos` (root) | No issues found! |
| `dart analyze --fatal-infos` (example/) | No issues found! |
| `flutter test` (root) | +1464: All tests passed! |
| `flutter test test/preset_switcher_test.dart` (example/) | +2: All tests passed! |
| `python -m ruff check` | All checks passed! |
| `PYTHONPATH=tools python -m pytest tools/tests -q` | 229 passed (includes the history gate) |
| `theme_defaults --check` | exit 0 |
| `theme_presets --check` | exit 0 |
| `m3_tokens_css --tokens design_tokens.json --output tools/tests/fixtures/m3_tokens.css --check` | exit 0 |
| `python -m scaffold_codegen.generators`, then `git diff --exit-code lib/` | exit 0; `git status --porcelain -- lib/` empty |

## Contract freeze since e67e00c

- `color`, `typography`, `shape` and `elevation` keys of `design_tokens.json`: equal at e67e00c and the
  gate head (compared with `git show e67e00c:design_tokens.json`).
- `tools/tests/fixtures/m3_tokens.css` did not exist at e67e00c (first commit 24c2636, Phase 12), so
  `git diff --quiet e67e00c -- <file>` cannot hold. Equivalent check: the CSS generated from
  e67e00c's `design_tokens.json` is byte-identical to the committed snapshot, and no commit changed the
  snapshot after 24c2636.
- `test/theme/consumer_contract_test.dart` passed within the root `flutter test` run.
