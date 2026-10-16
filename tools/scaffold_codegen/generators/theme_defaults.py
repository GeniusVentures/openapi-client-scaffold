#!/usr/bin/env python3
"""Generate the default ScaffoldPalette / ScaffoldDimens values from design_tokens.json.

The ``scaffold`` namespace of the repo token file is the source of truth. Each
region listed in ``REGIONS`` is rendered through
``templates/theme/const_args.dart.jinja2`` and spliced between the
``GENERATED`` / ``END GENERATED`` marker comments inside the matching const
constructor call in ``lib/theme/``. Everything outside the markers is left as
written.

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
from pathlib import Path

from scaffold_codegen import DESIGN_TOKENS, LIB_THEME_DIR, REPO_ROOT, TEMPLATES_DIR
from scaffold_codegen.engine import create_environment

TEMPLATE_NAME = "theme/const_args.dart.jinja2"

BEGIN_MARKER = "    // GENERATED from design_tokens.json {id}. Do not edit."
END_MARKER = "    // END GENERATED {id}"

#: (file name in LIB_THEME_DIR, token path, literal kind). Row order is splice order.
REGIONS: tuple[tuple[str, tuple[str, ...], str], ...] = (
    ("scaffold_dimens.dart", ("scaffold", "dimens"), "double"),
)

_DOUBLE_RE = re.compile(r"-?\d+\.\d+")
_NAME_RE = re.compile(r"[a-z][A-Za-z0-9]*")


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


_LITERAL_ENCODERS = {
    "double": dart_double,
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


def _splice(text: str, file_name: str, rid: str, body: str) -> str:
    begin = BEGIN_MARKER.format(id=rid)
    end = END_MARKER.format(id=rid)
    lines = text.split("\n")
    begins = [i for i, line in enumerate(lines) if line == begin]
    ends = [i for i, line in enumerate(lines) if line == end]
    if len(begins) != 1 or len(ends) != 1 or begins[0] >= ends[0]:
        raise ThemeTokenError(
            f"{file_name}: region {rid} needs exactly one begin marker before exactly one end marker"
        )
    return "\n".join(lines[: begins[0] + 1] + body.split("\n")[:-1] + lines[ends[0] :])


def render_files(
    tokens_path: Path = DESIGN_TOKENS, theme_dir: Path = LIB_THEME_DIR
) -> dict[Path, str]:
    """Return the full regenerated text of every target file, keyed by path."""
    tokens = load_tokens(tokens_path)
    template = create_environment([str(TEMPLATES_DIR)]).get_template(TEMPLATE_NAME)

    file_names = list(dict.fromkeys(row[0] for row in REGIONS))
    rendered: dict[Path, str] = {}
    for file_name in file_names:
        target = theme_dir / file_name
        text = target.read_bytes().decode("utf-8").replace("\r\n", "\n")
        for row_file, path, kind in REGIONS:
            if row_file != file_name:
                continue
            rid = region_id(path)
            encode = _LITERAL_ENCODERS[kind]
            args = []
            for name, value in _region_entries(tokens, path).items():
                if not _NAME_RE.fullmatch(name):
                    raise ThemeTokenError(f"{rid}: invalid entry name {name!r}")
                args.append({"name": name, "literal": encode(f"{rid}.{name}", value)})
            text = _splice(text, file_name, rid, template.render(args=args))
        rendered[target] = text
    return rendered


def _display(path: Path) -> str:
    try:
        return path.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return str(path)


def run(check: bool, tokens_path: Path = DESIGN_TOKENS, theme_dir: Path = LIB_THEME_DIR) -> int:
    try:
        rendered = render_files(tokens_path, theme_dir)
    except ThemeTokenError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

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
        print(f"{'rendered' if changed else 'unchanged'} lib/theme/{path.name}")

    if drifted:
        for path in drifted:
            print(f"drift: {_display(path)}", file=sys.stderr)
        print(
            "regenerate with: python -m scaffold_codegen.generators.theme_defaults",
            file=sys.stderr,
        )
        return 1
    return 0


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
