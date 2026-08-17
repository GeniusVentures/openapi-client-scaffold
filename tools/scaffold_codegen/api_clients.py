#!/usr/bin/env python3
"""
scaffold_codegen.api_clients

Generates typed API clients from OpenAPI specs using openapi-generator-cli.
Supports multiple generator targets: dart-dio, typescript-axios, javascript, etc.

Reads specs from ../api-specs/*_openapi.json (parent project).
Generates into generated/{language}/{domain}/ (gitignored, never committed).

Usage:
    python3 -m scaffold_codegen.api_clients                     # all generators, all specs
    python3 -m scaffold_codegen.api_clients -g typescript-axios # specific generator
    python3 -m scaffold_codegen.api_clients -g dart-dio -s gsm  # specific generator + spec

Requires ``tools/`` on ``PYTHONPATH`` (or an editable install of this package).
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

from scaffold_codegen import REPO_ROOT

# Generator configurations — add new targets here
GENERATORS = {
    "dart-dio": {
        "output_dir": "dart",
        "additional_properties": [
            "serializationLibrary=json_serializable",
        ],
    },
    "typescript-axios": {
        "output_dir": "typescript",
        "additional_properties": [
            "npmName=@geniusventures/api-client",
            "supportsES6=true",
        ],
    },
    "javascript": {
        "output_dir": "javascript",
        "additional_properties": [
            "usePromises=true",
            "emitModelMethods=true",
        ],
    },
}


def find_openapi_generator():
    """Find openapi-generator-cli on the system."""
    if shutil.which("openapi-generator-cli"):
        return "openapi-generator-cli"
    candidates = [
        Path.home() / "Library" / "pnpm" / "bin" / "openapi-generator-cli",
        Path.home() / ".local" / "bin" / "openapi-generator-cli",
        Path.home() / "node_modules" / ".bin" / "openapi-generator-cli",
    ]
    for candidate in candidates:
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


def main():
    parser = argparse.ArgumentParser(
        description="Generate typed API clients from OpenAPI specs"
    )
    parser.add_argument(
        "-g", "--generator",
        choices=list(GENERATORS.keys()),
        help="Specific generator to run (default: all)"
    )
    parser.add_argument(
        "-s", "--spec",
        help="Specific spec to generate (without _openapi.json suffix, e.g. 'gsm')"
    )
    args = parser.parse_args()

    scaffold_root = REPO_ROOT  # frontend/ submodule root
    project_root = scaffold_root.parent  # parent project root

    spec_dir = project_root / "api-specs"
    output_base = scaffold_root / "generated"

    openapi_gen = find_openapi_generator()
    if openapi_gen is None:
        print("ERROR: openapi-generator-cli not found.", file=sys.stderr)
        print("Install with: pnpm install -g @openapitools/openapi-generator-cli", file=sys.stderr)
        sys.exit(1)

    if not spec_dir.is_dir():
        print(f"ERROR: Spec directory not found at {spec_dir}", file=sys.stderr)
        print("Create api-specs/ in the parent project with *_openapi.json files.", file=sys.stderr)
        sys.exit(1)

    generators_to_run = [args.generator] if args.generator else list(GENERATORS.keys())

    print(f"Using openapi-generator-cli: {openapi_gen}")
    print(f"Spec directory: {spec_dir}")
    print(f"Output directory: {output_base}")
    print()

    spec_files = sorted(spec_dir.glob("*_openapi.json"))
    if args.spec:
        spec_files = [f for f in spec_files if f.stem == f"{args.spec}_openapi"]
    if not spec_files:
        print("ERROR: No *_openapi.json specs found.", file=sys.stderr)
        sys.exit(1)

    total_count = 0
    for gen_name in generators_to_run:
        gen_config = GENERATORS[gen_name]
        gen_output_dir = output_base / gen_config["output_dir"]

        for spec in spec_files:
            domain = spec.stem.replace("_openapi", "")
            output_dir = gen_output_dir / domain

            print(f"[{gen_name}] Generating {domain}...")

            if output_dir.exists():
                shutil.rmtree(output_dir)

            cmd = [
                openapi_gen, "generate",
                "-i", str(spec),
                "-g", gen_name,
                "-o", str(output_dir),
                "--skip-validate-spec",
            ]
            for prop in gen_config["additional_properties"]:
                cmd.extend(["--additional-properties", prop])

            result = subprocess.run(cmd, capture_output=True, text=True)

            if result.returncode != 0:
                print(f"  WARNING: Generation failed for {domain}: {result.stderr.strip()}")
                continue

            total_count += 1
            print(f"  ✓ {gen_name}/{domain}")

    print(f"\nGenerated {total_count} client(s).")


if __name__ == "__main__":
    main()
