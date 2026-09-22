#!/usr/bin/env python3
"""Generate the three ScaffoldSelectionIndicator* variant files.

Renders ``templates/components/selection_indicator.dart.jinja2`` (Jinja2
StrictUndefined) once per variant, overriding ``variant`` and
``widget_class_name`` so each output file declares exactly one variant class.
The template is the source of truth: regenerate and diff against the committed
``lib/components/`` files to detect drift.

Usage:
    python3 -m scaffold_codegen.generators.selection_indicator
"""
from __future__ import annotations

import json
import sys

from scaffold_codegen import DESIGN_TOKENS, LIB_COMPONENTS_DIR, TEMPLATES_DIR
from scaffold_codegen.engine import create_environment, render_template

VARIANTS = {
    "radio": "ScaffoldSelectionIndicatorRadio",
    "checkbox": "ScaffoldSelectionIndicatorCheckbox",
    "toggle": "ScaffoldSelectionIndicatorToggle",
}


def main() -> int:
    vars_path = TEMPLATES_DIR / "components" / "selection_indicator_vars.json"

    base_vars = json.loads(vars_path.read_text(encoding="utf-8"))
    tokens = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))

    env = create_environment([str(TEMPLATES_DIR)])

    for variant, class_name in VARIANTS.items():
        context = dict(base_vars)
        context["variant"] = variant
        context["widget_class_name"] = class_name
        context["tokens"] = tokens
        output = (
            LIB_COMPONENTS_DIR / f"scaffold_selection_indicator_{variant}.dart"
        )
        render_template(
            env,
            "components/selection_indicator.dart.jinja2",
            str(output),
            context,
        )
        print(f"rendered lib/components/scaffold_selection_indicator_{variant}.dart")

    return 0


if __name__ == "__main__":
    sys.exit(main())
