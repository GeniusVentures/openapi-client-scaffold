#!/usr/bin/env python3
"""
Tests for scaffold_codegen.m3_tokens_css — M3 design token to CSS custom
property generator.

Tests exercise the CLI entry point via subprocess.run(), validating exit codes,
stderr messages, and output file content against design_tokens.json.
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile

import pytest

from scaffold_codegen import DESIGN_TOKENS, REPO_ROOT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

#: The CLI runs in a subprocess, which does not inherit pytest's ``pythonpath``
#: setting (that only mutates the test process's sys.path). Put tools/ on the
#: child's PYTHONPATH so the package resolves without an editable install.
_TOOLS_DIR = REPO_ROOT / "tools"


def _subprocess_env() -> dict[str, str]:
    """Return os.environ with tools/ prepended to PYTHONPATH."""
    env = dict(os.environ)
    existing = env.get("PYTHONPATH", "")
    env["PYTHONPATH"] = (
        f"{_TOOLS_DIR}{os.pathsep}{existing}" if existing else str(_TOOLS_DIR)
    )
    return env


class RunResult:
    def __init__(self, completed):
        self.returncode = completed.returncode
        self.stdout = completed.stdout
        self.stderr = completed.stderr


def _resolve_tokens_path() -> str:
    """Return the absolute path to the design_tokens.json fixture."""
    return str(DESIGN_TOKENS)


def _run_script(*args: str) -> RunResult:
    """Execute the m3_tokens_css CLI with the given arguments.

    Invoked as ``python -m scaffold_codegen.m3_tokens_css`` from the repo root
    so the package resolves the same way it does under CMake and CI.

    Returns
    -------
    RunResult
        Completed process with .returncode, .stdout, .stderr as str.
    """
    completed = subprocess.run(
        [sys.executable, "-m", "scaffold_codegen.m3_tokens_css", *args],
        capture_output=True,
        text=True,
        timeout=10,
        cwd=REPO_ROOT,
        env=_subprocess_env(),
    )
    return RunResult(completed)


def _read_output(path: str) -> str:
    """Read a file and return its contents as a string."""
    with open(path, encoding="utf-8") as f:
        return f.read()


# ---------------------------------------------------------------------------
# Test cases
# ---------------------------------------------------------------------------


class TestGenerateM3TokensCss:
    """Test the m3_tokens_css CLI behavior and output correctness."""

    # -- Test 1: Produces a valid CSS file -----------------------------------

    def test_produces_valid_css_file(self):
        """Running with --tokens design_tokens.json --output /tmp/test_tokens.css exits 0
        and writes a file that starts with a CSS comment and contains :root."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0, (
                f"Expected exit code 0, got {result.returncode}\nstderr: {result.stderr}"
            )
            content = _read_output(output_path)
            assert "Auto-generated from design_tokens.json" in content, (
                "Output missing expected comment header"
            )
            assert ":root {" in content, (
                "Output missing :root block"
            )
            assert len(content) > 0, "Output file is empty"
        finally:
            os.unlink(output_path)

    # -- Test 2: Contains --md-sys-color-primary with correct values ---------

    def test_color_primary_values(self):
        """The generated CSS contains --md-sys-color-primary with the correct light
        and dark hex values from design_tokens.json."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            # Light value
            assert "--md-sys-color-primary:" in content
            assert "#6750A4" in content or "#6750a4" in content, (
                f"Expected primary light hex #6750A4 in:\n{content}"
            )

            # Dark value (in dark media query)
            assert "prefers-color-scheme: dark" in content, (
                "Missing dark color scheme media query"
            )
            assert "#D0BCFF" in content or "#d0bcff" in content, (
                f"Expected primary dark hex #D0BCFF in:\n{content}"
            )

            # Verify both occurrences (light + dark)
            count = content.count("--md-sys-color-primary:")
            assert count == 2, (
                f"Expected 2 occurrences of --md-sys-color-primary:, got {count}"
            )
        finally:
            os.unlink(output_path)

    # -- Test 3: --md-sys-typography-display-size: 57px ----------------------

    def test_typography_display_size(self):
        """The generated CSS contains --md-sys-typography-display-size: 57px."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            assert "--md-sys-typography-display-size:" in content, (
                "Missing typography display-size custom property"
            )
            # 57px should appear in the same line as --md-sys-typography-display-size
            for line in content.split("\n"):
                if "--md-sys-typography-display-size:" in line:
                    assert "57px" in line, (
                        f"Expected 57px in typography display-size line, got: {line.strip()}"
                    )
                    break
            else:
                pytest.fail("typography-display-size property not found in output")
        finally:
            os.unlink(output_path)

    # -- Test 4: --md-sys-shape-extra-small: 4px -----------------------------

    def test_shape_extra_small(self):
        """The generated CSS contains --md-sys-shape-extra-small: 4px."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            assert "--md-sys-shape-extra-small:" in content, (
                "Missing shape extra-small custom property"
            )
            for line in content.split("\n"):
                if "--md-sys-shape-extra-small:" in line:
                    assert "4px" in line, (
                        f"Expected 4px in shape extra-small line, got: {line.strip()}"
                    )
                    break
            else:
                pytest.fail("shape-extra-small property not found in output")
        finally:
            os.unlink(output_path)

    # -- Test 5: --md-sys-elevation-level0: none -----------------------------

    def test_elevation_level0_none(self):
        """Empty shadow string (level0) maps to 'none' in CSS."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            assert "--md-sys-elevation-level0:" in content, (
                "Missing elevation level0 custom property"
            )
            # Look for --md-sys-elevation-level0 and verify it maps to 'none'
            for line in content.split("\n"):
                if "--md-sys-elevation-level0:" in line:
                    assert "none" in line, (
                        f"Expected 'none' for level0 shadow, got: {line.strip()}"
                    )
                    break
            else:
                pytest.fail("elevation-level0 property not found in output")
        finally:
            os.unlink(output_path)

    # -- Test 6: Missing tokens file exits 1 with stderr ---------------------

    def test_missing_tokens_file_exits_1(self):
        """Running with --tokens pointing to a missing file exits with code 1
        and writes to stderr."""
        result = _run_script(
            "--tokens", "/nonexistent/tokens.json",
            "--output", "/tmp/test_out.css",
        )
        assert result.returncode == 1, (
            f"Expected exit code 1 for missing file, got {result.returncode}"
        )
        assert "ERROR" in result.stderr, (
            f"Expected ERROR message on stderr for missing file, got: {result.stderr!r}"
        )
        assert "not found" in result.stderr.lower() or "no such file" in result.stderr.lower(), (
            f"Expected 'not found' message on stderr, got: {result.stderr!r}"
        )

    # -- Test 7: Invalid JSON exits 1 with stderr ----------------------------

    def test_invalid_json_tokens_exits_1(self):
        """Running with --tokens pointing to invalid JSON exits with code 1
        and writes to stderr."""
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False
        ) as tmp:
            tmp.write("this is not valid JSON {{{")
            invalid_tokens = tmp.name

        try:
            result = _run_script(
                "--tokens", invalid_tokens,
                "--output", "/tmp/test_out.css",
            )
            assert result.returncode == 1, (
                f"Expected exit code 1 for invalid JSON, got {result.returncode}"
            )
            assert "ERROR" in result.stderr, (
                f"Expected ERROR message on stderr for invalid JSON, got: {result.stderr!r}"
            )
            assert "json" in result.stderr.lower() or "invalid" in result.stderr.lower(), (
                f"Expected JSON-related error on stderr, got: {result.stderr!r}"
            )
        finally:
            os.unlink(invalid_tokens)

    # -- Test 8: Lighting/dark scheme blocks are properly structured ---------

    def test_dark_scheme_block_structure(self):
        """The dark scheme block contains only colors, not typography/shape/elevation."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            # Split into blocks: before dark media query and inside it
            assert "prefers-color-scheme: dark" in content
            dark_start = content.index("@media (prefers-color-scheme: dark)")
            light_block = content[:dark_start]
            dark_block = content[dark_start:]

            # Light block should have typography, shape, elevation
            assert "--md-sys-typography-" in light_block
            assert "--md-sys-shape-" in light_block
            assert "--md-sys-elevation-" in light_block

            # Dark block should NOT have typography, shape, elevation
            assert "--md-sys-typography-" not in dark_block, (
                "Dark scheme block contains typography properties"
            )
            assert "--md-sys-shape-" not in dark_block, (
                "Dark scheme block contains shape properties"
            )
            assert "--md-sys-elevation-" not in dark_block, (
                "Dark scheme block contains elevation properties"
            )

            # Dark block should have dark color values
            assert "--md-sys-color-" in dark_block
        finally:
            os.unlink(output_path)

    # -- Test 9: All 11 color roles are present in the output ----------------

    def test_all_color_roles_present(self):
        """All 11 M3 color roles are present in the generated CSS."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            expected_roles = [
                "primary",
                "secondary",
                "tertiary",
                "error",
                "surface",
                "surface-variant",
                "outline",
                "on-primary",
                "on-secondary",
                "on-surface",
                "on-error",
            ]
            for role in expected_roles:
                prop = f"--md-sys-color-{role}:"
                count = content.count(prop)
                assert count == 2, (
                    f"Expected 2 occurrences of {prop} (light + dark), got {count}"
                )
        finally:
            os.unlink(output_path)

    # -- Test 10: All 5 typography scales have all 4 properties ---------------

    def test_typography_scales_complete(self):
        """All 5 typography scales have size, weight, letter-spacing, and line-height."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            scales = ["display", "headline", "title", "body", "label"]
            properties = ["size", "weight", "letter-spacing", "line-height"]
            for scale in scales:
                for prop in properties:
                    css_var = f"--md-sys-typography-{scale}-{prop}:"
                    assert css_var in content, (
                        f"Missing typography property: {css_var}"
                    )
        finally:
            os.unlink(output_path)

    # -- Test 11: All 5 shape corner sizes are present -----------------------

    def test_shape_corners_complete(self):
        """All 5 shape corner sizes are present in the generated CSS."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            sizes = ["extra-small", "small", "medium", "large", "extra-large"]
            for size in sizes:
                css_var = f"--md-sys-shape-{size}:"
                assert css_var in content, (
                    f"Missing shape corner property: {css_var}"
                )
        finally:
            os.unlink(output_path)

    # -- Test 12: All 6 elevation levels are present -------------------------

    def test_elevation_levels_complete(self):
        """All 6 elevation levels (level0-level5) are present."""
        tokens = _resolve_tokens_path()
        with tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False) as tmp:
            output_path = tmp.name

        try:
            result = _run_script("--tokens", tokens, "--output", output_path)
            assert result.returncode == 0
            content = _read_output(output_path)

            for level in range(6):
                css_var = f"--md-sys-elevation-level{level}:"
                assert css_var in content, (
                    f"Missing elevation property: {css_var}"
                )
        finally:
            os.unlink(output_path)
