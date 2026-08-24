---
phase: 06-core-ui-foundation
plan: "06"
subsystem: ui
tags: [flutter, widget-atoms, template-generated, composite, card, state-view, search-bar, cubit, hydrated-bloc, drift-gate, kitchen-sink]

# Dependency graph
requires:
  - phase: 06-core-ui-foundation
    plan: "05"
    provides: ScaffoldSelectableSurface, ScaffoldDraggable, ScaffoldDropTarget, ScaffoldFileInputSurface (Wave 2 atoms)
provides:
  - ScaffoldCard (generated, composes ScaffoldSurface + ScaffoldPressable)
  - ScaffoldStateView (generated, composes ScaffoldSkeleton + ScaffoldStatusIndicator + ScaffoldPressable)
  - ScaffoldSearchBar (generated, composes ScaffoldSurface + ScaffoldFocusOutline + ScaffoldStatusIndicator + ScaffoldBadge + ScaffoldLiveRegion)
  - scripts/generate_composites.py (reproducible drift gate)
  - KitchenSinkDemo (28 atoms + ScaffoldMotion + 3 composites gallery)
affects:
  - Phase 6 completion — final Wave 3 dependency layer

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Jinja2 StrictUndefined template -> generated composite (drift-gated via generate_composites.py)
    - State-held cubit + BlocProvider.value (hydrate seed reads cubit without descending provider)
    - In-memory Storage test helper (avoids Hive async deadlock under flutter_test fake-async)

key-files:
  created:
    - lib/components/scaffold_card.dart (+_cubit/_state)
    - lib/components/scaffold_state_view.dart (+_cubit/_state)
    - lib/components/scaffold_search_bar.dart (+_cubit/_state)
    - scripts/generate_composites.py
    - test/helpers/memory_storage.dart
    - test/components/scaffold_card_test.dart
    - test/components/scaffold_state_view_test.dart
    - test/components/scaffold_search_bar_test.dart
    - example/lib/demos/kitchen_sink_demo.dart
  modified:
    - templates/components/{card,state,search_bar}.dart.jinja2 (+_cubit/_state/_vars.json companions)
    - lib/frontend_scaffold.dart

key-decisions:
  - Elevated card uses ScaffoldSurface(elevation: 4) — ScaffoldSurface maps elevation to Material's shadow; the ScaffoldElevation.card box-shadow list is not accepted by ScaffoldSurface's API, so elevation 4 + deepBlueCardColor fulfils the contract
  - Search bar holds the cubit in State and exposes it via BlocProvider.value, so the post-frame hydrate seed can read the cubit directly (the provider is a descendant, not an ancestor, of the State element)
  - Search bar loading indicator uses StatusVariant.info (no 'loading' StatusVariant exists in the shipped enum)
  - In-memory Storage test helper replaces Hive-backed HydratedStorage in tests (Hive's async write deadlocks under flutter_test's fake-async clock)

requirements-completed: [WIDG-26, WIDG-27, WIDG-28]

# Metrics
duration: 38min
completed: 2026-08-13
status: complete
---

# Phase 6 Plan 6: Core UI Foundation Summary

**Generated the 3 Wave 3 composites (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar) from the existing card/state/search_bar Jinja2 templates via engine.py — composing the Phase 6 atoms instead of raw Material widgets — kept the Cubit + hydrated_bloc architecture, and shipped a kitchen-sink demo proving all 28 atoms + ScaffoldMotion compose and render.**

## Performance

- **Duration:** ~38 min
- **Completed:** 2026-08-13
- **Tasks:** 3 (all complete)
- **Files created/modified:** 23

## Accomplishments

