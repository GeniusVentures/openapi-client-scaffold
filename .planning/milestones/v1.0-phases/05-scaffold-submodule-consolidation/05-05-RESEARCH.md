---
provenance: "Re-homed from genius-ai-boss .planning/workstreams/frontend-templates on 2026-08-09 (scaffold workstream bootstrap); paths normalized to repo-relative"
phase: 05-scaffold-submodule-consolidation
plan: "05"
task: 1
type: research
source_of_truth:
  repo: /Users/Shared/SSDevelopment/Development/GeniusVentures/GeniusNetwork/GeniusWallet
  branch: redesign/toast-notification-260808
  tip: b4b63a5a
  files:
    - lib/components/toast/toast_widget.dart
    - lib/components/toast/toast_manager.dart
    - lib/components/toast/toast_navigator_observer.dart
    - test/components/toast_test.dart
    - .planning/sketches/079-toast-two-densities/README.md
scaffold_baseline:
  repo: frontend/scaffold
  commit_with_CR_fixes: 7fc42ed
  files:
    - lib/components/toast/toast_manager.dart   (contains CR-02..04)
    - lib/components/toast/toast_widget.dart    (old API — required title, hardcoded colors)
    - lib/components/toast/toast_navigator_observer.dart
---

# 05-05 Research — Toast Redesign Port Contract

This document is the single reference Task 3 uses to port the GeniusWallet toast
redesign into `frontend_scaffold` **without regressing the Phase-5 lifecycle
fixes (CR-02..04)**. It captures (1) the public API contract, (2) the density
rules from sketch-079, (3) a line-by-line conflict map between the redesign and
CR-02..04, (4) the import/theme neutralization table, and (5) the test
inventory (upstream suite + the CR-02..04 regression tests the upstream suite
lacks).

---

## 1. Public API contract

### 1.1 Top-level call (the "one notification, one call, everywhere" entry point)

```dart
// NEW signature (message-first, optional title, optional type, optional duration):
void showToast(
  BuildContext context,
  String message, {
  String? title,                          // null → compact density
  ToastType type = ToastType.success,     // default success (receipt)
  Duration? duration,                     // null → density default (compact 2s / card 5s)
  VoidCallback? onClose,
})
```

**Breaking change vs current scaffold:** current scaffold exposes only
`ToastManager().showToast({required context, required title, required message,
required type, duration = 5s, onClose})`. The redesign makes `title` optional,
moves `message` to positional, defaults `type` to `success`, and adds a
top-level `showToast(context, message, ...)` free function. Scaffold's old
method-style call (`ToastManager().showToast(...)`) is replaced by the free
function; `ToastManager.instance.show(...)` remains as the underlying entry.

### 1.2 `ToastManager` (singleton, redesigned)

| Member | Signature / value | Notes |
|---|---|---|
| `instance` | `static final ToastManager instance = ToastManager._();` | Singleton accessor (was a factory `ToastManager()` returning `_instance`) |
| `visibleCount` | `@visibleForTesting int get visibleCount` | Test-only metric, replaces nothing (new) |
| `show({...})` | named-only; see §1.1 | The underlying impl — top-level `showToast` delegates here |
| `disposeAll()` | `void disposeAll()` | Renamed from `dispose()`; semantics preserved (clear all toasts synchronously) |

### 1.3 `ToastWidget`

```dart
class ToastWidget extends StatelessWidget {
  final String message;
  final String? title;                   // OPTIONAL — was `required this.title`
  final ToastType type;
  final VoidCallback onDismiss;
  const ToastWidget({super.key, required this.message, required this.type,
                     required this.onDismiss, this.title});

  ToastDensity get density => title == null ? ToastDensity.compact : ToastDensity.card;
  String get semanticLabel => title == null ? message : '$title. $message';
}
```

### 1.4 Enums and constants

