---
phase: 05-scaffold-submodule-consolidation
plan: "05"
subsystem: frontend-scaffold toast component
tags: [flutter, toast, theming, port, lifecycle]
requirements: [SUB-01]
status: complete
dependency_graph:
  requires: ["05-04", "GeniusWallet redesign/toast-notification-260808 @ b4b63a5a (read-only source)"]
  provides: ["frontend_scaffold 0.3.0 two-density toast API (showToast free function, ToastManager.instance)"]
  affects: ["frontend/scaffold example app toast demo", "host apps consuming frontend_scaffold toasts"]
tech_stack:
  added: [ToastDensity enum, ScaffoldElevation tokens]
  patterns: ["M3 ThemeExtension tokens (ScaffoldPalette/ScaffoldDimens) seeded from GeniusWallet dark values", "State-owned auto-dismiss timer (lifecycle bound to element, not singleton manager)"]
key_files:
  created:
    - lib/theme/scaffold_elevation.dart
  modified:
    - lib/components/toast/toast_widget.dart
    - lib/components/toast/toast_manager.dart
    - lib/components/toast/toast_navigator_observer.dart
    - lib/theme/scaffold_dimens.dart
    - lib/theme/scaffold_palette.dart
    - lib/frontend_scaffold.dart
    - test/components/toast_test.dart
    - example/lib/demos/toast_demo.dart
    - pubspec.yaml
  deleted:
    - lib/components/toast/ticker_provider.dart
decisions:
  - "Re-homed from genius-ai-boss .planning/workstreams/frontend-templates on 2026-08-09 (scaffold workstream bootstrap); paths normalized to repo-relative"
  - "M3 textTheme (labelMedium/titleMedium/bodySmall) over bundling Inter — scaffold is a generic package; host apps supply their own textTheme"
  - "New ScaffoldElevation.card token rather than inline shadow"
  - "radiusMd (12.0) added as separate token; borderRadiusCard (15.0) untouched"
  - "Palette/dimens defaults seeded with GeniusWallet dark-mode values from b4b63a5a"
  - "CR-02: kept redesign's State-held auto-dismiss timer (superset of scaffold's manager-held timer fix)"
  - "CR-03: redesign's dismissed-flag guard retained; scaffold's null-after-fire implemented via show()-time overlay-identity prune + _forget null-out (exactly-once preserved)"
  - "CR-04: redesign's _forget + mounted-guarded _restack kept verbatim; scaffold's _disposed builder guard no longer needed"
metrics:
  duration: "~2h (tasks 3-4)"
  completed: 2026-08-09
---

# Phase 05 Plan 05: Toast Redesign Sync Summary

Two-density GeniusWallet toast redesign ported into `frontend_scaffold` 0.3.0 with message-first API, optional title, and Phase-5 lifecycle fixes (CR-02..04) preserved — the scaffold now owns the authoritative toast UX.

## What shipped

**Task 1 — Research (parent commit 194bde5):** `05-05-RESEARCH.md` — the port contract: public API table, sketch-079 density rules, line-by-line CR-02..04 × redesign conflict map, import/theme neutralization list, and the 10-test inventory.

**Task 2 — Red-first tests (scaffold commit 6f428ca):** Ported upstream's 7-test suite plus 3 new CR-02..04 regression tests into `test/components/toast_test.dart`, harness adapted to `scaffoldThemeExtensions`.

**Task 3 — Redesign port (scaffold commit 6c9cf51):**
- `ToastDensity {compact, card}`; density selected by `title == null`
- Top-level `showToast(context, message, {title, type, duration, onClose})` free function; `ToastManager.instance` singleton with `visibleCount` and `disposeAll()` (renamed from `dispose()`)
- Per-density durations (compact 2s / card 5s), 44pt dismiss affordance on card, density-aware stack strides (44/84), cap of 3 with oldest evicted, safe-area derived top offset, swipe-to-dismiss, reduced-motion fade, `Semantics(liveRegion)` + `semanticLabel`
- Theme neutralization: zero `genius_wallet` references. Added 8 `ScaffoldDimens` fields (`space2/3/4/6/8/12`, `radiusMd`, `radiusPill`), 7 `ScaffoldPalette` fields (`surfaceElevated`, `borderSubtle`, `textPrimary`, `textSecondary`, `statusSuccess`, `statusError`, `statusWarningText` — seeded with GW dark values from b4b63a5a), and new `ScaffoldElevation.card` token
- Typography via M3 `textTheme` (no Inter bundled)
- Removed `ToastTickerProvider` (manager no longer owns AnimationControllers)
- pubspec `0.2.0` → `0.3.0` (breaking API change)

**Task 4 — Example demo (scaffold commit 381e122):** `toast_demo.dart` updated to the new API — compact receipts ("Link copied" etc.) plus manual/auto card alerts per type; shown/closed onClose counters kept as the CR-02..04 smoke test; `disposeAll` button exercises the route-pop path.

## Gate override

The plan's human gate required waiting for GeniusWallet `redesign/toast-notification-260808` to merge to GeniusWallet develop before Task 3. The user overrode it ("it's a fricken widget"): the port was taken against the **pinned branch tip `b4b63a5a`** with GeniusWallet strictly read-only. The scaffold is the authority going forward; upstream drift is out of scope.

## CR-02..04 preservation (per the research conflict map)

