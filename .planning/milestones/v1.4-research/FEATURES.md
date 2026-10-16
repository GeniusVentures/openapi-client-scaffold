# Feature Landscape: v1.4 Design Tokens & Midnight Preset

**Domain:** Opt-in dark/light design preset ("midnight") for a shared Flutter M3 widget library
**Researched:** 2026-10-16
**Overall confidence:** HIGH. Every claim below comes from reading the wallet and scaffold source directly; nothing here depends on web research.

**Sources read in full:** wallet `lib/theme/` (all 14 files): `gw_colors.dart`, `genius_wallet_colors.dart`, `genius_wallet_consts.dart`, `genius_wallet_typography.dart`, `genius_wallet_font_size.dart`, `genius_wallet_motion.dart`, `genius_wallet_elevation.dart`, `genius_wallet_gradient.dart`, `genius_wallet_decorations.dart`, `theme.dart`, `nav_chip_style.dart`, `gw_appearance.dart`, `gw_context_extension.dart`, `genius_wallet_text.dart`. Scaffold: `lib/theme/*` (5 files), `design_tokens.json`, `m3_tokens_css.py`, and a grep of every `palette.*`/`dimens.*` consumer in `lib/components/`.

**Naming rule:** "wallet" in this file means the source app. Midnight token names below are neutral (no brand names in `lib/`). Wallet identifiers appear only as the left-hand source column.

---

## 0. Findings that shape the whole milestone

1. **`design_tokens.json` does not describe the Dart defaults today.** It is a stock M3 baseline (primary `#6750A4`, purple). The Dart defaults (`ScaffoldPalette.defaultPalette`, `ScaffoldDimens.defaultDimens`) are a separate, deep-blue/green set and exist nowhere in the JSON. The CSS generator reads only four keys (`color.roles`, `typography.scale`, `shape.corner`, `elevation`). Consequences:
   - Feature 1 (Dart generated from JSON, byte-identical) means adding NEW top-level sections for palette, dimens, shadows etc. These are additive, so GCS's CSS output is untouched.
   - The existing four M3 sections must not change value, or GCS's rendered templates change.
   - The generator must reproduce today's file shape, including `ScaffoldColors.x` references, `Color.fromRGBO(...)` forms and doc comments, or "byte-identical" is not achievable. Decide early whether it means byte-identical or semantically identical.
2. **The scaffold palette is the wallet's previous generation.** `deepBlueCardColor`, `grayPrimary`, `deepBlueTertiary`, `borderGrey`, `surfaceElevated`, `borderSubtle`, `textPrimary`, `textSecondary`, `statusSuccess`, `statusError` and `statusWarningText` already equal the wallet's DARK values. What differs is the accent system: wallet now uses cyan (primary), mint (secondary) and purple (tertiary), while the scaffold uses mint-green `lightGreenPrimary` plus a hard blue `blue500`. So the dark preset is mostly an accent swap plus a surface ladder, not a rewrite.
3. **Slot names are legacy colour names, not roles** (`lightGreenPrimary`, `deepBlueTertiary`, `blue500`). Putting cyan into `lightGreenPrimary` would be a misnomer. See section 7, "Semantic alias fields".
4. **The wallet resolves appearance through a global static (`GWAppearance.isLight`).** The scaffold resolves through `Theme.of(context)` extensions. Do not port the global. Midnight ships two palettes (dark and light) that the host registers per `ThemeData`, exactly like `defaultPalette`/`lightPalette` today.
5. **Four things are static consts, not themeable, today.** These are `ScaffoldElevation.card`, `ScaffoldMotionDurations/Curves` (61 call sites), the font family (hard-coded `'Roboto'` in `text_entry_field_widget.dart`, `'monospace'` in two files) and all type sizes (hard-coded in `action_button.dart`, `string_button.dart`). The scaffold has no gradient tokens and no type tokens at all.

---

## 1. Token map: colours

Status key: **SAME** = scaffold field exists with equal value. **VALUE** = field exists, midnight needs a different value (no new field). **NEW** = no field today. **SKIP** = domain-specific or legacy, do not port.
Class key: **TS** = table stakes for a convincing midnight. **NTH** = nice-to-have. **-** = skip.

Wallet values are `dark / light`; "fixed" means the same in both modes.

### 1a. Surfaces

