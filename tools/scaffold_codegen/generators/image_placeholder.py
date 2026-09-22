#!/usr/bin/env python3
"""Generate the four ScaffoldImagePlaceholder* variant files.

Renders ``templates/components/image_placeholder.dart.jinja2`` (Jinja2
StrictUndefined) once per variant, overriding ``variant``, ``widget_class_name``,
and ``variant_label`` so each output file declares exactly one variant class.
The template is the source of truth: regenerate and diff against the committed
``lib/components/`` files to detect drift.

Usage:
    python3 -m scaffold_codegen.generators.image_placeholder
"""
from __future__ import annotations

import json
import sys

from scaffold_codegen import DESIGN_TOKENS, LIB_COMPONENTS_DIR, TEMPLATES_DIR
from scaffold_codegen.engine import create_environment, render_template

VARIANTS = {
    "loading": ("ScaffoldImagePlaceholderLoading", "Loading image"),
    "missing": ("ScaffoldImagePlaceholderMissing", "No image"),
    "empty": ("ScaffoldImagePlaceholderEmpty", "No image"),
    "failed": ("ScaffoldImagePlaceholderFailed", "Image failed to load"),
}


def main() -> int:
    vars_path = TEMPLATES_DIR / "components" / "image_placeholder_vars.json"

    base_vars = json.loads(vars_path.read_text(encoding="utf-8"))
    tokens = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))

    env = create_environment([str(TEMPLATES_DIR)])

    for variant, (class_name, variant_label) in VARIANTS.items():
        context = dict(base_vars)
        context["variant"] = variant
        context["widget_class_name"] = class_name
        context["variant_label"] = variant_label
        context["tokens"] = tokens
        output = (
            LIB_COMPONENTS_DIR / f"scaffold_image_placeholder_{variant}.dart"
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
