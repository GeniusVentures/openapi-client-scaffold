#!/usr/bin/env python3
"""Generate the three Wave 3 composite widget file sets.

Renders the existing ``templates/components/`` templates (card, state,
search_bar) plus their ``_cubit`` / ``_state`` companions through the shared
Jinja2 ``StrictUndefined`` engine. The templates are the source of truth:
regenerate and diff against the committed ``lib/components/`` files to detect
drift (any hand-edit to a generated file, or any divergence between template
and committed output, fails the build).

Usage:
    python3 -m scaffold_codegen.generators.composites
"""
from __future__ import annotations

import json
import sys

from scaffold_codegen import DESIGN_TOKENS, LIB_COMPONENTS_DIR, TEMPLATES_DIR
from scaffold_codegen.engine import create_environment, render_template

COMPONENTS = {
    "card": {
        "vars": "card_vars.json",
        "templates": {
            "components/card.dart.jinja2": "scaffold_card.dart",
            "components/card_cubit.dart.jinja2": "scaffold_card_cubit.dart",
            "components/card_state.dart.jinja2": "scaffold_card_state.dart",
        },
    },
    "state": {
        "vars": "state_vars.json",
        "templates": {
            "components/state.dart.jinja2": "scaffold_state_view.dart",
            "components/state_cubit.dart.jinja2": "scaffold_state_view_cubit.dart",
            "components/state_view_state.dart.jinja2": "scaffold_state_view_state.dart",
        },
    },
    "search_bar": {
        "vars": "search_bar_vars.json",
        "templates": {
            "components/search_bar.dart.jinja2": "scaffold_search_bar.dart",
            "components/search_bar_cubit.dart.jinja2": "scaffold_search_bar_cubit.dart",
            "components/search_bar_state.dart.jinja2": "scaffold_search_bar_state.dart",
        },
    },
}


def main() -> int:
    tokens = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))

    env = create_environment([str(TEMPLATES_DIR)])

    for spec in COMPONENTS.values():
        vars_path = TEMPLATES_DIR / "components" / spec["vars"]
        base_vars = json.loads(vars_path.read_text(encoding="utf-8"))
        context = dict(base_vars)
        context["tokens"] = tokens
        for template_name, output_name in spec["templates"].items():
            output = LIB_COMPONENTS_DIR / output_name
            render_template(env, template_name, str(output), context)
            print(f"rendered lib/components/{output_name}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
