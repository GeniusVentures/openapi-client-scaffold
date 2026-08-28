#!/usr/bin/env python3
"""
Required-CLI-argument fail-loud tests — DEC-01 / SC-2 regression guard.

``cpp_store`` takes its template and output trees as explicit required
arguments (``--templates-dir`` / ``--output-dir``) — no parent-relative
fallback exists anywhere in the scaffold. Calling it without the tree
args must fail loudly: argparse exits with code 2 and a usage error
BEFORE any filesystem access or render happens, so no template content
is needed for this test — the validation failure is the contract.

The assertion pins the exit code only (not capsys output text): the
SystemExit code is the stable ``SC-2`` contract.

``api_clients`` follows the same contract: its specs directory is a
required ``--api-specs-dir`` flag (no parent-relative default), so
calling it without the flag exits 2 before the openapi-generator
lookup runs.
"""

from __future__ import annotations

import pytest

from scaffold_codegen import api_clients
from scaffold_codegen.generators import cpp_store


def test_cpp_store_requires_paths():
    """cpp_store.main([]) must exit 2 (argparse required-flag usage error)."""
    with pytest.raises(SystemExit) as excinfo:
        cpp_store.main([])
    assert excinfo.value.code == 2


def test_api_clients_requires_specs_dir():
    """api_clients.main([]) must exit 2 (argparse required-flag usage error)."""
    with pytest.raises(SystemExit) as excinfo:
        api_clients.main([])
    assert excinfo.value.code == 2
