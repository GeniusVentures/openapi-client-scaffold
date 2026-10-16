"""Capture gate rules on synthetic commits, plus the real repository history."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from capture_gate import (
    MANIFEST,
    CaptureCommit,
    FileChange,
    GateError,
    Manifest,
    Rebaseline,
    find_violations,
    load_manifest,
    main,
    read_capture_commits,
)
from scaffold_codegen import REPO_ROOT

SHA = "a" * 40
EMPTY = Manifest(base="b" * 40, rebaselines=())


def _commit(*changes: FileChange) -> CaptureCommit:
    return CaptureCommit(SHA, "c" * 40, "chore: change captures", changes)


def test_repository_capture_history_is_sanctioned():
    manifest = load_manifest(MANIFEST)
    commits = read_capture_commits(REPO_ROOT, manifest.base)
    assert find_violations(commits, manifest) == []


def test_unlisted_png_modification_is_a_violation():
    commit = _commit(FileChange("M", "images/foo_light.png"))
    violations = find_violations([commit], EMPTY)
    assert len(violations) == 1
    assert violations[0].startswith(SHA[:7])


def test_added_only_commit_passes_unlisted():
    commit = _commit(FileChange("A", "images/new_light.png"))
    assert find_violations([commit], EMPTY) == []


def _entry(**overrides) -> Rebaseline:
    fields = {
        "sha": SHA,
        "subject": "chore: change captures",
        "scope": "default",
        "follows": "c" * 40,
        "record": "test record",
    }
    fields.update(overrides)
    return Rebaseline(**fields)


def _manifest(*entries: Rebaseline) -> Manifest:
    return Manifest(base="b" * 40, rebaselines=entries)


def _png(path: str, status: str = "M") -> FileChange:
    return FileChange(status, path)


def test_unlisted_non_png_under_images_is_a_violation():
    commit = _commit(FileChange("A", "images/notes.txt"))
    violations = find_violations([commit], EMPTY)
    assert any("images/notes.txt" in v for v in violations)


def test_listed_non_png_under_images_is_a_violation():
    commit = _commit(_png("images/x.gif"))
    violations = find_violations([commit], _manifest(_entry()))
    assert any("images/x.gif" in v for v in violations)


def test_listed_commit_touching_non_image_path_is_a_violation():
    commit = _commit(
        _png("images/chip_light.png"), FileChange("M", "lib/theme/scaffold_palette.dart")
    )
    violations = find_violations([commit], _manifest(_entry()))
    assert any("lib/theme/scaffold_palette.dart" in v for v in violations)


def test_midnight_entry_changing_default_capture_is_a_violation():
    commit = _commit(_png("images/chip_light.png"))
    violations = find_violations([commit], _manifest(_entry(scope="midnight")))
    assert any("images/chip_light.png" in v for v in violations)


def test_default_entry_changing_midnight_capture_is_a_violation():
    commit = _commit(_png("images/midnight/chip_light.png"))
    violations = find_violations([commit], _manifest(_entry(scope="default")))
    assert any("images/midnight/chip_light.png" in v for v in violations)


def test_midnight_entry_changing_only_midnight_passes():
    commit = _commit(_png("images/midnight/chip_light.png"))
    assert find_violations([commit], _manifest(_entry(scope="midnight"))) == []


def test_default_entry_changing_only_default_passes():
    commit = _commit(_png("images/chip_light.png"))
    assert find_violations([commit], _manifest(_entry())) == []


def test_subject_mismatch_is_a_violation():
    commit = _commit(_png("images/chip_light.png"))
    violations = find_violations([commit], _manifest(_entry(subject="other")))
    assert any("subject" in v for v in violations)


def test_follows_mismatch_is_a_violation():
    commit = _commit(_png("images/chip_light.png"))
    violations = find_violations([commit], _manifest(_entry(follows="d" * 40)))
    assert any("follows" in v for v in violations)


def test_null_follows_skips_the_parent_check():
    commit = _commit(_png("images/chip_light.png"))
    assert find_violations([commit], _manifest(_entry(follows=None))) == []


def test_entry_without_a_matching_commit_is_a_violation():
    violations = find_violations([], _manifest(_entry()))
    assert len(violations) == 1
    assert violations[0].startswith(SHA[:7])


def test_unlisted_rename_is_a_violation():
    commit = _commit(
        FileChange("R", "images/a.png"), FileChange("R", "images/b.png")
    )
    violations = find_violations([commit], EMPTY)
    assert any("images/a.png" in v for v in violations)


def _write_manifest(tmp_path, mutate) -> Path:
    data = {
        "base": "b" * 40,
        "rebaselines": [
            {
                "sha": SHA,
                "subject": "s",
                "scope": "default",
                "follows": None,
                "record": "r",
            }
        ],
    }
    mutate(data)
    path = tmp_path / "manifest.json"
    path.write_text(json.dumps(data), encoding="utf-8", newline="\n")
    return path


def _first(data):
    return data["rebaselines"][0]


@pytest.mark.parametrize(
    "mutate",
    [
        lambda d: d.update(extra=1),
        lambda d: _first(d).update(extra=1),
        lambda d: _first(d).pop("record"),
        lambda d: _first(d).update(sha="abc1234"),
        lambda d: _first(d).update(sha="A" * 40),
        lambda d: _first(d).update(follows="F" * 40),
        lambda d: d.update(base="short"),
        lambda d: _first(d).update(scope="other"),
        lambda d: _first(d).update(subject=""),
        lambda d: _first(d).update(record=""),
        lambda d: d["rebaselines"].append(dict(_first(d))),
    ],
)
def test_malformed_manifest_raises_value_error(tmp_path, mutate):
    with pytest.raises(ValueError):
        load_manifest(_write_manifest(tmp_path, mutate))


def test_valid_manifest_loads(tmp_path):
    manifest = load_manifest(_write_manifest(tmp_path, lambda d: None))
    assert manifest.rebaselines[0].sha == SHA
    assert manifest.rebaselines[0].follows is None


def test_cli_exits_2_on_malformed_manifest(tmp_path):
    path = _write_manifest(tmp_path, lambda d: _first(d).update(scope="bogus"))
    assert main(["history", "--manifest", str(path)]) == 2


def test_unreachable_base_names_fetch_depth():
    with pytest.raises(GateError, match="fetch-depth: 0"):
        read_capture_commits(REPO_ROOT, "0" * 40)
