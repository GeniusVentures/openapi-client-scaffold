#!/usr/bin/env python3
"""
CPP-02 standards snapshot: no bare magic numbers in emitted C++.

D-08 requires every numeric literal to be a named ``constexpr`` with
``kCamelCase`` naming. The FFI layer must return the named
``genius::stores::ffi`` status constants (never bare ``return 0;`` style
codes), and the store must seed its subscription ids from
``kInitialSubscriptionId`` (never a bare ``= 1;`` assignment).
"""

from __future__ import annotations

import re

from scaffold_codegen.generators import cpp_store

#: Bare status-code return (0..4) instead of a named kFfi* constant.
BARE_STATUS_RETURN_RE = re.compile(r"return [0-4];")


def _reference_store_dir():
    """Render the reference store (idempotent) and return its output dir.

    Returns
    -------
    pathlib.Path
        ``frontend/generated/pos/cpp/order_entry`` after a fresh render.
    """
    assert cpp_store.main() == 0
    return cpp_store.PARENT_GENERATED / "pos" / "cpp" / "order_entry"


def test_no_bare_magic_numbers():
    """FFI statuses and subscription seeding use named constants, not literals."""
    store_dir = _reference_store_dir()

    ffi_cpp = (store_dir / "order_entry_ffi.cpp").read_text(encoding="utf-8")

    # Every status return goes through a named kFfi* constant.
    assert BARE_STATUS_RETURN_RE.search(ffi_cpp) is None, (
        f"bare status return in order_entry_ffi.cpp: {BARE_STATUS_RETURN_RE.search(ffi_cpp).group(0)!r}"
    )
    assert "kFfiSuccess" in ffi_cpp, "kFfiSuccess missing from order_entry_ffi.cpp"
    assert "kFfiErrorNullArgument" in ffi_cpp, "kFfiErrorNullArgument missing from order_entry_ffi.cpp"

    store_cpp = (store_dir / "OrderEntryStore.cpp").read_text(encoding="utf-8")
    assert "kInitialSubscriptionId" in store_cpp, "kInitialSubscriptionId missing from OrderEntryStore.cpp"
    assert "= 1;" not in store_cpp, "bare subscription-id assignment (= 1;) in OrderEntryStore.cpp"
