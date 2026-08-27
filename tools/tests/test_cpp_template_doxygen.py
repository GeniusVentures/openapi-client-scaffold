#!/usr/bin/env python3
"""
CPP-02 standards snapshot: Doxygen documentation on emitted C++.

D-08 requires generated C++ to carry Doxygen ``@file``/``@brief`` headers on
every translation unit and ``@param``/``@return`` on public interface
methods. These tests re-render the reference composite widget (order_entry)
through the generator and assert the documentation is present in the OUTPUT
— not merely in the template sources.
"""

from __future__ import annotations

from scaffold_codegen.generators import cpp_store


def _reference_store_dir():
    """Render the reference store (idempotent) and return its output dir.

    Returns
    -------
    pathlib.Path
        ``frontend/generated/pos/cpp/order_entry`` after a fresh render.
    """
    assert cpp_store.main() == 0
    return cpp_store.PARENT_GENERATED / "pos" / "cpp" / "order_entry"


def test_doxygen_file_brief():
    """Every emitted .hpp under the reference store dir carries @file + @brief.

    A vacuous pass is impossible: the glob must find at least one header.
    """
    store_dir = _reference_store_dir()
    headers = sorted(store_dir.glob("*.hpp"))
    assert headers, f"no .hpp emitted under {store_dir}"

    for header in headers:
        text = header.read_text(encoding="utf-8")
        assert "@file" in text, f"@file missing from {header}"
        assert "@brief" in text, f"@brief missing from {header}"


def test_doxygen_params_on_public_methods():
    """The pure-virtual interface documents its methods with @param/@return."""
    store_dir = _reference_store_dir()
    text = (store_dir / "IOrderEntryStore.hpp").read_text(encoding="utf-8")
    assert "@param" in text, "@param missing from IOrderEntryStore.hpp"
    assert "@return" in text, "@return missing from IOrderEntryStore.hpp"