| Symbol | Value | Purpose |
|---|---|---|
| `enum ToastDensity { compact, card }` | two values | Drives layout, duration, dismiss affordance, semantics |
| `enum ToastType { success, error, warning }` | unchanged | Status kind — drives accent color + icon only |
| `_kCardStride = 84.0` | double | Vertical stride per card toast in the stack |
| `_kCompactStride = 44.0` | double | Vertical stride per compact toast in the stack |
| `_kMaxVisible = 3` | int | Cap on stack; oldest evicted beyond this |
| `_kMobileHeaderHeight = 60.0` | double | App-bar height used in mobile top-offset derivation |
| `_kCompactDuration = Duration(seconds: 2)` | Duration | Default compact (receipt) lifetime |
| card default duration | `Duration(seconds: 5)` | Default card (alert) lifetime |
| animation duration | `Duration(milliseconds: 300)` | Slide/fade transition length |
| dismiss-button target | `BoxConstraints.tightFor(width: 44, height: 44)` | 44pt a11y floor (was ~28pt) |
| dismiss-button icon size | `18` | visual glyph size inside the 44pt box |
| compact icon size | `16` | smaller glyph for the pill |
| card icon size | `20` | larger glyph for the alert |
| mobile horizontal inset | `GeniusWalletConsts.space3` (6.0) | left/right edge inset on mobile |
| desktop horizontal inset | `GeniusWalletConsts.space12` (24.0) | right edge on desktop (left = null) |
| mobile max width | `560` | ConstrainedBox maxWidth on mobile |
| desktop max width | `420` | ConstrainedBox maxWidth on desktop |
| mobile breakpoint | `< 600` | `MediaQuery.size.width < 600` selects mobile placement |
| compact vertical padding | `space3` (6.0) | pill vertical inset |
| compact horizontal padding | `space8` (16.0) | pill horizontal inset |
| card padding | `space6` (12.0) all around | alert inset |
| card title-to-message gap | `space2` (4.0) | row-to-message vertical gap |
| compact border radius | `radiusPill` (48.0) | pill shape |
| card border radius | `radiusMd` (12.0) | alert shape |
| desktop top inset | `space12` (24.0) | desktop top-offset base |
| mobile top inset | `padding.top + _kMobileHeaderHeight + space4` (44+60+8 = 112 on a 14 Pro) | derived — never a literal |

### 1.5 Safe-area / placement behavior

- **Mobile** (`MediaQuery.size.width < 600`):
  `top = MediaQuery.padding.top + _kMobileHeaderHeight + GeniusWalletConsts.space4 + offsetAbove`.
  Slide-in from top (`Offset(0, -1)`), dismiss by swipe-up (`DismissDirection.up`).
- **Desktop**: `top = GeniusWalletConsts.space12 + offsetAbove`.
  Slide-in from right (`Offset(1, 0)`), dismiss by swipe-right (`DismissDirection.startToEnd`).
- **Reduced motion**: when `MediaQuery.disableAnimations` is true, replace `SlideTransition`
  with `FadeTransition` (no travel, only opacity).
- **Stacking**: each toast's `offsetAbove` is the sum of strides of every toast
  currently above it (density-aware: card 84, compact 44). Recomputed from list
  order on every restack, so a dismissed toast's hole closes automatically.

### 1.6 Semantics / a11y

- `Semantics(container: true, liveRegion: true, label: semanticLabel)` wraps
  every toast.
- `semanticLabel`: title present → `'$title. $message'`; title absent → `message`.
- `Material(type: MaterialType.transparency, ...)` ancestor is mandatory —
  without it `Text` inherits the no-Material debug fallback (red + yellow
  double underline).

---

## 2. Density rules (sketch-079)

| Aspect | compact (receipt) | card (alert) |
|---|---|---|
| Trigger | `title == null` | `title != null` |
| Use case | "Link copied" — user just acted, they already know | "Verification failed" — user did not ask, may need to act |
| Shape | Pill (`radiusPill` 48) | Rounded rect (`radiusMd` 12) |
| Width | auto-width (intrinsic, centered via `Align`) | full-width inset (mobile: `space3` both sides; desktop: 420 max) |
| Title | none | `titleMd` typography, ellipsis, `textPrimary` |
| Message | `labelMd`, single line, ellipsis, `textPrimary` | `bodySm`, wraps, `textSecondary` |
| Icon size | 16 | 20 |
| Layout | single Row, `mainAxisSize: min` | two rows: Row(icon, title, dismiss) + full-width message below |
| Dismiss affordance | none (auto-dismiss only) | 44×44 IconButton + swipe gesture |
| Default duration | 2s | 5s |
| Status color application | leading icon only | leading icon only (no 2px full ring — that was the OLD visual) |
| Padding | h=`space8` (16), v=`space3` (6) | all=`space6` (12) |
| Semantics | `liveRegion: true`, `label = message` | `liveRegion: true`, `label = '$title. $message'` |
| Stride in stack | 44 | 84 |

