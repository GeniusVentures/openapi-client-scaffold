"""Tests for scaffold_codegen.generators.theme_presets (preset token files -> lib/theme/presets)."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

from scaffold_codegen import LIB_THEME_DIR, MIDNIGHT_TOKENS, REPO_ROOT
from scaffold_codegen.generators import theme_presets
from scaffold_codegen.generators.theme_presets import REGIONS, main, render_files, run

PRESET_FILE = "presets/midnight_tokens.dart"
FIELD = "textPrimary"


@pytest.fixture
def workdir(tmp_path: Path) -> tuple[Path, Path]:
    """Copies of the token file and the preset Dart file; the repo is never written."""
    tokens = tmp_path / "midnight.json"
    shutil.copyfile(MIDNIGHT_TOKENS, tokens)
    theme = tmp_path / "theme"
    (theme / "presets").mkdir(parents=True)
    shutil.copyfile(LIB_THEME_DIR / PRESET_FILE, theme / PRESET_FILE)
    return tokens, theme


def _subprocess_env() -> dict[str, str]:
    env = dict(os.environ)
    tools = str(REPO_ROOT / "tools")
    existing = env.get("PYTHONPATH", "")
    env["PYTHONPATH"] = f"{tools}{os.pathsep}{existing}" if existing else tools
    return env


def _edit_token(tokens: Path) -> None:
    data = json.loads(tokens.read_text(encoding="utf-8"))
    data["scaffold"]["palette"]["dark"][FIELD] = "0xFF123456"
    tokens.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def test_committed_files_match_render() -> None:
    for path, content in render_files().items():
        assert path.read_bytes() == content.encode("utf-8"), path.name


def test_cli_check_passes_on_real_repo() -> None:
    completed = subprocess.run(
        [sys.executable, "-m", "scaffold_codegen.generators.theme_presets", "--check"],
        capture_output=True,
        text=True,
        timeout=30,
        cwd=REPO_ROOT,
        env=_subprocess_env(),
    )
    assert completed.returncode == 0, completed.stderr


def test_token_edit_drifts_until_regenerated(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    _edit_token(tokens)
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 0
    assert "Color(0xFF123456)" in (theme / PRESET_FILE).read_text(encoding="utf-8")


def test_hand_edited_generated_line_fails_check_and_regenerates(
    workdir: tuple[Path, Path],
) -> None:
    tokens, theme = workdir
    target = theme / PRESET_FILE
    original = target.read_bytes()
    target.write_bytes(original.replace(b"Color(0xFFFFFFFF),", b"Color(0xFFFFFFFE),", 1))
    assert target.read_bytes() != original
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert target.read_bytes() == original


def test_check_writes_nothing(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    _edit_token(tokens)
    before = (theme / PRESET_FILE).read_bytes()
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert (theme / PRESET_FILE).read_bytes() == before


def test_invalid_token_exits_one_without_writing(
    workdir: tuple[Path, Path], capsys: pytest.CaptureFixture[str]
) -> None:
    tokens, theme = workdir
    data = json.loads(tokens.read_text(encoding="utf-8"))
    data["scaffold"]["palette"]["dark"][FIELD] = "0xFFFFFFFF); evil("
    tokens.write_text(json.dumps(data), encoding="utf-8")
    before = (theme / PRESET_FILE).read_bytes()
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 1
    assert FIELD in capsys.readouterr().err
    assert (theme / PRESET_FILE).read_bytes() == before


def test_cli_has_no_token_path_option() -> None:
    with pytest.raises(SystemExit) as excinfo:
        main(["--tokens", "x"])
    assert excinfo.value.code == 2


def test_rendered_output_has_no_carriage_return() -> None:
    for content in render_files().values():
        assert "\r" not in content


def test_every_region_targets_the_presets_folder() -> None:
    assert REGIONS
    for file_name, *_ in REGIONS:
        assert file_name.startswith("presets/")
    assert set(render_files()) == {LIB_THEME_DIR / PRESET_FILE}


def test_driver_has_its_own_region_table() -> None:
    from scaffold_codegen.generators import theme_defaults

    assert theme_presets.REGIONS is not theme_defaults.REGIONS
    assert not set(REGIONS) & set(theme_defaults.REGIONS)


def test_scaffold_gradients_regions_render_an_empty_dark_and_a_light_sheen() -> None:
    lines = render_files()[LIB_THEME_DIR / PRESET_FILE].split("\n")

    def body(region: str) -> list[str]:
        begin = lines.index(f"    // GENERATED from tokens/midnight.json {region}. Do not edit.")
        end = lines.index(f"    // END GENERATED {region}")
        return lines[begin + 1 : end]

    assert body("scaffold.gradients.dark") == []
    light = body("scaffold.gradients.light")
    assert len(light) == 1
    assert light[0].startswith("    surfaceSheen: LinearGradient(")


def test_scaffold_shapes_region_renders_the_focused_border_width() -> None:
    lines = render_files()[LIB_THEME_DIR / PRESET_FILE].split("\n")
    begin = lines.index("    // GENERATED from tokens/midnight.json scaffold.shapes. Do not edit.")
    end = lines.index("    // END GENERATED scaffold.shapes")
    assert lines[begin + 1 : end] == ["    inputFocusedBorderWidth: 2.0,"]


def test_midnight_tokens_have_no_m3_keys() -> None:
    data = json.loads(MIDNIGHT_TOKENS.read_text(encoding="utf-8"))
    assert not {"color", "typography", "shape", "elevation"} & set(data)
