"""Every codegen writer must emit LF line endings on every OS (TOK-04)."""
from __future__ import annotations

import ast
import os
import subprocess
import sys
from pathlib import Path

from scaffold_codegen import DESIGN_TOKENS, REPO_ROOT
from scaffold_codegen.engine import create_environment, render_template

_CODEGEN_DIR = REPO_ROOT / "tools" / "scaffold_codegen"


def _has_lf_newline(call: ast.Call) -> bool:
    for kw in call.keywords:
        if kw.arg == "newline":
            return isinstance(kw.value, ast.Constant) and kw.value.value == "\n"
    return False


def _is_text_write_open(call: ast.Call) -> bool:
    if not (isinstance(call.func, ast.Name) and call.func.id == "open"):
        return False
    mode = None
    if len(call.args) >= 2 and isinstance(call.args[1], ast.Constant):
        mode = call.args[1].value
    for kw in call.keywords:
        if kw.arg == "mode" and isinstance(kw.value, ast.Constant):
            mode = kw.value.value
    if not isinstance(mode, str):
        return False
    return any(c in mode for c in "wax") and "b" not in mode


def _is_write_text(call: ast.Call) -> bool:
    return isinstance(call.func, ast.Attribute) and call.func.attr == "write_text"


def test_every_text_writer_passes_lf_newline() -> None:
    offenders: list[str] = []
    for path in sorted(_CODEGEN_DIR.rglob("*.py")):
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        for node in ast.walk(tree):
            if not isinstance(node, ast.Call):
                continue
            if (_is_write_text(node) or _is_text_write_open(node)) and not _has_lf_newline(node):
                offenders.append(f"{path.relative_to(REPO_ROOT)}:{node.lineno}")
    assert not offenders, f"writers missing newline=\"\\n\": {offenders}"


def test_render_template_writes_lf_only(tmp_path: Path) -> None:
    tpl_dir = tmp_path / "tpl"
    tpl_dir.mkdir()
    (tpl_dir / "two_lines.jinja2").write_bytes(b"first {{ a }}\nsecond\n")
    out = tmp_path / "out" / "result.txt"

    env = create_environment([str(tpl_dir)])
    render_template(env, "two_lines.jinja2", str(out), {"a": "x"})

    data = out.read_bytes()
    assert b"\n" in data
    assert b"\r" not in data


def test_m3_tokens_css_bare_script_writes_lf_only(tmp_path: Path) -> None:
    out = tmp_path / "m3_tokens.css"
    env = {k: v for k, v in os.environ.items() if k != "PYTHONPATH"}
    completed = subprocess.run(
        [
            sys.executable,
            str(_CODEGEN_DIR / "m3_tokens_css.py"),
            "--tokens",
            str(DESIGN_TOKENS),
            "--output",
            str(out),
        ],
        capture_output=True,
        text=True,
        timeout=30,
        cwd=REPO_ROOT,
        env=env,
    )
    assert completed.returncode == 0, completed.stderr
    data = out.read_bytes()
    assert b"\n" in data
    assert b"\r" not in data
