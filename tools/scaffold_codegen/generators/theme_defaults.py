#!/usr/bin/env python3
"""Generate the default values of the scaffold theme extensions from design_tokens.json.

The ``scaffold`` namespace of the repo token file is the source of truth. Each
region listed in ``REGIONS`` is rendered through a template chosen by its style
and spliced between the ``GENERATED`` / ``END GENERATED`` marker comments in the
matching file in ``lib/theme/``. An ``args`` region holds ``name: literal,``
lines inside a const constructor call
(``templates/theme/const_args.dart.jinja2``); a ``params`` region holds
``this.name = literal,`` lines inside a constructor parameter list
(``templates/theme/const_params.dart.jinja2``); a ``null`` token in a params region renders
``this.name,`` for a nullable field, and an args region rejects it. Everything outside the markers is
left as written. Target files: scaffold_palette.dart, scaffold_dimens.dart,
scaffold_shadows.dart, scaffold_motion_theme.dart, scaffold_typography.dart,
scaffold_color_roles.dart, scaffold_gradients.dart, scaffold_shapes.dart.

The CLI always reads the repo ``design_tokens.json``; a CMake ``DESIGN_TOKENS``
override never feeds committed Dart.

Usage:
    python3 -m scaffold_codegen.generators.theme_defaults [--check]

Exit status is 0 when the files are written or already clean, and 1 on drift
(``--check``) or a token error.
"""
from __future__ import annotations

import argparse
import decimal
import json
import re
import sys
from collections.abc import Callable
from pathlib import Path

from scaffold_codegen import DESIGN_TOKENS, LIB_THEME_DIR, REPO_ROOT, TEMPLATES_DIR
from scaffold_codegen.engine import create_environment

TEMPLATE_NAMES = {
    "args": "theme/const_args.dart.jinja2",
    "params": "theme/const_params.dart.jinja2",
}

DEFAULTS_SOURCE = "design_tokens.json"

BEGIN_MARKER = "    // GENERATED from {source} {id}. Do not edit."
END_MARKER = "    // END GENERATED {id}"

#: (file name in LIB_THEME_DIR, token path, literal kind, style). Row order is splice order.
REGIONS: tuple[tuple[str, tuple[str, ...], str, str], ...] = (
    ("scaffold_palette.dart", ("scaffold", "palette", "dark"), "color", "args"),
    ("scaffold_palette.dart", ("scaffold", "palette", "light"), "color", "args"),
    ("scaffold_dimens.dart", ("scaffold", "dimens"), "double", "args"),
    ("scaffold_shadows.dart", ("scaffold", "shadows", "dark"), "shadows", "params"),
    ("scaffold_shadows.dart", ("scaffold", "shadows", "light"), "shadows", "args"),
    ("scaffold_motion_theme.dart", ("scaffold", "motion", "durations"), "duration", "params"),
    ("scaffold_motion_theme.dart", ("scaffold", "motion", "curves"), "curve", "params"),
    ("scaffold_typography.dart", ("scaffold", "typography", "textStyles"), "textStyle", "params"),
    ("scaffold_typography.dart", ("scaffold", "typography", "fontFamilies"), "fontFamily", "params"),
    ("scaffold_color_roles.dart", ("scaffold", "colorRoles", "dark"), "color", "params"),
    ("scaffold_color_roles.dart", ("scaffold", "colorRoles", "light"), "color", "args"),
    ("scaffold_gradients.dart", ("scaffold", "gradients"), "gradient", "params"),
    ("scaffold_shapes.dart", ("scaffold", "shapes"), "double", "params"),
)

_DOUBLE_RE = re.compile(r"-?\d+\.\d+")
_NAME_RE = re.compile(r"[a-z][A-Za-z0-9]*")
_ARGB_RE = re.compile(r"0x[0-9A-F]{8}")
_DART_REF_RE = re.compile(r"ScaffoldColors\.[a-z][A-Za-z0-9]*")
# A list literal or constructor call is only a constant default value with an explicit `const`.
_NEEDS_CONST_RE = re.compile(r"\[|[A-Z][A-Za-z0-9]*\(")


