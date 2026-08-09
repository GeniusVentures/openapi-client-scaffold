---
provenance: "Re-homed from genius-ai-boss .planning/workstreams/frontend-templates on 2026-08-09 (scaffold workstream bootstrap); paths normalized to repo-relative"
phase: 05-scaffold-submodule-consolidation
reviewed: 2026-08-05T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - pubspec.yaml
  - README.md
  - lib/genius_scaffold.dart
  - lib/theme/genius_wallet_consts.dart
  - lib/theme/genius_wallet_colors.g.dart
  - lib/utils/breakpoints.dart
  - lib/components/action_button.dart
  - lib/components/app_screen_view.dart
  - lib/components/desktop_body_container.dart
  - lib/components/responsive_grid.dart
  - lib/components/sliding_drawer_button.dart
  - lib/components/string_button.dart
  - lib/components/text_entry_field.g.dart
  - lib/components/text_entry_field_widget.g.dart
  - lib/components/text_form_field_logic.g.dart
  - lib/components/loading/loading.dart
  - lib/components/toast/toast_manager.dart
  - lib/components/toast/toast_widget.dart
  - lib/components/toast/ticker_provider.dart
  - lib/components/toast/toast_navigator_observer.dart
  - lib/components/animation/x_animation.dart
  - lib/components/animation/checkmark_animation.dart
  - lib/components/bottom_drawer/bottom_drawer.dart
  - lib/components/bottom_drawer/responsive_drawer.dart
  - lib/components/custom/text_entry_field_logic.dart
findings:
  critical: 4
  warning: 7
  info: 6
  total: 17
status: issues_found
---

# Phase 5: Code Review Report — genius_scaffold Package

**Reviewed:** 2026-08-05
**Depth:** standard
**Files Reviewed:** 20 (one extra file beyond the requested list was found and reviewed: `lib/components/custom/text_entry_field_logic.dart` was already in the list; `pubspec.lock` and `templates/` were inspected for cross-references)
**Status:** issues_found

## Summary

`dart analyze lib/` runs clean against Flutter 3.41.9, so nothing blocks `analyze` today. However, the package has **one Critical** SDK-constraint defect that will break consumers on older Flutter, **three Critical** correctness bugs in `ToastManager`, and **pervasive Warning-level naming contamination** from the GeniusWallet origin that contradicts the "generic scaffolding package" contract — exactly the headline user finding. The public barrel (`lib/genius_scaffold.dart`) exports `GeniusWalletColors`, `GeniusWalletConsts`, and `GeniusBreakpoints` (typo for `GeniusWalletBreakpoints` — or perhaps intentionally shortened, either way it's broken), and the pubspec description itself reads "GeniusWallet-derived bloc widgets."

`templates/` was grep'd for wallet references — **no contamination in templates** (clean). All wallet-branded identifiers are confined to `lib/` and `pubspec.yaml`.

The four `*.g.dart` files carry a "PARABEAC-GENERATED CODE. DO NOT MODIFY." banner, but there is no `build.yaml`, no `parabeac` dependency in `pubspec.yaml`, and no generator script in this repo that would regenerate them — they are effectively hand-copied source masquerading as generated output. This is misleading and must be resolved (either drop the banner and rename to non-`.g.dart`, or actually wire up Parabeac — see IN-06).

**Recommended rename scheme (one, applied consistently):**

| Current | Proposed |
|---|---|
| `theme/genius_wallet_colors.g.dart` | `theme/scaffold_colors.dart` |
| `class GeniusWalletColors` | `class ScaffoldColors` |
| `theme/genius_wallet_consts.dart` | `theme/scaffold_dimens.dart` (these are spacing/radius/height, not "colors") |
| `class GeniusWalletConsts` | `class ScaffoldDimens` |
| `class GeniusBreakpoints` (in `utils/breakpoints.dart`) | `class ScaffoldBreakpoints` |
| `pinCount`, `Wallet Address` hint | remove or move to consumer apps |

This pairs `Scaffold*` with the package name `genius_scaffold` and keeps internal vocabulary neutral (no `Wallet`, no `Genius` prefix on individual classes — the package name itself already provides namespace).

---

## Critical Issues

### CR-01: `withValues()` used but Flutter SDK constraint allows older Flutter that doesn't have it

**File:** `lib/theme/genius_wallet_colors.g.dart:72`
**Issue:**
```dart
static Color btnFilterSelected = lightGreenPrimary.withValues(alpha: 0.1);
```
`Color.withValues()` was added in **Flutter 3.27** (December 2024). The pubspec declares `environment: sdk: ^3.5.0` with **no explicit Flutter constraint**, so consumers on Flutter 3.5–3.26 will fail to compile with `The method 'withValues' isn't defined for the class 'Color'`. `dart analyze` passes here only because the local Flutter is 3.41.9.

**Fix (pick one — prefer option A):**

A) Tighten the Flutter SDK constraint in `pubspec.yaml`:
```yaml
environment:
  sdk: ^3.5.0
  flutter: ">=3.27.0"
```

