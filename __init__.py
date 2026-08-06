# frontend/scaffold — Jinja2 template engine for M3 UI codegen.
#
# This package provides a shared Jinja2 engine used by build-time scripts and
# CMake custom targets to render Dart/HTML/YAML from Jinja2 templates.
# Output files contain no Python/Jinja2 runtime dependencies.
#
# Usage:
#     from frontend.scaffold.engine import create_environment, render_template
