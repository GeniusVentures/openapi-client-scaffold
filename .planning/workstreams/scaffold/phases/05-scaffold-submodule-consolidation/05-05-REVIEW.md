---
provenance: "Re-homed from genius-ai-boss .planning/workstreams/frontend-templates on 2026-08-09 (scaffold workstream bootstrap); paths normalized to repo-relative"
phase: 05-scaffold-submodule-consolidation
plan: "05"
reviewed: 2026-08-09T00:00:00Z
depth: deep
files_reviewed: 10
files_reviewed_list:
  - lib/components/toast/toast_manager.dart
  - lib/components/toast/toast_widget.dart
  - lib/components/toast/toast_navigator_observer.dart
  - lib/components/toast/ticker_provider.dart (deleted)
  - lib/theme/scaffold_dimens.dart
  - lib/theme/scaffold_palette.dart
  - lib/theme/scaffold_elevation.dart
  - lib/frontend_scaffold.dart
  - example/lib/demos/toast_demo.dart
  - test/components/toast_test.dart
findings:
  critical: 1
  warning: 6
  info: 3
  total: 10
status: issues_found
---

# Phase 05 Plan 05: Code Review Report — Toast Two-Density Redesign Port

**Reviewed:** 2026-08-09
**Depth:** deep (lifecycle traced across manager / state / observer; ThemeExtension copyWith/lerp verified field-by-field against the diff; genericity sweep against the 05-REVIEW standard)
**Files Reviewed:** 10 (9 live + 1 deletion)
**Status:** issues_found

## Summary

The port is structurally sound on the dimensions it set out to prove: CR-02..04 hold under the new lifecycle model (State-held timer, `dismissed` flag re-entry guard, `_forget` + mounted-guarded `_restack`, overlay-identity prune on `show()`), the new ThemeExtension fields implement `copyWith`/`lerp` completely and consistently with the pre-existing fields, the `ticker_provider.dart` deletion is clean (no dangling source references — only stale build-system file lists under `example/build/`, which are generated artifacts), and the test suite genuinely exercises the CR invariants rather than asserting around them.

One **Critical** remains: the same genericity-contamination class that was the headline of the prior `05-REVIEW.md` has been re-introduced in documentation comments on the new theme tokens. Every new `ScaffoldDimens` field carries `(GeniusWalletConsts.spaceN)` provenance comments, `ScaffoldPalette`'s seven new fields are annotated `GW dark: …` / `(sketch-079)`, and `ScaffoldElevation` references `GeniusWalletElevation` twice. For a package whose stated contract is "ZERO GeniusWallet/wallet-specific references," shipping public API doc comments that name the upstream app and its internal sketch IDs is the exact failure mode Phase 5 exists to eliminate — and these are doc comments on *public API*, so they surface in consumers' IDE tooltips and generated docs.

The lifecycle code itself has no Critical defects. The warnings are real-but-bounded: a magic-number mobile-breakpoint that disagrees with the package's own `ScaffoldBreakpoints.small` (760 vs 600), a dismiss-direction inversion on desktop, a Dismissible key derived from `widget.hashCode` that can collide across identical toasts, an eviction path that fires `onClose` with a null callback silently dropping consumer hooks, and `_AnimatedToastState` reading `widget.offsetAbove` only at insert time (stale after `_restack` marks the entry dirty but the State rebuilds against the *captured* value — actually re-read per build, see WR-05 analysis for the residual edge).

**Verdict: approve-with-fixes** — CR-01 (doc-comment genericity sweep) must land before merge; the warnings can ride the same commit.

---

## Critical Issues

### CR-01: GeniusWallet/GeniusWalletConsts/GeniusWalletElevation references in public API doc comments — genericity contract violated

**Files:**
- `lib/theme/scaffold_dimens.dart:28, 31, 34, 37, 40, 43, 46-48, 51`
- `lib/theme/scaffold_palette.dart:33, 36, 39, 42, 45, 48, 51, 74`
- `lib/theme/scaffold_elevation.dart:4, 10`

**Issue:** The package contract for Phase 5 (set by the prior `05-REVIEW.md`, reaffirmed in the 05-05 task brief) is **zero** GeniusWallet/wallet-specific references, naming, or branding in `frontend_scaffold`. The new theme tokens violate this in their doc comments:

```dart
/// 4pt spacing scale step (GeniusWalletConsts.space2).        // dimens:28
/// Corner radius for alert cards (GeniusWalletConsts.radiusMd). // dimens:46

/// Elevated surface fill used by toasts painted into the root Overlay.
/// GW dark: #0C0E14 (sketch-079).                              // palette:33

/// Matches GeniusWalletElevation.card dark value (black @ 35%). // elevation:10

/// Default palette seeded from the raw [ScaffoldColors] constants, plus
/// the toast-needed tokens seeded with GeniusWallet's dark-mode values. // palette:74
```

This is the same contamination class the prior review flagged as Critical (naming leakage from the upstream app into a package consumed by non-wallet apps). These are *public API* doc comments — they render in IDE hover and `dart doc` output for every consumer. A host app reading "GW dark: white 12%" or "(sketch-079)" has no idea what "GW" or "sketch-079" is, and the reference leaks the upstream app's internal design-tracking IDs into generic scaffolding. The hex values themselves are fine (they're just colors); the *labels* are the defect.

`grep -rn genius_wallet lib/components/toast/` is clean (the summary's verification gate), but that grep pattern misses `GeniusWallet` (no underscore), `GW`, and `GeniusWalletConsts`/`GeniusWalletElevation` in theme files — which is why this slipped through.

**Fix:** Strip the provenance labels; keep the values. E.g.:

```dart
/// 4pt spacing scale step.
final double space2;

/// Elevated surface fill used by toasts painted into the root Overlay.
final Color surfaceElevated;   // default #0C0E14

/// Shadow under toasts and other transient elevated surfaces (black @ 35%).
static const List<BoxShadow> card = [ ... ];
```

If provenance is genuinely useful for future syncs, put it in the phase planning docs (`.planning/.../05-05-RESEARCH.md` already has the conflict map) — not in shipped source. A follow-up `grep -rn -iE "geniuswallet|genius_wallet|\bGW\b|sketch-0" lib/ example/lib/` should return zero matches.

---

## Warnings

### WR-01: Mobile breakpoint `600` contradicts the package's own `ScaffoldBreakpoints.small` (760)

**File:** `lib/components/toast/toast_manager.dart:296`

```dart
final isMobile = media.size.width < 600;
```

The package already ships `ScaffoldBreakpoints.small = 760` (`lib/utils/breakpoints.dart:6`) and `useDesktopLayout()` keys off it. The toast independently invents a 600px threshold, so on a 600–760px-wide window (a narrow tablet or a resized desktop window) the rest of the scaffold lays out as mobile while the toast positions itself as desktop (top-right, `startToEnd` dismiss). Two different "is this mobile?" answers in one package is a consistency bug waiting for a bug report.

**Fix:** Use the shared token — `final isMobile = media.size.width <= ScaffoldBreakpoints.small;` (or `!ScaffoldBreakpoints.useDesktopLayout(context)` if the platform check is wanted too). If 600 was a deliberate design choice from the upstream redesign, the deviation should at minimum be documented in the constant's comment explaining why it diverges from `ScaffoldBreakpoints.small`.

---

### WR-02: Desktop swipe-to-dismiss direction contradicts the entry animation

**File:** `lib/components/toast/toast_manager.dart:312-315`

```dart
final slideFrom = isMobile ? const Offset(0, -1) : const Offset(1, 0);
final dismissDirection = isMobile
    ? DismissDirection.up
    : DismissDirection.startToEnd;
```

On desktop the toast slides in from the **right** (`Offset(1, 0)`), and the comment at line 310-311 says "a desktop one slides in horizontally at the top-right and is swiped back out the way it came." But `DismissDirection.startToEnd` means swipe **left-to-right** (in LTR) — which *is* "back out the way it came" for a right-side toast, so this is actually correct in LTR. The defect is RTL: in an RTL locale, `startToEnd` becomes right-to-left, and the toast is still positioned at `right: dimens.space12` sliding in from `Offset(1, 0)` — the swipe now flings it *across* the screen (leftward) instead of back off the right edge. The toast's visual position is locale-invariant (always right) but its dismiss direction is locale-dependent. Either position the toast `end`-anchored and slide from `Offset(1,0)`-in-text-direction, or use `DismissDirection.endToStart`'s mirror — i.e., pick one coordinate system (physical or directional) and use it for both position and dismiss.

**Fix:** For a right-anchored toast in both LTR and RTL, use a physical direction:

```dart
final dismissDirection = isMobile
    ? DismissDirection.up
    : DismissDirection.endToStart; // swiped away from the leading edge, off the right in LTR
```

No — the clean fix given the right-anchor is simply `DismissDirection.horizontal` is wrong (allows both ways); the *correct* physical direction is left-to-right regardless of locale, which Flutter doesn't expose as a locale-invariant enum value. So anchor the toast to `end` (Directionality-aware) and keep `startToEnd`, OR keep the physical right anchor and wrap the `Dismissible` in a forced-LTR `Directionality` so `startToEnd` always means left-to-right. The second is less invasive:

```dart
Directionality(
  textDirection: TextDirection.ltr, // dismiss gesture is physical, not textual
  child: Dismissible(...),
)
```

Flag as Warning, not Critical — RTL hosts are presumably rare for current consumers, but the misbehavior is deterministic when it happens.

---

### WR-03: `Dismissible` key derived from `widget.hashCode` can collide and is unstable across rebuilds

**File:** `lib/components/toast/toast_manager.dart:347`

```dart
child: Dismissible(
  key: ValueKey(widget.hashCode),
```

`widget.hashCode` for `_AnimatedToast` is the default `Object.hashCode` (identity), so each instance gets a distinct key — the *intent* (uniqueness) holds. But `_AnimatedToast` is constructed fresh on **every** `OverlayEntry` rebuild (`builder: (_) => _AnimatedToast(...)`), and `_restack()` calls `markNeedsBuild()` on all siblings after any dismiss. Each rebuild produces a new widget instance → new `hashCode` → new `ValueKey` → the `Dismissible` sees a different key and **discards its internal state** (`_DismissibleState`, including any in-progress drag). Practically: if the user is mid-swipe on toast #2 when toast #1 auto-dismisses, `_restack` rebuilds #2's entry, the key changes, and the drag is reset — the toast snaps back. This is a real interaction bug, just a narrow one.

**Fix:** Use a key that is stable for the toast's lifetime and unique per toast. The manager already has the identity object — pass it (or a counter) through:

```dart
// in show(): give _ActiveToast a final int id = _nextId++;
// in the entry builder: key: ValueKey(toast.id) — but builder closes over `toast`, fine
```

Note `Dismissible` also needs the key to survive the `markNeedsBuild` rebuild, which a captured `toast.id` does. (`_offsetAbove(toast)` is already captured by closure in the same builder, so closing over `toast.id` adds no new lifetime concern.)

---

### WR-04: Stack-cap eviction fires `_dismiss(toast, null)` — consumer's `onClose` is silently dropped, not nulled

**File:** `lib/components/toast/toast_manager.dart:98-100`

```dart
while (_toasts.length >= _kMaxVisible) {
  _dismiss(_toasts.first, null);
}
```

`_dismiss(toast, null)` marks the toast dismissed and removes it, but the `_ActiveToast.onClose` stored at construction (`toast = _ActiveToast(..., onClose: onClose)`) is **never invoked and never nulled** on this path — the record just dies with the callback attached. Two consequences:

1. The consumer's `onClose` silently never fires when their toast is evicted by volume (4th toast shown). For the demo's counters this shows up as `shown=5, closed=4` with no crash and no signal — a consumer relying on `onClose` for "user saw/dismissed this" bookkeeping gets a wrong count.
2. The stored closure is retained until the `_ActiveToast` is GC'd — harmless here because the record is dropped, but it means `_ActiveToast.onClose`'s "fires at most once, then nulled" invariant (the CR-03 comment at line 231-233) is only *mostly* true: the eviction path fires it **zero** times, which the comment's contract ("at most once") technically permits but the API's implicit contract ("onClose fires when the toast closes") does not. Eviction *is* a close — the toast animates out via `controller.reverse()` exactly as a manual close does.

The CR-03 test pins exactly-once for *manual + timer* races; nothing pins the eviction path at all. Decide the contract: either eviction fires `onClose` (pass `toast.onClose` instead of `null` — the callback is already there, `_dismiss` already calls it last), or document on `showToast` that `onClose` may not fire if the toast is evicted by the 3-visible cap.

**Fix (preferred):**

```dart
while (_toasts.length >= _kMaxVisible) {
  final victim = _toasts.first;
  _dismiss(victim, victim.onClose); // eviction is a close; honor the callback
}
```

(`_dismiss` nulls nothing itself — it also doesn't null `toast.onClose` after calling it, relying on the parameter instead; see WR-06. With this change the CR-03 "exactly once" guarantee still holds because `dismissed` is set before the callback fires.)

---

### WR-05: `_dismiss` fires the `onClose` *parameter*, never `_ActiveToast.onClose` — the stored-callback null-out the CR-03 comment describes doesn't exist

**File:** `lib/components/toast/toast_manager.dart:189-209` and `:121-125`

The comment at line 121-124 says:

```dart
// CR-03 hybrid: the `dismissed` flag guards re-entry, and the
// stored callback is nulled after firing so a second `_dismiss`
// (swipe racing the auto-dismiss timer) cannot fire it twice.
```

Read the code: `_dismiss(toast, onClose)` receives the callback **as a parameter from the call site** (`onDismiss: () => _dismiss(toast, onClose)` closes over the original `show()` argument) and calls `onClose?.call()` at line 208. `_ActiveToast.onClose` (the *stored* callback) is **never read by `_dismiss`** and **never nulled by `_dismiss`**. It is only nulled by `_forget`, `_drop`, and the cross-overlay prune. So:

- The "stored callback is nulled after firing" mechanism described in the comment **does not exist**. What actually prevents double-fire is solely the `dismissed` flag (set at line 193 before any callback). That is sufficient — the flag *is* the guard — but the comment documents a two-layer defense where only one layer is implemented, and `_ActiveToast.onClose` is a dead field on every path except teardown (where nulling it is pointless anyway since the record is being removed).
- Consequence beyond a misleading comment: WR-04's eviction path *can't* honor the consumer callback via the stored field without reading the field the current code treats as write-only, and anyone "fixing" the field to match the comment (nulling it in `_dismiss`) would change nothing observable — it's write-only today.

**Fix:** Either delete `_ActiveToast.onClose` and fix the comment to credit only the `dismissed` flag, or make the mechanism real: `_dismiss` reads `toast.onClose`, nulls it, then fires — and the entry's `onDismiss` closure becomes `() => _dismiss(toast)` with no captured callback. The second is better because it also fixes WR-04 for free (eviction calls the same `_dismiss(toast)` and the stored callback fires). As-is this is Warning (dead/misdocumented mechanism), not Critical, because the single guard that exists is correct.

---

### WR-06: `_offsetAbove` is read per-build, but `_restack` only runs on list mutation — toasts added *above* an existing toast never shift it

**File:** `lib/components/toast/toast_manager.dart:107, 163-173, 178-187`

`offsetAbove` is captured into the entry builder at insert: `builder: (_) => _AnimatedToast(offsetAbove: _offsetAbove(toast), ...)`. Since the closure re-invokes `_offsetAbove(toast)` on every rebuild and `_restack()` marks siblings dirty after dismiss, the *removal* direction works (pinned by the "evicts the oldest" test). But consider insert: `show()` appends the new toast at the **end** of `_toasts` and inserts its entry on **top** of the overlay stack. `_offsetAbove` sums strides of toasts at indices `< index` — i.e., *older* toasts. New toast N gets `offsetAbove = sum(strides of 0..N-1)`, so it renders *below* all existing toasts, and existing toasts never need to move (their index doesn't change on append). That's consistent — no bug — **but** the top-positioning math places index 0 highest on screen (`top = base + 0`) and index N lowest, i.e., the *oldest* toast is on top and new toasts appear *underneath* the stack, near the vertical center of the screen once 3 are up. Combined with the cap eviction (oldest evicted first, from the top), the visual model is a downward-growing stack whose most recent — most relevant — item is furthest from the header. If that's the intended design (the summary doesn't say either way; upstream's `pushReplacement`-style UX usually puts newest on top), fine — but then the `_kMaxVisible` comment ("Beyond this the oldest is evicted. Was uncapped: at the old flat 85px stride the fourth toast sat at 355px") describes growth *downward*, and a compact (44px stride) under two cards (84px each) lands the third toast at `base + 168`, which on a 390x844 phone with `base ≈ 115` is y≈283 — fine. The risk case is the one the file's own ponytail comment names: a card whose message wraps to 3 lines exceeds the 84px stride and overlaps the toast below. The comment disclaims this ("not done here"), so it's a documented limitation — but it's a *correctness* limitation (visual overlap = broken UI), and "only large text scale reaches it" understates it: any card message over ~2 lines at normal scale exceeds 84px of content (`space6` padding 12×2 + title ~28 + space2 4 + body ~40 = ~96px before wrapping).

**Fix:** Cheap mitigation without the full single-`Column` rewrite: measure nothing, but bump `_kCardStride` to a value covering the worst realistic card (e.g. 112), accepting extra air under short cards; or clamp card message `maxLines: 2` + ellipsis in `_Card` so 84px is a hard bound. Flagging as Warning because the overlap is reachable at default text scale with a long-ish message, not just at 2.0x.

---

## Info

### IN-01: `_kMobileHeaderHeight = 60.0` duplicates `ScaffoldDimens.appBarHeight = 65.0` with a stale cross-reference

**File:** `lib/components/toast/toast_manager.dart:24-25`

The comment cites `MobileHeader.preferredSize` — no `MobileHeader` type exists in this package (grep confirms). The package's own header token is `ScaffoldDimens.appBarHeight = 65.0`, which the toast ignores in favor of a private 60.0 literal. So the toast's top offset (`padding.top + 60 + 8`) will sit 5px *under* a 65px app bar on any host using the package's own dimens. The doc reference is to the upstream app. **Fix:** use `dimens.appBarHeight` (host-overridable, and the stale comment disappears), or at minimum rename the comment to not cite a type the package doesn't contain.

### IN-02: `ToastNavigatorObserver` clears toasts on *every* `didPush` — including the push that hosts the toast's own caller

**File:** `lib/components/toast/toast_navigator_observer.dart:16-20`

`didPush` → `disposeAll()` means: user taps a button, app pushes a route, the new route's `initState`/build calls `showToast` — fine (push happens first). But any app that shows a toast and *then* pushes (e.g., "Saved" toast fired optimistically before navigation completes) has the toast instantly killed by its own navigation. This is pre-existing behavior carried through the port (the diff on this file is comment churn), so it's not a 05-05 regression — flagging Info so the API contract is at least consciously kept: `ToastNavigatorObserver` makes toasts route-scoped, and `onClose` does **not** fire on route-change teardown (by design, per `disposeAll` docs). That second half is worth one line in `showToast`'s doc, since it's surprising.

### IN-03: Test `_pumpHost` doesn't reset `devicePixelRatio` / full view state; `tearDown` ordering is load-bearing

**File:** `test/components/toast_test.dart:18-20, 43`

`addTearDown(tester.view.resetPhysicalSize)` resets size but not `devicePixelRatio` (set to 1.0 at line 19) — `resetPhysicalSize` on current Flutter does reset DPR transitively in most versions, but the explicit `tester.view.resetDevicePixelRatio` pairing is the robust form. Minor. The `tearDown(() => ToastManager.instance.disposeAll())` at line 43 is doing real work: the singleton's `_overlay` field survives between tests, and without this teardown a stale-overlay prune could mask a leak in a later test (the suite currently orders around it correctly). Not a defect — worth a one-line comment noting the singleton must be reset between tests, since the next person to add a test file will copy `_pumpHost` without it.

---

## Positive verification (checked, no findings)

- **CR-02 timer lifecycle**: `_autoDismiss` created in `initState`, cancelled in `dispose` before `_controller.dispose()` — correct order; manager holds no timers. `late final toast`/`entry` closure dance in `show()` is safe: `onControllerReady` and `onDismiss` can only fire after `overlay.insert`, by which point both are assigned.
- **CR-03 exactly-once**: `dismissed` is set before `onClose?.call()`; all re-entry paths (`_dismiss`, `_forget`, `_drop`) check or set the flag first. Test pins the manual+timer race with a 6s pump. Holds.
- **CR-04 teardown**: `_forget` runs from `State.dispose` before controller disposal; `_restack` guards `entry.mounted`; the cross-overlay prune in `show()` covers the inserted-but-never-built edge (empirically confirmed per the summary, and the mechanism reads correctly — `identical(overlay, _overlay)` is the right identity check for `OverlayState`).
- **ThemeExtension correctness**: every new field in `ScaffoldDimens` (8) and `ScaffoldPalette` (7) appears in the constructor (all `required`), `copyWith` (nullable param + `?? this.`), and `lerp` (`lerpDouble` / `Color.lerp(...)!` — non-nullable fields make the `!` sound). `defaultDimens`/`defaultPalette` supply all fields. `ScaffoldElevation` is a static token class, not a `ThemeExtension`, so no lerp obligation. No missing-field bugs.
- **`ticker_provider.dart` deletion**: removed from barrel export (`frontend_scaffold.dart`), zero source references in `lib/`, `test/`, `example/lib/`; matches in `example/build/**` are generated file lists (stale until next build, harmless). Deletion is clean.
- **Barrel diff**: exactly one export removed (`ticker_provider.dart`), one added (`scaffold_elevation.dart`). Correct.
- **Example demo**: counters wire `onClose` per-call; `disposeAll` button exercises the CR-04 path; no wallet references in the demo.
- **`Navigator.of(context).overlay!` fallback** (`toast_manager.dart:85`): `navigator.overlay` is non-null for a mounted Navigator in practice; the force-unwrap is consistent with the comment's "throwing is what `Overlay.of` already did" stance. Acceptable.

---

_Reviewed: 2026-08-09_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
