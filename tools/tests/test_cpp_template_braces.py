#!/usr/bin/env python3
"""
CPP-02 standards snapshot: Allman bracing in emitted C++.

D-08 requires Allman/Ullman braces — every opening brace sits on its own
line. The K&R tell is a line ending ``... ) {``: a closing parenthesis
followed by an opening brace on the SAME line. This test re-renders the
reference composite widget (order_entry) and asserts no emitted ``.hpp`` or
``.cpp`` line matches ``\\)\\s*\\{``.
"""

from __future__ import annotations

import re

from scaffold_codegen.generators import cpp_store

#: K&R-style brace on the same line as the closing parenthesis (e.g. ``) {``).
K_AND_R_BRACE_RE = re.compile(r"\)\s*\{")


def _emitted_cpp_files():
    """Render the reference store (idempotent) and return its emitted C++ files.

    Returns
    -------
    list[pathlib.Path]
        Every ``.hpp``/``.cpp`` under the reference store dir plus the
        once-only shared ``ffi_common.hpp``.
    """
    assert cpp_store.main() == 0
    store_dir = cpp_store.PARENT_GENERATED / "pos" / "cpp" / "order_entry"
    files = sorted(store_dir.glob("*.hpp")) + sorted(store_dir.glob("*.cpp"))
    files.append(cpp_store.PARENT_GENERATED / "shared" / "cpp" / "ffi_common.hpp")
    return files


def test_allman_braces():
    """No emitted C++ line puts an opening brace after a closing parenthesis."""
    emitted = _emitted_cpp_files()
    assert len(emitted) >= 3, f"expected several emitted C++ files, got {emitted}"

    for path in emitted:
        assert path.exists(), f"missing rendered output: {path}"
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            assert K_AND_R_BRACE_RE.search(line) is None, (
                f"K&R brace in {path}:{line_number}: {line.strip()!r} (D-08 requires Allman braces)"
            )