| Wallet token | Wallet value | Scaffold field today | Status | Class | Notes |
|---|---|---|---|---|---|
| `surfaceBase` (page) | `#0B0D12` / `#DCE0E6` | none | NEW | TS | Page/scaffold background. No scaffold widget paints it; consumers set `scaffoldBackgroundColor`. Needed by the preset's `ThemeData` builder and canvas gradient stops. |
| `surfaceElevated` (card) | `#0C0E14` / `#FFFFFF` | `surfaceElevated` `#0C0E14` / `#FFFFFF` | SAME | TS | Light mode in the wallet is white cards on grey page; scaffold light already matches. |
| `surfaceMenu` (sheet/menu) | `#171A21` / `#EFF2F6` | none (drawers use `deepBlueTertiary` `#05090F`) | NEW | TS | Drawers/bottom sheets are `deepBlueTertiary` today (darker than the page). The wallet floats sheets ABOVE the panel, so they are lighter. Needs a semantic sheet slot (section 7). |
| `surfaceSunken` (deepest) | `#06080C` / `#CFD4DB` | `deepBlueTertiary` `#05090F` (near, not equal) | NEW | NTH | Used for track grooves and wells. Only add if a component needs a recessed track (`ScaffoldSlider` track is a candidate). |
| `surfaceWell` | `#06080C` / `#EFF2F6` | none | NEW | NTH | Derived getter in the wallet. Skip unless a consumer appears. |
| `surfaceOverlay` (scrim) | black @ 60% (`#99000000`) | hard-coded `Colors.black87` in `responsive_drawer.dart` | NEW | TS | Scrim is hard-coded to 87%. Tokenise. Default must stay `black87`. |
| `deepBlueCardColor` (legacy) | `#0A121F` fixed | `deepBlueCardColor` `#0A121F` | SAME | - | Wallet itself is migrating off it. In midnight, alias to `surfaceElevated`. |
| `deepBlueTertiary` (legacy) | `#05090F` fixed | `deepBlueTertiary` `#05090F` | SAME | - | Same: midnight value, not a new wallet token. |
| `deepBlueMenu`, `deepBlue`, `grayPrimary` (legacy) | `#0F1B2E`, `#14253D`, `#151E29` | `grayPrimary` `#151E29` only | SKIP | - | Wallet legacy names. `grayPrimary` is the scaffold's input fill: midnight value, no new field. |

### 1b. Text

| Wallet token | Wallet value | Scaffold field today | Status | Class | Notes |
|---|---|---|---|---|---|
| `textPrimary` | `#FFFFFF` / `#10131A` | `textPrimary` `#FFFFFF` / `#17191E` | VALUE (light `#17191E` to `#10131A`) | TS | Dark equal. |
| `textSecondary` | `#8A8F9D` / `#5A606E` | `textSecondary` `#8A8F9D` / `#5A6070` | VALUE (light, 2 digits) | TS | Dark equal. |
| `gray500` (= textSecondary alias) | `#8A8F9D` | `gray500` `#73788C` | VALUE | TS | Scaffold uses `gray500` for hint text and ActionButton labels. Midnight maps it to `#8A8F9D`. |
| `textPrimary80/70/60/54/38/30/24/12/10` | `#FFF` or `#10131A` at 80/70/60/54/38/30/24/12/10% | none | NEW (9) | NTH | Do NOT add nine fields. These are one colour at fixed alphas. Derive with `textPrimary.withValues(alpha:)` or one helper. Wallet comment: 80% is the minimum that clears AA on page; keep that as a documented constant if any component needs "muted". |
| `textTertiary` | `#35363D` fixed | none | NEW | NTH | Disabled labels. Note: `#35363D` on `#0C0E14` is about 1.5:1, which is fine for disabled (exempt from AA) but not for anything else. |
| `textDisabled` | `#2A2B31` fixed | `disabledOverlayColor` (overlay, different mechanism) | SKIP | - | Scaffold disables via dim overlay, not a colour. Keep that. |
| `textOnBrand` | `#000B18` fixed | none | NEW | TS | Near-black text on cyan/mint fills. Wallet notes white-on-brand failed AA (2.56:1) and near-black gives 7.74:1. Needed for `ColorScheme.onPrimary`, badge text, selected checkbox tick. |
| `textMutedOnSunken` | `#4A5060` (light) / `#8A8F9D` | none | SKIP | - | Only exists for `surfaceSunken`. Skip unless that token is added. |
| `textOnDarkChrome` | `#FFFFFF` fixed | hard-coded `Colors.white` (bottom drawer, text field) | SKIP | - | Fix the hard-codes instead (section 5). |

### 1c. Borders

| Wallet token | Wallet value | Scaffold field today | Status | Class | Notes |
|---|---|---|---|---|---|
| `borderSubtle` | white 12% / `#10131A` 12% | `borderSubtle` `#1FFFFFFF` / `#1F000000` | SAME (dark) / VALUE (light ink tint) | TS | Hairline on cards. |
| `borderStrong` | white 24% / ink 24% | none | NEW | NTH | No scaffold consumer. |
| `borderControl` | white 36% / ink 48% | `borderGrey` white 30% / black 12% | NEW | **TS (AA gate)** | The wallet measured that white 30% on `#0C0E14` is 2.64:1, below the 3:1 needed by WCAG 1.4.11, and 36% is the first step that passes (3.30:1). The scaffold's input border is `borderGrey` at 30%, which fails the same test. Midnight needs this token so its inputs pass; the defaults stay as they are. |
| `borderControlOnBrand` | white 58% / ink 52% | none | NEW | NTH | Only for switches/checkboxes filled with a translucent brand wash. Add if `ScaffoldSelectionIndicator*` is restyled. |
| `borderBrand` | `#14C8FF` fixed | none | SKIP | - | Equals brand primary. |
| `borderGrey` | white 30% | `borderGrey` white 30% | SAME | - | Legacy. |

### 1d. Brand / accent

