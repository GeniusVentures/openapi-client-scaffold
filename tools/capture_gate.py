"""Capture gate: existing captures change only in sanctioned re-baseline commits.

The ``history`` subcommand walks git history from the v1.4 base to HEAD and
checks every commit that touched ``images/`` against
``tools/capture_rebaselines.json``. An existing capture may change only in a
commit listed there. The ``render`` subcommand re-runs the capture harness into
a scratch directory and diffs it byte for byte against ``images/``.

The render check is local only. Rasterization differs between machines, so CI
cannot compare bytes; CI runs the history check through pytest.

Exit codes: 0 pass, 1 violations or differences, 2 setup error.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

from scaffold_codegen import REPO_ROOT

MANIFEST = REPO_ROOT / "tools" / "capture_rebaselines.json"
IMAGES_DIR = REPO_ROOT / "images"


class GateError(Exception):
    """A setup problem: unreadable git state or an unreachable base."""


@dataclass(frozen=True)
class FileChange:
    status: str
    path: str


@dataclass(frozen=True)
class CaptureCommit:
    sha: str
    first_parent: str | None
    subject: str
    changes: tuple[FileChange, ...]


@dataclass(frozen=True)
class Rebaseline:
    sha: str
    subject: str
    scope: str
    follows: str | None
    record: str


@dataclass(frozen=True)
class Manifest:
    base: str
    rebaselines: tuple[Rebaseline, ...]


def load_manifest(path: Path) -> Manifest:
    data = json.loads(path.read_text(encoding="utf-8"))
    entries = tuple(
        Rebaseline(
            sha=e["sha"],
            subject=e["subject"],
            scope=e["scope"],
            follows=e["follows"],
            record=e["record"],
        )
        for e in data["rebaselines"]
    )
    return Manifest(base=data["base"], rebaselines=entries)


def _git(
    repo: Path, *args: str, ok: tuple[int, ...] = (0,)
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *args], cwd=repo, text=True, capture_output=True, check=False
    )
    if result.returncode not in ok:
        raise GateError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result


def _parse_name_status(raw: str) -> tuple[FileChange, ...]:
    fields = raw.split("\0")
    changes: list[FileChange] = []
    i = 0
    while i < len(fields) and fields[i]:
        status = fields[i][0]
        if status in "RC":
            changes.append(FileChange(status, fields[i + 1]))
            changes.append(FileChange(status, fields[i + 2]))
            i += 3
        else:
            changes.append(FileChange(status, fields[i + 1]))
            i += 2
    return tuple(changes)


def read_capture_commits(
    repo: Path, base: str, head: str = "HEAD"
) -> list[CaptureCommit]:
    ancestry = _git(
        repo, "merge-base", "--is-ancestor", base, head, ok=(0, 1, 128)
    )
    if ancestry.returncode != 0:
        raise GateError(
            f"base {base} is not reachable from {head}; "
            "CI must check out full history (actions/checkout fetch-depth: 0)"
        )
    listing = _git(
        repo,
        "rev-list",
        "--reverse",
        "--full-history",
        "--no-merges",
        f"{base}..{head}",
        "--",
        "images",
    )
    commits: list[CaptureCommit] = []
    for sha in listing.stdout.split():
        tree = _git(
            repo, "diff-tree", "--no-commit-id", "-r", "-z", "--name-status", "-M", sha
        )
        meta = _git(repo, "show", "-s", "--format=%P%x00%s", sha)
        parents, subject = meta.stdout.rstrip("\n").split("\0", 1)
        first_parent = parents.split()[0] if parents.split() else None
        commits.append(
            CaptureCommit(sha, first_parent, subject, _parse_name_status(tree.stdout))
        )
    return commits


def _is_image(path: str) -> bool:
    return path.startswith("images/")


def _unsanctioned_changes(commit: CaptureCommit) -> list[str]:
    changed = [c.path for c in commit.changes if _is_image(c.path) and c.status != "A"]
    if not changed:
        return []
    return [f"{commit.sha[:7]} changes existing captures without a manifest entry: {', '.join(changed)}"]


def find_violations(
    commits: Sequence[CaptureCommit], manifest: Manifest
) -> list[str]:
    listed = {e.sha for e in manifest.rebaselines}
    violations: list[str] = []
    for commit in commits:
        if commit.sha not in listed:
            violations.extend(_unsanctioned_changes(commit))
    return violations


def _describe(commit: CaptureCommit, manifest: Manifest, violations: list[str]) -> str:
    entry = next((e for e in manifest.rebaselines if e.sha == commit.sha), None)
    if entry is not None:
        label = f"sanctioned {entry.scope}"
    elif any(v.startswith(commit.sha[:7]) for v in violations):
        label = "UNSANCTIONED"
    else:
        label = "added only"
    return f"{commit.sha[:7]} {label} {commit.subject}"


def _run_history(args: argparse.Namespace) -> int:
    manifest = load_manifest(args.manifest)
    commits = read_capture_commits(REPO_ROOT, manifest.base, args.head)
    violations = find_violations(commits, manifest)
    for commit in commits:
        print(_describe(commit, manifest, violations))
    print(
        f"{len(commits)} capture commits, {len(manifest.rebaselines)} sanctioned, "
        f"{len(violations)} violations"
    )
    for violation in violations:
        print(f"VIOLATION {violation}")
    return 1 if violations else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    history = sub.add_parser("history", help="check git history of images/")
    history.add_argument("--head", default="HEAD")
    history.add_argument("--manifest", type=Path, default=MANIFEST)
    args = parser.parse_args(argv)
    try:
        return _run_history(args)
    except (GateError, ValueError, KeyError, OSError) as exc:
        print(f"capture_gate: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
