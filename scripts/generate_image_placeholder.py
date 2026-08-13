#!/usr/bin/env python3
"""Generate the four ScaffoldImagePlaceholder* variant files.

Renders ``templates/components/image_placeholder.dart.jinja2`` (Jinja2
StrictUndefined) once per variant, overriding ``variant``, ``widget_class_name``,
and ``variant_label`` so each output file declares exactly one variant class.
The template is the source of truth: regenerate and diff against the committed
``lib/components/`` files to detect drift.

Usage:
    python3 scripts/generate_image_placeholder.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from engine import create_environment, render_template  # noqa: E402

VARIANTS = {
    "loading": ("ScaffoldImagePlaceholderLoading", "Loading image"),
    "missing": ("ScaffoldImagePlaceholderMissing", "No image"),
    "empty": ("ScaffoldImagePlaceholderEmpty", "No image"),
    "failed": ("ScaffoldImagePlaceholderFailed", "Image failed to load"),
}


def main() -> int:
    vars_path = ROOT / "templates" / "components" / "image_placeholder_vars.json"
    tokens_path = ROOT / "design_tokens.json"

    base_vars = json.loads(vars_path.read_text(encoding="utf-8"))
    tokens = json.loads(tokens_path.read_text(encoding="utf-8"))

    env = create_environment([str(ROOT / "templates")])

    for variant, (class_name, variant_label) in VARIANTS.items():
        context = dict(base_vars)
        context["variant"] = variant
        context["widget_class_name"] = class_name
        context["variant_label"] = variant_label
        context["tokens"] = tokens
        output = (
            ROOT / "lib" / "components" / f"scaffold_image_placeholder_{variant}.dart"
        )
        render_template(
            env,
            "components/image_placeholder.dart.jinja2",
            str(output),
            context,
        )
        print(f"rendered lib/components/scaffold_image_placeholder_{variant}.dart")

    return 0


if __name__ == "__main__":
    sys.exit(main())