| Wallet token | Wallet value | Scaffold field today | Status | Class | Notes |
|---|---|---|---|---|---|
| `brandPrimary` (cyan fill) | `#14C8FF` fixed | `blue500` `#0068EF` (used only for `StatusVariant.info` and one loading dot) | NEW accent | TS | Midnight primary accent. |
| `brandPrimaryStrong` | `#0AAEE6` fixed | none | NEW | TS | The brand FILL (checked checkbox, selected day, nav icon). |
| `brandPrimaryOnSurface` | dark `#0AAEE6` / light `#0A6885` | `focusRingColor` `#00EAAE` (nearest) | NEW accent-on-surface | **TS (AA gate)** | Brand colour used as foreground (text, outline, focus ring). Wallet measured light at 6.30 / 5.61 / 4.76:1 on elevated/menu/base; the raw cyan is 1.96:1 on white. This is THE token that keeps midnight-light AA-compliant. |
| `brandPrimaryBadgeText` | `#0AB2EB` / `#0A6480` | none | NEW | NTH | Tuned for a label on a 12% wash over a selection tint (4.59 / 4.74:1 worst case). Only if the badge/selected-chip composite is restyled. |
| `brandPrimaryMuted` / `Subtle` | `#14C8FF` at ~24% / ~12% | none | NEW | TS | Hover and selection tint. Derive from the accent with alpha, do not store two more colours. |
| `brandSecondary` (mint) | `#2BF5B4` fixed | `lightGreenPrimary` `#00EAAE` (near) / `lightGreenSecondary` `#01CC95` | VALUE | TS | Midnight secondary accent. |
| `brandSecondaryStrong` | `#0AD89C` fixed | `statusSuccess` `#0AD89C` | SAME value | - | Same hex as dark success. |
| `brandSecondaryBright` | `#5BFFD0` fixed | none | NEW | NTH | Only as a gradient stop. |
| `brandSecondaryMuted` / `Subtle` | `#2BF5B4` at ~24% / ~12% | none | derive | NTH | Derive. |
| `brandTertiary` (purple) | `#C28FFF` fixed | none | NEW | NTH | No scaffold consumer. Per YAGNI, add the field only when a component reads it. `ColorScheme.tertiary` in the preset still needs the value, so it lives in the token file even without a palette field. |
| `brandTertiaryMuted` / `Subtle` | at ~24% / ~12% | none | derive | - | Skip. |
| `gradientBlue` / `gradientGreen` | `#0AAEE6` / `#0AD89C` | none | NEW | NTH | Gradient stops. Belong in the gradient section. |
| `lightGreenPrimary` (legacy) | `Colors.greenAccent` `#69F0AE` | `lightGreenPrimary` `#00EAAE` | SKIP | - | Wallet is moving off it. |
| `lightGreenSecondary`, `mutedGreen` | `#54C48E`, `#2EBE7B` | `lightGreenSecondary` `#01CC95` | SKIP | - | Same. |
| `btnText`, `btnDisabled`, `btnTextDisabled`, `btnGradientBlue/Green`, `btnFilter`, `btnFilterSelected`, `foundationError`, `brandGreen*` | legacy | `btnFilter` etc. exist only in raw `ScaffoldColors` | SKIP | - | Legacy aliases that the wallet itself calls "backwards-compatibility". Do not port. |

### 1e. Status

| Wallet token | Wallet value | Scaffold field today | Status | Class | Notes |
|---|---|---|---|---|---|
| `statusSuccess` | `#0AD89C` / `#07875F` | `statusSuccess` `#0AD89C` / `#0AA06B` | SAME (dark) / VALUE (light) | TS | Wallet light `#07875F` is 4.53:1 on white; scaffold light `#0AA06B` computes to 3.36:1 on white, so the existing light default FAILS AA for text. Fix lives in midnight-light only (defaults stay). |
| `statusError` | `#FF4D4D` / `#D92D2D` | `statusError` `#FF4D4D` / `#D13438` | SAME (dark) / VALUE (light) | TS | Scaffold light `#D13438` already computes to 4.93:1 on white (passes); wallet `#D92D2D` is 4.81:1. Value change is for visual parity, not AA. |
| `statusWarning` (fill) | `#FFC42E` fixed | none (`statusWarningText` only) | NEW | NTH | A fill is needed only if a warning badge/dot is restyled. |
| `statusWarningText` | `#FFC42E` / `#92400E` | `statusWarningText` `#FFC42E` / `#9A6A00` | SAME (dark) / VALUE (light) | TS | |
| `statusSuccessText` | `#0AD89C` / `#065F46` | none | NEW | NTH | Darker text-safe success for tinted backgrounds. Add only if status text sits on a wash. |
| `statusErrorText` | `#FF4D4D` / `#991B1B` | none | NEW | NTH | Same. |
| `statusInfo` | `#14C8FF` fixed (= brandPrimary) | `blue500` `#0068EF` | VALUE | TS | `StatusVariant.info` reads `blue500`. Midnight sets `blue500` to the cyan, or the info variant is moved to the semantic accent field. |
| `statusNeutral` | `#64748B` fixed (fill only) | `StatusVariant.neutral` reads `textSecondary` | SKIP | - | Wallet carve-out for transaction badges; domain-specific. |
| `fixedStatusError`, `fixedTextSecondary` | = dark values | none | SKIP | - | Compat shims for wallet's non-themed call sites. |
| `walletIdentityFills[8]` + `walletIdentityFill(address)` | 8 hex fills, sha256 pick | none | SKIP | - | Wallet domain logic (address hash to avatar colour). Violates "atoms know nothing about domain". |

