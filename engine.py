#!/usr/bin/env python3
"""
engine.py — Shared Jinja2 template engine for M3 UI codegen.

Provides a reusable rendering pipeline that any script or CMake target can
import.  Uses Jinja2's ``StrictUndefined`` so missing template variables
produce clear, actionable error messages (D-02).

Public API
----------
``create_environment(template_dirs) -> jinja2.Environment``
    Build a Jinja2 Environment with a multi-directory FileSystemLoader,
    StrictUndefined validation, and consistent whitespace settings.

``render_template(env, template_name, output_path, vars) -> None``
    Render a named template and write the result to *output_path*.

CLI
---
    python3 frontend/scaffold/engine.py \\
        --template base/m3_base_layout.jinja2 \\
        --output path/to/output.html \\
        --template-dir frontend/scaffold/templates/ \\
        --tokens frontend/scaffold/design_tokens.json \\
        --vars vars.json
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# Lazy import of jinja2 with clear error for bare environments
# (same pattern as generate_domain_modules.py lines 51-57)
# ---------------------------------------------------------------------------
try:
    import jinja2
except ImportError:  # pragma: no cover — exercised only on bare environments
    sys.stderr.write(
        "ERROR: jinja2 is required. Install with: pip install jinja2\n"
    )
    sys.exit(1)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def create_environment(template_dirs: list[str]) -> jinja2.Environment:
    """Construct a Jinja2 Environment with multi-directory template search.

    Parameters
    ----------
    template_dirs : list[str]
        One or more directories containing ``.jinja2`` template files.
        Directories are searched in order — the first match wins.

    Returns
    -------
    jinja2.Environment
        A configured Jinja2 environment with:
        - ``FileSystemLoader`` across all *template_dirs*
        - ``undefined=jinja2.StrictUndefined`` (T-01-02 mitigation: missing
          variables raise ``jinja2.UndefinedError`` with the variable name)
        - ``keep_trailing_newline=True``, ``trim_blocks=False``,
          ``lstrip_blocks=False`` (matching generate_domain_modules.py
          lines 973-976)

    Raises
    ------
    ValueError
        If *template_dirs* is empty.
    """
    if not template_dirs:
        raise ValueError("template_dirs must contain at least one directory")

    resolved_dirs: list[str] = []
    for d in template_dirs:
        path = str(Path(d).resolve())
        if not os.path.isdir(path):
            sys.stderr.write(f"WARNING: template directory not found: {path}\n")
            continue
        resolved_dirs.append(path)

    if not resolved_dirs:
        raise ValueError(
            f"No valid template directories found among: {template_dirs}"
        )

    return jinja2.Environment(
        loader=jinja2.FileSystemLoader(resolved_dirs),
        undefined=jinja2.StrictUndefined,
        keep_trailing_newline=True,
        trim_blocks=False,
        lstrip_blocks=False,
    )


def render_template(
    env: jinja2.Environment,
    template_name: str,
    output_path: str,
    vars: dict[str, Any],
) -> None:
    """Render a named template and write the result to *output_path*.

    Parameters
    ----------
    env : jinja2.Environment
        A Jinja2 environment (obtained from ``create_environment()``).
    template_name : str
        Template name relative to one of the search directories
        (e.g. ``"base/m3_base_layout.jinja2"``).
    output_path : str
        Filesystem path where the rendered output is written.  Parent
        directories are created if they do not exist.
    vars : dict[str, Any]
        Flat dict of template variables passed to ``template.render(**vars)``.

    Raises
    ------
    jinja2.TemplateNotFound
        If *template_name* cannot be found in any search directory.
    jinja2.UndefinedError
        If the template references an undefined variable (StrictUndefined).
    OSError
        If *output_path* cannot be written.
    """
    _validate_template_name(template_name)

    template = env.get_template(template_name)
    rendered = template.render(**vars)

    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(rendered, encoding="utf-8")


# ---------------------------------------------------------------------------
# Threat mitigation: T-01-01 — path traversal guard
# ---------------------------------------------------------------------------

_ABSOLUTE_PATH_RE = r"^[A-Za-z]:[/\\]" if sys.platform == "win32" else r"^/"


def _validate_template_name(template_name: str) -> None:
    """Reject template names that attempt path traversal or absolute paths.

    T-01-01 mitigation: template names come from user-supplied input
    (CLI ``--template`` or a build-config data source).  We reject any
    name containing ``..`` segments, leading ``/``, or a drive-letter
    prefix to prevent escaping the FileSystemLoader sandbox.

    Raises
    ------
    ValueError
        If *template_name* contains ``..`` or is an absolute path.
    """
    if ".." in template_name:
        raise ValueError(
            f"Invalid template name: '{template_name}' contains '..' "
            f"(path traversal not allowed)"
        )
    if os.path.isabs(template_name):
        raise ValueError(
            f"Invalid template name: '{template_name}' is an absolute path "
            f"(must be relative to a template directory)"
        )


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    """CLI entry point for ad-hoc template rendering.

    Returns
    -------
    int
        0 on success, 1 on error (template not found, undefined variable,
        invalid arguments, etc.).
    """
    parser = argparse.ArgumentParser(
        description="Render a Jinja2 template to a file."
    )
    parser.add_argument(
        "--template",
        required=True,
        help="Template name relative to a template directory "
             "(e.g. base/m3_base_layout.jinja2)",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output file path (parent directories are created if needed)",
    )
    parser.add_argument(
        "--vars",
        default=None,
        help="Path to a JSON file containing template variables as a flat dict",
    )
    parser.add_argument(
        "--tokens",
        default=None,
        help="Path to a JSON file containing M3 design tokens "
             "(e.g. design_tokens.json)",
    )
    parser.add_argument(
        "--template-dir",
        action="append",
        dest="template_dirs",
        required=True,
        help="Directory containing .jinja2 templates (repeatable)",
    )
    args = parser.parse_args(argv)

    template_vars: dict[str, Any] = {}

    # --- Load design tokens (loaded first; vars merge on top) -----------------
    if args.tokens:
        try:
            tokens_path = Path(args.tokens)
            tokens_data = json.loads(tokens_path.read_text(encoding="utf-8"))
            if not isinstance(tokens_data, dict):
                sys.stderr.write(
                    f"ERROR: tokens file '{args.tokens}' must contain a JSON object\n"
                )
                return 1
            template_vars["tokens"] = tokens_data
        except json.JSONDecodeError as exc:
            sys.stderr.write(
                f"ERROR: invalid JSON in tokens file '{args.tokens}': {exc}\n"
            )
            return 1
        except FileNotFoundError:
            sys.stderr.write(
                f"ERROR: tokens file not found: {args.tokens}\n"
            )
            return 1

    # --- Load template variables (merges on top of tokens) --------------------
    if args.vars:
        try:
            vars_path = Path(args.vars)
            vars_data = json.loads(vars_path.read_text(encoding="utf-8"))
            if not isinstance(vars_data, dict):
                sys.stderr.write(
                    f"ERROR: vars file '{args.vars}' must contain a JSON object\n"
                )
                return 1
            template_vars.update(vars_data)
        except json.JSONDecodeError as exc:
            sys.stderr.write(
                f"ERROR: invalid JSON in vars file '{args.vars}': {exc}\n"
            )
            return 1
        except FileNotFoundError:
            sys.stderr.write(f"ERROR: vars file not found: {args.vars}\n")
            return 1

    # --- Create environment and render --------------------------------------
    try:
        env = create_environment(args.template_dirs)
        render_template(env, args.template, args.output, template_vars)
    except jinja2.TemplateNotFound as exc:
        sys.stderr.write(f"ERROR: template not found: {exc}\n")
        return 1
    except jinja2.UndefinedError as exc:
        sys.stderr.write(f"ERROR: undefined variable: {exc}\n")
        return 1
    except ValueError as exc:
        sys.stderr.write(f"ERROR: {exc}\n")
        return 1
    except OSError as exc:
        sys.stderr.write(f"ERROR: cannot write output: {exc}\n")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
