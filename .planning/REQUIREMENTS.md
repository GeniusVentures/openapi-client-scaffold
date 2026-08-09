# Requirements: Frontend Scaffold v1.1

**Milestone:** v1.1 Widget Library
**Created:** 2026-08-09

## Active Requirements

### Core Template Widgets

*Jinja2 templates exist in `templates/components/` — these requirements ship the Dart `lib/components/` implementations.*

- [ ] **WIDG-01:** ScaffoldCard widget — M3 card with configurable header/body/actions slots and elevated/outlined/filled variant selection
- [ ] **WIDG-02:** ScaffoldStateView widget — renders one of empty (icon + headline + subtitle + optional CTA), loading (skeleton rows), or error (inline card with icon/message/retry button) states from a single variant-enum constructor
- [ ] **WIDG-03:** ScaffoldSearchBar widget — pill-shaped search TextField with clear button, animated results dropdown showing grouped SearchResult items under labelled headers

### Media Widgets

*New template + widget pairs — critical path for genius-tube Phase 2.*

- [ ] **WIDG-04:** MediaCard widget — configurable aspect ratio (16:9, 9:16, 1:1), thumbnail slot from any ImageProvider, typed badge slots (top-left, top-right, bottom-right), metadata row builder accepting arbitrary children
- [ ] **WIDG-05:** MediaControls widget — overlay control bar with play/pause toggle, seekbar supporting buffered-amount display, volume mute/unmute, and fullscreen enter/exit; all callbacks optional (no-op when null)

### Integration Widgets

*Workspace-common — reusable by any Genius Network app.*

- [ ] **WIDG-06:** WalletConnectSheet widget — bottom sheet presenting Reown WalletConnect session state (disconnected QR connect, connected wallet address + network, disconnect action); callbacks for onConnect/onDisconnect; session state passed in (not managed internally)
- [ ] **WIDG-07:** ScaffoldBadge widget — compact icon + label chip with configurable background color and optional density (compact/card)

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

*Filled by roadmap step.*

---
*Last updated: 2026-08-09*