### 1f. Scaffold palette fields with no wallet counterpart (keep value or reuse)

`skeletonBaseColor` / `skeletonShimmerColor`, `disabledOverlayColor`, `dragFeedbackBackground`, `dropZoneHighlight` / `dropZoneRejected`, `focusRingColor`. The wallet has no source for these. Midnight sets `focusRingColor` to `brandPrimaryOnSurface`, `dropZoneHighlight` to the accent at 20%, `dropZoneRejected` to error at 20%, and skeleton to surface values. These are the preset author's choices, not extractions. **LOW confidence on aesthetics, HIGH that they need a value.**

---

## 2. Token map: spacing, radius, layout

| Wallet token | Value | Scaffold `ScaffoldDimens` | Status | Class | Notes |
|---|---|---|---|---|---|
| `horizontalPadding` (space10) | 20 | `horizontalPadding` 20 | SAME | TS | |
| `horizontalDesktopPadding` (space20) | 40 | 40 | SAME | TS | |
| `verticalDesktopPadding` (space20) | 40 | 40 | SAME | TS | |
| `itemSpacing` (space8) | 16 | 16 | SAME | TS | |
| `borderRadiusCard` (radiusLg) | 15 | 15 | SAME | TS | |
| `borderRadiusButton` (radiusPill) | 48 | 48 | SAME | TS | |
| `appBarHeight` | **68** | **65** | VALUE | TS | Only dimension whose existing field differs. |
| `space2/3/4/6/8/12` | 4 / 6 / 8 / 12 / 16 / 24 | same six | SAME | TS | `space3` is the wallet's one declared half-step off the 4-pt grid. |
| `space10` | 20 | none | NEW | NTH | Equals `horizontalPadding`. Add only if a component needs the step. |
| `space16` / `space20` / `space24` / `space32` | 32 / 40 / 48 / 64 | none | NEW | NTH | No scaffold consumer. Skip until needed. |
| `radiusXs` | 4 | `skeletonCornerRadius` 4 (coincident) | NEW | NTH | The wallet's search bar uses 4. |
| `radiusSm` | 8 | none | NEW | NTH | |
| `radiusBase` | 10 | none | NEW | NTH | Matches the marketing site default. |
| `radiusMd` | 12 | `radiusMd` 12 | SAME | TS | |
| `radiusLg` | 15 | `borderRadiusCard` 15 | SAME | TS | |
| `radius2xl` | 16 | none | NEW | NTH | Hard-coded `16` exists in `responsive_drawer.dart`. |
| `radiusXl` | 24 | none | NEW | NTH | |
| `radiusPill` | 48 | `radiusPill` 48 | SAME | TS | |
| `pinCount`, `swapFabClearance`, `kMaxBottomSafeInset` | 4 / 84 / 20 | none | SKIP | - | App-specific. `kMaxBottomSafeInset` is a nav/safe-area policy, not a design token. |

**Net:** the dimension set is already 90% aligned. For TS, only `appBarHeight` changes value. Full radius ladder is NTH, and worth adding only because three hard-coded radii in the components (drawer top 16, toggle 12, checkbox 2) need somewhere to point.

---

## 3. Token map: typography

The scaffold has **no Dart typography token**. Components call `Theme.of(context).textTheme.<slot>` (used: `labelSmall`, `labelMedium`, `labelLarge`, `titleMedium`, `bodySmall`, `bodyLarge`), and `design_tokens.json` `typography.scale` is M3 sizes feeding CSS only. So typography is a preset concern: a `TextTheme` plus a small extension.

| Wallet style | Spec (size / line height / weight / tracking) | M3 slot used by wallet | Scaffold today | Class | Notes |
|---|---|---|---|---|---|
| `displayLg` | 32 / 40 / w700 / -0.4 | `displayLarge` | host `textTheme` (M3: 57 / 64) | TS | |
| `displayMd` | 28 / 36 / w700 / -0.4 | `displayMedium` | host | TS | |
| `headlineLg` | 24 / 32 / w600 / -0.4 | `headlineLarge` | host | TS | |
| `headlineMd` | 20 / 28 / w600 / 0 | `headlineMedium` | host | TS | |
| `titleLg` | 18 / 24 / w600 | `titleLarge` | host | TS | |
| `titleMd` | 16 / 22 / w500 | `titleMedium` | host (`ToastWidget` card title) | TS | |
| `bodyLg` | 16 / 24 / w400 | `bodyLarge` | host (`ScaffoldSearchBar` hint) | TS | |
| `bodyMd` | 16 / 24 / w400 | `bodyMedium` | host | TS | Wallet bumped 14 to 16 for touch legibility; bodyLg and bodyMd coincide. |
| `bodySm` | 14 / 20 / w400, colour fixed `#8A8F9D` | `bodySmall` | host (toast body) | TS | The baked colour is a wallet compat quirk. In midnight, leave colour to the widget (`palette.textSecondary`). |
| `labelMd` | 13 / 18 / w500 | `labelMedium` | host (`ScaffoldChip`, toast) | TS | |
| `numericDisplay` | 32 / 40 / w700 / -0.4 + tabular figures | none (custom) | none | NTH | |
| `numericHeadline` | 24 / 32 / w600 + tabular | none | none | NTH | |
| `numericBody` | 14 / 20 / w500 + tabular | none | none (`media_controls`, `scaffold_chart` set `tabularFigures` by hand) | NTH | Candidate for `ScaffoldFormattedValue*` and chart axis labels. |
| `sansFamily` | `Inter` (bundled w400/500/600/700) | none | `Roboto` hard-coded in text field | TS | Needs a decision on font delivery, see section 7. |
| `monoFamily` | `JetBrainsMono` | `'monospace'` hard-coded in `scaffold_code_block.dart`, `scaffold_streaming_rich_text.dart` | NTH | Make it a field on the typography extension; default `'monospace'`. |
| `displaySmall`, `headlineSmall`, `titleSmall`, `labelLarge`, `labelSmall` | **unmapped in wallet** (fall to Material defaults in Inter) | scaffold reads `labelSmall` (`ScaffoldBadge`) and `labelLarge` (`ScaffoldSearchBar` chips) | **GAP** | TS | The wallet gives no spec for 5 of 15 slots, and two of those are used by scaffold widgets. Midnight must choose values (derive from the wallet scale, e.g. `labelLarge` 14 / 20 / w500, `labelSmall` 12 / 16 / w500). This is a design decision, not an extraction. |
| `GeniusWalletFontSize.medium` / `.title` | 16 / 20 | none | SKIP | - | Wallet legacy holdout; subsumed by the scale. |

