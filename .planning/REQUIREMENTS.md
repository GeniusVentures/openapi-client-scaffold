# Requirements: Frontend Scaffold v1.1

**Milestone:** v1.1 Widget Library
**Created:** 2026-08-09
**Updated:** 2026-08-10 — Phase 6 re-scoped to 28 widget atoms + ScaffoldMotion

## Active Requirements

### Phase 6: Core UI Foundation — 28 widget atoms + ScaffoldMotion

*Every consumer app builds from these base atoms. Composites (ScaffoldCard, ScaffoldStateView, ScaffoldSearchBar) ship as pre-built Jinja2-template-generated widgets consuming the atoms.*

#### Wave 0 — Zero-dependency foundations (10 widgets + ScaffoldMotion)

*No scaffold dependencies. Only consume `Theme.of(context)`, `Breakpoints`, and `ScaffoldMotion`.*

- [ ] **WIDG-01:** ScaffoldMotion — shared animation durations, curves, delays, stagger timing, and reduced-motion rules. Not a widget — a utility consumed by ScaffoldAnimatedDisplay and other atoms.
- [ ] **WIDG-02:** ScaffoldSurface — styles any child with a background, border, shape, radius, elevation, and state layer. The foundational container atom.
- [ ] **WIDG-03:** ScaffoldTouchTarget — ensures that any child has the required touch area and accessibility semantics.
- [ ] **WIDG-04:** ScaffoldFocusOutline — draws a consistent keyboard or accessibility focus border around any child.
- [ ] **WIDG-05:** ScaffoldLiveRegion — announces changing text or status to screen readers without changing the visible layout.
- [ ] **WIDG-06:** ScaffoldOverflowFade — fades a clipped edge to show that more content exists.
- [ ] **WIDG-07:** ScaffoldScrollEdgeIndicator — marks which edges contain more scrollable content.
- [ ] **WIDG-08:** ScaffoldResponsiveVisibility — shows, hides, or replaces a child according to the active breakpoint (consumes existing `Breakpoints`).
- [ ] **WIDG-09:** ScaffoldFormattedValue — displays numbers, money, percentages, dates, times, and durations in a consistent format. **Template candidate** — each format uses a different Flutter formatter and import.
- [ ] **WIDG-10:** ScaffoldColorSwatch — displays a selectable or read-only color sample.

#### Wave 1 — Single-dependency atoms (11 widgets)

*Depend on one or more Wave 0 atoms. Four are template candidates; seven are plain parameterized widgets.*

- [ ] **WIDG-11:** ScaffoldBadge — displays a dot, count, icon, or short text over or beside another widget. Consumes ScaffoldSurface.
- [ ] **WIDG-12:** ScaffoldStatusIndicator — shows a generic status through color, shape, icon, and accessible text. Consumes ScaffoldTouchTarget.
- [ ] **WIDG-13:** ScaffoldSelectionIndicator — displays selected, unselected, partial, radio, or checked states. Consumes ScaffoldTouchTarget. **Template candidate** — radio/checkbox/toggle have structurally different widget trees.
- [ ] **WIDG-14:** ScaffoldImagePlaceholder — represents loading, missing, empty, or failed images. Consumes ScaffoldSurface. **Template candidate** — each variant has different icon + label composition.
- [ ] **WIDG-15:** ScaffoldSkeleton — displays an animated placeholder for content that is loading. Consumes ScaffoldMotion for animation timing.
- [ ] **WIDG-16:** ScaffoldAnimatedDisplay — applies configurable animation to any child (fade, pulse, scale, slide, rotate, shake, bounce). Consumes ScaffoldMotion. **Template candidate** — each animation uses a different `Animation`/`AnimatedWidget` subclass.
- [ ] **WIDG-17:** ScaffoldPressable — gives any child pressed, hovered, focused, and disabled interaction states. Consumes ScaffoldTouchTarget.
- [ ] **WIDG-18:** ScaffoldDisabledOverlay — blocks interaction and visually marks a child as disabled, with an optional reason. Consumes ScaffoldSurface.
- [ ] **WIDG-19:** ScaffoldDragHandle — displays the standard grip used to move or reorder content. Consumes ScaffoldTouchTarget.
- [ ] **WIDG-20:** ScaffoldResizeHandle — provides horizontal, vertical, or corner drag behavior for resizing content. Consumes ScaffoldTouchTarget.
- [ ] **WIDG-21:** ScaffoldNumericInput — accepts numeric values with bounds, precision, step size, units, and optional increment/decrement actions. Consumes ScaffoldTouchTarget.

#### Wave 2 — Multi-dependency atoms (4 widgets)

*Depend on two or more Wave 0-1 atoms.*

- [ ] **WIDG-22:** ScaffoldSelectableSurface — makes any child a selectable surface with selected, focused, pressed, and disabled states. Consumes ScaffoldPressable + ScaffoldSurface.
- [ ] **WIDG-23:** ScaffoldDraggable — makes any child draggable and supplies drag feedback, preview, and state callbacks. Consumes ScaffoldPressable + ScaffoldDragHandle.
- [ ] **WIDG-24:** ScaffoldDropTarget — accepts dragged content and displays idle, accepted, rejected, and dropped states. Consumes ScaffoldSurface + ScaffoldStatusIndicator.
- [ ] **WIDG-25:** ScaffoldFileInputSurface — provides the visual and interaction surface for selecting or dropping files, including validation states. Consumes ScaffoldSurface + ScaffoldDropTarget + ScaffoldStatusIndicator.

#### Wave 3 — Composites with Jinja2 templates (3 widgets)

*Pre-built generic widgets generated from existing `templates/components/` — composed from Wave 0-2 atoms.*

