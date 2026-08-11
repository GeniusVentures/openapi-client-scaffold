# Phase 6: Core UI Foundation - Context

**Gathered:** 2026-08-11
**Status:** Ready for planning

## Phase Boundary

Deliver 28 universal UI widget atoms + ScaffoldMotion across 4 dependency-layered waves within the `frontend_scaffold` package. These are the primitive building blocks every Genius Network consumer app composes into its interfaces — generic, M3-themed, zero app-specific logic. The 3 existing Jinja2 templates (card, state, search_bar) ship as pre-built composites consuming the atoms.

## Implementation Decisions

### ScaffoldMotion Design
- **D-01:** ScaffoldMotion is both a utility class (static `durations`/`curves` constants) and an InheritedWidget — **Reversibility:** costly — 28 widgets will call `ScaffoldMotion.of(context)` to read reduced-motion preference; changing to a different propagation mechanism touches every atom's build method
- Widgets read `ScaffoldMotion.of(context).reducedMotion` for accessibility preferences; animations respect this by substituting zero-duration or fading instead of motion
- Default durations and easing curves live as static consts on the utility class: `ScaffoldMotion.durations.short`/`medium`/`long`, `ScaffoldMotion.curves.standard`/`decelerate`/`emphasized`

### Accessibility Depth
- **D-02:** Full a11y across all 28 atoms — **Reversibility:** costly — retrofitting Semantics/liveRegion/focus after widgets ship requires touching every atom's build method and widget tests
- Every interactive atom gets `Semantics` with appropriate `Role`, `label`, and `value`/`hint`
- Atoms that report changing values (NumericInput, FormattedValue, StatusIndicator, etc.) use `Semantics(liveRegion: true)` following the toast pattern
- Keyboard-navable atoms (Pressable, SelectableSurface, Draggable, DropTarget) must participate in focus order and respond to Enter/Space
- Focus outlines (ScaffoldFocusOutline) must be visible in all states — not just keyboard-focused but also when TalkBack/VoiceOver is active

### Theme Token Strategy
- **D-03:** Proactive token expansion in Wave 0 — **Reversibility:** one-way — once theme extensions are published, removing tokens would break consumers who adopted them; adding tokens is safe but changing existing ones requires a major version bump of the `frontend_scaffold` package
- Before any Wave 0 widgets ship, add these tokens to `ScaffoldPalette` and `ScaffoldDimens`:
  - **Palette:** focus ring color, skeleton base color, skeleton shimmer color, disabled overlay color, drag feedback background, drop zone highlight, drop zone rejected
  - **Dimens:** focus ring width, skeleton corner radius, disabled overlay opacity, drag handle size, minimum touch target (48), touch target padding
- Tokens use `copyWith`/`lerp` to match the existing `ThemeExtension` pattern
- Default values seeded from the existing dark-mode palette (surfaceElevated/borderSubtle-based darker/lighter variants)

### API Philosophy
- **D-04:** Pure composability — **Reversibility:** costly — changing from pure composability to convenience constructors is additive (no consumer breakage); the reverse would remove constructor signatures consumers depend on
- Each atom does exactly one thing: `ScaffoldSurface` renders background/border/shape/elevation (no content knowledge), `ScaffoldTouchTarget` enforces 48×48 hit area (no visual handling), `ScaffoldBadge` renders a dot/count/icon chip (no positioning)
- Consumers compose: `Stack` + `Positioned` + atom. The scaffold does not bake in a layout opinion
- If a composition pattern repeats across all three consumer apps, that's a template candidate — build-time codegen via Jinja2, not runtime composition in the atom
- No convenience constructors that compose multiple atoms (e.g., no `ScaffoldBadge.dot(child: icon, count: 3)` — the caller stacks and positions)

### Claude's Discretion
No areas deferred to Claude — all decisions explicitly made.

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scaffold Workstream
- `.planning/workstreams/scaffold/ROADMAP.md` — Phase 6 scope, wave definitions, success criteria, dependency layering
- `.planning/workstreams/scaffold/REQUIREMENTS.md` — SUB-01..03 requirements (completed Phase 5); WIDG-01..28 requirements for this phase
- `.planning/workstreams/scaffold/STATE.md` — Accumulated decisions, pending todos, consumer demand matrix
- `.planning/workstreams/scaffold/CONSUMERS.md` — Cross-app widget demand matrix (genius-tube, genius-ai-boss, GeniusWallet)

