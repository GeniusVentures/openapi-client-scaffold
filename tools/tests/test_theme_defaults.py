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
    dart_color,
    dart_curve,
    dart_double,
    dart_duration,
    dart_font_family,
    dart_gradient,
    dart_shadows,
    dart_text_style,
    render_files,
    run,
)

DIMENS_FILE = "scaffold_dimens.dart"
PALETTE_FILE = "scaffold_palette.dart"


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


def test_dart_color_string_and_ref() -> None:
    assert dart_color("x", "0xFF0C0E14") == "Color(0xFF0C0E14)"
    ref = {"value": "0xFF00EAAE", "dartRef": "ScaffoldColors.lightGreenPrimary"}
    assert dart_color("x", ref) == "ScaffoldColors.lightGreenPrimary"


@pytest.mark.parametrize(
    "value",
    [
        "0xff0c0e14",
        "0xFF0C0E",
        "#0C0E14",
        "0xFF0C0E14); evil(",
        {"value": "0xFF00EAAE", "dartRef": "ScaffoldColors.lightGreenPrimary", "extra": 1},
        {"dartRef": "ScaffoldColors.lightGreenPrimary"},
        {"value": "0xFF00EAAE", "dartRef": "Colors.red"},
        {"value": "0xFF00EAAE", "dartRef": "ScaffoldColors.a; b"},
        20,
        None,
    ],
)
def test_dart_color_rejects_invalid(value: object) -> None:
    with pytest.raises(ThemeTokenError):
        dart_color("x", value)


def test_palette_token_change_regenerates_only_that_line(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    data = json.loads(tokens.read_text(encoding="utf-8"))
    assert data["scaffold"]["palette"]["dark"]["statusError"] == "0xFFFF4D4D"
    text = tokens.read_text(encoding="utf-8")
    tokens.write_text(
        text.replace('"statusError": "0xFFFF4D4D"', '"statusError": "0xFFFF0000"'), encoding="utf-8"
    )
    before = (theme / PALETTE_FILE).read_text(encoding="utf-8").splitlines()

    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 0

    after = (theme / PALETTE_FILE).read_text(encoding="utf-8").splitlines()
    changed = [(a, b) for a, b in zip(before, after, strict=True) if a != b]
    assert changed == [("    statusError: Color(0xFFFF4D4D),", "    statusError: Color(0xFFFF0000),")]


def test_palette_regions_hold_22_entries_and_dimens_21() -> None:
    scaffold = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))["scaffold"]
    assert len(scaffold["palette"]["dark"]) == 22
    assert len(scaffold["palette"]["light"]) == 22
    assert len(scaffold["dimens"]) == 21


SHADOWS_FILE = "scaffold_shadows.dart"


def _shadow(**overrides: object) -> dict[str, object]:
    entry: dict[str, object] = {
        "color": "0x59000000",
        "blurRadius": Decimal("16.0"),
        "offset": [Decimal("0.0"), Decimal("4.0")],
    }
    entry.update(overrides)
    return entry


def test_dart_shadows_single_entry() -> None:
    assert dart_shadows("x", [_shadow()]) == (
        "[BoxShadow(color: Color(0x59000000), blurRadius: 16.0, offset: Offset(0.0, 4.0))]"
    )


def test_dart_shadows_joins_entries_and_allows_empty() -> None:
    two = dart_shadows("x", [_shadow(), _shadow(blurRadius=Decimal("2.5"))])
    assert two.count("BoxShadow(") == 2
    assert "), BoxShadow(" in two
    assert two.startswith("[") and two.endswith("]")
    assert dart_shadows("x", []) == "[]"


@pytest.mark.parametrize(
    "value",
    [
        "x",
        {"card": 1},
        [_shadow(extra=1)],
        [{"color": "0x59000000", "blurRadius": Decimal("1.0")}],
        [_shadow(color="0x59abcdef")],
        [_shadow(color="0x590000")],
        [_shadow(color={"value": "0x59000000", "dartRef": "ScaffoldColors.gray500"})],
        [_shadow(blurRadius=16)],
        [_shadow(offset=[Decimal("0.0")])],
        [_shadow(offset=[Decimal("0.0"), Decimal("1.0"), Decimal("2.0")])],
        [_shadow(offset=[0, Decimal("4.0")])],
        [_shadow(offset="0,4")],
        ["not a dict"],
    ],
)
def test_dart_shadows_rejects_invalid(value: object) -> None:
    with pytest.raises(ThemeTokenError):
        dart_shadows("x", value)


def test_committed_shadows_file_matches_render() -> None:
    rendered = render_files()[LIB_THEME_DIR / SHADOWS_FILE]
    committed = (LIB_THEME_DIR / SHADOWS_FILE).read_bytes()
    assert committed == rendered.encode("utf-8")
    assert "    this.card = const [BoxShadow(" in rendered