The wallet's `GeniusWalletText` (UI strings like "Wallet Backup", "Add Wallet") is wallet copy and out of scope. It is listed here only to show the file was covered.

---

## 4. Token map: motion, shadows, gradients

### 4a. Motion

| Wallet token | Value | Scaffold today | Status | Class | Notes |
|---|---|---|---|---|---|
| `fast` | 120 ms | `ScaffoldMotionDurations.short` 150 ms | VALUE | TS | Names differ; map by position, do not rename the scaffold fields (public API). |
| `base` | 200 ms | `.medium` 300 ms | VALUE | TS | |
| `slow` | 320 ms | `.long` 500 ms | VALUE | TS | |
| `standard` | `Curves.easeOutCubic` | `ScaffoldMotionCurves.standard` = `easeInOut` | VALUE | TS | |
| `emphasized` | `Curves.easeOutExpo` | `.emphasized` = `Cubic(0.2, 0, 0, 1.2)` (overshoots) | VALUE | TS | Behaviour change: wallet has no overshoot. |
| (none) | - | `.decelerate` = `easeOut` | no wallet equivalent | - | Keep `easeOut` in midnight, or alias to `standard`. |

Today these are `static const` on classes with no `BuildContext`, referenced at 61 sites. **They are not themeable without a code change.** The existing `ScaffoldMotion` InheritedWidget (carries `reducedMotion`, falls back to a default instance) is the natural carrier. Unthemed hard-coded durations remain (800 ms checkmark/x animation, 500 ms drop reset, 1060 ms streaming cursor, 2 s ActionButton rotate, 300 ms toast); leave them, they are not wallet tokens.

### 4b. Shadows

| Wallet token | Value (dark / light) | Scaffold today | Status | Class | Notes |
|---|---|---|---|---|---|
| `card` | black 35% / black 12%; blur 16; offset (0, 4) | `ScaffoldElevation.card` = dark only, same values, static const | SAME (dark) / NEW (light) | TS | Scaffold doc says "host apps that need appearance-aware shadows can substitute their own" and provides no mechanism. |
| `dialog` | black 45% / black 20%; blur 32; offset (0, 8) | none | NEW | TS | |
| `glowBrand` | brand primary @ 18%, blur 24 | none | NEW | NTH | Mode-invariant. |
| `glowGradient` | primary @ 15% offset (-6, 8) + secondary @ 15% offset (6, 8); blur 28 | none | NEW | NTH | Hero CTA glow. |
| (M3 `elevation.level0..5` in JSON) | CSS box-shadow strings | CSS only | n/a | - | Different representation and a different consumer (CSS). Dart shadows need a structured `[ {color, blur, dx, dy, spread} ]` form with light and dark. Leave the M3 elevation block untouched. |

### 4c. Gradients

| Wallet token | Value | Scaffold today | Class | Notes |
|---|---|---|---|---|
| `brandCta` | L to R, `#0AD89C` to `#0AAEE6` | none | NTH | CTA fill. Scaffold has no primary CTA widget with a gradient option. |
| `brandCtaText(proxy)` | same as shader, collapses to flat `brandPrimaryOnSurface` when the surface is light | none | NTH | Wallet logic in a static method. In a preset this is a rule ("gradient text degrades to a flat AA-safe colour on light"), not a token. |
| `brandBorder` | L to R, `#14C8FF` to `#5BFFD0` | none | NTH | Outline gradient. Needs a gradient-border painter (not in scaffold). |
| `heroWash` | vertical, `surfaceBase` to `surfaceElevated` | none | NTH | |
| `canvas` | vertical, dark `#14171E` / `#0B0D12` / `#07090D` at 0 / .4 / 1; light `#E3E6EB` / `#DCE0E6` / `#D3D7DE` | none | NTH | Page wash. |
| `canvasTopLight` | radial, center (0, -0.9), r 1.0, white 12% to 0, stops 0 / .6, dark only | none | NTH | |
| `surfaceSheen` | dark: flat `surfaceElevated` (both stops equal); light: `#FFFFFF` to `#F5F7FA` vertical | none | **TS for light only** | Dark sheen is flat on purpose (their comment: "flat, no sheen"), so a surface gradient token only matters for midnight-light. |
| `greenBlueGreenGradient` | vertical `#0068EF` to `#01DDA6` | none | SKIP | Legacy, used by old continue buttons. |
| noise texture | `assets/images/textures/noise.png`, 4% opacity, repeat, dark only | none | NTH | Needs an image asset or a procedural painter. See section 5. |