### Existing Codebase (read before writing any atom)
- `src/scaffold/lib/frontend_scaffold.dart` — Barrel export pattern; new atoms must follow this
- `src/scaffold/lib/theme/scaffold_palette.dart` — M3 ThemeExtension pattern for colors; tokens added to this class
- `src/scaffold/lib/theme/scaffold_dimens.dart` — M3 ThemeExtension pattern for dimensions; tokens added to this class
- `src/scaffold/lib/theme/scaffold_theme.dart` — `context.palette`/`context.dimens` extensions; atoms use these
- `src/scaffold/lib/utils/breakpoints.dart` — Responsive thresholds; Wave 0's ResponsiveVisibility uses these
- `src/scaffold/lib/components/action_button.dart` — Example of existing widget pattern (StatefulWidget, `context.palette`/`context.dimens`, `Theme.of(context).textTheme`)

### Template Infrastructure (read before Wave 3 composites)
- `src/scaffold/templates/components/card.dart.jinja2` — Template structure, slot pattern, variant conditionals, M3 widget usage
- `src/scaffold/templates/components/card_vars.json` — Fixture variable schema for template rendering

### Prior Phase
- `.planning/workstreams/scaffold/phases/05-scaffold-submodule-consolidation/05-05-SUMMARY.md` — Toast redesign decisions, ThemeExtension pattern established, a11y pattern (Semantics + liveRegion), dart analyze gate, CR-02..04 lifecycle fixes

## Existing Code Insights

### Reusable Assets
- **ScaffoldPalette** (15 semantic color tokens): extend with focus ring color, skeleton colors, disabled overlay, drag/drop feedback colors
- **ScaffoldDimens** (17 spacing/sizing tokens): extend with focus ring width, skeleton radius, touch target size, drag handle size, disabled opacity
- **ScaffoldBreakpoints**: static breakpoint thresholds (small=760, tablet=1200, medium=1644, large=1920) — Wave 0's ResponsiveVisibility consumes these
- **ScaffoldThemeX**: `BuildContext` extension providing `context.palette` and `context.dimens` — every atom uses this pattern
- **ScaffoldElevation**: elevation token class — consumed by Surface and card composite

### Established Patterns
- M3 `ThemeExtension<T>` with `copyWith`/`lerp` — all token classes follow this; new tokens must use the same pattern
- `StatefulWidget` + `SingleTickerProviderStateMixin` — existing animation pattern (ActionButton). ScaffoldMotion may provide a common TickerProvider mixin or extension
- `context.palette`/`context.dimens` lookups with `??` fallback — every widget resolves theme tokens this way
- Barrel export from `frontend_scaffold.dart` — every public widget gets a `library frontend_scaffold; export '...'` line
- Jinja2 `StrictUndefined` templates with `_vars.json` fixture files — template-generated composites and the 4 Wave 1 template candidates follow this
- `dart analyze --fatal-infos` gate — zero warnings required on all code paths

### Integration Points
- New atom files in `lib/components/` (flat directory — no subdirectories needed; 28 files is manageable)
- Template-generated composites in `templates/components/` with corresponding `_vars.json`
- All public classes exported from `lib/frontend_scaffold.dart` barrel
- Tests in `test/` matching the lib/ structure
- Example demos in `example/lib/demos/` (at minimum: a kitchen-sink demo showing each atom)
- Test harness uses `scaffoldThemeExtensions` list to register theme tokens (matches Phase 5 pattern)

## Specific Ideas

No specific visual references or "I want it like X" examples raised during discussion. Atoms follow Material 3 idioms and the dark-seeded ScaffoldPalette defaults established in Phase 5.

## Deferred Ideas

None — discussion stayed within phase scope.

---

*Phase: 6-Core UI Foundation*
*Context gathered: 2026-08-11*
