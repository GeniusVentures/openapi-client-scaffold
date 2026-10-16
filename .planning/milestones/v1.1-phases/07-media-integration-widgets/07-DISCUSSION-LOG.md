# Phase 7: Media & Integration Widgets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-15
**Phase:** 7-Media & Integration Widgets
**Areas discussed:** MediaCard badge-slot API shape, MediaCard metadata row builder, MediaControls state ownership, MediaControls time labels, WalletConnectSheet QR connect rendering, media_card.dart.jinja2 template scope

---

## MediaCard badge-slot API shape

| Option | Description | Selected |
|--------|-------------|----------|
| A1 typed slots only | `topLeftBadge`/`topRightBadge`/`bottomRightBadge` params, each a `ScaffoldBadge`. Matches WIDG-29 exactly. | ✓ |
| A2 typed + generic escape hatch | Three typed slots plus `extraBadges: List<Positioned>` for unplanned positions. | |

**User's choice:** A1
**Notes:** Generic list would let consumers bypass the typed contract and drift visual consistency.

---

## MediaCard metadata row builder

| Option | Description | Selected |
|--------|-------------|----------|
| B1 metadataRow: List<Widget> | Caller passes children; scaffold lays out in a Row with theme spacing + overflow/ellipsis. | ✓ |
| B2 metadataBuilder | Full freedom via `Widget Function(BuildContext)`; scaffold reserves vertical space only. | |

**User's choice:** B1
**Notes:** Builder would force every consumer to re-solve spacing/overflow; results drift across apps.

---

## MediaControls state ownership

| Option | Description | Selected |
|--------|-------------|----------|
| C1 stateless + transient seek | Render from passed-in isPlaying/position/duration/buffered; private state holds only seek-scrub during drag, `onSeek` on release. | ✓ |
| C2 cubit trio | `MediaControlsCubit` + state matching Card/StateView/SearchBar composites. | |

**User's choice:** C1
**Notes:** Playback truth stays in the consuming app's cubit. A scaffold cubit would duplicate state and invite drift.

---

## MediaControls time labels

| Option | Description | Selected |
|--------|-------------|----------|
| C-a yes, optional | Time labels on by default, hideable via `showTimeLabels`; uses existing `ScaffoldFormattedValueDuration` (WIDG-09). | ✓ |
| C-b no labels | Seekbar only; consumers add their own labels. | |

**User's choice:** C-a

---

## WalletConnectSheet QR connect rendering

| Option | Description | Selected |
|--------|-------------|----------|
| D1 qrBuilder slot | `qrBuilder: Widget Function(BuildContext, String uri)`; consumer supplies the QR widget. Scaffold dependency-free. | ✓ |
| D2 add qr_flutter | Sheet renders QR internally; adds a rendering dependency to the shared package. | |

**User's choice:** D1
**Notes:** GeniusWallet and genius-tube each bring their own QR renderer; genius-ai-boss never shows a QR and shouldn't inherit the dependency.

---

## media_card.dart.jinja2 template scope

| Option | Description | Selected |
|--------|-------------|----------|
| E1 widget-only template | Single `StatelessWidget` composing ScaffoldSurface + badge slots + ScaffoldPressable. | ✓ |
| E2 widget + cubit + state trio | Matches Card/StateView/SearchBar exactly. | |

**User's choice:** E1
**Notes:** MediaCard owns no live-drivable state (aspect ratio/badges/metadata are plain rebuild params); a cubit would wrap nothing.

---

## Claude's Discretion

- MediaControls internal control-bar layout (icon choice, ordering, spacing) — M3 media-control idioms + ScaffoldPressable/TouchTarget patterns.
- WalletConnectSheet connected-state layout details (address truncation, network chip styling).

## Deferred Ideas

None — discussion stayed within phase scope.

---

**Owner rationale (applies to all selections):** the scaffold submodule is a shareable generic widget library; apps compose specialty widgets from it. Typed generic contracts live in scaffold; app-specific rendering, state, and dependencies belong to consumers.
