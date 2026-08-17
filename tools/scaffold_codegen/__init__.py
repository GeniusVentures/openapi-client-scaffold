"""scaffold_codegen — Jinja2 template engine and generators for M3 UI codegen.

Build-time only. The Dart/HTML/YAML output this package renders carries no
Python or Jinja2 runtime dependency.

Entry points (all runnable as ``python3 -m``):
    scaffold_codegen.engine                Ad-hoc single-template render.
    scaffold_codegen.m3_tokens_css         Design tokens -> CSS custom properties.
    scaffold_codegen.api_clients           OpenAPI specs -> typed API clients.
    scaffold_codegen.generators.<name>     Widget-family generators.

The path constants below are the single source of truth for repo-relative
locations, replacing the per-script ``ROOT = Path(__file__).parent.parent``
arithmetic that each generator previously carried its own copy of.
"""

from pathlib import Path

#: Repository root (this file lives at <root>/tools/scaffold_codegen/__init__.py).
REPO_ROOT = Path(__file__).resolve().parents[2]

#: Jinja2 template search root, passed to ``engine.create_environment()``.
TEMPLATES_DIR = REPO_ROOT / "templates"

#: M3 design token single source of truth.
DESIGN_TOKENS = REPO_ROOT / "design_tokens.json"

#: Destination for generated Dart widgets (committed; drift-checked).
LIB_COMPONENTS_DIR = REPO_ROOT / "lib" / "components"

__all__ = [
    "REPO_ROOT",
    "TEMPLATES_DIR",
    "DESIGN_TOKENS",
    "LIB_COMPONENTS_DIR",
]
