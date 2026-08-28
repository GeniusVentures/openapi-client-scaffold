# frontend/scaffold/templates/cpp

**DEPRECATED — legacy placeholder (Phase 7, D-14).**

C++ Cubit-style interface template authoring lives in the **consuming repo's
own templates tree** (its `--templates-dir` argument, surface-organized:
`admin/`, `pos/`, `storefront/`, `shared/`). The templates serve multiple
workstreams (frontend-templates, touch-pos, and future consumers), so each
consumer authors them in its own repo rather than in this submodule
(D-11/D-14).

This directory is retained only as a legacy placeholder to keep the loader
path reserved (SUB-02, D5-04) — do not author template content here.

The shared base contracts (`i_widget_store.hpp.jinja2`,
`i_widget_importer.hpp.jinja2`, `ffi_common.hpp.jinja2`) live under the
consuming tree's `shared/cpp/`; rendered output lands under the consuming
project's `--output-dir/<surface>/cpp/`. Rendering still goes through this
scaffold's engine (`tools/scaffold_codegen/engine.py`, Jinja2 with
`StrictUndefined`).
