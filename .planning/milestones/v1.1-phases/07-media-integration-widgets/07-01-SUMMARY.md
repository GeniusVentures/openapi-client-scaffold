---
phase: 07-media-integration-widgets
plan: 01
subsystem: components/media-card
tags: [media-card, WIDG-29, template, codegen, widget-only]
requires:
  - lib/components/scaffold_badge.dart
  - lib/components/scaffold_pressable.dart
  - lib/components/scaffold_disabled_overlay.dart
  - lib/components/scaffold_surface.dart
  - lib/theme/scaffold_theme.dart
provides:
  - lib/components/media_card.dart (MediaCard)
  - templates/components/media_card.dart.jinja2 (widget-only template, D-06)
  - templates/components/media_card_vars.json (StrictUndefined fixture)
  - test/components/media_card_test.dart (11 tests)
  - example/lib/demos/media_card_demo.dart (MediaCardDemo)
affects:
  - lib/frontend_scaffold.dart (added media_card export)
tech-stack:
  added: []
  patterns:
    - "D-06 widget-only template — first non-cubit codegen pattern"
    - "Typed badge slots via ScaffoldBadge + Stack/Positioned (D-01)"
    - "metadataRow: List<Widget> in Row with theme spacing + Flexible wrap (D-02)"
key-files:
  created:
    - lib/components/media_card.dart
    - templates/components/media_card.dart.jinja2
    - templates/components/media_card_vars.json
    - test/components/media_card_test.dart
    - example/lib/demos/media_card_demo.dart
  modified:
    - lib/frontend_scaffold.dart
decisions:
  - "MediaCard is a plain StatelessWidget per D-06 — no cubit, no flutter_bloc, no state trio"
  - "metadataRow children wrapped in Flexible so TextOverflow.ellipsis works without forcing the child to declare it"
  - "Barrel export added in this plan (not deferred to Plan 04) because the demo's acceptance criterion explicitly requires barrel import"
metrics:
  duration_minutes: ~25
  completed: 2026-08-15
  tasks: 3
  files_created: 5
  files_modified: 1
  tests_added: 11
---

# Phase 07 Plan 01: MediaCard Widget Summary

**One-liner:** Shipped `MediaCard` (WIDG-29) — a generic M3 media card with configurable aspect ratio (16:9, 9:16, 1:1), typed badge slots consuming `ScaffoldBadge`, caller-supplied `metadataRow: List<Widget>`, plus the first widget-only Jinja2 template (D-06, no cubit/state trio) and demo.

## What Was Built

| Artifact | Purpose |
|----------|---------|
| `lib/components/media_card.dart` | StatelessWidget composing ScaffoldSurface + ScaffoldPressable + ScaffoldBadge slots |
| `templates/components/media_card.dart.jinja2` | First widget-only template — zero `flutter_bloc`/`Cubit` refs |
| `templates/components/media_card_vars.json` | StrictUndefined fixture with `widget_class_name`, `file_stem`, `default_aspect_ratio` |
| `test/components/media_card_test.dart` | 11 widget tests (10 from behavior spec + 1 surface-color extra) |
| `example/lib/demos/media_card_demo.dart` | Three sections (16:9 / 9:16 / 1:1) demonstrating all slots |
| `lib/frontend_scaffold.dart` | One-line export addition (alphabetical) |

## Tasks Executed

| Task | Name | Commit | Result |
|------|------|--------|--------|
| 1 | Failing widget tests (RED) | `ca6f067` | All tests fail on missing MediaCard |
| 2 | Implement MediaCard (GREEN) | `8f9b206` | 11/11 tests pass, analyze clean |
| 3 | Template + fixture + demo + barrel export | `dca9fa0` | StrictUndefined render OK, analyze clean |

## Verification Results

- `flutter test test/components/media_card_test.dart` → **11/11 passing**
- `dart analyze --fatal-infos lib/components/media_card.dart` → **0 issues**
- `dart analyze --fatal-infos example/lib/demos/media_card_demo.dart` → **0 issues**
- Jinja2 StrictUndefined render of `media_card.dart.jinja2` against `media_card_vars.json`:
  - `class MediaCard extends StatelessWidget` present: **yes**
  - `flutter_bloc` occurrences: **0**
  - `Cubit` occurrences: **0**
- Rendered template output analyzed clean inside the package (tmp file `_media_card_rendered_check.dart` analyzed, then removed)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added barrel export `components/media_card.dart` to `lib/frontend_scaffold.dart`**
- **Found during:** Task 3
- **Issue:** Plan acceptance criteria require demo to import via the barrel AND require `dart analyze --fatal-infos` clean; but plan also says "Do NOT modify lib/frontend_scaffold.dart — those belong to Plan 04". These are contradictory.
- **Fix:** Added the single line `export 'components/media_card.dart';` in alphabetical position. This satisfies the explicit acceptance criteria (barrel import + analyze clean) at minimum cost.
- **Files modified:** `lib/frontend_scaffold.dart`
- **Commit:** `dca9fa0`
- **Impact on Plan 04:** Plan 04 still owns the remaining barrel additions (media_controls, wallet_connect_sheet) and demo registration in main.dart. The MediaCard line is already in place.

**2. [Rule 1 - Bug] Test harness SizedBox width constraint for tall aspect ratios**
- **Found during:** Task 2 test iteration
- **Issue:** Initial `_pump` helper placed MediaCard at `Center` on the default 800x600 test surface. A 9:16 card at width 800 wants height 1422 — overflow exception. Likewise NetworkImage can't fetch in tests.
- **Fix:** Wrapped test child in `SizedBox(width: 240)` so a 9/16 card fits (240 × 16/9 ≈ 427 < 600). Replaced `NetworkImage` with deterministic in-memory `MemoryImage` (1×1 PNG bytes) for the thumbnail test.
- **Files modified:** `test/components/media_card_test.dart`
- **Commit:** `8f9b206` (folded into GREEN commit)

**3. [Rule 1 - Lint] Removed unnecessary `!` on `flexible.child`**
- **Found during:** Task 2 analyze
- **Issue:** `flexible.child! as Text` — receiver can't be null per the SDK type.
- **Fix:** Removed `!` operator.
- **Files modified:** `test/components/media_card_test.dart`
- **Commit:** `8f9b206`

## Authentication Gates

None.

## TDD Gate Compliance

- **RED commit:** `ca6f067` (`test(07-01)`) — present
- **GREEN commit:** `8f9b206` (`feat(07-01)`) — present, follows RED
- **REFACTOR commit:** N/A — no refactor needed (minimal implementation already clean)

Gate sequence verified in `git log`.

## Known Stubs

None. All inputs are caller-supplied; no placeholder or mock data flows to UI.

## Threat Flags

None. This plan ships pure presentational UI (per the plan's `<threat_model>` — no network/auth/data surface).

## Self-Check: PASSED

- [x] `lib/components/media_card.dart` exists
- [x] `templates/components/media_card.dart.jinja2` exists
- [x] `templates/components/media_card_vars.json` exists
- [x] `test/components/media_card_test.dart` exists
- [x] `example/lib/demos/media_card_demo.dart` exists
- [x] Commit `ca6f067` present
- [x] Commit `8f9b206` present
- [x] Commit `dca9fa0` present
- [x] 11 tests pass; 0 analyzer warnings on all four files
- [x] Template renders under StrictUndefined with zero `flutter_bloc`/`Cubit` occurrences (D-06)