**Stacking & eviction**: cap of 3 visible toasts; oldest evicted when a 4th is
shown. Strides are density-aware — a compact toast reserves 44 px for the one
below it, a card reserves 84 px.

**Accent color source** (both densities): `ToastType` →
- success → `GWColors.statusSuccess`
- error → `GWColors.statusError`
- warning → `GWColors.statusWarningText`

**Icons**: success → `Icons.check_circle_outline_outlined`; error →
`Icons.error_outline_outlined`; warning → `Icons.warning_amber_outlined`.

**Surfaces**: `GWColors.surfaceElevated` fill, `GWColors.borderSubtle` 1px
border, `GeniusWalletElevation.card` shadow — opaque (no translucent scrim)
because the toast is painted into the root Overlay and must read over anything.

---

## 3. Conflict map — redesign × CR-02..04

The scaffold's current `toast_manager.dart` (commit `7fc42ed`) contains three
Critical fixes from Phase 5. The GW redesign branch **predates** those fixes.
A naive file copy would reintroduce all three bugs. The port MUST reapply them
on top of the redesigned manager. The redesign actually fixes the same class
of bug differently in two places — those are noted below.

### CR-02 — `OverlayEntry` leak / dispose of in-flight AnimationController

**Scaffold fix (7fc42ed)**: auto-dismiss `Timer` is stored on `_ToastEntry`
and cancelled in `_removeToast`/`dispose`; entry is idempotently removed via
`_isRemoved` flag; `_teardownEntry` disposes tickerProvider + controller
synchronously after `reverse().then(...)` completes.

