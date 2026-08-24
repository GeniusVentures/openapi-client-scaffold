# Phase 7: Media & Integration Widgets - Context

**Gathered:** 2026-08-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship three generic, M3-themed widgets into the `frontend_scaffold` package plus one new Jinja2 template:

- **MediaCard (WIDG-29)** — configurable aspect ratio (16:9, 9:16, 1:1), thumbnail from any `ImageProvider`, typed badge slots, metadata row, and a new `templates/components/media_card.dart.jinja2`
- **MediaControls (WIDG-30)** — overlay control bar: play/pause toggle, seekbar with buffered-amount display, volume mute/unmute, fullscreen enter/exit; all callbacks optional
- **WalletConnectSheet (WIDG-31)** — bottom sheet presenting Reown WalletConnect session state (disconnected QR connect / connected wallet address + network / disconnect), built on the existing `BottomDrawer`

All three are generic building blocks consumed by genius-tube (Phase 2/4), GeniusWallet, and genius-ai-boss. They carry zero app-specific business logic, zero protocol logic, and zero Reown session ownership. This phase clarifies HOW to implement the three widgets — it does not add new capabilities.

</domain>

<decisions>
## Implementation Decisions

### Guiding Principle
- **D-00:** (owner-stated rationale) `frontend_scaffold` is a shareable generic widget library; consuming apps compose specialty widgets from scaffold atoms. Every decision below follows from this — scaffold owns typed, generic contracts; app-specific rendering, state, and dependencies are pushed to consumers.

### MediaCard
- **D-01:** Badge slots are typed, not generic. Three optional named parameters — `topLeftBadge`, `topRightBadge`, `bottomRightBadge` — each accepting a `ScaffoldBadge`. This matches the WIDG-29 "typed badge slots" contract verbatim and gives consumers an unambiguous API. No generic `badges` map and no `extraBadges` escape hatch: an open list would let consumers bypass the typed contract and drift visual consistency across apps.
- **D-02:** Metadata row is `metadataRow: List<Widget>`. The caller passes arbitrary children; the scaffold lays them out in a `Row` applying theme spacing and overflow/ellipsis handling. This honors WIDG-29's "arbitrary caller-supplied children" while guaranteeing consistent padding/overflow behavior. A free-form `metadataBuilder` was rejected — every consumer would re-solve spacing/overflow and results would drift.

### MediaControls
- **D-03:** Stateless render + private transient seek state only. The widget renders purely from passed-in `isPlaying` / `position` / `duration` / `buffered`. Playback truth lives in the consuming app's playback cubit (consistent with "Flutter holds no protocol/media logic"). A private `StatefulWidget` holds ONLY the transient seek-scrub position while the user is dragging, and emits `onSeek` on release. No `MediaControlsCubit` — a cubit would duplicate playback state already owned by the app and invite drift.
- **D-04:** Optional time labels using the existing duration formatter. Position/duration text is shown beside the seekbar by default, hideable via `showTimeLabels`. Labels are rendered with the existing `ScaffoldFormattedValueDuration` (WIDG-09) rather than ad-hoc string formatting.

### WalletConnectSheet
- **D-05:** QR connect is a consumer-supplied `qrBuilder` slot. The sheet takes `qrBuilder: Widget Function(BuildContext context, String uri)` and the consumer renders the QR (qr_flutter, custom painter, etc.). Scaffold gains NO QR dependency. This extends the "session state passed in externally" philosophy to rendering — the URI is data scaffold owns; turning it into pixels is the consumer's choice. GeniusWallet and genius-tube each bring their own QR renderer. Adding `qr_flutter` to scaffold was rejected — it would force a rendering dependency on every consumer (including genius-ai-boss, which never shows a QR).

### Template Scope
- **D-06:** `media_card.dart.jinja2` generates a widget-only file. A single `StatelessWidget` composing `ScaffoldSurface` + typed `ScaffoldBadge` slots + `ScaffoldPressable`. No cubit/state trio. The Card/StateView/SearchBar composites use a cubit because their variant/state is drivable live; MediaCard's aspect ratio, badges, and metadata are plain rebuild parameters with no internal state worth owning, so a cubit would wrap nothing and add drift surface.

### Claude's Discretion
- MediaControls internal control-bar layout (icon choice, ordering, spacing of play/volume/fullscreen buttons) — follow M3 media-control idioms and existing ScaffoldPressable/TouchTarget patterns.
- WalletConnectSheet connected-state layout details (address truncation, network chip styling) — compose from existing atoms.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scaffold Workstream
- `.planning/workstreams/scaffold/ROADMAP.md` — Phase 7 scope, success criteria 1-6, dependency on Phase 6 atoms
- `.planning/workstreams/scaffold/REQUIREMENTS.md` — completed WIDG-01..28 (Phase 6 atoms these widgets consume)
- `.planning/REQUIREMENTS.md` — **authoritative WIDG-29 / WIDG-30 / WIDG-31 requirement text** (these live in the parent REQUIREMENTS.md, not the workstream copy, which only tracks through WIDG-28)
- `.planning/workstreams/scaffold/CONSUMERS.md` — cross-app demand matrix (genius-tube Phase 2/4, GeniusWallet shared Reown UI, genius-ai-boss)
- `.planning/workstreams/scaffold/STATE.md` — accumulated decisions, Reown version-band coordination note (Phase 7 planning concern)

