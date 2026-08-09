---
workstream: scaffold
type: reference
source: genius-tube scaffold exploration (apps/genius-tube, 2026-08-09)
status: living
---

# Scaffold Consumers & Widget Demand

Cross-app view of which consuming projects need what from `frontend_scaffold`. This is
demand-side intelligence for the scaffold roadmap — it does not change the scope boundary
(scaffold owns generic widgets/templates; app-specific composites live in the consuming
app). Provenance: distilled from genius-tube's scaffold exploration notes (2026-08-09),
which surveyed the existing `lib/` inventory against dttube and genius-ai-boss needs.

> Living document — update as consumers surface new widget needs or as template-only
> widgets get implemented. Not a commitment; priorities are consumer-stated.

## Implemented (lib/) — available to all consumers

ActionButton, StringButton, SlidingDrawerButton, AppScreenView, DesktopBodyContainer,
ResponsiveGrid, BottomDrawer, ResponsiveDrawer, TextEntryField, TextFormFieldLogic,
ToastManager (two-density, v0.3.0), Loading, CheckmarkAnimation, XAnimation;
theme: ScaffoldColors, ScaffoldDimens, ScaffoldPalette, ScaffoldElevation, ScaffoldTheme;
utils: Breakpoints.

## Template-only (templates/ exist, no lib/ widget yet)

| Template | Envisions | Priority |
|----------|-----------|----------|
| `card.dart.jinja2` | `ScaffoldCard` — header/body/actions slots, elevated/outlined/filled | High |
| `state.dart.jinja2` | `ScaffoldStateView` — empty/loading/error variants | High |
| `search_bar.dart.jinja2` | `ScaffoldSearchBar` — pill-shaped, grouped results | Medium |
| `navigation.dart.jinja2` | Navigation components | Medium |
| `data_table.dart.jinja2` | Data table | Low |
| `form_dialog.dart.jinja2` | Form dialog | Medium |

## Needs new template + widget

| Widget | Why | Priority |
|--------|-----|----------|
| `MediaCard` | aspect ratio + thumbnail + badge slots + metadata row | Critical (genius-tube Phase 2) |
| `MediaControls` | play/pause, seekbar, volume, fullscreen overlay | Critical (genius-tube Phase 2) |
| `WalletConnectSheet` | Reown session UI — shared with GeniusWallet per genius-tube ADR-002 | High (genius-tube Phase 4) |
| `ScaffoldBadge` | icon + label chip, configurable color | Medium |

## Cross-app consumer matrix

| App | What it needs from scaffold |
|-----|-----------------------------|
| genius-tube | MediaCard, MediaControls, ScaffoldStateView, WalletConnectSheet, ScaffoldSearchBar |
| genius-ai-boss | ScaffoldCard, ScaffoldSearchBar, ScaffoldStateView, form_dialog, data_table |
| GeniusWallet | WalletConnectSheet (shared Reown session UI per genius-tube ADR-002) |

## Boundary decisions (from genius-tube exploration)

- Font choice lives in theme (`scaffold_theme.dart`), not in primitive widget wrappers
- Image caching and localization are infrastructure, not widgets
- Media cards are generic (configurable aspect ratio + badge slots + metadata builder) — not app-specific
- WalletConnectSheet is workspace-shared (GeniusWallet also uses Reown)
- App-specific widgets (genius-tube's TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline) are composites built from scaffold atoms — they live in the consuming app, not here