Gradient token shape needed (new field): list of stops with colour, optional stops, begin/end alignment or radial centre/radius, one per mode. **Default for every gradient field must be `null`** so existing `color:` fills are untouched; a flat fill and a two-equal-stop gradient are visually equal but not guaranteed pixel-equal, and the golden gate would catch it.

---

## 5. What tokens cannot express (component restyles)

Each row is a visible wallet trait that needs component code to change, not just a value. "Generated" means the file is a committed Jinja2 output family, so the change goes in `templates/components/*.jinja2` and gets regenerated (CLAUDE.md rule).

| # | Wallet look | Scaffold today | Restyle needed | Where | Class | Complexity |
|---|---|---|---|---|---|---|
| R1 | Card = gradient/flat fill + 1 px hairline + custom `BoxShadow` (no Material elevation, no tint) | `ScaffoldCard` elevated variant uses `Material(elevation: 4)`; `ScaffoldSurface.elevation` uses Material elevation | Route both through the shadow token (`ScaffoldShadows.card`/`dialog`), draw hairline, keep Material path as the default | `scaffold_card.dart` (**generated**: `card.dart.jinja2`), `scaffold_surface.dart` | TS | Med. Defaults must stay on the Material path. |
| R2 | Hover = brand tint fill + brand 1 px edge, no geometry change (their "THE hover treatment") | `ScaffoldPressable` paints a `textPrimary` 8% state layer | Add hover fill/edge tokens and a draw path. The edge cannot be done with a state layer | `scaffold_pressable.dart`, then every pressable consumer | TS | Med. One widget, wide blast radius. |
| R3 | Outlined primary button: transparent fill, 1 px accent outline, radius 15, padding 16 x 20, no overlay/tint | `ActionButton` / `StringButton` hard-code `ElevatedButton.styleFrom` / `MaterialButton` | Not expressible via `ColorScheme` alone. The preset's `ThemeData` button themes cover plain Material buttons, but the scaffold's own button widgets bake their own shape/size. Remove the baked values or read tokens | `action_button.dart`, `string_button.dart` | TS | Low-Med |
| R4 | Gradient CTA fill + glow | no gradient button | New button variant or decoration slot | new / `string_button.dart` | NTH | Med |
| R5 | Input: pinned floating label, radius 15, 1 px `brandPrimaryOnSurface` focus border, `borderControl` (3:1) enabled edge | `TextEntryFieldWidget`: filled, **hard-coded `'Roboto'`, `Colors.white` text and hint, `borderGrey`** | Replace hard-codes with theme/palette reads. **This also resolves the open ticket `TICKET-text-entry-field-light-mode-contrast.md`** | `text_entry_field_widget.dart` | TS | Low, but changes default LIGHT rendering (white text on light fill becomes dark text), so the "defaults unchanged" golden gate must be re-baselined for that capture, or the fix gated to the preset |
| R6 | Sheets/drawers: `surfaceMenu` fill, top radius from token, scrim from token | `deepBlueTertiary` fill, `Colors.black87` scrim, top radius 16, `Colors.white` close icon/title, `Colors.white12` divider | Replace hard-codes with tokens. Same default-light-change caveat as R5 | `bottom_drawer.dart`, `responsive_drawer.dart` | TS | Low |
| R7 | Dividers = `surfaceMenu` / `colorScheme.surfaceContainerHighest` | n/a | Preset `dividerTheme`; no scaffold code | preset | TS | Low |
| R8 | Selection/focus use `brandPrimaryOnSurface`, not green | `ScaffoldSelectableSurface`, `ScaffoldChip`, `ScaffoldBadge`, `ScaffoldSearchBar` and others read `lightGreenPrimary` (about 25 sites) | Semantic alias field (section 7) then switch the call sites. Pure rename at call sites, no look change in defaults | most of `lib/components/`, several **generated** | TS | Med (breadth, not depth) |
| R9 | Tabular figures on numbers | `ScaffoldFormattedValue*` and chart labels do not set `tabularFigures` (only `media_controls`, `scaffold_chart`, by hand) | Read `numeric*` styles from the typography extension | `scaffold_formatted_value_*` (**generated**: `formatted_value.dart.jinja2`), `scaffold_chart.dart` | NTH | Low-Med |
| R10 | Mono family token | `'monospace'` literal in two files | Read `typography.monoFamily` | `scaffold_code_block.dart`, `scaffold_streaming_rich_text.dart` | NTH | Low |
| R11 | Selection checkbox: tick colour `textOnBrand`, fill `brandPrimaryStrong`, side `brandPrimaryOnSurface` | `Colors.white` tick, hard-coded radius 2 | Tokenise tick colour and radius | `scaffold_selection_indicator_checkbox.dart` (**generated**), `..._toggle.dart` (radius 12 hard-coded) | TS | Low |
| R12 | Page canvas: vertical wash + (dark) radial top light + 4% noise | no page-background widget | New `ScaffoldCanvas` widget (gradient wash and optional glow). Noise either as a bundled PNG or a seeded `CustomPainter` | new | NTH | Med. A bundled PNG adds an asset to every consumer. Prefer painter. |
| R13 | Themed toast/dialog shadow | `ToastWidget` uses `ScaffoldElevation.card` (static) | Read shadow token | `toast_widget.dart` | TS | Low |
| R14 | `ThemeData` assembly: `ColorScheme`, `TextTheme`, 15 component themes (appBar, tabBar, datePicker, buttons, input, searchBar, dropdown, navRail, bottomNav, checkbox, divider, menu, progress, dialog, textSelection) | The scaffold has **no ThemeData builder**; its widgets inherit from the host's theme | New function in the preset, e.g. `midnightTheme(Brightness)`, that returns `ThemeData` plus the three extensions. This is the only way ColorScheme/TextTheme/Material widgets get the look | new `lib/theme/` file(s) | TS | Med-High (largest single item) |
| R15 | Wallet `ColorScheme.outline = brandPrimary` and `error = fixedStatusError` in both modes | n/a | Copy with care: cyan `outline` colours every default Material outline. Decide deliberately for the preset; do not copy blindly | preset | TS | Low, but a trap |

