# Scaffold Planning

This directory is the `frontend_scaffold` submodule's own planning record, owned by the
**scaffold** workstream. It travels with the submodule so every consuming repo —
genius-ai-boss, genius-tube, and any sibling project that adds this submodule — shares one
source of truth for what the scaffold is and what changed.

## Layout

```
.planning/
└── workstreams/
    └── scaffold/
        ├── REQUIREMENTS.md      # SUB-01..03 — the submodule's contract with consumers
        ├── ROADMAP.md           # Phase 5 (consolidation) anchor + scope boundary
        ├── STATE.md             # current position / session continuity
        └── phases/
            └── 05-scaffold-submodule-consolidation/   # Phase 5 artifacts
```

## Scope boundary

This workstream owns the submodule's **contents**: the `frontend_scaffold` Dart widget
package (`lib/`) and the `templates/` directory.

It does **not** own consuming-repo build orchestration (CMake pipeline,
`FLUTTER_TEMPLATE_STYLE`, generated-module drivers). That stays in each consumer's own
workstream (e.g. genius-ai-boss `frontend-templates`, Phases 6-8).

## Working in this repo

Run gsd-sdk / GSD commands with this submodule as the project root and `--ws scaffold`,
which routes planning to `.planning/workstreams/scaffold/`. The parent repo's
`frontend-templates` workstream retains the Phase 5 orchestration history (parent-side
plans) and continues to own Phases 6-8.

## Provenance

Extracted from `genius-ai-boss/.planning/workstreams/frontend-templates/` on 2026-08-09.
Phase 5 scaffold-facing artifacts were re-homed here with paths normalized to repo-relative.