class ThemeTokenError(ValueError):
    """A token file or target Dart file cannot be turned into generated output."""


def region_id(path: tuple[str, ...]) -> str:
    return ".".join(path)


def load_tokens(path: Path) -> dict:
    """Parse the token file, keeping the exact digits of every JSON number."""
    text = path.read_bytes().decode("utf-8")
    tokens = json.loads(text, parse_float=decimal.Decimal)
    if not isinstance(tokens, dict) or "scaffold" not in tokens:
        raise ThemeTokenError(f"{path}: missing top-level 'scaffold' key")
    return tokens


def dart_double(name: str, value: object) -> str:
    """Return the Dart double literal for a token, written exactly as in the token file."""
    if isinstance(value, decimal.Decimal) and _DOUBLE_RE.fullmatch(str(value)):
        return str(value)
    raise ThemeTokenError(f"{name}: expected a decimal number such as 20.0, got {value!r}")


def dart_color(name: str, value: object) -> str:
    """Return the Dart expression for a color token.

    A ``0xAARRGGBB`` string becomes ``Color(...)``. An object holding ``value`` and
    ``dartRef`` is emitted as the ScaffoldColors reference; ``value`` is the resolved ARGB the
    Dart parity test checks the reference against.
    """
    if isinstance(value, str) and _ARGB_RE.fullmatch(value):
        return f"Color({value})"
    if (
        isinstance(value, dict)
        and set(value) == {"value", "dartRef"}
        and isinstance(value["value"], str)
        and _ARGB_RE.fullmatch(value["value"])
        and isinstance(value["dartRef"], str)
        and _DART_REF_RE.fullmatch(value["dartRef"])
    ):
        return value["dartRef"]
    raise ThemeTokenError(
        f"{name}: expected an uppercase 0xAARRGGBB string or a {{value, dartRef}} object, got {value!r}"
    )


_SHADOW_KEYS = {"color", "blurRadius", "offset"}


def dart_shadows(name: str, value: object) -> str:
    """Return a Dart ``List<BoxShadow>`` literal for a list of shadow objects."""
    if not isinstance(value, list):
        raise ThemeTokenError(f"{name}: expected a list of shadow objects, got {value!r}")
    entries = []
    for index, entry in enumerate(value):
        label = f"{name}[{index}]"
        if not isinstance(entry, dict) or set(entry) != _SHADOW_KEYS:
            raise ThemeTokenError(f"{label}: expected exactly the keys {sorted(_SHADOW_KEYS)}, got {entry!r}")
        color = entry["color"]
        if not (isinstance(color, str) and _ARGB_RE.fullmatch(color)):
            raise ThemeTokenError(f"{label}.color: expected an uppercase 0xAARRGGBB string, got {color!r}")
        offset = entry["offset"]
        if not (isinstance(offset, list) and len(offset) == 2):
            raise ThemeTokenError(f"{label}.offset: expected a list of two numbers, got {offset!r}")
        blur = dart_double(f"{label}.blurRadius", entry["blurRadius"])
        dx = dart_double(f"{label}.offset", offset[0])
        dy = dart_double(f"{label}.offset", offset[1])
        entries.append(
            f"BoxShadow(color: Color({color}), blurRadius: {blur}, offset: Offset({dx}, {dy}))"
        )
    return "[" + ", ".join(entries) + "]"


_CURVE_NAME_RE = re.compile(r"Curves\.[a-z][A-Za-z0-9]*")


def dart_duration(name: str, value: object) -> str:
    """Return ``Duration(milliseconds: n)`` for a non-negative integer of milliseconds."""
    if isinstance(value, int) and not isinstance(value, bool) and value >= 0:
        return f"Duration(milliseconds: {value})"
    raise ThemeTokenError(f"{name}: expected a non-negative integer of milliseconds, got {value!r}")


