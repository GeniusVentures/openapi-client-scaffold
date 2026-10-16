"""Tests for scaffold_codegen.generators.theme_defaults (design tokens -> lib/theme defaults)."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from decimal import Decimal
from pathlib import Path

import pytest

from scaffold_codegen import DESIGN_TOKENS, LIB_THEME_DIR, REPO_ROOT
from scaffold_codegen.generators import theme_defaults
from scaffold_codegen.generators.theme_defaults import (
    REGIONS,
    ThemeTokenError,
    dart_double,
    render_files,
    run,
)

DIMENS_FILE = "scaffold_dimens.dart"


@pytest.fixture
def workdir(tmp_path: Path) -> tuple[Path, Path]:
    """Copies of the token file and the generated-into theme files; the repo is never written."""
    tokens = tmp_path / "design_tokens.json"
    shutil.copyfile(DESIGN_TOKENS, tokens)
    theme = tmp_path / "theme"
    theme.mkdir()
    for file_name in {row[0] for row in REGIONS}:
        shutil.copyfile(LIB_THEME_DIR / file_name, theme / file_name)
    return tokens, theme


def _subprocess_env() -> dict[str, str]:
    env = dict(os.environ)
    tools = str(REPO_ROOT / "tools")
    existing = env.get("PYTHONPATH", "")
    env["PYTHONPATH"] = f"{tools}{os.pathsep}{existing}" if existing else tools
    return env


def test_committed_files_match_render() -> None:
    for path, content in render_files().items():
        assert path.read_bytes() == content.encode("utf-8"), path.name


def test_cli_check_passes_on_real_repo() -> None:
    completed = subprocess.run(
        [sys.executable, "-m", "scaffold_codegen.generators.theme_defaults", "--check"],
        capture_output=True,
        text=True,
        timeout=30,
        cwd=REPO_ROOT,
        env=_subprocess_env(),
    )
    assert completed.returncode == 0, completed.stderr


def test_token_change_fails_check_until_regenerated(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    text = tokens.read_text(encoding="utf-8")
    assert '"horizontalPadding": 20.0' in text
    edited = text.replace('"horizontalPadding": 20.0', '"horizontalPadding": 21.0')
    tokens.write_text(edited, encoding="utf-8")

    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert "    horizontalPadding: 21.0,\n" in (theme / DIMENS_FILE).read_text(encoding="utf-8")
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 0


def test_hand_edit_fails_check_and_regeneration_restores(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    target = theme / DIMENS_FILE
    original = target.read_bytes()
    assert b"    appBarHeight: 65.0,\n" in original
    target.write_bytes(original.replace(b"    appBarHeight: 65.0,\n", b"    appBarHeight: 66.0,\n"))

    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert target.read_bytes() == (LIB_THEME_DIR / DIMENS_FILE).read_bytes()


def test_check_writes_nothing(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    target = theme / DIMENS_FILE
    drifted = target.read_bytes().replace(b"appBarHeight: 65.0", b"appBarHeight: 66.0")
    target.write_bytes(drifted)
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert target.read_bytes() == drifted


def test_output_has_no_carriage_return(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    crlf = (theme / DIMENS_FILE).read_bytes().replace(b"\n", b"\r\n")
    (theme / DIMENS_FILE).write_bytes(crlf)
    for content in render_files(tokens, theme).values():
        assert "\r" not in content
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert b"\r" not in (theme / DIMENS_FILE).read_bytes()


def test_dart_double_keeps_literal_digits() -> None:
    assert dart_double("x", Decimal("0.40")) == "0.40"
    assert dart_double("x", Decimal("20.0")) == "20.0"


@pytest.mark.parametrize("value", [20, True, "20.0", Decimal("1E+1"), 1.5, None])
def test_dart_double_rejects_non_decimal_forms(value: object) -> None:
    with pytest.raises(ThemeTokenError):
        dart_double("x", value)


def test_missing_scaffold_key(workdir: tuple[Path, Path], capsys: pytest.CaptureFixture[str]) -> None:
    tokens, theme = workdir
    data = json.loads(tokens.read_text(encoding="utf-8"))
    del data["scaffold"]
    tokens.write_text(json.dumps(data), encoding="utf-8")
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert "scaffold" in capsys.readouterr().err


def test_missing_begin_marker(workdir: tuple[Path, Path], capsys: pytest.CaptureFixture[str]) -> None:
    tokens, theme = workdir
    target = theme / DIMENS_FILE
    lines = [
        line
        for line in target.read_text(encoding="utf-8").split("\n")
        if "GENERATED from design_tokens.json scaffold.dimens" not in line
    ]
    target.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert "scaffold.dimens" in capsys.readouterr().err


def test_bad_entry_name_is_rejected(workdir: tuple[Path, Path], capsys: pytest.CaptureFixture[str]) -> None:
    tokens, theme = workdir
    data = json.loads(tokens.read_text(encoding="utf-8"))
    data["scaffold"]["dimens"]["_comment"] = "x"
    tokens.write_text(json.dumps(data), encoding="utf-8")
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert "_comment" in capsys.readouterr().err


def test_cli_has_no_token_path_option() -> None:
    with pytest.raises(SystemExit) as exc:
        theme_defaults.main(["--tokens", "x"])
    assert exc.value.code == 2


def test_existing_token_keys_and_order_preserved() -> None:
    data = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))
    assert list(data) == ["_comment", "color", "typography", "shape", "elevation", "scaffold"]
