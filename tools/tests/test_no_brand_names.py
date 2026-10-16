"""The package content carries no brand or product names (PROJECT.md: neutral generic package).

Scans the text files under lib/, example/ and tokens/ for the organization and
product names and for the source app's identifier prefixes. The platform runner
folders of the example app are skipped: their bundle identifiers carry the
publisher's reverse-DNS domain, which is build metadata and not package content.
"""
from __future__ import annotations

import re
import subprocess

from scaffold_codegen import REPO_ROOT

SCANNED_ROOTS = ("lib", "example", "tokens")
SCANNED_SUFFIXES = (".dart", ".md", ".yaml", ".yml", ".json", ".jinja2", ".txt")
SKIPPED_PREFIXES = tuple(
    f"example/{platform}/"
    for platform in ("android", "ios", "linux", "macos", "web", "windows")
)
DENY_PATTERNS = (
    re.compile(r"genius", re.IGNORECASE),
    re.compile(r"\bgnus\b", re.IGNORECASE),
    re.compile(r"\bGW[A-Z]"),
    re.compile(r"\bgw_"),
)
ANCHOR_FILES = (
    "tokens/midnight.json",
    "lib/theme/presets/midnight_theme.dart",
    "example/lib/main.dart",
)


def _scanned_files() -> list[str]:
    result = subprocess.run(
        [
            "git",
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "--",
            *SCANNED_ROOTS,
        ],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return [
        path
        for path in result.stdout.splitlines()
        if path.endswith(SCANNED_SUFFIXES) and not path.startswith(SKIPPED_PREFIXES)
    ]


def find_brand_names(text: str) -> list[tuple[int, str]]:
    """Return (line number, line) for every line that matches a deny pattern."""
    return [
        (number, line.strip())
        for number, line in enumerate(text.splitlines(), start=1)
        if any(pattern.search(line) for pattern in DENY_PATTERNS)
    ]


def test_matcher_detects_each_deny_pattern() -> None:
    for sample in (
        "// uses GeniusTheme here",
        "see geniuswallet",
        "owner: GNUS.ai",
        "final x = GWColors.blue;",
        "import 'gw_theme.dart';",
    ):
        assert find_brand_names(sample), sample


def test_matcher_ignores_neutral_text() -> None:
    for sample in ("// the source app's port", "final gwidth = 3;", "GWei"):
        assert not find_brand_names(sample), sample


def test_scan_set_includes_anchor_files() -> None:
    scanned = set(_scanned_files())
    for anchor in ANCHOR_FILES:
        assert anchor in scanned, anchor


def test_no_brand_names_in_package_content() -> None:
    hits = []
    for path in _scanned_files():
        text = (REPO_ROOT / path).read_text(encoding="utf-8")
        hits.extend(
            f"{path}:{number}: {line}" for number, line in find_brand_names(text)
        )
    assert not hits, "brand names found:\n" + "\n".join(hits)
