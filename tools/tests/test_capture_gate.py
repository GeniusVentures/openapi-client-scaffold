"""Capture gate rules on synthetic commits, plus the real repository history."""
from __future__ import annotations

from capture_gate import (
    MANIFEST,
    CaptureCommit,
    FileChange,
    Manifest,
    find_violations,
    load_manifest,
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