**Not restylable from the theme directory** (found only via comments, files live in the wallet app, not read): `GWCard`, `GWSelectRow`, `GWViewAllLink`, nav tabs, `continue_button`, `swap_field`, `transaction_badge`. The token map above covers what those consume; the widgets themselves are wallet domain and are not in scope.

---

## 6. Table stakes vs differentiators for the opt-in `midnight` preset

### Table stakes (without these the preset does not read as the wallet look)

1. Dark palette and light palette registered as two `ScaffoldPalette` values (`midnightDark`, `midnightLight`), with the accent swap (cyan primary, mint secondary), surface ladder (base / elevated / menu / overlay) and text/border values from sections 1a to 1e.
2. `brandPrimaryOnSurface` and `borderControl` tokens, and a verified AA check across both palettes. These two are what the wallet needed to make light mode and inputs pass.
3. `ScaffoldDimens` midnight instance (only `appBarHeight` 68 differs from defaults).
4. Typography: full 15-slot `TextTheme` in Inter, with the five unspecified slots decided.
5. Themeable shadows (card, dialog; light and dark) as a new extension with defaults equal to `ScaffoldElevation.card`.
6. Themeable motion (durations and curves) with defaults equal to today.
7. `ThemeData` builder (R14) so the Material widgets inherit the look.
8. Hover recipe (R2), input restyle (R5), drawer/sheet restyle (R6), selection/focus semantic aliasing (R8).
9. Light-mode `surfaceSheen` gradient (only if the white-to-grey card is wanted; dark has none).

### Nice-to-have (defer unless time allows)

- Gradient tokens for CTA / border / hero wash / canvas (sections 4c, R4, R12).
- Glow shadows.
- Numeric (tabular) text styles and `monoFamily` (R9, R10).
- Full radius ladder and space10..space32.
- `borderStrong`, `borderControlOnBrand`, `statusWarning` fill, `statusSuccessText` / `statusErrorText`, `surfaceSunken` / `surfaceWell`.
- Noise texture.
- Midnight CSS (the engine already takes `--tokens`, so a midnight JSON that follows the M3 schema gives CSS output for free; only worth doing if a consumer asks).

### Anti-features (do not build)

