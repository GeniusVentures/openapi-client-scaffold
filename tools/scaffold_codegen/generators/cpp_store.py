#!/usr/bin/env python3
"""Generate the C++ state-store half of the hybrid composable model.

Renders a consuming project's surface templates through the shared Jinja2
``StrictUndefined`` engine — the SAME engine every other generator uses
(CPP-01: no parallel pipeline). The template tree is the consuming
project's surface-template root passed via ``--templates-dir`` (contains
``<surface>/cpp/`` and ``shared/cpp/``); for every per-store
``*_vars.json`` manifest discovered under a surface's ``cpp/`` directory
this emits, under ``<output-dir>/<surface>/``:

- ``cpp/<store>/I<Widget>Store.hpp`` and ``I<Widget>Importer.hpp`` (07-01
  shared interface templates),
- ``cpp/<store>/<Widget>Store.hpp/.cpp``, ``<Widget>OpenApiImporter.hpp``,
  ``<store>_ffi.hpp/.cpp`` (07-02 concrete store + C-ABI FFI templates), and
- ``dart/<store>/<store>_ffi_adapter.dart`` (07-02 Dart FFI adapter).

``ffi_common.hpp.jinja2`` is widget-independent and renders ONCE with an empty
context into ``<output-dir>/shared/cpp/ffi_common.hpp`` (D-07-01a).

Output splits by surface (D-13/D-14): rendering one surface never clobbers
another surface's generated tree.

Usage:
    python3 -m scaffold_codegen.generators.cpp_store --templates-dir <dir> --output-dir <dir>
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from scaffold_codegen.engine import create_environment, render_template

#: Product surfaces owning template directories (D-12).
SURFACES = ["admin", "pos", "storefront", "shared"]

#: Suffix of the per-store manifest files this generator discovers.
VARS_SUFFIX = "_vars.json"


def render_store(env, surface: str, store_stem: str, vars_: dict, generated_dir: Path) -> None:
    """Render one composite-widget store's full template set.

    Template names resolve against this surface's environment (shared
    ``cpp/`` first, then ONLY this surface's ``cpp/`` — never another
    surface's directory, so a cross-surface template-name collision
    cannot render the wrong template); outputs land under
    ``<output-dir>/<surface>/`` split by surface (D-13). The mapping
    below is the locked contract — do not invent output names.

    Parameters
    ----------
    env : jinja2.Environment
        Environment from ``create_environment()`` (StrictUndefined).
    surface : str
        Product surface owning the store (e.g. ``"pos"``).
    store_stem : str
        Manifest filename stem, e.g. ``order_entry`` for
        ``order_entry_vars.json``. Also the FFI symbol prefix.
    vars_ : dict
        Full manifest contents (nested ``cpp`` object included) — the
        templates read ``widget_class_name`` and ``cpp.model_*`` under
        StrictUndefined.
    generated_dir : Path
        Output root from ``--output-dir``; this surface's ``cpp/`` and
        ``dart/`` trees are created beneath it.
    """
    widget_class_name = vars_["widget_class_name"]
    cpp_dir = generated_dir / surface / "cpp" / store_stem
    dart_dir = generated_dir / surface / "dart" / store_stem

    outputs = [
        # 07-01 shared interface templates.
        ("i_widget_store.hpp.jinja2", cpp_dir / f"I{widget_class_name}Store.hpp"),
        ("i_widget_importer.hpp.jinja2", cpp_dir / f"I{widget_class_name}Importer.hpp"),
        # 07-02 concrete store, importer, C-ABI FFI, and Dart adapter.
        (f"{store_stem}_store.hpp.jinja2", cpp_dir / f"{widget_class_name}Store.hpp"),
        (f"{store_stem}_store.cpp.jinja2", cpp_dir / f"{widget_class_name}Store.cpp"),
        (f"{store_stem}_importer.hpp.jinja2", cpp_dir / f"{widget_class_name}OpenApiImporter.hpp"),
        (f"{store_stem}_ffi.hpp.jinja2", cpp_dir / f"{store_stem}_ffi.hpp"),
        (f"{store_stem}_ffi.cpp.jinja2", cpp_dir / f"{store_stem}_ffi.cpp"),
        (f"{store_stem}_ffi_adapter.dart.jinja2", dart_dir / f"{store_stem}_ffi_adapter.dart"),
    ]

    for template_name, output in outputs:
        render_template(env, template_name, str(output), vars_)
        print(f"rendered {output.relative_to(generated_dir)}")


def main(argv: list[str] | None = None) -> int:
    """Render every surface's stores plus the once-only shared FFI header.

    Both trees are explicit required arguments (DEC-01/SC-2): the
    consuming project passes its own template root (``--templates-dir``)
    and output root (``--output-dir``) — no parent-relative fallback
    exists.

    Renders ``ffi_common.hpp.jinja2`` once with an empty context from a
    shared-only environment (D-07-01a), then discovers each surface's
    ``*_vars.json`` manifests and renders their template sets from a
    per-surface environment whose loader spans ONLY the shared ``cpp/``
    directory plus that surface's ``cpp/`` directory — a bare template
    name can never resolve into another surface's tree, so cross-surface
    name collisions cannot render the wrong template (D-13/D-14). Store
    names are never hardcoded — discovery is the glob.

    Returns
    -------
    int
        0 on success; a non-zero exit propagates from the failing render
        via an exception (StrictUndefined makes missing variables fatal).
    """
    parser = argparse.ArgumentParser(
        description="Generate the C++ state-store half of the hybrid composable model"
    )
    parser.add_argument(
        "--templates-dir",
        required=True,
        help="Root of the consuming project's surface template tree "
             "(contains <surface>/cpp/ and shared/cpp/)",
    )
    parser.add_argument(
        "--output-dir",
        required=True,
        help="Generated-output root (<surface>/{cpp,dart} are created beneath it)",
    )
    args = parser.parse_args(argv)

    templates_dir = Path(args.templates_dir)
    generated_dir = Path(args.output_dir)
    shared_cpp = templates_dir / "shared" / "cpp"

    if not templates_dir.is_dir():
        sys.stderr.write(f"ERROR: Templates directory not found at {templates_dir}\n")
        return 1

    # Widget-independent shared header: rendered ONCE, empty context (D-07-01a).
    shared_env = create_environment([str(shared_cpp)])
    ffi_common_output = generated_dir / "shared" / "cpp" / "ffi_common.hpp"
    render_template(shared_env, "ffi_common.hpp.jinja2", str(ffi_common_output), {})
    print(f"rendered {ffi_common_output.relative_to(generated_dir)}")

    for surface in SURFACES:
        surface_cpp = templates_dir / surface / "cpp"
        manifests = sorted(surface_cpp.glob(f"*{VARS_SUFFIX}")) if surface_cpp.is_dir() else []
        if not manifests:
            continue
        env = create_environment([str(shared_cpp), str(surface_cpp)])
        for vars_path in manifests:
            store_stem = vars_path.name[: -len(VARS_SUFFIX)]
            vars_ = json.loads(vars_path.read_text(encoding="utf-8"))
            render_store(env, surface, store_stem, vars_, generated_dir)

    return 0


if __name__ == "__main__":
    sys.exit(main())