| Concern | Port decision | Where |
|---|---|---|
| CR-02 auto-dismiss timer leak | Redesign's `_AnimatedToastState`-held timer (initState/dispose) — structurally stronger than scaffold's manager-held timer; also fixes the widget-test pending-timer path | `toast_manager.dart` `_AnimatedToastState` |
| CR-02 reverse-before-remove | `controller.isAnimating \|\| isCompleted` guard + synchronous `else` teardown (verbatim) | `_dismiss` |
| CR-03 onClose exactly-once | Redesign's `dismissed` flag guards re-entry; `_dismiss` reads/nulls/fires the STORED `_ActiveToast.onClose` (made real in review fix cc22a49 — was write-only before), so the 3-cap eviction path honors consumer onClose; `disposeAll` does NOT fire consumer callbacks (route-pop is not a consumer close) | `_dismiss`, `_forget`, `disposeAll` |
| CR-04 dispose with in-flight toast | Redesign's `_forget` (from `State.dispose`) + `mounted` guard in `_restack` kept verbatim; scaffold's `_disposed` builder guard dropped (State now drives lifecycle) | `_forget`, `_restack` |
| CR-02/04 edge: teardown races first frame | **New in this port:** manager tracks the overlay it inserted into; `show()` against a different overlay drops stale records. Without it, a toast inserted-but-never-built (teardown before the first frame) leaked in the singleton list because Flutter reports a removed-before-built entry as still mounted — empirically confirmed during execution | `show()` overlay-identity prune |

## Verification results

- `flutter pub get` (package + example): OK
- `dart analyze --fatal-infos lib/ test/`: **No issues found!**
- `dart analyze --fatal-infos` (example): **No issues found!**
- `flutter test`: **00:00 +10: All tests passed!** (7 ported upstream + 3 CR regression)
- `flutter build macos --debug` (example): **✓ Built build/macos/Build/Products/Debug/frontend_scaffold_example.app**
- `grep ToastDensity toast_widget.dart`, `grep "String? title" toast_widget.dart`: OK
- `grep 0.3.0 pubspec.yaml`: OK
- `grep -rn genius_wallet lib/components/toast/`: zero matches

## Deviations from plan

**1. [Rule 3 — blocking] Test harness pump adjustments.** Two CR regression tests tapped the Dismiss button after a single `pump()`, when the toast was still at its off-screen slide-in start — the tap missed (hit-test failure). Added a 300ms pump to reach steady state before tapping. Assertions unchanged.

**2. [Rule 1 — bug] `dispose with in-flight toast` never built the entry.** The original test showed a toast and tore down without pumping; the OverlayEntry was inserted but never built, so no State existed to run `_forget`, and Flutter reports a removed-before-built entry as mounted — the manager had no signal its overlay died and the record leaked in the singleton list (empirically confirmed: `visibleCount == 1` after teardown). Fixed two ways: (a) the test now pumps once so the toast is genuinely in-flight when the tree goes away (its stated intent), and (b) the manager prunes stale records when `show()` resolves a different overlay than the one it inserted into — the CR-04-consistent production hardening for the same edge.

**3. [Planned deviation, from research §4.4] M3 textTheme over Inter.** Scaffold does not bundle Inter; typography uses `Theme.of(context).textTheme.{labelMedium,titleMedium,bodySmall}.copyWith(color:)`.

## Key decisions

- **M3 textTheme over Inter** — scaffold is generic; consumers supply their own textTheme
- **`ScaffoldElevation.card` token** rather than inline shadow
- **`radiusMd` (12.0) added as a separate token** — `borderRadiusCard` (15.0) untouched so existing card consumers don't change
- **Palette/dimens seeded with GW dark-mode values** — host apps override via `ThemeData.extensions`; a light default palette is a tracked follow-up (out of scope)
- **State-owned auto-dismiss timer** — superset of CR-02's fix, binds timer lifecycle to the element

## Commits

| Repo | SHA | Message |
|---|---|---|
| parent | 194bde5 | docs(frontend-templates): 05-05 research — toast redesign port contract |
| parent | b6e0a8d | docs(frontend-templates): 05-05 plan/tasks updated for gate override |
| scaffold | 6f428ca | test(toast): port upstream toast suite + CR-02..04 regression tests (red) |
| scaffold | 6c9cf51 | feat(toast)!: port two-density redesign from GeniusWallet (message-first API, optional title) |
| scaffold | 381e122 | feat(example): toast demo exercises compact + card densities |
| scaffold | cc22a49 | fix(toast): resolve 05-05 code review findings (genericity, lifecycle, breakpoints) |

## Post-summary code review (05-05-REVIEW.md)

Post-execution `gsd-code-reviewer` pass (verdict: approve-with-fixes): 1 Critical / 6 Warning / 3 Info. All Critical + Warning resolved in scaffold `cc22a49`; the 3 Info deferred. Key resolutions:
- **CR-01 (Critical):** GeniusWallet provenance stripped from public doc comments in the new theme tokens (`scaffold_dimens`/`scaffold_palette`/`scaffold_elevation`) — the same genericity class the prior 05-REVIEW flagged; the original verification grep (`genius_wallet` in `lib/components/toast/`) missed `GeniusWallet`/`GW` in `lib/theme/`.
- **WR-01..06:** toast mobile breakpoint aligned to `ScaffoldBreakpoints.small` (760, was magic 600); RTL-safe desktop dismiss direction; stable `Dismissible` key (was `widget.hashCode`, reset swipes on `_restack`); CR-03 stored-callback mechanism made real (fixes silent onClose drop on 3-cap eviction); `_kCardStride` 84→112 (was exceedable at default text scale).
- Re-verified post-fix: `dart analyze --fatal-infos` clean, 10/10 tests green, zero GeniusWallet refs in `lib/` + `example/lib/`.

## Self-Check: PASSED

- scaffold commits 6c9cf51, 381e122 confirmed via `git log`
- All Task 3/4 verification gates green (analyze, 10/10 tests, macos build)
- Research doc contract honored: API table, density rules, conflict map, neutralization list all implemented
