"""Compare two logical-changes.json files and write one-way containment results."""

from __future__ import annotations

import argparse
from pathlib import Path

from tracing_logical_compare import compare_logical_changes, load_logical_changes, write_compare_results


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare baseline logical changes against a target logical-changes.json artifact."
    )
    parser.add_argument("--baseline-file", required=True, help="Baseline logical-changes.json to require")
    parser.add_argument("--target-file", required=True, help="Target logical-changes.json to search")
    parser.add_argument(
        "--output-file",
        help="Where to write compare-results.json; defaults next to the baseline file",
    )
    return parser.parse_args()


def default_output_path(baseline_file: Path, target_file: Path) -> Path:
    baseline_label = baseline_file.resolve().parent.name
    target_label = target_file.resolve().parent.name
    return baseline_file.resolve().parent / f"compare-results-{baseline_label}-vs-{target_label}.json"


def main() -> int:
    args = parse_args()
    baseline_file = Path(args.baseline_file)
    target_file = Path(args.target_file)
    output_file = Path(args.output_file) if args.output_file else default_output_path(baseline_file, target_file)

    baseline_changes = load_logical_changes(baseline_file)
    target_changes = load_logical_changes(target_file)
    results = compare_logical_changes(
        baseline_changes,
        target_changes,
        str(baseline_file),
        str(target_file),
    )
    write_compare_results(output_file, results)

    print(f"Baseline changes: {results['summary']['baseline_change_count']}")
    print(f"Target changes:   {results['summary']['target_change_count']}")
    print(f"Matched:          {results['summary']['matched_change_count']}")
    print(f"Missing:          {results['summary']['missing_change_count']}")
    print(f"Skipped:          {results['summary']['skipped_change_count']}")
    print(f"Output written to: {output_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())