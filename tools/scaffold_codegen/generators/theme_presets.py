#!/usr/bin/env python3
"""Generate the opt-in preset Dart files in lib/theme/presets from their own token files.

This is the ``theme_defaults`` codegen with a second region table. Each row of
``REGIONS`` is rendered by ``theme_defaults.render_regions`` and spliced between the
``GENERATED`` / ``END GENERATED`` marker comments of a file under ``lib/theme/presets/``.
Currently the midnight preset, read from ``tokens/midnight.json``.

The CLI reads only ``MIDNIGHT_TOKENS`` and writes only under ``presets/``; it takes no
token-path option.

Usage:
    python -m scaffold_codegen.generators.theme_presets [--check]

Exit status is 0 when the files are written or already clean, and 1 on drift
(``--check``) or a token error.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from scaffold_codegen import LIB_THEME_DIR, MIDNIGHT_TOKENS
from scaffold_codegen.generators import theme_defaults
from scaffold_codegen.generators.theme_defaults import ThemeTokenError

SOURCE = "tokens/midnight.json"

#: (file name in LIB_THEME_DIR, token path, literal kind, style). Row order is splice order.
REGIONS: tuple[tuple[str, tuple[str, ...], str, str], ...] = (
    ("presets/midnight_tokens.dart", ("scaffold", "palette", "dark"), "color", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "palette", "light"), "color", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "colorRoles", "dark"), "color", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "colorRoles", "light"), "color", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "dimens"), "double", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "shadows", "dark"), "shadows", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "shadows", "light"), "shadows", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "motion", "durations"), "duration", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "motion", "curves"), "curve", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "typography", "textStyles"), "textStyle", "args"),
    ("presets/midnight_tokens.dart", ("scaffold", "typography", "fontFamilies"), "fontFamily", "args"),
    ("presets/midnight_tokens.dart", ("preset", "colors", "dark"), "color", "args"),
    ("presets/midnight_tokens.dart", ("preset", "colors", "light"), "color", "args"),
)


def render_files(
    tokens_path: Path = MIDNIGHT_TOKENS, theme_dir: Path = LIB_THEME_DIR
) -> dict[Path, str]:
    """Return the full regenerated text of every preset file, keyed by path."""
    return theme_defaults.render_regions(tokens_path, theme_dir, REGIONS, SOURCE)


def run(check: bool, tokens_path: Path = MIDNIGHT_TOKENS, theme_dir: Path = LIB_THEME_DIR) -> int:
    try:
        rendered = render_files(tokens_path, theme_dir)
    except ThemeTokenError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return theme_defaults.write_rendered(
        rendered, check, "python -m scaffold_codegen.generators.theme_presets"
    )


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