- [ ] **WIDG-26:** ScaffoldCard — presents grouped content using ScaffoldSurface + ScaffoldPressable with header, body, action areas. Generated from `templates/components/card.dart.jinja2` (elevated/outlined/filled variants selectable at render time).
- [ ] **WIDG-27:** ScaffoldStateView — presents loading, empty, error, unavailable, and success states with optional actions. Generated from `templates/components/state.dart.jinja2` — each state variant composes a different atom set (ScaffoldSkeleton for loading, ScaffoldImagePlaceholder + ScaffoldStatusIndicator for empty/error).
- [ ] **WIDG-28:** ScaffoldSearchBar — provides search entry, clear, loading, filtering, and result-state hooks. Generated from `templates/components/search_bar.dart.jinja2` — composes ScaffoldSurface + ScaffoldPressable + ScaffoldStatusIndicator.

### Phase 7: Media & Integration Widgets

*Moved from original Phases 7-8. Depends on Phase 6 atoms (ScaffoldBadge for MediaCard badge slots, ScaffoldSurface + ScaffoldPressable for controls).*

- [ ] **WIDG-29:** MediaCard widget — configurable aspect ratio (16:9, 9:16, 1:1), thumbnail slot from any ImageProvider, typed badge slots (top-left, top-right, bottom-right) consuming ScaffoldBadge, metadata row builder accepting arbitrary children. New `templates/components/media_card.dart.jinja2`.
- [ ] **WIDG-30:** MediaControls widget — overlay control bar with play/pause toggle, seekbar supporting buffered-amount display, volume mute/unmute, and fullscreen enter/exit; all callbacks optional. Consumes ScaffoldPressable + ScaffoldTouchTarget.
- [ ] **WIDG-31:** WalletConnectSheet widget — bottom sheet presenting Reown WalletConnect session state (disconnected QR connect, connected wallet address + network, disconnect action); callbacks for onConnect/onDisconnect; session state passed in. Builds on existing BottomDrawer.

## Future Requirements

*Deferred to post-v1.1:*

- Navigation component widgets (from `navigation.dart.jinja2`)
- DataTable widget (from `data_table.dart.jinja2`)
- FormDialog widget (from `form_dialog.dart.jinja2`)
- Light default palette for ScaffoldPalette (dark-seeded currently)

## Out of Scope

| Item | Reason |
|------|--------|
| App-specific composites (TokenGateBadge, EntitlementStatusBar, CreatorUploadPipeline) | Built from scaffold atoms in consuming apps — not generic |
| State management (providers/blocs/cubits) | Consumers own their state layer |
| Backend integration (API clients, sockets) | OpenAPI codegen covers API clients; sockets are app-specific |
| Platform channels / FFI | Consuming app concern |
| GeniusWallet migration to scaffold | GeniusWallet may or may not adopt — library model means no forced migration |

## Traceability

| Requirement | Phase | Wave | Description |
|-------------|-------|------|-------------|
| WIDG-01 | Phase 6 | 0 | ScaffoldMotion |
| WIDG-02 | Phase 6 | 0 | ScaffoldSurface |
| WIDG-03 | Phase 6 | 0 | ScaffoldTouchTarget |
| WIDG-04 | Phase 6 | 0 | ScaffoldFocusOutline |
| WIDG-05 | Phase 6 | 0 | ScaffoldLiveRegion |
| WIDG-06 | Phase 6 | 0 | ScaffoldOverflowFade |
| WIDG-07 | Phase 6 | 0 | ScaffoldScrollEdgeIndicator |
| WIDG-08 | Phase 6 | 0 | ScaffoldResponsiveVisibility |
| WIDG-09 | Phase 6 | 0 | ScaffoldFormattedValue |
| WIDG-10 | Phase 6 | 0 | ScaffoldColorSwatch |
| WIDG-11 | Phase 6 | 1 | ScaffoldBadge |
| WIDG-12 | Phase 6 | 1 | ScaffoldStatusIndicator |
| WIDG-13 | Phase 6 | 1 | ScaffoldSelectionIndicator |
| WIDG-14 | Phase 6 | 1 | ScaffoldImagePlaceholder |
| WIDG-15 | Phase 6 | 1 | ScaffoldSkeleton |
| WIDG-16 | Phase 6 | 1 | ScaffoldAnimatedDisplay |
| WIDG-17 | Phase 6 | 1 | ScaffoldPressable |
| WIDG-18 | Phase 6 | 1 | ScaffoldDisabledOverlay |
| WIDG-19 | Phase 6 | 1 | ScaffoldDragHandle |
| WIDG-20 | Phase 6 | 1 | ScaffoldResizeHandle |
| WIDG-21 | Phase 6 | 1 | ScaffoldNumericInput |
| WIDG-22 | Phase 6 | 2 | ScaffoldSelectableSurface |
| WIDG-23 | Phase 6 | 2 | ScaffoldDraggable |
| WIDG-24 | Phase 6 | 2 | ScaffoldDropTarget |
| WIDG-25 | Phase 6 | 2 | ScaffoldFileInputSurface |
| WIDG-26 | Phase 6 | 3 | ScaffoldCard (template-generated composite) |
| WIDG-27 | Phase 6 | 3 | ScaffoldStateView (template-generated composite) |
| WIDG-28 | Phase 6 | 3 | ScaffoldSearchBar (template-generated composite) |
| WIDG-29 | Phase 7 | - | MediaCard |
| WIDG-30 | Phase 7 | - | MediaControls |
| WIDG-31 | Phase 7 | - | WalletConnectSheet |

**Coverage: 31/31 v1.1 requirements mapped. No orphans.**

---
*Last updated: 2026-08-10 — Phase 6 re-scoped to Core UI Foundation (28 atoms + ScaffoldMotion)*