def dart_curve(name: str, value: object) -> str:
    """Return a ``Curves.<name>`` reference or ``Cubic(a, b, c, d)`` for four control points."""
    if isinstance(value, str) and _CURVE_NAME_RE.fullmatch(value):
        return value
    if isinstance(value, list) and len(value) == 4:
        points = ", ".join(dart_double(f"{name}[{i}]", v) for i, v in enumerate(value))
        return f"Cubic({points})"
    raise ThemeTokenError(
        f"{name}: expected a 'Curves.<name>' string or four cubic control points, got {value!r}"
    )


_FONT_FAMILY_RE = re.compile(r"[A-Za-z][A-Za-z0-9 _-]*")
_FONT_WEIGHTS = frozenset(range(100, 1000, 100))
_TEXT_STYLE_KEYS = ("fontFamily", "fontSize", "fontWeight", "letterSpacing", "lineHeight", "tabularFigures")


def dart_font_family(name: str, value: object) -> str:
    """Return a single-quoted Dart string for a font family name."""
    if isinstance(value, str) and _FONT_FAMILY_RE.fullmatch(value):
        return f"'{value}'"
    raise ThemeTokenError(f"{name}: expected a font family name such as 'Roboto', got {value!r}")


def dart_text_style(name: str, value: object) -> str:
    """Return a ``TextStyle(...)`` literal; the keys are emitted in a fixed order.

    ``lineHeight`` is in px and becomes ``height: lineHeight / fontSize``, the multiplier Flutter
    expects. ``tabularFigures`` must be ``true``.
    """
    if not isinstance(value, dict) or not set(value) <= set(_TEXT_STYLE_KEYS):
        raise ThemeTokenError(
            f"{name}: expected an object with keys from {list(_TEXT_STYLE_KEYS)}, got {value!r}"
        )
    parts = []
    for key in _TEXT_STYLE_KEYS:
        if key not in value:
            continue
        label = f"{name}.{key}"
        entry = value[key]
        if key == "fontFamily":
            parts.append(f"{key}: {dart_font_family(label, entry)}")
        elif key == "fontWeight":
            if not (isinstance(entry, int) and not isinstance(entry, bool) and entry in _FONT_WEIGHTS):
                raise ThemeTokenError(f"{label}: expected one of 100, 200, ..., 900, got {entry!r}")
            parts.append(f"{key}: FontWeight.w{entry}")
        elif key == "lineHeight":
            if "fontSize" not in value:
                raise ThemeTokenError(f"{label}: a line height needs a fontSize to divide by")
            line_height = dart_double(label, entry)
            parts.append(f"height: {line_height} / {dart_double(f'{name}.fontSize', value['fontSize'])}")
        elif key == "tabularFigures":
            if entry is not True:
                raise ThemeTokenError(f"{label}: expected true, got {entry!r}")
            parts.append("fontFeatures: [FontFeature.tabularFigures()]")
        else:
            parts.append(f"{key}: {dart_double(label, entry)}")
    return f"TextStyle({', '.join(parts)})"


_ALIGNMENTS = (
    "topLeft",
    "topCenter",
    "topRight",
    "centerLeft",
    "center",
    "centerRight",
    "bottomLeft",
    "bottomCenter",
    "bottomRight",
)
_LINEAR_GRADIENT_KEYS = frozenset({"type", "begin", "end", "colors", "stops"})
_RADIAL_GRADIENT_KEYS = frozenset({"type", "center", "radius", "colors", "stops"})


def _gradient_alignment(label: str, value: object) -> str:
    if isinstance(value, str) and value in _ALIGNMENTS:
        return f"Alignment.{value}"
    raise ThemeTokenError(f"{label}: expected one of {list(_ALIGNMENTS)}, got {value!r}")


