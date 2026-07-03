# frontend/scaffold/templates

Identity client API templates only — special-cased, matching the backend
scaffold pattern (``backend/scaffold/``).  These templates generate
identity-specific Dart client code for the identity domain.

## Design principle

Identity templates are kept separate from the general M3 UI templates in
``frontend/templates/`` because identity is an autonomous submodule with its
own build pipeline and API spec (``json/identity_openapi.json``).  General
UI component templates should **not** go here.

## Cross-reference

See ``frontend/templates/`` for all general and M3 UI component templates.
