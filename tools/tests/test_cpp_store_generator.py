#!/usr/bin/env python3
"""
Tests for scaffold_codegen.generators.cpp_store — CPP-01 render-path smoke.

CPP-01 requires the C++ interface templates to render through the EXISTING
``scaffold_codegen.engine`` (StrictUndefined, multi-directory loader) — no
parallel pipeline. These tests render the reference composite widget
(``order_entry``) by invoking the generator's ``main()`` directly and assert
the full C++/Dart output set lands under ``frontend/generated/`` with the
expected contract markers:

- the 07-01 interface template output (``class IOrderEntryStore``),
- D-05 OpenAPI model reuse (``#include "commerce/generated/model/Order.h"``),
- the D-16 push entry point (``order_entry_store_subscribe``), and
- the once-only shared header carrying ``FFI_EXPORT`` (D-07-01a).

No subprocess, no sleeps: the generator is imported and called in-process.
"""

from __future__ import annotations

from scaffold_codegen.engine import create_environment, render_template
from scaffold_codegen.generators import cpp_store


def _assert_contains(path, needle: str) -> None:
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


def test_render_reference_store():
    """Rendering via cpp_store.main() emits the full order_entry output set.

    Proves CPP-01 end-to-end: the reference composite widget renders through
    the existing engine with the correct OpenAPI/FFI bindings (D-05/D-16)
    and no StrictUndefined errors.
    """
    assert cpp_store.main() == 0

    pos_cpp = cpp_store.PARENT_GENERATED / "pos" / "cpp" / "order_entry"

    # 07-01 shared interface template output.
    _assert_contains(pos_cpp / "IOrderEntryStore.hpp", "class IOrderEntryStore")

    # D-05: the store reuses the generated OpenAPI model directly.
    _assert_contains(
        pos_cpp / "OrderEntryStore.cpp",
        '#include "commerce/generated/model/Order.h"',
    )

    # D-16: push/subscribe is part of the FFI surface from the start.
    _assert_contains(pos_cpp / "order_entry_ffi.hpp", "order_entry_store_subscribe")

    # Dart half of the hybrid model (D-02: both halves always generated).
    adapter = cpp_store.PARENT_GENERATED / "pos" / "dart" / "order_entry" / "order_entry_ffi_adapter.dart"
    assert adapter.exists(), f"missing rendered output: {adapter}"

    # Widget-independent shared header, rendered ONCE (D-07-01a).
    _assert_contains(
        cpp_store.PARENT_GENERATED / "shared" / "cpp" / "ffi_common.hpp",
        "FFI_EXPORT",
    )


def test_no_strictundefined_on_blank_context(tmp_path):
    """Rendering ffi_common.hpp.jinja2 with an empty context raises nothing.

    T-07-07 mitigation: the shared header is widget-independent, so a blank
    context must render cleanly. A ``jinja2.UndefinedError`` here would fail
    the test loudly instead of emitting silently-wrong C++.
    """
    env = create_environment([str(cpp_store.SHARED_CPP)])
    output = tmp_path / "ffi_common.hpp"
    render_template(env, "ffi_common.hpp.jinja2", str(output), {})
    _assert_contains(output, "FFI_EXPORT")