**Redesign equivalent**: the redesign **moves the auto-dismiss timer off the
manager entirely** — it lives on `_AnimatedToastState` (`_autoDismiss =
Timer(widget.duration, widget.onDismiss)`), created in `initState` and
cancelled in `State.dispose()`. This is a *structurally stronger* fix than
CR-02: the timer's lifecycle is bound to the widget's element, so a torn-down
tree always cancels it (verified by the upstream test "a torn-down tree leaves
no timer running").

**Port action**: **keep the redesign's timer placement**. Do NOT reintroduce
the scaffold's manager-held `Timer`. The redesign's approach is a superset —
it solves CR-02's leak path AND the pending-timer failure in widget tests.
**However**, the redesign's `_dismiss` still has the "reverse on a
non-animating controller" path — port the scaffold's
`controller.isAnimating || controller.isCompleted` guard verbatim, and keep
the synchronous-teardown `else` branch.

### CR-03 — auto-dismiss timer never cancelled on manual close → `onClose` double-fires

**Scaffold fix (7fc42ed)**: `_removeToast` is idempotent (`_isRemoved` flag);
`onClose` fires exactly once and is then nulled.

**Redesign equivalent**: `_dismiss` guards with `if (toast.dismissed) return;`
and sets `toast.dismissed = true` before calling `onClose?.call()`. Timer
cancellation is automatic because the timer lives on the `State` (see CR-02)
and `State.dispose` runs when the entry is removed.

**Port action**: **preserve the redesign's `dismissed` flag** AND keep the
scaffold's "fire `onClose` exactly once, then null it" pattern. The redesign
calls `onClose?.call()` unconditionally at the end of `_dismiss` — fine —
but does not null it out, so a second `_dismiss` (e.g. swipe + timer racing)
would fire it twice. Add the scaffold's `entry.onClose = null;` immediately
after `entry.onClose?.call();`. Also keep `disposeAll()` firing `onClose`
once per entry (the redesign's `disposeAll` passes `null` for `onClose`,
which is correct — route-pop teardown should NOT trigger consumer close
callbacks; this matches the scaffold's behavior).

### CR-04 — builder runs against a disposed AnimationController after route pop

**Scaffold fix (7fc42ed)**: `_disposed` flag on `_ToastEntry` checked at the
top of the `OverlayEntry` builder → returns `SizedBox.shrink()`; `dispose()`
tears down synchronously without `reverse().then(...)`.

**Redesign equivalent**: `_forget(toast)` is called from `_AnimatedToastState.dispose`
and removes the toast from `_toasts` without touching the entry; `_restack`
checks `toast.entry.mounted` before `markNeedsBuild()`. These cover the
"tree torn down before first frame" path.

**Port action**: **keep the redesign's `_forget` + `mounted` guard**. The
redesign does NOT need the scaffold's `_disposed` builder short-circuit,
because the overlay entry's lifecycle is now driven by the State (its
`dispose` runs before the controller's). Keep the redesign's `_restack`
mounted check verbatim.

### Summary of the port's lifecycle contract

| Concern | Redesign mechanism | Scaffold mechanism | Port decision |
|---|---|---|---|
| Auto-dismiss timer ownership | `_AnimatedToastState` (initState/dispose) | `_ToastEntry.autoDismissTimer` | **Redesign** — stronger, also fixes widget-test pending-timer |
| Removal idempotency | `toast.dismissed` flag | `_isRemoved` flag | **Redesign** — equivalent; keep single flag |
| `onClose` exactly-once | `dismissed` guard only | guard + null-after-fire | **Hybrid** — redesign guard + null-after-fire |
| Reverse-before-remove | `isAnimating \|\| isCompleted` (already in redesign) | same condition + synchronous else | **Redesign** — already matches scaffold |
| Route-pop teardown | `_forget` from `State.dispose` + `mounted` guard in `_restack` | `_disposed` flag in builder | **Redesign** — `_disposed` no longer needed |
| `disposeAll` synchronous | `_dismiss(..., null)` per entry | full synchronous teardown | **Redesign** — `_dismiss` already synchronous for non-animating controllers |
| `onClose` on `disposeAll` | passes `null` — does NOT fire | fires once per entry | **Redesign** — route-pop should not notify consumers |

---

## 4. Import / theme neutralization list

Every reference the redesigned GW files make, and what it becomes in the
scaffold package. Scaffold already exposes `context.palette` and
`context.dimens` via `ScaffoldThemeX` (`lib/theme/scaffold_theme.dart`), and
ships `scaffoldThemeExtensions` for tests.

| GW import / symbol | Scaffold replacement | Notes |
|---|---|---|
| `package:genius_wallet/components/toast/toast_manager.dart` | `package:frontend_scaffold/components/toast/toast_manager.dart` | package rename |
| `package:genius_wallet/components/toast/toast_widget.dart` | `package:frontend_scaffold/components/toast/toast_widget.dart` | package rename |
| `package:genius_wallet/theme/genius_wallet_consts.dart` | `package:frontend_scaffold/theme/scaffold_dimens.dart` | **BUT** — `ScaffoldDimens` does NOT carry the `space*` / `radius*` scale. See §4.1 below. |
| `package:genius_wallet/theme/gw_colors.dart` (`GWColors`) | `package:frontend_scaffold/theme/scaffold_palette.dart` (`ScaffoldPalette`) | `ScaffoldPalette` is missing several fields the toast needs. See §4.2. |
| `package:genius_wallet/theme/gw_context_extension.dart` (`context.gw`) | `package:frontend_scaffold/theme/scaffold_theme.dart` (`context.palette`) | direct rename |
| `package:genius_wallet/theme/genius_wallet_elevation.dart` (`GeniusWalletElevation.card`) | new `ScaffoldElevation` (or inline) | scaffold has no elevation tokens yet. See §4.3. |
| `package:genius_wallet/theme/genius_wallet_typography.dart` (`GeniusWalletTypography.{labelMd,titleMd,bodySm}`) | new `ScaffoldTypography` (or use `Theme.of(context).textTheme`) | scaffold has no typography tokens yet. See §4.4. |
| `GeniusWalletConsts.space2` (4.0) | `ScaffoldDimens` extension (new field) or local const | see §4.1 |
| `GeniusWalletConsts.space3` (6.0) | same | see §4.1 |
| `GeniusWalletConsts.space4` (8.0) | same | see §4.1 |
| `GeniusWalletConsts.space6` (12.0) | same | see §4.1 |
| `GeniusWalletConsts.space8` (16.0) | same | see §4.1 |
| `GeniusWalletConsts.space12` (24.0) | same | see §4.1 |
| `GeniusWalletConsts.radiusMd` (12.0) | `ScaffoldDimens.borderRadiusCard` (currently 15.0) — **value mismatch** | see §4.1 |
| `GeniusWalletConsts.radiusPill` (48.0) | `ScaffoldDimens.borderRadiusButton` (currently 48.0) | value matches; rename usage |
| `GWColors.surfaceElevated` | new field on `ScaffoldPalette` | see §4.2 |
| `GWColors.borderSubtle` | new field on `ScaffoldPalette` | see §4.2 |
| `GWColors.textPrimary` | new field on `ScaffoldPalette` | see §4.2 |
| `GWColors.textSecondary` | new field on `ScaffoldPalette` | see §4.2 |
| `GWColors.statusSuccess` | new field on `ScaffoldPalette` | see §4.2 |
| `GWColors.statusError` | new field on `ScaffoldPalette` | see §4.2 |
| `GWColors.statusWarningText` | new field on `ScaffoldPalette` | see §4.2 |
| `context.gw` | `context.palette` | extension getter rename |

### 4.1 `ScaffoldDimens` extension — add the spacing/radius scale

Current `ScaffoldDimens` has only 7 layout fields; it does NOT carry the 4-pt
spacing scale or the radius tokens the toast needs. Task 3 must extend
`ScaffoldDimens` with the following fields, seeded from
`GeniusWalletConsts` defaults:

```dart
final double space2;   // 4.0
final double space3;   // 6.0
final double space4;   // 8.0
final double space6;   // 12.0
final double space8;   // 16.0
final double space12;  // 24.0
final double radiusMd;   // 12.0  (GeniusWalletConsts.radiusMd)
final double radiusPill; // 48.0  (GeniusWalletConsts.radiusPill — matches existing borderRadiusButton)
```

(`borderRadiusCard` currently 15.0 — the redesign uses 12.0 for the card.
Decision: keep `borderRadiusCard` untouched and add `radiusMd` as a separate
token so existing card consumers don't change.)

### 4.2 `ScaffoldPalette` extension — add toast-needed fields

Current `ScaffoldPalette` has 8 fields (card surface, greens, grays, blues,
border, tertiary). The toast needs seven more, all appearance-aware in GW
(light/dark) but for the scaffold port they can be seeded with the dark-mode
values as defaults (host apps override via `ThemeData.extensions`):

```dart
final Color surfaceElevated;    // GW dark: #0C0E14 (per sketch-079)
final Color borderSubtle;       // GW dark borderSubtle
final Color textPrimary;        // GW dark textPrimary
final Color textSecondary;      // GW dark: #8A8F9D (per sketch-079)
final Color statusSuccess;      // GW: #0AD89C (per sketch-079)
final Color statusError;        // GW: #FF4D4D (per sketch-079)
final Color statusWarningText;  // GW dark warning text
```

Task 3 must read the actual dark values from
`GeniusWallet/.../genius_wallet_colors.dart` at the merge commit.

### 4.3 Elevation

`GeniusWalletElevation.card` is a single `BoxShadow(blurRadius: 16,
offset: Offset(0,4), color: black @ 12% light / 35% dark)`. Scaffold has no
elevation tokens. Two options for Task 3:

- **(A)** add `ScaffoldElevation.card` as a static list (mode-invariant dark
  value as default) — minimal port; or
- **(B)** inline the shadow in `_Compact` / `_Card`.

Recommend **(A)** — keeps the shadow a token, matches the redesign's
appearance-aware structure, and is a one-class addition.

### 4.4 Typography

The redesign uses three type styles: `labelMd` (compact message),
`titleMd` (card title), `bodySm` (card message). Scaffold has no typography
tokens. Task 3 options:

- **(A)** add `ScaffoldTypography` with the three getters (Inter, sizes
  12/16/14, weights 500/500/400) — needs the Inter font asset, which scaffold
  does not currently bundle; or
- **(B)** use `Theme.of(context).textTheme.{labelMedium,titleMedium,bodySmall}`
  and `.copyWith(color: ...)` — zero new assets, M3-native.

Recommend **(B)** for the scaffold port: scaffold is a generic package and
should not bundle Inter; consumer apps supply their own textTheme. The
redesign's exact pixel sizes are a GeniusWallet brand decision, not a scaffold
invariant. Document this deviation in the SUMMARY.

---

## 5. Test inventory

### 5.1 Upstream suite — `GeniusWallet/test/components/toast_test.dart` (188 lines, 7 tests)

| # | Test name | What it proves | Scaffold equivalent |
|---|---|---|---|
| 1 | `no title gives a compact pill with no dismiss button` | `ToastDensity.compact` selected when `title == null`; no `Dismiss` tooltip | direct port (imports + `scaffoldThemeExtensions` in harness) |
| 2 | `a title gives the card, with a 44pt dismiss target` | `ToastDensity.card` selected; IconButton ≥ 44×44 | direct port |
| 3 | `a screen reader is handed both halves of an alert` | `semanticLabel == '$title. $message'`; `Semantics.liveRegion == true` | direct port |
| 4 | `toast text carries no inherited debug underline` | `RichText` `decoration == TextDecoration.none` (no-Material fallback guarded) | direct port |
| 5 | `the top offset is derived from the safe area, not a literal` | `Positioned.top == topInset + 68` for both 47 and 20 insets | direct port — constant 68 = `_kMobileHeaderHeight` (60) + `space4` (8) |
| 6 | `the stack caps at three and evicts the oldest` | `visibleCount == 3` after 5 shows; oldest gone, newest present | direct port |
| 7 | `a torn-down tree leaves no timer running` | `visibleCount == 0` after `pumpWidget(SizedBox.shrink())` (auto-dismiss timer cancelled by State.dispose) | direct port |

**Harness pattern (upstream)**: `_pumpHost(tester, {size, topInset})` sets
`tester.view.physicalSize`, `devicePixelRatio = 1.0`, wraps a `MaterialApp`
in a `MediaQuery` with the given padding, and returns a captured
`BuildContext`. Tests tear down with `ToastManager.instance.disposeAll()`.

**Harness adaptations for scaffold**:
- `MaterialApp(theme: ThemeData(extensions: scaffoldThemeExtensions), ...)`
  so `context.palette` / `context.dimens` resolve.
- Imports: `package:genius_wallet/...` → `package:frontend_scaffold/...`.

### 5.2 CR-02..04 regression tests the upstream suite LACKS

These are NEW tests to add in Task 2. They pin the lifecycle behaviors that
Phase 5's review identified as Critical, which the redesign's structure now
covers but which are not independently test-locked upstream.

| # | Test name (proposed) | CR covered | What it proves |
|---|---|---|---|
| 8 | `manual dismiss fires onClose exactly once (no timer double-fire)` | CR-03 | show toast with `onClose` counter; tap Dismiss; pump past the auto-dismiss duration; counter == 1 |
| 9 | `dispose with in-flight toast does not crash` | CR-02 + CR-04 | show toast; immediately `pumpWidget(SizedBox.shrink())` (route pop) before first frame settles; expect no exception, `visibleCount == 0` |
| 10 | `entry is removed after reverse animation completes` | CR-02 | show toast; dismiss manually; `visibleCount` drops to 0 immediately (list mutation is synchronous); pump 300ms; entry removed from overlay (no lingering widget) |

Test 8 is the strongest guard — it directly catches the Phase-5 regression
where the auto-timer outlived manual dismissal and double-fired `onClose`.
Test 10 pins the "reverse().then(remove)" path so a future refactor can't
silently leak OverlayEntries.

### 5.3 Test-file layout

```
test/components/toast_test.dart   (all 10 tests, one file)
```

No separate CR file — keeping one suite matches upstream and keeps the
ported-diff readable.

---

## 6. Open questions for Task 3 (flagged, not blocking)

1. **Typography strategy** (§4.4) — recommend M3 `textTheme` over bundling
   Inter. Confirm with user if brand fidelity matters here.
2. **Elevation strategy** (§4.3) — recommend a new `ScaffoldElevation` class.
3. **`borderRadiusCard` value** — redesign uses 12, scaffold's token is 15.
   Add a separate `radiusMd` token rather than change the existing one.
4. **Palette defaults** — scaffold is dark-seeded; do we also ship a light
   palette default? (Out of scope for 05-05; track as follow-up.)
