"""CSS drift tests: committed snapshot, --check contract, additive-namespace inertness."""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

from scaffold_codegen import DESIGN_TOKENS, REPO_ROOT
from scaffold_codegen.m3_tokens_css import generate_css

_SCRIPT = REPO_ROOT / "tools" / "scaffold_codegen" / "m3_tokens_css.py"
_FIXTURE = REPO_ROOT / "tools" / "tests" / "fixtures" / "m3_tokens.css"


def _run_bare(*args: str) -> subprocess.CompletedProcess[str]:
    """Run the script the way CMake does: no PYTHONPATH."""
    env = {k: v for k, v in os.environ.items() if k != "PYTHONPATH"}
    return subprocess.run(
        [sys.executable, str(_SCRIPT), *args],
        capture_output=True,
        text=True,
        timeout=30,
        cwd=REPO_ROOT,
        env=env,
    )


def test_fixture_matches_generated_css() -> None:
    tokens = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))
    assert _FIXTURE.read_bytes() == generate_css(tokens).encode("utf-8")


def test_check_passes_when_clean_and_does_not_write() -> None:
    before = _FIXTURE.read_bytes()
    result = _run_bare(
        "--tokens", str(DESIGN_TOKENS), "--output", str(_FIXTURE), "--check"
    )
    assert result.returncode == 0, result.stderr
    assert _FIXTURE.read_bytes() == before


def test_check_fails_on_token_drift(tmp_path: Path) -> None:
    tokens = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))
    tokens["color"]["roles"]["primary"]["light"] = "#000000"
    drifted = tmp_path / "tokens.json"
    drifted.write_text(json.dumps(tokens), encoding="utf-8", newline="\n")
    before = _FIXTURE.read_bytes()

    result = _run_bare(
        "--tokens", str(drifted), "--output", str(_FIXTURE), "--check"
    )

    assert result.returncode == 1
    assert "out of date" in result.stderr
    assert _FIXTURE.read_bytes() == before


def test_check_fails_when_output_missing(tmp_path: Path) -> None:
    missing = tmp_path / "absent.css"
    result = _run_bare(
        "--tokens", str(DESIGN_TOKENS), "--output", str(missing), "--check"
    )
    assert result.returncode == 1
    assert "out of date" in result.stderr
    assert not missing.exists()


def test_scaffold_namespace_is_inert_for_css() -> None:
    tokens = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))
    base = {k: v for k, v in tokens.items() if k != "scaffold"}
    extended = {
        **base,
        "scaffold": {
            "palette": {"dark": {"surface": "#000000"}, "light": {"surface": "#FFFFFF"}},
            "dimens": {"gap": 8},
        },
    }
    assert generate_css(base) == generate_css(extended)


def test_bare_script_without_check_still_writes(tmp_path: Path) -> None:
    out = tmp_path / "nested" / "m3_tokens.css"
    result = _run_bare("--tokens", str(DESIGN_TOKENS), "--output", str(out))
    assert result.returncode == 0, result.stderr
    assert out.read_bytes() == _FIXTURE.read_bytes()