### Prior Phase Decisions (locked patterns to reuse)
- `.planning/workstreams/scaffold/phases/06-core-ui-foundation/06-CONTEXT.md` — D-01 ScaffoldMotion InheritedWidget, D-02 full a11y, D-03 theme-token expansion, D-04 pure composability. Phase 7 widgets consume the Phase 6 atoms shipped under these decisions.
- `.planning/workstreams/scaffold/phases/05-scaffold-submodule-consolidation/05-05-SUMMARY.md` — ThemeExtension pattern, a11y pattern (Semantics + liveRegion), `dart analyze` gate, toast lifecycle fixes

### Existing Code (read before writing any widget)
- `lib/frontend_scaffold.dart` — barrel export pattern; all three widgets must be exported here
- `lib/components/scaffold_badge.dart` — the atom MediaCard badge slots consume (WIDG-12)
- `lib/components/scaffold_pressable.dart` — pressed/hovered/focused/disabled wrapper MediaControls + MediaCard consume (WIDG-17)
- `lib/components/scaffold_touch_target.dart` — 48×48 hit-area enforcement for MediaControls buttons (WIDG-02)
- `lib/components/scaffold_surface.dart` — surface treatment for MediaCard + sheet styling (WIDG-01)
- `lib/components/scaffold_formatted_value_duration.dart` — duration formatter for MediaControls time labels (WIDG-09)
- `lib/components/bottom_drawer/bottom_drawer.dart` — `BottomDrawer` StatelessWidget; WalletConnectSheet builds on this
- `lib/components/bottom_drawer/responsive_drawer.dart` — `ResponsiveDrawer.show<T>()` (desktop breakpoint 800, `showModalBottomSheet` on mobile); WalletConnectSheet presentation entry point

### Template Infrastructure (read before writing media_card template)
- `templates/components/card.dart.jinja2` — template structure, slot pattern, generated-header convention (source schema + generator version), Jinja2 usage
- `templates/components/card_vars.json` — fixture variable schema for standalone template rendering

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **ScaffoldBadge** (WIDG-12): the atom filling MediaCard's three typed badge slots
- **ScaffoldPressable** (WIDG-17) + **ScaffoldTouchTarget** (WIDG-02): MediaControls play/volume/fullscreen buttons and MediaCard tap target
- **ScaffoldSurface** (WIDG-01): MediaCard surface + WalletConnectSheet styling
- **ScaffoldFormattedValueDuration** (WIDG-09): MediaControls position/duration labels (D-04)
- **BottomDrawer / ResponsiveDrawer**: WalletConnectSheet presentation primitive; `ResponsiveDrawer.show<T>()` handles the desktop(800)/mobile breakpoint
- **ScaffoldMotion** (D-01 from Phase 6): any MediaControls show/hide or press animations respect reduced-motion

### Established Patterns
- M3 `ThemeExtension` via `context.palette` / `context.dimens` — every widget resolves tokens this way; no hardcoded colors/dimens
- Pure composability (Phase 6 D-04) — each widget does one thing; consumers compose with `Stack`/`Positioned`
- Barrel export from `frontend_scaffold.dart` — every public widget gets an export line
- Generated-code header convention — source schema + generator version; generated code is never committed (CI regenerates + diffs)
- Jinja2 `StrictUndefined` + `_vars.json` fixture — media_card template follows this
- `dart analyze --fatal-infos` gate — zero warnings required
- Full a11y (Phase 6 D-02) — interactive controls get Semantics + focus; MediaControls is the most a11y-sensitive widget this phase

### Integration Points
- New widgets in `lib/components/` (flat directory): `media_card.dart`, `media_controls.dart`, `wallet_connect_sheet.dart`
- New template `templates/components/media_card.dart.jinja2` + `templates/components/media_card_vars.json`
- All three exported from `lib/frontend_scaffold.dart`
- Tests in `test/components/` matching lib/ structure
- Example demos in `example/lib/demos/` showing each widget

</code_context>

<specifics>
## Specific Ideas

- MediaCard and MediaControls are **Critical for genius-tube Phase 2** (public-media playback) per CONSUMERS.md; WalletConnectSheet is **High for genius-tube Phase 4** and shared with GeniusWallet per ADR-002.
- Reown version-band coordination with GeniusWallet (1.4.0+) is a Phase 7 planning concern noted in STATE.md — the sheet itself takes session state externally and does NOT pin a Reown version.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 7-Media & Integration Widgets*
*Context gathered: 2026-08-15*