def test_shadow_token_change_regenerates_only_dark_line(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    text = tokens.read_text(encoding="utf-8")
    dark_start = text.index('"shadows"')
    edited = text[:dark_start] + text[dark_start:].replace(
        '"blurRadius": 16.0', '"blurRadius": 20.0', 1
    )
    assert edited != text
    tokens.write_text(edited, encoding="utf-8")
    before = (theme / SHADOWS_FILE).read_text(encoding="utf-8").splitlines()

    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 0

    after = (theme / SHADOWS_FILE).read_text(encoding="utf-8").splitlines()
    changed = [(a, b) for a, b in zip(before, after, strict=True) if a != b]
    assert len(changed) == 1
    assert changed[0][0].startswith("    this.card = ")
    assert "blurRadius: 20.0" in changed[0][1]


def test_scaffold_group_order_keeps_existing_keys_first() -> None:
    scaffold = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))["scaffold"]
    assert list(scaffold)[:3] == ["_comment", "palette", "dimens"]
    assert scaffold["shadows"]["dark"] == scaffold["shadows"]["light"]


MOTION_FILE = "scaffold_motion_theme.dart"


def test_dart_duration() -> None:
    assert dart_duration("x", 150) == "Duration(milliseconds: 150)"
    assert dart_duration("x", 0) == "Duration(milliseconds: 0)"


@pytest.mark.parametrize("value", [True, -1, Decimal("150.0"), "150", None])
def test_dart_duration_rejects_invalid(value: object) -> None:
    with pytest.raises(ThemeTokenError):
        dart_duration("x", value)


def test_dart_curve() -> None:
    assert dart_curve("x", "Curves.easeInOut") == "Curves.easeInOut"
    points = [Decimal("0.2"), Decimal("0.0"), Decimal("0.0"), Decimal("1.2")]
    assert dart_curve("x", points) == "Cubic(0.2, 0.0, 0.0, 1.2)"


@pytest.mark.parametrize(
    "value",
    [
        "Curves.easeInOut()",
        "curves.linear",
        "Cubic(0.2,0,0,1)",
        [Decimal("0.2"), Decimal("0.0"), Decimal("1.0")],
        [Decimal("0.2"), Decimal("0.0"), Decimal("0.0"), 1],
        5,
    ],
)
def test_dart_curve_rejects_invalid(value: object) -> None:
    with pytest.raises(ThemeTokenError):
        dart_curve("x", value)


def test_motion_token_change_regenerates_only_that_line(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    text = tokens.read_text(encoding="utf-8")
    assert '"medium": 300' in text
    tokens.write_text(text.replace('"medium": 300', '"medium": 350'), encoding="utf-8")
    before = (theme / MOTION_FILE).read_text(encoding="utf-8").splitlines()

    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 0

    after = (theme / MOTION_FILE).read_text(encoding="utf-8").splitlines()
    changed = [(a, b) for a, b in zip(before, after, strict=True) if a != b]
    assert changed == [
        (
            "    this.medium = const Duration(milliseconds: 300),",
            "    this.medium = const Duration(milliseconds: 350),",
        )
    ]


def _style(**overrides: object) -> dict[str, object]:
    style: dict[str, object] = {
        "fontFamily": "Roboto",
        "fontSize": Decimal("14.0"),
        "fontWeight": 400,
        "letterSpacing": Decimal("0.0"),
    }
    style.update(overrides)
    return style


def test_dart_text_style_fixed_order() -> None:
    expected = (
        "TextStyle(fontFamily: 'Roboto', fontSize: 14.0, "
        "fontWeight: FontWeight.w400, letterSpacing: 0.0)"
    )
    assert dart_text_style("x", _style()) == expected
    reordered = dict(reversed(list(_style().items())))
    assert dart_text_style("x", reordered) == expected


def test_dart_text_style_subset() -> None:
    assert dart_text_style("x", {"fontSize": Decimal("12.5")}) == "TextStyle(fontSize: 12.5)"


@pytest.mark.parametrize(
    "value",
    [
        _style(color="0xFFFFFFFF"),
        _style(fontWeight=450),
        _style(fontWeight="w400"),
        _style(fontWeight=True),
        _style(fontSize=14),
        _style(fontFamily="Rob'oto"),
        "TextStyle()",
    ],
)
def test_dart_text_style_rejects_invalid(value: object) -> None:
    with pytest.raises(ThemeTokenError):
        dart_text_style("x", value)


def test_dart_font_family() -> None:
    assert dart_font_family("x", "monospace") == "'monospace'"
    assert dart_font_family("x", "Open Sans") == "'Open Sans'"


@pytest.mark.parametrize("value", ["Rob'oto", "", "1abc", "a\nb", 5, None])
def test_dart_font_family_rejects_invalid(value: object) -> None:
    with pytest.raises(ThemeTokenError):
        dart_font_family("x", value)


def test_typography_group_order_and_m3_key_untouched() -> None:
    data = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))
    assert list(data["scaffold"]) == [
        "_comment",
        "palette",
        "dimens",
        "shadows",
        "motion",
        "typography",
        "colorRoles",
        "gradients",
    ]
    assert data["typography"] != data["scaffold"]["typography"]