- Updated the 3 existing template sets so the generated composites consume Phase 6 atoms instead of raw Material: `card.dart.jinja2` (Card/GestureDetector → ScaffoldSurface + ScaffoldPressable), `state.dart.jinja2` (Card/ElevatedButton/OutlinedButton/Loading → ScaffoldSkeleton + ScaffoldStatusIndicator + ScaffoldPressable, now 5 states incl. unavailable/success), `search_bar.dart.jinja2` (TextField InputDecoration/Card → ScaffoldSurface pill + ScaffoldFocusOutline + ScaffoldStatusIndicator + ScaffoldBadge + ScaffoldLiveRegion).
- Generated all 9 composite files (`scaffold_card`/`scaffold_state_view`/`scaffold_search_bar` + their `_cubit`/`_state` companions) via a committed `scripts/generate_composites.py` driving `engine.py` (Jinja2 StrictUndefined). The drift gate regenerates + `git diff --exit-code` → zero difference.
- Composites keep Cubit (flutter_bloc + hydrated_bloc) for hydrated variant state (cardVariant / stateType / query), matching the existing template architecture and the UI-SPEC "Cubit not Riverpod" correction.
- Wrote 11 widget tests exercising the composites through their internal BlocProvider (card surface treatments + onTap + slots; state view loading/error/success; search bar idle/query-clear/isLoading-badge), all green.
- Exported all 9 generated files from `lib/frontend_scaffold.dart`.
- Created `example/lib/demos/kitchen_sink_demo.dart` rendering all 28 atoms + ScaffoldMotion + the 3 composites in a scrollable, wave-grouped gallery with a reducedMotion Switch toggle and a main.dart wiring note.
- Full gate green: `dart analyze --fatal-infos lib/ test/` clean, `dart analyze --fatal-infos example/lib/` clean, `flutter test` 154/154 passing, drift gate regenerates all 9 files with zero diff.

## Task Commits

1. **Task 1: update card/state/search_bar templates to compose Phase 6 atoms** — `7cd4fcd`
2. **Task 2 (TDD): failing tests for 3 composites** — `f31b3d3` (test)
3. **Task 2 (TDD): generate composites + drift gate + barrel + tests** — `85c6acf` (feat)
4. **Task 3: kitchen-sink demo** — `a466da6`

## Files Created/Modified

- `templates/components/{card,state,search_bar}.dart.jinja2` + `_cubit`/`_state`/`_vars.json` companions — source of truth (updated)
- `scripts/generate_composites.py` — reproducible generator driving engine.py
- `lib/components/scaffold_card.dart` + `scaffold_card_cubit.dart` + `scaffold_card_state.dart` (generated)
- `lib/components/scaffold_state_view.dart` + `scaffold_state_view_cubit.dart` + `scaffold_state_view_state.dart` (generated)
- `lib/components/scaffold_search_bar.dart` + `scaffold_search_bar_cubit.dart` + `scaffold_search_bar_state.dart` (generated)
- `lib/frontend_scaffold.dart` — 9 new barrel exports
- `test/components/scaffold_card_test.dart`, `scaffold_state_view_test.dart`, `scaffold_search_bar_test.dart`
- `test/helpers/memory_storage.dart` — in-memory hydrated Storage
- `example/lib/demos/kitchen_sink_demo.dart` — full gallery

## Decisions Made