def _gradient_colors(label: str, value: object) -> str:
    if not (isinstance(value, list) and len(value) >= 2):
        raise ThemeTokenError(f"{label}: expected a list of at least two 0xAARRGGBB strings, got {value!r}")
    for color in value:
        if not (isinstance(color, str) and _ARGB_RE.fullmatch(color)):
            raise ThemeTokenError(f"{label}: expected uppercase 0xAARRGGBB strings, got {color!r}")
    return "[" + ", ".join(f"Color({color})" for color in value) + "]"


def _gradient_stops(label: str, value: object, count: int) -> str:
    if not (isinstance(value, list) and len(value) == count):
        raise ThemeTokenError(f"{label}: expected {count} stops, one per color, got {value!r}")
    previous = decimal.Decimal(0)
    for index, stop in enumerate(value):
        dart_double(f"{label}[{index}]", stop)
        if not previous <= stop <= 1:
            raise ThemeTokenError(f"{label}: stops must not decrease and must stay within 1.0, got {value!r}")
        previous = stop
    return "[" + ", ".join(str(stop) for stop in value) + "]"


def dart_gradient(name: str, value: object) -> str | None:
    """Return a ``LinearGradient(...)`` or ``RadialGradient(...)`` literal; None for an unset gradient."""
    if value is None:
        return None
    kind = value.get("type") if isinstance(value, dict) else None
    allowed = {"linear": _LINEAR_GRADIENT_KEYS, "radial": _RADIAL_GRADIENT_KEYS}.get(str(kind))
    if allowed is None or not set(value) <= allowed or "colors" not in value:
        raise ThemeTokenError(
            f"{name}: expected a null, linear or radial gradient object with known keys, got {value!r}"
        )
    parts = []
    if kind == "linear":
        for key in ("begin", "end"):
            if key not in value:
                raise ThemeTokenError(f"{name}: a linear gradient needs {key!r}, got {value!r}")
            parts.append(f"{key}: {_gradient_alignment(f'{name}.{key}', value[key])}")
    else:
        center = value.get("center")
        if not (isinstance(center, list) and len(center) == 2):
            raise ThemeTokenError(f"{name}.center: expected a list of two numbers, got {center!r}")
        x = dart_double(f"{name}.center", center[0])
        y = dart_double(f"{name}.center", center[1])
        parts.append(f"center: Alignment({x}, {y})")
        if "radius" not in value:
            raise ThemeTokenError(f"{name}: a radial gradient needs 'radius', got {value!r}")
        parts.append(f"radius: {dart_double(f'{name}.radius', value['radius'])}")
    colors = _gradient_colors(f"{name}.colors", value["colors"])
    parts.append(f"colors: {colors}")
    if "stops" in value:
        parts.append(f"stops: {_gradient_stops(f'{name}.stops', value['stops'], len(value['colors']))}")
    constructor = "LinearGradient" if kind == "linear" else "RadialGradient"
    return f"{constructor}({', '.join(parts)})"


_LITERAL_ENCODERS: dict[str, Callable[[str, object], str | None]] = {
    "double": dart_double,
    "color": dart_color,
    "shadows": dart_shadows,
    "duration": dart_duration,
    "curve": dart_curve,
    "textStyle": dart_text_style,
    "fontFamily": dart_font_family,
    "gradient": dart_gradient,
}


def _region_entries(tokens: dict, path: tuple[str, ...]) -> dict:
    node: object = tokens
    for key in path:
        if not isinstance(node, dict) or key not in node:
            raise ThemeTokenError(f"{region_id(path)}: token path does not resolve to an object")
        node = node[key]
    if not isinstance(node, dict):
        raise ThemeTokenError(f"{region_id(path)}: token path does not resolve to an object")
    return node