COLOR_ROLES_FILE = "scaffold_color_roles.dart"
COLOR_ROLE_NAMES = [
    "accent",
    "accentOnSurface",
    "borderControl",
    "inputForeground",
    "sheetForeground",
    "sheetDivider",
]


def test_committed_color_roles_file_matches_render() -> None:
    rendered = render_files()[LIB_THEME_DIR / COLOR_ROLES_FILE]
    assert (LIB_THEME_DIR / COLOR_ROLES_FILE).read_bytes() == rendered.encode("utf-8")
    assert "    this.accent = ScaffoldColors.lightGreenPrimary,\n" in rendered
    assert "    this.inputForeground = const Color(0xFFFFFFFF),\n" in rendered
    assert "    inputForeground: Color(0xFFFFFFFF),\n" in rendered
    assert rendered.count("// GENERATED from design_tokens.json scaffold.colorRoles") == 2


def test_color_roles_tokens_are_a_dark_light_pair() -> None:
    roles = json.loads(DESIGN_TOKENS.read_text(encoding="utf-8"))["scaffold"]["colorRoles"]
    assert list(roles["dark"]) == COLOR_ROLE_NAMES
    assert list(roles["light"]) == COLOR_ROLE_NAMES


def test_color_role_token_change_regenerates_only_light_line(workdir: tuple[Path, Path]) -> None:
    tokens, theme = workdir
    text = tokens.read_text(encoding="utf-8")
    light_start = text.index('"light"', text.index('"colorRoles"'))
    edited = text[:light_start] + text[light_start:].replace(
        '"sheetDivider": "0x1FFFFFFF"', '"sheetDivider": "0x33FFFFFF"', 1
    )
    assert edited != text
    tokens.write_text(edited, encoding="utf-8")
    before = (theme / COLOR_ROLES_FILE).read_text(encoding="utf-8").splitlines()

    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert run(check=False, tokens_path=tokens, theme_dir=theme) == 0
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 0

    after = (theme / COLOR_ROLES_FILE).read_text(encoding="utf-8").splitlines()
    changed = [(a, b) for a, b in zip(before, after, strict=True) if a != b]
    assert changed == [("    sheetDivider: Color(0x1FFFFFFF),", "    sheetDivider: Color(0x33FFFFFF),")]


GRADIENTS_FILE = "scaffold_gradients.dart"


def test_dart_gradient_accepts_only_null() -> None:
    assert dart_gradient("x", None) is None


@pytest.mark.parametrize("value", [{"colors": []}, "LinearGradient()", [], 0])
def test_dart_gradient_rejects_everything_else(value: object) -> None:
    with pytest.raises(ThemeTokenError, match="x"):
        dart_gradient("x", value)


def test_committed_gradients_region_is_one_line() -> None:
    rendered = render_files()[LIB_THEME_DIR / GRADIENTS_FILE]
    assert (LIB_THEME_DIR / GRADIENTS_FILE).read_bytes() == rendered.encode("utf-8")
    lines = rendered.split("\n")
    begin = lines.index("    // GENERATED from design_tokens.json scaffold.gradients. Do not edit.")
    end = lines.index("    // END GENERATED scaffold.gradients")
    assert lines[begin + 1 : end] == ["    this.edgeFade,"]


def test_non_null_gradient_token_fails_naming_the_entry(
    workdir: tuple[Path, Path],
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    tokens, theme = workdir
    monkeypatch.setattr(
        theme_defaults,
        "REGIONS",
        (("scaffold_gradients.dart", ("scaffold", "gradients"), "gradient", "args"),),
    )
    data = json.loads(tokens.read_text(encoding="utf-8"))
    data["scaffold"]["gradients"]["edgeFade"] = {"colors": ["0xFF000000"]}
    tokens.write_text(json.dumps(data), encoding="utf-8")
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert "scaffold.gradients" in capsys.readouterr().err


def test_gradients_region_in_args_style_rejects_null(
    workdir: tuple[Path, Path],
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    tokens, theme = workdir
    monkeypatch.setattr(
        theme_defaults,
        "REGIONS",
        (("scaffold_gradients.dart", ("scaffold", "gradients"), "gradient", "args"),),
    )
    assert run(check=True, tokens_path=tokens, theme_dir=theme) == 1
    assert "scaffold.gradients.edgeFade" in capsys.readouterr().err
