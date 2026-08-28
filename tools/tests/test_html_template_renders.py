#!/usr/bin/env python3
"""
Tests for the html component leg render — BLD-01 regression guard.

BLD-01 requires the v1.0 HTML/CSS output path to remain available and
functional as an alternative style. Every
``templates/components/<comp>.html.jinja2`` must render with its sibling
``<comp>_vars.json`` fixture under ``StrictUndefined`` — a fixture missing a
template-referenced variable must fail loudly (T-08-04 mitigation), never
emit silently-wrong html.

The context is built exactly as ``scaffold_codegen.engine.main()`` builds it
for the CMake html leg: design tokens load FIRST into
``context["tokens"]``, then the fixture dict merges on top. No subprocess, no
sleeps, no ``default()`` filters, no swallowing of ``UndefinedError`` — the
render goes through the same engine functions the build calls.
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from scaffold_codegen import DESIGN_TOKENS, TEMPLATES_DIR
from scaffold_codegen.engine import create_environment, render_template

#: Component directory holding the *.html.jinja2 templates and *_vars.json
#: fixtures (passed to create_environment as the loader directory).
COMPONENTS_DIR = TEMPLATES_DIR / "components"

#: Every component with an html fragment template + sibling vars fixture.
COMPONENTS = [
    "data_table",
    "form_dialog",
    "navigation",
    "search_bar",
    "card",
    "state",
]

#: Structural marker each rendered fragment must contain (verified against the
#: class attribute strings the fixture branch of each template emits).
MARKERS = {
    "data_table": "m3-table__head",
    "form_dialog": "m3-form-dialog",
    "navigation": "m3-navigation",
    "search_bar": "m3-search__group",
    "card": "m3-card__title",
    "state": "m3-state--empty",
}

#: Shared stylesheet link every html fragment emits (v1.0 layout contract).
SHARED_STYLESHEET = "../styles/m3_tokens.css"


def _assert_contains(path: Path, needle: str) -> None:
    """Assert *path* exists and its text contains *needle*.

    Parameters
    ----------
    path : pathlib.Path
        Rendered output file to inspect.
    needle : str
        Substring expected in the file's text.

    Raises
    ------
    AssertionError
        If the file is missing or the needle is absent.
    """
    assert path.exists(), f"missing rendered output: {path}"
    text = path.read_text(encoding="utf-8")
    assert needle in text, f"{needle!r} not found in {path}:\n{text}"


@pytest.mark.parametrize("component", COMPONENTS)
def test_component_html_fixture_renders(component: str, tmp_path: Path) -> None:
    """Each ``<comp>.html.jinja2`` renders with its sibling ``<comp>_vars.json``.

    Proves the BLD-01 html leg is renderable end-to-end: the fixture provides
    every variable the template references, so ``StrictUndefined`` raises
    nothing and the output carries the component's structural marker plus the
    shared stylesheet link. A fixture that drops or renames a key fails this
    test loudly with a ``jinja2.UndefinedError`` naming the variable.
    """
    env = create_environment([str(COMPONENTS_DIR)])

    fixture = json.loads(
        (COMPONENTS_DIR / f"{component}_vars.json").read_text(encoding="utf-8")
    )

    # Mirror engine.py main(): tokens first, vars merged on top.
    context: dict = {"tokens": json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))}
    context.update(fixture)

    output = tmp_path / f"{component}.html"
    render_template(env, f"{component}.html.jinja2", str(output), context)

    _assert_contains(output, MARKERS[component])
    _assert_contains(output, SHARED_STYLESHEET)
