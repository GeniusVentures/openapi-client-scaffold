"""The consumer check harness stays portable: no machine paths, no pinned commits."""
from __future__ import annotations

import re

from scaffold_codegen import REPO_ROOT

HARNESS = REPO_ROOT / "tools" / "consumer_check" / "gcs_check.sh"

MACHINE_PATTERNS = {
    "windows drive path": re.compile(r"\b[A-Za-z]:[\\/]"),
    "msys drive path": re.compile(r"(?<![\w.])/[a-z]/[A-Za-z0-9_.-]+/"),
    "home directory path": re.compile(r"/(?:home|Users)/"),
    "roaming app data": re.compile(r"AppData", re.IGNORECASE),
    "pinned commit": re.compile(r"\b[0-9a-f]{7,40}\b"),
}


def find_machine_specifics(text: str) -> list[tuple[int, str, str]]:
    """Return (line number, pattern name, line) for every machine-specific match."""
    return [
        (number, name, line.strip())
        for number, line in enumerate(text.splitlines(), start=1)
        for name, pattern in MACHINE_PATTERNS.items()
        if pattern.search(line)
    ]


def test_harness_exists_with_bash_shebang() -> None:
    assert HARNESS.is_file()
    assert HARNESS.read_text(encoding="utf-8").startswith("#!/usr/bin/env bash")


def test_harness_has_no_machine_specific_content() -> None:
    hits = find_machine_specifics(HARNESS.read_text(encoding="utf-8"))
    assert not hits, "machine-specific content:\n" + "\n".join(map(str, hits))


def test_matcher_detects_each_pattern() -> None:
    samples = {
        "windows drive path": r"C:\Users\someone\app",
        "msys drive path": "cd /c/work/project",
        "home directory path": "ROOT=/home/dev/app",
        "roaming app data": "cache in appdata/Roaming",
        "pinned commit": "BASE=8ada743",
    }
    assert set(samples) == set(MACHINE_PATTERNS)
    for name, sample in samples.items():
        assert name in {hit[1] for hit in find_machine_specifics(sample)}, sample


def test_matcher_ignores_portable_text() -> None:
    for sample in (
        'APP="$(cd "$APP_ARG" && pwd)"',
        "git -C \"$APP/scaffold\" checkout -q --detach \"$BASE\"",
        "# flutter on PATH, python via PYTHON",
    ):
        assert not find_machine_specifics(sample), sample