def _splice(text: str, file_name: str, source: str, rid: str, body: str) -> str:
    begin = BEGIN_MARKER.format(source=source, id=rid)
    end = END_MARKER.format(id=rid)
    lines = text.split("\n")
    begins = [i for i, line in enumerate(lines) if line == begin]
    ends = [i for i, line in enumerate(lines) if line == end]
    if len(begins) != 1 or len(ends) != 1 or begins[0] >= ends[0]:
        raise ThemeTokenError(
            f"{file_name}: region {rid} needs exactly one begin marker before exactly one end marker"
        )
    return "\n".join(lines[: begins[0] + 1] + body.split("\n")[:-1] + lines[ends[0] :])


def render_regions(
    tokens_path: Path,
    theme_dir: Path,
    regions: tuple[tuple[str, tuple[str, ...], str, str], ...],
    source: str,
) -> dict[Path, str]:
    """Return the full regenerated text of every file named in ``regions``, keyed by path.

    A region's file name is relative to ``theme_dir`` and may contain a subdirectory. ``source``
    is the token file name written into the begin markers.
    """
    tokens = load_tokens(tokens_path)
    environment = create_environment([str(TEMPLATES_DIR)])
    templates = {style: environment.get_template(name) for style, name in TEMPLATE_NAMES.items()}

    file_names = list(dict.fromkeys(row[0] for row in regions))
    rendered: dict[Path, str] = {}
    for file_name in file_names:
        target = theme_dir / file_name
        text = target.read_bytes().decode("utf-8").replace("\r\n", "\n")
        for row_file, path, kind, style in regions:
            if row_file != file_name:
                continue
            rid = region_id(path)
            encode = _LITERAL_ENCODERS[kind]
            args = []
            for name, value in _region_entries(tokens, path).items():
                if not _NAME_RE.fullmatch(name):
                    raise ThemeTokenError(f"{rid}: invalid entry name {name!r}")
                literal = None if value is None else encode(f"{rid}.{name}", value)
                if literal is None and style == "args":
                    raise ThemeTokenError(f"{rid}.{name}: an args region needs a literal")
                if literal is not None and style == "params" and _NEEDS_CONST_RE.match(literal):
                    literal = f"const {literal}"
                args.append({"name": name, "literal": literal})
            text = _splice(text, file_name, source, rid, templates[style].render(args=args))
        rendered[target] = text
    return rendered


def render_files(
    tokens_path: Path = DESIGN_TOKENS, theme_dir: Path = LIB_THEME_DIR
) -> dict[Path, str]:
    """Return the full regenerated text of every default target file, keyed by path."""
    return render_regions(tokens_path, theme_dir, REGIONS, DEFAULTS_SOURCE)


def _display(path: Path) -> str:
    try:
        return path.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return str(path)


def write_rendered(rendered: dict[Path, str], check: bool, regenerate_command: str) -> int:
    """Write the rendered files, or with ``check`` report drift. Return the exit code."""
    drifted = []
    for path, content in rendered.items():
        data = content.encode("utf-8")
        changed = path.read_bytes() != data
        if check:
            if changed:
                drifted.append(path)
            continue
        if changed:
            path.write_text(content, encoding="utf-8", newline="\n")
        print(f"{'rendered' if changed else 'unchanged'} {_display(path)}")

    if drifted:
        for path in drifted:
            print(f"drift: {_display(path)}", file=sys.stderr)
        print(f"regenerate with: {regenerate_command}", file=sys.stderr)
        return 1
    return 0


def run(check: bool, tokens_path: Path = DESIGN_TOKENS, theme_dir: Path = LIB_THEME_DIR) -> int:
    try:
        rendered = render_files(tokens_path, theme_dir)
    except ThemeTokenError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return write_rendered(rendered, check, "python -m scaffold_codegen.generators.theme_defaults")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument(
        "--check",
        action="store_true",
        help="Write nothing; exit 1 if the committed files differ from the token file.",
    )
    args = parser.parse_args(argv)
    return run(check=args.check)


if __name__ == "__main__":
    sys.exit(main())
