# frontend/scaffold/templates/cpp

**DEPRECATED — legacy placeholder (Phase 7, D-14).**

C++ Cubit-style interface template authoring has moved to the **parent repo**
at `frontend/templates/<surface>/cpp/` (surface-organized: `admin/`, `pos/`,
`storefront/`, `shared/`). The templates serve multiple workstreams
(frontend-templates, touch-pos, and future consumers), so they live in the
parent repo rather than this submodule (D-11/D-14). See the parent repo's
`frontend/templates/README.md` for the authoritative layout.

This directory is retained only as a legacy placeholder to keep the loader
path reserved (SUB-02, D5-04) — do not author template content here.

The shared base contracts (`i_widget_store.hpp.jinja2`,
`i_widget_importer.hpp.jinja2`, `ffi_common.hpp.jinja2`) live at
`frontend/templates/shared/cpp/` in the parent repo; rendered output lands at
`frontend/generated/<surface>/cpp/`. Rendering still goes through this
scaffold's engine (`tools/scaffold_codegen/engine.py`, Jinja2 with
`StrictUndefined`).