| Anti-feature | Why | Instead |
|---|---|---|
| Port `GWAppearance` / any global `isLight` flag | Breaks const-widget rebuilds (the wallet's own todo documents this) and ignores `Theme` | Register the light or dark palette per `ThemeData` |
| Port wallet legacy colour names (`deepBlue*`, `btn*`, `brandGreen*`, `mutedGreen`) | The wallet calls them backwards-compat aliases | Midnight sets values on existing scaffold slots |
| `walletIdentityFill(address)` | Domain logic in atoms | Consumer concern |
| Nine `textPrimaryNN` alpha fields | One colour at fixed alphas | Derive with `withValues(alpha:)` |
| `brandTertiary` palette field with no reader | YAGNI | Keep the value in the token file for `ColorScheme.tertiary` only |
| Change `defaultPalette` / `lightPalette` / `defaultDimens` / M3 JSON values | GCS registers these and renders from the JSON | Everything new is additive; midnight is a separate set |
| Brand names in `lib/` or `example/` | Hard rule | Names `midnight`, `accent`, `surfaceSheet` etc. |
| Required new constructor params on `ScaffoldPalette` | Breaks any consumer that constructs one | See next section |

---

## 7. Structural decisions the token map forces

### Semantic alias fields (recommended)
Add role fields whose **default equals the existing legacy slot**, then repoint components at the role field. Examples (names are proposals):

| New role field | Default (keeps today's look) | Midnight dark value |
|---|---|---|
| `accent` | `lightGreenPrimary` | `#0AAEE6` (`brandPrimaryStrong`) for fills |
| `accentOnSurface` | `lightGreenPrimary` | dark `#0AAEE6` / light `#0A6885` |
| `accentSecondary` | `lightGreenSecondary` | `#2BF5B4` |
| `surfaceSheet` | `deepBlueTertiary` | `#171A21` (light `#EFF2F6`) |
| `surfaceBase` | none (new) | `#0B0D12` (light `#DCE0E6`) |
| `surfaceScrim` | `#DD000000` (black87) | `#99000000` |
| `borderControl` | `borderGrey` | white 36% / ink 48% |
| `textOnAccent` | `#17191E` (current `_kOnStatusDark`) | `#000B18` |

Make them **optional constructor parameters** that fall back in the initializer list (`accent = accent ?? lightGreenPrimary`). Existing consumers (GCS) that construct nothing are unaffected, and ones that do construct a palette keep compiling.

### Where new token groups live
`ScaffoldPalette` already has 22 fields times three hand-maintained places (field, `copyWith`, `lerp`). Adding about 8 more makes it large. Shadows, typography, motion and gradients should be **new `ThemeExtension`s** with `context.shadows` etc. getters that fall back to defaults when unregistered, exactly like `context.palette` and `context.dimens`. `scaffoldThemeExtensions` in `scaffold_theme.dart` gets the new defaults appended. This matches the existing pattern and is the lowest-risk way to meet "defaults equal today's look".

### Font delivery (OPEN, MEDIUM confidence)
Wallet bundles Inter (4 weights) and JetBrains Mono in its own `pubspec.yaml`. If the scaffold bundles them in its pubspec, **every consumer's build grows**, including GCS, which doesn't use midnight. Recommendation: the preset references the family names with a `fontFamilyFallback`, the host app (and `example/`) registers the fonts. Verify the licence (both are OFL) before bundling anything.

### Generated-file constraint
`card`, `state_view`, `search_bar`, `selection_indicator`, `formatted_value`, `image_placeholder`, `animated_display` are committed Jinja2 families. R1, R8, R9 and R11 touch them, so those edits go through `templates/components/*.jinja2` plus regeneration, not the `.dart` files.

---

## 8. Dependencies

```
JSON sections for Dart defaults (Feature 1)
  -> new theme extensions (shadows, typography, motion, gradients)  [defaults == today]
  -> semantic alias fields on ScaffoldPalette                        [defaults == today]
      -> component call-site repointing (R8)                         [no visual change in defaults]
      -> midnight token file -> midnightDark/Light palettes, dimens, extensions
          -> ThemeData builder (R14)
          -> restyles R1, R2, R3, R5, R6, R11, R13                    [need tokens present]
              -> golden gate (defaults unchanged) + AA gate (midnight dark + light)
```

R5 and R6 remove hard-coded white and so alter default LIGHT output. They are the one place where "goldens of defaults unchanged" and "fix the hard-coded colours" conflict. That is a decision for the owner, not something to resolve silently.

---

## 9. MVP recommendation

Prioritise, in order:

1. Pipeline (Feature 1): JSON sections for current palette/dimens, generator, drift test. No visible change.
2. Additive fields (Feature 3): alias fields on palette, plus shadows, typography and motion extensions, all defaulting to today.
3. Midnight token file and `midnightDark`/`midnightLight` palettes, dimens, `ThemeData` builder, AA verification (Feature 4).
4. Restyles R2, R3, R5, R6, R8, R11, R13 (Feature 5).

Defer: gradients and canvas (R4, R12), glows, numeric styles, full radius ladder, midnight CSS.

---

## Confidence

| Area | Level | Reason |
|---|---|---|
| Wallet token values | HIGH | Read directly from source; light/dark factories read in full |
| Scaffold gap analysis | HIGH | All five `lib/theme/` files and the `palette.*` call sites read |
| Component restyle list | MEDIUM | Based on theme-dir code plus scaffold component greps. Wallet component files (`GWCard`, `GWSelectRow`, buttons) were not read, so some wallet looks are inferred from theme comments |
| Slot-value choices for fields with no wallet source (skeleton, drop zone, 5 unmapped text slots) | LOW | Design decisions the owner must make |
| Byte-identical generation feasibility | MEDIUM | Depends on the generator reproducing doc comments and `ScaffoldColors.x` refs; a stack-level question for the STACK researcher |

## Sources

- `C:\Users\User\Documents\Projects\GNUS\GeniusWallet\lib\theme\*.dart` (14 files)
- `C:\Users\User\Documents\Projects\GNUS\GeniusWallet\pubspec.yaml` (font declarations)
- `C:\Users\User\Documents\Projects\GNUS\openapi-client-scaffold\lib\theme\*.dart`, `design_tokens.json`, `tools\scaffold_codegen\m3_tokens_css.py`
- `C:\Users\User\Documents\Projects\GNUS\openapi-client-scaffold\.planning\workstreams\scaffold\MILESTONE-CONTEXT.md`, `.planning\handoffs\HANDOFF-261016-wallet-styling.md`, `TICKET-text-entry-field-light-mode-contrast.md`
