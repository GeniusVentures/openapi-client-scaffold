#!/usr/bin/env python3
"""
generate_m3_tokens_css.py -- Read design_tokens.json, write m3_tokens.css.

Outputs CSS custom properties for all four M3 token categories (color,
typography, shape, elevation) with light and dark color scheme variants.

Usage
-----
    python3 generate_m3_tokens_css.py \\
        --tokens design_tokens.json \\
        --output generated/styles/m3_tokens.css

CLI
---
    --tokens  PATH    Required.  Path to design_tokens.json.
    --output  PATH    Required.  Path for the generated .css file.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Kebab-case conversion
# ---------------------------------------------------------------------------

def _to_kebab_case(camel: str) -> str:
    """Convert a camelCase string to kebab-case.

    Inserts a hyphen before each uppercase letter (after the first character),
    then lowercases the entire string.  Handles consecutive uppercase letters
    as a single block (e.g. ``"onPrimary"`` → ``"on-primary"``,
    ``"surfaceVariant"`` → ``"surface-variant"``).

    Parameters
    ----------
    camel : str
        A camelCase string (no existing hyphens, no underscores).

    Returns
    -------
    str
        The kebab-case equivalent.
    """
    if not camel:
        return ""

    kebab: list[str] = [camel[0].lower()]
    for i, ch in enumerate(camel[1:], start=1):
        if ch.isupper():
            # Insert hyphen before uppercase unless previous char was also
            # uppercase (e.g. "URL" stays "url", not "u-r-l").
            prev = camel[i - 1]
            if not prev.isupper():
                kebab.append("-")
            kebab.append(ch.lower())
        else:
            kebab.append(ch)
    return "".join(kebab)


# ---------------------------------------------------------------------------
# CSS generation
# ---------------------------------------------------------------------------

def _emit_color_roles(roles: dict, buf: list[str], indent: int) -> None:
    """Emit ``--md-sys-color-*`` custom properties from the color roles dict.

    Parameters
    ----------
    roles : dict
        Each key is a role name (camelCase), value is ``{"light": hex, "dark": hex}``.
    buf : list[str]
        Output buffer to append lines to.
    indent : int
        Number of spaces to indent each property line.
    """
    prefix = " " * indent
    for role, values in sorted(roles.items()):
        css_name = f"--md-sys-color-{_to_kebab_case(role)}"
        light = values.get("light", "")
        buf.append(f"{prefix}{css_name}: {light};")


def _emit_color_roles_dark(roles: dict, buf: list[str], indent: int) -> None:
    """Emit ``--md-sys-color-*`` dark scheme overrides.

    Parameters
    ----------
    roles : dict
        Same shape as ``_emit_color_roles``.
    buf : list[str]
        Output buffer.
    indent : int
        Indent depth inside the ``:root`` of the dark media query.
    """
    prefix = " " * indent
    for role, values in sorted(roles.items()):
        css_name = f"--md-sys-color-{_to_kebab_case(role)}"
        dark = values.get("dark", "")
        buf.append(f"{prefix}{css_name}: {dark};")


def _emit_typography(scale: dict, buf: list[str], indent: int) -> None:
    """Emit ``--md-sys-typography-*-*`` custom properties.

    Parameters
    ----------
    scale : dict
        Keys are scale names (e.g. "display", "headline"); each value is a dict
        with keys "size", "weight", "letterSpacing", "lineHeight".
    buf, indent : as above.
    """
    prefix = " " * indent
    # Match on original camelCase property names (before kebab conversion) to
    # decide whether a value needs "px" units appended.
    unitful = {"size", "letterspacing", "lineheight"}
    for scale_name, props in sorted(scale.items()):
        for prop_name, value in sorted(props.items()):
            css_scale = _to_kebab_case(scale_name)
            css_prop = _to_kebab_case(prop_name)
            css_name = f"--md-sys-typography-{css_scale}-{css_prop}"
            if prop_name.lower() in unitful:
                buf.append(f"{prefix}{css_name}: {value}px;")
            else:
                buf.append(f"{prefix}{css_name}: {value};")


def _emit_shape(corner: dict, buf: list[str], indent: int) -> None:
    """Emit ``--md-sys-shape-*`` custom properties.

    Parameters
    ----------
    corner : dict
        Keys are size names (camelCase, e.g. "extraSmall"); values are numeric px.
    """
    prefix = " " * indent
    for size_name, value in sorted(corner.items()):
        css_name = f"--md-sys-shape-{_to_kebab_case(size_name)}"
        buf.append(f"{prefix}{css_name}: {value}px;")


def _emit_elevation(elevation: dict, buf: list[str], indent: int) -> None:
    """Emit ``--md-sys-elevation-*`` custom properties.

    Each level produces two custom properties:
    - ``--md-sys-elevation-{level}: <shadow>`` — shadow value, "none" for empty.
    - ``--md-sys-elevation-{level}-tint: <opacity>`` — surface tint opacity.

    Parameters
    ----------
    elevation : dict
        Keys like "level0".."level5"; each value has "shadow" (str) and
        "surfaceTint" (float).
    """
    prefix = " " * indent
    for level_name, values in sorted(elevation.items()):
        shadow = values.get("shadow", "")
        surface_tint = values.get("surfaceTint", 0.0)
        css_name = f"--md-sys-elevation-{level_name}"

        if shadow == "":
            buf.append(f"{prefix}{css_name}: none;")
        else:
            buf.append(f"{prefix}{css_name}: {shadow};")

        buf.append(f"{prefix}{css_name}-tint: {surface_tint};")


def generate_css(tokens: dict) -> str:
    """Generate the full m3_tokens.css content from a parsed token dict.

    Parameters
    ----------
    tokens : dict
        Parsed design_tokens.json data.

    Returns
    -------
    str
        Complete CSS content as a string.
    """
    lines: list[str] = []

    # Comment header
    lines.append(
        "/* Auto-generated from design_tokens.json "
        "by generate_m3_tokens_css.py -- do not edit by hand. */"
    )
    lines.append("")

    color = tokens.get("color", {}).get("roles", {})
    typography = tokens.get("typography", {}).get("scale", {})
    shape = tokens.get("shape", {}).get("corner", {})
    elevation = tokens.get("elevation", {})

    # -- Light scheme (:root) -----------------------------------------------
    lines.append(":root {")
    _emit_color_roles(color, lines, indent=4)
    lines.append("")
    _emit_typography(typography, lines, indent=4)
    lines.append("")
    _emit_shape(shape, lines, indent=4)
    lines.append("")
    _emit_elevation(elevation, lines, indent=4)
    lines.append("}")

    # -- Dark scheme --------------------------------------------------------
    if color:
        lines.append("")
        lines.append("@media (prefers-color-scheme: dark) {")
        lines.append("    :root {")
        _emit_color_roles_dark(color, lines, indent=8)
        lines.append("    }")
        lines.append("}")

    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    """CLI entry point.

    Returns
    -------
    int
        0 on success, 1 on error.
    """
    parser = argparse.ArgumentParser(
        description="Generate M3 design tokens CSS custom properties."
    )
    parser.add_argument(
        "--tokens",
        required=True,
        help="Path to design_tokens.json",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path for the generated m3_tokens.css file",
    )
    args = parser.parse_args(argv)

    # --- Load and parse tokens JSON ----------------------------------------
    tokens_path = Path(args.tokens)
    try:
        tokens_data = json.loads(tokens_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        sys.stderr.write(f"ERROR: tokens file not found: {args.tokens}\n")
        return 1
    except json.JSONDecodeError as exc:
        sys.stderr.write(
            f"ERROR: invalid JSON in tokens file: {args.tokens}: {exc}\n"
        )
        return 1

    if not isinstance(tokens_data, dict):
        sys.stderr.write(
            f"ERROR: tokens file must contain a JSON object: {args.tokens}\n"
        )
        return 1

    # --- Generate CSS -----------------------------------------------------
    css = generate_css(tokens_data)

    # --- Write output -----------------------------------------------------
    output_path = Path(args.output)
    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(css, encoding="utf-8")
    except OSError as exc:
        sys.stderr.write(f"ERROR: cannot write output file: {exc}\n")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
