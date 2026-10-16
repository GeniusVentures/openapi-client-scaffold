"""Run every committed generator (the families in ``COMMITTED_GENERATORS``)."""
from __future__ import annotations

import argparse
import subprocess
import sys

from scaffold_codegen.generators import COMMITTED_GENERATORS


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python -m scaffold_codegen.generators",
        description="Regenerate every committed generator family under lib/.",
    )
    parser.parse_args(argv)
    for name in COMMITTED_GENERATORS:
        module = f"scaffold_codegen.generators.{name}"
        # A subprocess keeps each driver's argv parsing identical to its documented command.
        result = subprocess.run([sys.executable, "-m", module], check=False)
        if result.returncode != 0:
            print(f"ERROR: {module} exited {result.returncode}", file=sys.stderr)
            return result.returncode
    return 0


if __name__ == "__main__":
    sys.exit(main())
