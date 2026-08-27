#!/usr/bin/env python3
"""
CPP-02 standards snapshot: interface-first design in emitted C++.

D-08 requires interface-first design: ``I``-prefixed abstract classes with
pure-virtual methods (``= 0;``), ``override`` on every concrete
implementation, and ``= delete`` on the manager-style store's copy
operations (D-19: one composite widget owns one store).
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


def test_i_prefix_pure_virtual():
    """The store contract is an I-prefixed interface with pure-virtual methods."""
    store_dir = _reference_store_dir()
    text = (store_dir / "IOrderEntryStore.hpp").read_text(encoding="utf-8")
    assert "class IOrderEntryStore" in text, (
        "IOrderEntryStore interface class missing from IOrderEntryStore.hpp"
    )
    assert "= 0;" in text, "pure-virtual (= 0;) methods missing from IOrderEntryStore.hpp"


def test_override_on_concrete():
    """The concrete store marks every contract method with override."""
    store_dir = _reference_store_dir()
    text = (store_dir / "OrderEntryStore.hpp").read_text(encoding="utf-8")
    assert "override" in text, "override missing from OrderEntryStore.hpp"


def test_delete_copy_on_manager():
    """The store is a manager class: copy operations are deleted (D-19)."""
    store_dir = _reference_store_dir()
    text = (store_dir / "OrderEntryStore.hpp").read_text(encoding="utf-8")
    assert "= delete" in text, "= delete missing from OrderEntryStore.hpp"
