"""Render a logical-changes.json artifact as a human-friendly Markdown report."""

from __future__ import annotations

import argparse
from pathlib import Path

from tracing_logical_markdown import load_and_render_logical_changes_markdown


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert a logical-changes.json artifact into a Markdown summary report."
    )
    parser.add_argument("--input-file", required=True, help="Path to logical-changes.json")
    parser.add_argument(
        "--output-file",
        help="Where to write the Markdown report; defaults next to the input file",
    )
    return parser.parse_args()


def default_output_path(input_file: Path) -> Path:
    return input_file.resolve().parent / "logical-changes.md"


def main() -> int:
    args = parse_args()
    input_file = Path(args.input_file)
    output_file = Path(args.output_file) if args.output_file else default_output_path(input_file)

    load_and_render_logical_changes_markdown(input_file, output_file)
    print(f"Output written to: {output_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())