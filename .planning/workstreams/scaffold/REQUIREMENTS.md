---
workstream: scaffold
milestone: v1.0
status: active
---

# Requirements: Scaffold

The `frontend_scaffold` submodule (openapi-client-scaffold) is the single shared source for
GeniusWallet bloc widgets and genius-tube C++ interface templates, consumable by any
consuming repo via submodule. These requirements define the submodule's contract with its
consumers. They were originally tracked as SUB-01..03 in the parent's `frontend-templates`
workstream (Phase 5); they are extracted here so the scaffold owns its own planning record
and sibling projects (e.g. genius-tube) share it.

## Requirements

### Submodule (SUB)

- [x] **SUB-01**: GeniusWallet bloc-based widgets are copied into this submodule as a shared, consumable Flutter package (`frontend_scaffold`), importable by any Flutter project without copying files
- [x] **SUB-02**: genius-tube generic C++ Cubit-style interface templates are pre-staged in `templates/` alongside the existing identity templates (placeholder carved out; actual C++ template content is downstream consumer scope)
- [x] **SUB-03**: this submodule is consumable as a pinned git submodule at the same commit across consuming repos (genius-ai-boss, genius-tube) so all build against the same widget/template sources from one origin

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| SUB-01 | Phase 5 | Complete (05-03, hardened by review + 05-05) |
| SUB-02 | Phase 5 | Complete (05-04 placeholder) |
| SUB-03 | Phase 5 | Complete (pinned submodule; per-consumer wiring is consumer scope) |

## Notes

- **Provenance**: extracted from `genius-ai-boss/.planning/workstreams/frontend-templates/REQUIREMENTS.md` (SUB-01..03) on 2026-08-09. The parent workstream retains its own copy as the orchestration record for Phases 5-8.
- **Scope boundary**: this workstream owns the submodule's *contents* (widget package, templates). Parent-side build orchestration (CMake pipeline, `FLUTTER_TEMPLATE_STYLE`, generated-module drivers) is owned by the consuming repo's workstream, not here.
