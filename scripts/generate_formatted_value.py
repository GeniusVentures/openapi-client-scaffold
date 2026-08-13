#!/usr/bin/env python3
"""Generate the six ScaffoldFormattedValue* variant files.

Renders ``templates/components/formatted_value.dart.jinja2`` (Jinja2
StrictUndefined) once per variant, overriding ``variant`` and
``widget_class_name`` in the context so each output file declares exactly one
variant class. The template is the source of truth: regenerate and diff
against the committed ``lib/components/`` files to detect drift.

Usage:
    python3 scripts/generate_formatted_value.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from engine import create_environment, render_template  # noqa: E402

VARIANTS = {
    "number": "ScaffoldFormattedValueNumber",
    "money": "ScaffoldFormattedValueMoney",
    "percentage": "ScaffoldFormattedValuePercentage",
    "date": "ScaffoldFormattedValueDate",
    "time": "ScaffoldFormattedValueTime",
    "duration": "ScaffoldFormattedValueDuration",
}


def main() -> int:
    vars_path = ROOT / "templates" / "components" / "formatted_value_vars.json"
    tokens_path = ROOT / "design_tokens.json"

    base_vars = json.loads(vars_path.read_text(encoding="utf-8"))
    tokens = json.loads(tokens_path.read_text(encoding="utf-8"))

    env = create_environment([str(ROOT / "templates")])

    for variant, class_name in VARIANTS.items():
        context = dict(base_vars)
        context["variant"] = variant
        context["widget_class_name"] = class_name
        context["tokens"] = tokens
        output = ROOT / "lib" / "components" / f"scaffold_formatted_value_{variant}.dart"
        render_template(
            env, "components/formatted_value.dart.jinja2", str(output), context
        )
        print(f"rendered lib/components/scaffold_formatted_value_{variant}.dart")

    return 0


if __name__ == "__main__":
    sys.exit(main())
