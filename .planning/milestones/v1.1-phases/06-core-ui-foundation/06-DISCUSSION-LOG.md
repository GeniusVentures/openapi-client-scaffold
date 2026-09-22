# Phase 6: Core UI Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-11
**Phase:** 06-core-ui-foundation
**Areas discussed:** ScaffoldMotion design, Accessibility depth, Theme token strategy, API philosophy

---

## ScaffoldMotion Design

| Option | Description | Selected |
|--------|-------------|----------|
| Static utility class only | Durations/curves as consts; no runtime propagation | |
| InheritedWidget only | Widget-tree propagation for reduced-motion; no constants | |
| Both | Utility constants + InheritedWidget propagation | ✓ |

**User's choice:** Both — widgets read `ScaffoldMotion.of(context)` for reduced-motion preference and `ScaffoldMotion.durations`/`curves` for constants.
**Notes:** Default durations and curves as static consts. Reduced-motion propagates through the widget tree so any subtree can opt in.

---

## Accessibility Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Minimum bar | Semantics on interactive elements only; deepen progressively | |
| Full a11y | Semantics roles, labels, liveRegion, focus management across all 28 atoms | ✓ |

**User's choice:** Full a11y — apply toast-level Semantics(liveRegion) + semanticLabel pattern across all 28 atoms.
**Notes:** Keyboard-navable atoms must participate in focus order. Focus outlines visible for both keyboard and screen-reader modes. Pattern already proven in the toast widget (Semantics + liveRegion + semanticLabel).

---

## Theme Token Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Proactive | Add focus ring, skeleton, disabled overlay, drag/drop tokens in Wave 0 before any widgets ship | ✓ |
| On-demand | Add tokens when each wave needs them | |

**User's choice:** Proactive — expand ScaffoldPalette and ScaffoldDimens in Wave 0 with all tokens the 28 atoms will need.
**Notes:** Palette additions: focus ring color, skeleton base, skeleton shimmer, disabled overlay, drag feedback, drop zone highlight, drop zone rejected. Dimens additions: focus ring width, skeleton radius, disabled opacity, drag handle size, minimum touch target, touch target padding. Defaults seeded from existing dark-mode palette.

---

## API Philosophy

| Option | Description | Selected |
|--------|-------------|----------|
| Convenience constructors | Atoms compose common patterns internally (e.g., Badge.dot(child:, count:)) | |
| Pure composability | Each atom does one thing; consumers compose with Stack/Positioned | ✓ |

**User's choice:** Pure composability — each atom has one job. Consumers handle layout via Stack + Positioned. If a composition pattern repeats across all three consumer apps, it becomes a Jinja2 template candidate.
**Notes:** Discussed JSON-config-driven widget construction briefly; rejected as redundant with the Jinja2 template system that already provides build-time code generation from config (vars.json). Runtime widget factories are a different capability — out of scope.

---

## Claude's Discretion

No areas deferred to Claude — all decisions explicitly made by user.

## Deferred Ideas

None.