B) Replace `withValues` with `withOpacity` (works on all Flutter versions but is deprecated as of 3.27 — this is the wrong direction):
```dart
static final Color btnFilterSelected = lightGreenPrimary.withOpacity(0.1);
```

Option A is correct — the package uses a modern API and should declare the requirement honestly.

**Side note:** this is also a `static` (non-final, non-const) mutable field, which is unusual for a "color palette" class. See IN-05.

---

### CR-02: `ToastManager._removeToast` can leak `OverlayEntry` and dispose an in-flight `AnimationController`

**File:** `lib/components/toast/toast_manager.dart:108-134`
**Issue:** The guard at line 122 checks `isAnimating || isCompleted` to decide whether to `reverse()` before removing the entry. But if the controller was just created and `forward()` has not yet completed (e.g., a second toast is shown within 300 ms of the first, and the first is auto-removed by its `Timer`), the controller is **in `isAnimating` state** — fine. However if the controller was never forwarded (edge case: `_removeToast` called twice via both the auto-timer and the user's manual dismiss at line 73-77), the second call finds `toastIndex == -1` and does nothing — **fine**. The real bug: **`reverse()` is called on a controller whose `forward()` may not have completed**, and `reverse().then(...)` removes the entry only when reverse finishes — if reverse is interrupted (e.g., the `TickerProvider` is disposed by `ToastNavigatorObserver.dispose()` mid-animation via a route change), the `then` callback never fires and the `OverlayEntry` leaks.

Worse: the `dispose()` method at line 136 calls `entry.animationController.reverse().then(...)` — but `ToastManager` is a singleton, so `dispose()` here means "clear all toasts" (called by `ToastNavigatorObserver` on every route change). If a toast was just added and its controller hasn't forwarded yet, `reverse()` on a `dismissed` controller is a no-op that **completes immediately without animating**, and the entry is removed — but the auto-dismiss `Timer` from line 102 is still pending and will later call `_removeToast` on a controller that has been disposed → **`AnimationController.reverse()` called after `dispose()`** crash.

**Fix:**
1. Store the `Timer` on `_ToastEntry` and cancel it in `_removeToast` and `dispose()`:
```dart
class _ToastEntry {
  final OverlayEntry overlayEntry;
  final AnimationController animationController;
  final ToastTickerProvider tickerProvider;
  final Timer autoDismissTimer;   // NEW
  bool _isRemoved = false;        // NEW — idempotency guard
  // ...
}
```
2. Make `_removeToast` idempotent (guard with `_isRemoved`).
3. Cancel `autoDismissTimer` before reversing the controller.
4. In `dispose()`, cancel all timers first, then dispose controllers synchronously (no async `reverse().then(...)` — just remove the entries).

---

### CR-03: `ToastManager` auto-dismiss `Timer` is never cancelled on manual close

**File:** `lib/components/toast/toast_manager.dart:73-77, 102-105`
**Issue:** When the user taps the close button on a toast, the `onDismiss` callback at line 73 calls `_removeToast(...)` — but the pending `Timer(duration, ...)` from line 102 is still scheduled. When the timer fires (up to 5 seconds later), it calls `_removeToast` again on the now-disposed `AnimationController`. While the `indexWhere` at line 113 returns `-1` and the body is skipped (so no crash), the `onClose` callback at line 104 is invoked a **second time** for a toast the user already dismissed:
```dart
Timer(duration, () {
  _removeToast(overlayEntry, animationController, tickerProvider);
  if (onClose != null) onClose();   // ← fires TWICE for manually-dismissed toasts
});
```
If `onClose` triggers a state change or analytics event, consumers will see double-firing.

**Fix:** Track timers per entry and cancel on removal:
```dart
late Timer autoDismissTimer;
autoDismissTimer = Timer(duration, () {
  _removeToast(overlayEntry, animationController, tickerProvider);
  if (onClose != null) onClose();
});
// Store autoDismissTimer on the _ToastEntry; cancel in _removeToast.
```
And in `_removeToast`, only call `onClose` from one path (either the timer or the manual dismiss, whichever fires first — guard with a `bool _closeNotified` flag on the entry).

---

### CR-04: `ToastManager._removeToast` skips removal when controller is in `dismissed` state, but `forward()` was never awaited

**File:** `lib/components/toast/toast_manager.dart:122-132`
**Issue:** The condition is:
```dart
if (animationController.isAnimating || animationController.isCompleted) {
  animationController.reverse().then((_) { ... remove entry ... });
} else {
  overlayEntry.remove();
  tickerProvider.dispose();
  animationController.dispose();
}
```
The `else` branch (controller state = `dismissed`, i.e., `forward()` was never called or has been reversed to 0) removes the entry and disposes synchronously. But `animationController.forward()` is called at line 91 immediately after `overlay.insert(overlayEntry)`, so by the time `_removeToast` runs (≥ the toast duration), the controller is `completed` — the `else` branch is unreachable in practice. This is **dead code** that misrepresents the state machine and would mask real bugs if the invariant ever broke. More importantly, there's a subtle race: `forward()` returns a `TickerFuture` — if `showToast` is called and then the route is popped **synchronously** (before the first frame), `ToastNavigatorObserver.didPop` calls `toastManager.dispose()` which calls `entry.animationController.reverse()` on a controller whose `forward()` ticker hasn't started yet. Reverse on a `dismissed` controller is a no-op, the `.then(...)` fires immediately, and the entry is removed — but the just-inserted overlay entry's builder will still try to build with a disposed animation on the next frame → **"A dismissed AnimationController was used"** exception in debug builds.

**Fix:** In `dispose()`, check `animationController.isAnimating` before calling `reverse()`; if not animating, dispose synchronously. And mark each entry with a `bool _disposed` flag so the builder short-circuits:
```dart
// Inside OverlayEntry builder:
if (entry._disposed) return const SizedBox.shrink();
```

---

## Warnings

### WR-01: Package, file, and class names contaminated with `GeniusWallet*` branding (HEADLINE finding)

**Files:** Multiple — see breakdown below
**Issue:** The package is documented as "generic scaffolding," but every theme token and the breakpoints class carry the `GeniusWallet` prefix, the pubspec description says "GeniusWallet-derived," and the barrel library docstring does too. This forces every consumer app to write `ScaffoldColors` as `GeniusWalletColors` in their code — a permanent public-API branding leak.

**Exact contaminated spots:**

| # | File | Line | Current text | Suggested replacement |
|---|------|------|--------------|----------------------|
| 1 | `pubspec.yaml` | 2 | `description: "Shared scaffolding library — GeniusWallet-derived bloc widgets, M3 templates, OpenAPI client generator."` | `description: "Shared scaffolding library — generic bloc widgets, M3 templates, OpenAPI client generator."` (and consider splitting the OpenAPI generator claim — it isn't part of the Dart package) |
| 2 | `lib/genius_scaffold.dart` | 3 | `/// Barrel export for GeniusWallet-derived generic bloc widgets,` | `/// Barrel export for generic bloc widgets,` |
| 3 | `lib/genius_scaffold.dart` | 27 | `export 'theme/genius_wallet_colors.g.dart';` | `export 'theme/scaffold_colors.dart';` |
| 4 | `lib/genius_scaffold.dart` | 28 | `export 'theme/genius_wallet_consts.dart';` | `export 'theme/scaffold_dimens.dart';` |
| 5 | `lib/theme/genius_wallet_colors.g.dart` | (filename) | `genius_wallet_colors.g.dart` | rename to `theme/scaffold_colors.dart` (also drops misleading `.g.dart` — see IN-06) |
| 6 | `lib/theme/genius_wallet_colors.g.dart` | 9 | `class GeniusWalletColors {` | `class ScaffoldColors {` |
| 7 | `lib/theme/genius_wallet_consts.dart` | (filename) | `genius_wallet_consts.dart` | rename to `theme/scaffold_dimens.dart` |
| 8 | `lib/theme/genius_wallet_consts.dart` | 1 | `class GeniusWalletConsts {` | `class ScaffoldDimens {` |
| 9 | `lib/utils/breakpoints.dart` | 6 | `abstract class GeniusBreakpoints {` | `abstract class ScaffoldBreakpoints {` |

**Consumer files inside the package that must be updated when renames land** (full import + usage list, line-accurate from current HEAD):

- `lib/components/action_button.dart` — lines 3, 4, 22, 23, 24, 92, 95
- `lib/components/loading/loading.dart` — lines 3, 17, 18
- `lib/components/text_entry_field_widget.g.dart` — lines 8, 9, 37, 42, 46, 50, 54, 57
- `lib/components/string_button.dart` — lines 2, 28
- `lib/components/bottom_drawer/bottom_drawer.dart` — lines 2, 19
- `lib/components/bottom_drawer/responsive_drawer.dart` — lines 2, 25, 40
- `lib/components/responsive_grid.dart` — line 11 (`GeniusBreakpoints.isNativeApp` → `ScaffoldBreakpoints.isNativeApp`)
- `lib/genius_scaffold.dart` — lines 27, 28

**Templates check:** `grep -ri "wallet" templates/` → **no matches**. Templates are clean.

**Fix:** Perform a single sweep rename. Suggested order:
1. Rename `theme/genius_wallet_colors.g.dart` → `theme/scaffold_colors.dart` and `GeniusWalletColors` → `ScaffoldColors`.
2. Rename `theme/genius_wallet_consts.dart` → `theme/scaffold_dimens.dart` and `GeniusWalletConsts` → `ScaffoldDimens`.
3. Rename `GeniusBreakpoints` → `ScaffoldBreakpoints` (file is already neutrally named).
4. Update all consumer files (the list above) and the barrel exports.
5. Update `pubspec.yaml` description and `lib/genius_scaffold.dart` docstring.

Since this is a `publish_to: 'none'` path/git-dep package consumed by in-flight apps (GeniusWallet, touch-pos), the rename must be coordinated — recommend doing it in one PR and bumping the version to `0.2.0` to signal breaking API.

---

### WR-02: Wallet-domain logic left in "generic" text entry logic — hardcoded "Wallet Address" hint

**File:** `lib/components/custom/text_entry_field_logic.dart:15`
**Issue:**
```dart
@override
String get hintText => 'Wallet Address';
```
A "generic scaffold" widget should not ship with a wallet-specific default hint. Any consumer app that instantiates `TextEntryField` without overriding `TextEntryFieldLogic` will see "Wallet Address" as the placeholder — a UX leak of the GeniusWallet origin. The class also has a `//debugPrint(...)` commented-out line (see IN-03) and a `TODO` comment indicating this was intended as an example but was shipped anyway.

**Fix:** Either:
- (A) Change the default to a neutral string: `String get hintText => '';` and let consumers subclass `TextFormFieldLogic` (the pattern `text_form_field_logic.g.dart` was designed for), or
- (B) Remove `TextEntryFieldLogic` from the package entirely — it is a GeniusWallet-specific subclass that doesn't belong in a generic scaffold. The base `TextFormFieldLogic` is sufficient as the extension point.

Recommendation: (B). The file is only used by `text_entry_field.g.dart` (line 8, 37), which itself is a Parabeac-generated stub that doesn't override anything useful — both can be deleted from the scaffold and re-added by any consumer that actually needs them.

---

### WR-03: `pinCount` constant is wallet-domain, not scaffold-generic

**File:** `lib/theme/genius_wallet_consts.dart:2`
**Issue:**
```dart
class GeniusWalletConsts {
  static const int pinCount = 4;
  ...
}
```
`pinCount` is a PIN-entry concept — it only makes sense for apps with PIN unlock (wallets, banking apps). A generic scaffold package has no business declaring this. It's also unused within the scaffold package itself (`grep -rn "pinCount" lib/` → only the declaration site).

**Fix:** Remove `pinCount` from `ScaffoldDimens`. Any consumer needing it should declare it locally.

---

### WR-04: `breakpoints.dart` uses `dart:io` `Platform` — will crash on web

**File:** `lib/utils/breakpoints.dart:1, 40`
**Issue:**
```dart
import 'dart:io';
...
static bool isMobileApp() => Platform.isAndroid || Platform.isIOS;
```
`dart:io` is **not available on web**. Although `getPlaform()` short-circuits with `if (kIsWeb) return ...;` before calling `isMobileApp()`, the *import itself* is what breaks web compilation — `import 'dart:io'` is a compile error in `flutter build web`. The scaffold package therefore **cannot be consumed by a Flutter web app**, which contradicts "generic scaffolding."

**Fix:** Use conditional imports or move to a default-target-platform check:
```dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

static bool isMobileApp() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
     defaultTargetPlatform == TargetPlatform.iOS);
```
This is the canonical Flutter idiom and removes the `dart:io` dependency entirely.

---

### WR-05: `getPlaform` typo in public method name

**File:** `lib/utils/breakpoints.dart:30`
**Issue:**
```dart
static Platforms getPlaform(BuildContext context) {
```
`getPlaform` should be `getPlatform`. It's public API exported through the barrel; consumers calling `ScaffoldBreakpoints.getPlaform(...)` will carry the typo forever once shipped.

**Fix:** Rename to `getPlatform`. Update the one in-package caller at line 27.

---

### WR-06: `ActionButton` returns `Expanded` from `build()` — composability hazard

**File:** `lib/components/action_button.dart:68`
**Issue:**
```dart
@override
Widget build(BuildContext context) {
  return Expanded(
    child: LayoutBuilder(...),
  );
}
```
`Expanded` is only valid as a direct child of `Row`/`Column`/`Flex`. Returning it from a widget's `build()` means `ActionButton` **cannot be used** in any other context (e.g., inside a `Padding`, `Container`, `Stack`, `GridView`) without throwing a `ParentDataWidget` error. This is a hard composability constraint smuggled into a "generic" widget — and there's no doc comment warning consumers.

**Fix:** Remove the outer `Expanded`. If the GeniusWallet consumer needed flex behavior, it can wrap `ActionButton` in `Expanded` at the call site. The widget itself should be layout-agnostic:
```dart
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) { ... },
  );
}
```

---

### WR-07: `pubspec.yaml` description conflates three unrelated concerns

**File:** `pubspec.yaml:2`
**Issue:**
```yaml
description: "Shared scaffolding library — GeniusWallet-derived bloc widgets, M3 templates, OpenAPI client generator."
```
Three problems:
1. "GeniusWallet-derived" — see WR-01.
2. "M3 templates" — these live in `templates/` and are Jinja2 files consumed by `engine.py`; they are **not part of the Dart package** and shouldn't be advertised in the Dart pubspec description.
3. "OpenAPI client generator" — also a Python concern (`scripts/generate_api_clients.py`, `openapitools.json`), not the Dart package.

The pubspec for a `publish_to: 'none'` package is the package's API contract — its description should describe what `lib/` actually exports.

**Fix:**
```yaml
description: "Shared Flutter scaffolding widgets — generic blocs, theme primitives, breakpoints, drawers, toasts, and animations."
```

---

## Info

### IN-01: `README.md` describes only the OpenAPI generator, not the Dart package

**File:** `README.md` (entire file)
**Issue:** The README is titled "OpenAPI Client Scaffolding" and documents `scripts/generate_api_clients.py`. It says nothing about the Dart widgets in `lib/`, the theme system, the barrel export, or how to consume the package from a Flutter app. A new contributor arriving at the submodule will not know that `lib/genius_scaffold.dart` exists or that it's a path-dependency target.
**Fix:** Add a top-level section "Dart scaffolding widgets (`genius_scaffold` package)" documenting the barrel, the theme classes, and a minimal usage example (`import 'package:genius_scaffold/genius_scaffold.dart';` + `ScaffoldColors.deepBlue`).

---

### IN-02: `_TextEntryField` State class is package-private when it should be private-to-library

**File:** `lib/components/text_entry_field.g.dart:20, 23`
**Issue:**
```dart
class _TextEntryField extends State<TextEntryField> {
```
The class name starts with `_` (library-private) but `TextEntryField` is exported through the barrel — Dart convention is `State<TextEntryField> createState() => _TextEntryFieldState();` (with the `State` suffix). The current name is confusing because `_TextEntryField` reads like a private widget, not a State. Also the explicit `_TextEntryField();` constructor at line 24 is redundant (default constructor suffices).

**Fix:**
```dart
@override
State<TextEntryField> createState() => _TextEntryFieldState();

class _TextEntryFieldState extends State<TextEntryField> {
  // drop the redundant constructor and the empty dispose() at lines 43-46
}
```
Also the `dispose()` override at lines 43-46 is empty (`super.dispose()` only) — dead code, delete it.

---

### IN-03: Commented-out `debugPrint` and a `TODO` left in shipped logic class

**File:** `lib/components/custom/text_entry_field_logic.dart:7, 11`
**Issue:**
```dart
/// TODO: Override any logic method here. See example below
/// See [TextFormFieldLogic] for overridable methods.
@override
ValueChanged<String>? get onChanged => (value) {
      //debugPrint('Value changed to $value');
    };
```
The `TODO` is Parabeac boilerplate, the `onChanged` override is a no-op that swallows changes, and the commented-out `debugPrint` is dead code.
**Fix:** If WR-02 (B) is adopted, delete this file. Otherwise, delete the TODO comment, the `onChanged` override (let the base class's null default flow through), and the commented debugPrint.

---

### IN-04: Public API classes missing dartdoc — most classes have no documentation

**Files:** All of `lib/components/**`, `lib/theme/**`, `lib/utils/**`
**Issue:** Of the 17 public classes exported by the barrel, only `StringButton` (line 4) and `TextFormFieldLogic` (lines 10-13) have dartdoc. The following have none:
- `ActionButton`, `ActionButtonAnimation`
- `AppScreenView`
- `DesktopBodyContainer`
- `ResponsiveGrid`
- `SlidingDrawerButton`
- `TextEntryField`, `TextEntryFieldWidget`
- `Loading`
- `ToastManager`, `ToastType`, `ToastWidget`, `ToastTickerProvider`, `ToastNavigatorObserver`
- `XAnimation`, `XAnimationState`, `XPainter`
- `CheckmarkAnimation`, `CheckmarkAnimationState`, `CheckmarkPainter`
- `BottomDrawer`, `ResponsiveDrawer`
- `GeniusWalletColors` / `GeniusWalletConsts` / `GeniusBreakpoints`

For a shared library consumed across multiple apps, this is a significant discoverability gap — especially for non-obvious parameters like `ActionButton`'s `Expanded` wrapper (WR-06) and `ToastManager`'s singleton behavior.
**Fix:** Add a one-line dartdoc to each public class and each non-obvious public method (`ToastManager.showToast`, `ResponsiveDrawer.show`, `ScaffoldBreakpoints.useDesktopLayout`).

---

### IN-05: `btnFilterSelected` is a non-final static — mutable shared state in a "constants" class

**File:** `lib/theme/genius_wallet_colors.g.dart:72`
**Issue:**
```dart
static Color btnFilterSelected = lightGreenPrimary.withValues(alpha: 0.1);
```
Every other field in the class is `static const Color`. This one is `static Color` (mutable). The mutation isn't a const-evaluability issue — `withValues` is non-const because of the alpha computation — but it should still be `static final` to prevent reassignment.
**Fix:**
```dart
static final Color btnFilterSelected = lightGreenPrimary.withValues(alpha: 0.1);
```

---

### IN-06: `.g.dart` filenames claim Parabeac-generated, but no generator is wired up

**Files:** `lib/theme/genius_wallet_colors.g.dart`, `lib/components/text_entry_field.g.dart`, `lib/components/text_entry_field_widget.g.dart`, `lib/components/text_form_field_logic.g.dart`
**Issue:** Each file starts with:
```
// *********************************************************************************
// PARABEAC-GENERATED CODE. DO NOT MODIFY.
// *********************************************************************************
```
…but `pubspec.yaml` has no `parabeac` dependency, no `build_runner`, no `build.yaml`, and no script in `scripts/` references Parabeac. These files were hand-copied from GeniusWallet and will be **hand-edited going forward** (the user explicitly said "these are hand-copied source"). Keeping the `.g.dart` extension and the "DO NOT MODIFY" banner is misleading: future contributors will either (a) be afraid to edit them, or (b) try to regenerate them and fail.
**Fix:** As part of the WR-01 rename, drop the `.g.dart` suffix (e.g., `theme/scaffold_colors.dart`, `components/text_form_field_logic.dart`) and delete the Parabeac banner. The four files affected:
- `theme/genius_wallet_colors.g.dart` → `theme/scaffold_colors.dart`
- `components/text_entry_field.g.dart` → either delete (see WR-02 B) or rename to `components/text_entry_field.dart`
- `components/text_entry_field_widget.g.dart` → `components/text_entry_field_widget.dart`
- `components/text_form_field_logic.g.dart` → `components/text_form_field_logic.dart`

Update `lib/genius_scaffold.dart` exports (lines 14, 15, 16) and the imports inside `action_button.dart`, `loading.dart`, `text_entry_field_widget.g.dart`, `text_entry_field.g.dart`, `string_button.dart`, `bottom_drawer.dart`, `responsive_drawer.dart`, `custom/text_entry_field_logic.dart` accordingly.

---

## Notes for the orchestrator

- **Templates dir is clean.** No rename work needed under `templates/`.
- **No changes required to `pubspec.lock`** — it's a build artifact and will regenerate.
- **Breaking-change sequencing:** WR-01 (renames) is a public API break for any consumer already importing `GeniusWalletColors`. Recommend a single coordinated PR that bumps `version: 0.1.0` → `0.2.0` and lands all renames + the pubspec Flutter constraint (CR-01) at once. Toast fixes (CR-02..04) can land independently.
- **Suggested plan forward (not part of this review):** a `05-04` fix plan covering CR-01, CR-02..04, WR-01..07 would be ~2-3 hours of mechanical work.

---

_Reviewed: 2026-08-05_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