- Elevated card maps to `ScaffoldSurface(elevation: 4, color: deepBlueCardColor)`; `ScaffoldSurface` renders elevation via Material's shadow and does not accept the `ScaffoldElevation.card` box-shadow list, so the elevation-4 + deepBlueCardColor treatment is the faithful equivalent.
- Search bar holds the cubit in State (`late final _cubit`) and provides it via `BlocProvider.value`, because `context.read` inside the `initState` post-frame callback cannot reach a `BlocProvider` that is a *descendant* of the State element.
- Search bar loading indicator uses `StatusVariant.info` (blue) since the shipped `StatusVariant` enum has no `loading` value.
- Tests use a synchronous in-memory `Storage` (Hive-backed `HydratedStorage` performs real async file I/O whose pending `hydrate()` write deadlocks subsequent tests in the same file under `flutter_test`'s fake-async clock).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Search bar `context.read` could not reach the descendant BlocProvider**
- **Found during:** Task 2 (first test run)
- **Issue:** The preserved `initState` post-frame hydrate seed called `context.read<Cubit>()`, but the `BlocProvider` created in `build` is a descendant (not ancestor) of the State's element, so `Provider.of` threw.
- **Fix:** Hold the cubit in State (`late final _cubit`) and expose it via `BlocProvider.value`; the seed reads `_cubit.state.query` directly and `dispose()` closes it.
- **Files modified:** `templates/components/search_bar.dart.jinja2` (+ regenerated `scaffold_search_bar.dart`)

**2. [Rule 1 - Bug] Composite tests deadlocked after 2 tests under flutter_test**
- **Found during:** Task 2 (full-file test run)
- **Issue:** `hydrate()` fires an async `Storage.write` on construction; Hive-backed `HydratedStorage`'s write does not cooperate with `flutter_test`'s fake-async clock, leaking a pending future that hung subsequent tests (10-minute timeout).
- **Fix:** Added `test/helpers/memory_storage.dart` (synchronous in-memory `Storage`) and pointed `HydratedBloc.storage` at it in `setUpAll`.
- **Files modified:** 3 test files + new `test/helpers/memory_storage.dart`

**3. [Rule 2 - Missing critical functionality] Reproducible drift gate script**
- **Found during:** Task 2
- **Issue:** The plan requires a regenerable drift gate; a committed generator (matching the Wave 2/4 `scripts/generate_*.py` convention) makes `regenerate → git diff --exit-code` a one-liner.
- **Fix:** Added `scripts/generate_composites.py` rendering all 9 files via engine.py's public API.
- **Files modified:** `scripts/generate_composites.py` (new)

**4. [Rule 1 - Bug] state.dart.jinja2 emitted unnecessary `!`**
- **Found during:** Task 2 `dart analyze --fatal-infos`
- **Issue:** `body != null && body!.isNotEmpty` and `Text(body!)` triggered `unnecessary_non_null_assertion` (Dart promotes the method parameter).
- **Fix:** Dropped the `!` operators in the `_statePanel` body handling.
- **Files modified:** `templates/components/state.dart.jinja2` (+ regenerated `scaffold_state_view.dart`)

**Total deviations:** 4 auto-fixed (Rule 1 ×3, Rule 2 ×1)
**Impact on plan:** All fixes were correctness/testability necessary; no scope creep, no architectural changes, no package-manager installs (jinja2 was already provisioned in `documentation/.venv`, used as-is).

## Issues Encountered

None beyond the auto-fixes above. Two hung `flutter_tester` processes (one a ~2h zombie from a prior phase) were cleaned up before re-running the suite with the in-memory storage fix.

## Threat Model

- **T-06-11 (DoS, SearchBar controller leak) — mitigated:** `_controller`, `_focusNode`, and the state-held `_cubit` are all disposed in `dispose()`.
- **T-06-12 (Tampering, generated composite drift) — mitigated:** `scripts/generate_composites.py` regenerates all 9 files via engine.py; `git diff --exit-code` is zero, and templates remain the source of truth (generated output never hand-edited).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Phase 6 is complete: 28 atoms + ScaffoldMotion + 3 generated composites shipped, exported, tested (154 tests), demoed, and drift-gated. No blockers.

---
*Phase: 06-core-ui-foundation*
*Completed: 2026-08-13*

## Self-Check: PASSED

- All 9 generated composite files present in `lib/components/`.
- `scripts/generate_composites.py` and `test/helpers/memory_storage.dart` present.
- `example/lib/demos/kitchen_sink_demo.dart` present.
- All 4 task commits present in `git log` (7cd4fcd, f31b3d3, 85c6acf, a466da6).
- `dart analyze --fatal-infos lib/ test/` → No issues found.
- `dart analyze --fatal-infos example/lib/` → No issues found.
- `flutter test` → 154/154 passing (11 new composite tests).
- Drift gate: `python3 scripts/generate_composites.py` → `git diff --exit-code` → zero difference.
