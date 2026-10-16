"""Runner tests: one classified list of generator modules, fail-fast subprocess loop."""
from __future__ import annotations

import pkgutil
import subprocess
import sys

import pytest

from scaffold_codegen import generators
from scaffold_codegen.generators import __main__ as runner


def test_every_generator_module_is_classified() -> None:
    modules = {m.name for m in pkgutil.iter_modules(generators.__path__)} - {"__main__"}
    committed = set(generators.COMMITTED_GENERATORS)
    consumer = set(generators.CONSUMER_GENERATORS)
    assert committed.isdisjoint(consumer)
    assert committed | consumer == modules


def test_runs_every_committed_generator_in_order(monkeypatch: pytest.MonkeyPatch) -> None:
    calls: list[list[str]] = []

    def fake_run(argv: list[str], **_: object) -> subprocess.CompletedProcess[str]:
        calls.append(argv)
        return subprocess.CompletedProcess(argv, 0)

    monkeypatch.setattr(runner.subprocess, "run", fake_run)
    assert runner.main([]) == 0
    assert calls == [
        [sys.executable, "-m", f"scaffold_codegen.generators.{name}"]
        for name in generators.COMMITTED_GENERATORS
    ]


def test_stops_on_first_failure(
    monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    calls: list[str] = []

    def fake_run(argv: list[str], **_: object) -> subprocess.CompletedProcess[str]:
        calls.append(argv[-1])
        code = 1 if argv[-1].endswith(".composites") else 0
        return subprocess.CompletedProcess(argv, code)

    monkeypatch.setattr(runner.subprocess, "run", fake_run)
    assert runner.main([]) == 1
    assert calls[-1] == "scaffold_codegen.generators.composites"
    assert "scaffold_codegen.generators.composites" in capsys.readouterr().err


def test_rejects_options() -> None:
    with pytest.raises(SystemExit) as exc:
        runner.main(["--check"])
    assert exc.value.code == 2
