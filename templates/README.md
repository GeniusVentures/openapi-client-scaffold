# frontend/scaffold/templates

Shared scaffolding templates for the openapi-client-scaffold submodule.
Consumable by any project that adds the scaffold as a submodule.

## Subtrees

- ``base/`` — Base M3 layout templates (e.g., ``m3_base_layout.jinja2``).
- ``components/`` — Generic M3 component template sets: ``card``,
  ``data_table``, ``form_dialog``, ``navigation``, ``search_bar``, ``state``.
  Each set has ``.dart.jinja2``, ``.css.jinja2``, ``.html.jinja2``, and a
  ``_vars.json`` variables file.
- ``cpp/`` — Placeholder for C++ Cubit-style interface templates (Phase 7).
- Module-scaffolding jinja2 files — ``module.dart.jinja2``,
  ``pubspec.yaml.jinja2``, ``api_provider.dart.jinja2``,
  ``provider.dart.jinja2``, ``form_screen.dart.jinja2``,
  ``list_screen.dart.jinja2`` — consumed by
  ``frontend/scripts/generate_domain_modules.py``.
- Identity client API templates — special-cased, remain identity-specific.

## Design principle

This directory consolidates **generic, reusable** templates shared across
all projects. Project-specific screens stay in the consuming project's own
templates directory. Renderers use a multi-directory
``jinja2.FileSystemLoader`` over both locations; the first match wins, so a
project can shadow a scaffold template by placing its own file with the same
relative path earlier in the loader path list.

Identity templates are special-cased: they remain identity-specific because
the identity submodule is autonomous, with its own build pipeline and API
spec (``json/identity_openapi.json``).

## Cross-reference

- ``../tools/scaffold_codegen/engine.py`` — Jinja2 rendering engine that
  consumes these templates.
- ``../tools/scaffold_codegen/generators/`` — per-widget-family drivers that
  render ``components/*.jinja2`` into the committed ``lib/components/`` files.
- ``../design_tokens.json`` — Material 3 design tokens referenced by the
  templates.
- ``frontend/templates/`` — project-specific residue (screens and other
  non-shared templates that did not move into the scaffold).
