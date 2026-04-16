"""Compare two logical-changes.json files and write one-way containment results."""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
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


def confirm_expected_filename(file_path: Path) -> bool:
    expected_name = "logical-changes.json"
    if file_path.name == expected_name:
        return True

    prompt = f"expecting {expected_name}, you gave {file_path.name} - are you sure? [y/n] "
    while True:
        response = input(prompt).strip().lower()
        if response == "y":
            return True
        if response == "n":
            return False
        print("Please answer y or n.")


def _fmt_identity(fields: dict) -> str:
    return ", ".join(f"{k}={v}" for k, v in fields.items()) if fields else "_(none)_"


def _fmt_payload(payload: dict) -> str:
    if not payload:
        return "_(empty)_"
    lines = [f"| Field | Value |", "| --- | --- |"]
    for k, v in payload.items():
        lines.append(f"| `{k}` | {v} |")
    return "\n".join(lines)


def write_compare_markdown(md_path: Path, results: dict) -> None:
    s = results["summary"]
    baseline_label = results["baseline"]["label"]
    target_label = results["target"]["label"]

    lines: list[str] = []

    lines.append("# Compare Results\n")
    lines.append(f"**Baseline:** `{baseline_label}`  ")
    lines.append(f"**Target:** `{target_label}`\n")

    lines.append("## Summary\n")
    lines.append("| Metric | Count |")
    lines.append("| --- | --- |")
    lines.append(f"| Baseline changes | {s['baseline_change_count']} |")
    lines.append(f"| Target changes | {s['target_change_count']} |")
    lines.append(f"| Comparable (baseline) | {s['comparable_baseline_change_count']} |")
    lines.append(f"| Matched | {s['matched_change_count']} |")
    lines.append(f"| Missing | {s['missing_change_count']} |")
    lines.append(f"| Skipped | {s['skipped_change_count']} |")
    lines.append("")

    # ── Matched ──────────────────────────────────────────────────────────────
    matched = results.get("matched_changes", [])
    lines.append(f"## Matched Changes ({len(matched)})\n")
    if not matched:
        lines.append("_None._\n")
    else:
        for item in matched:
            bc = item["baseline_change"]
            lines.append(
                f"### `{bc['database']}.{bc['schema_name']}.{bc['table_name']}` — {bc['operation'].upper()}"
            )
            lines.append(f"**Identity:** {_fmt_identity(bc['stable_identity']['fields'])}  ")
            lines.append(f"**Strategy:** {bc['stable_identity']['strategy']}\n")
            lines.append(_fmt_payload(bc.get("comparable_payload", {})))
            lines.append("")

    # ── Missing ───────────────────────────────────────────────────────────────
    missing = results.get("missing_changes", [])
    lines.append(f"## Missing Changes ({len(missing)})\n")
    lines.append("_Baseline changes that were not found in the target._\n")
    if not missing:
        lines.append("_None._\n")
    else:
        for item in missing:
            bc = item["baseline_change"]
            lines.append(
                f"### `{bc['database']}.{bc['schema_name']}.{bc['table_name']}` — {bc['operation'].upper()}"
            )
            lines.append(f"**Reason:** {item['reason']}  ")
            lines.append(f"**Identity:** {_fmt_identity(bc['stable_identity']['fields'])}  ")
            lines.append(f"**Strategy:** {bc['stable_identity']['strategy']}  ")
            candidates = item.get("candidate_count", 0)
            lines.append(f"**Candidates checked:** {candidates}\n")
            lines.append(_fmt_payload(bc.get("comparable_payload", {})))
            if item.get("candidate_details"):
                lines.append("\n**Closest candidates:**\n")
                for cd in item["candidate_details"]:
                    tc = cd.get("target_change", {})
                    lines.append(
                        f"- `{tc.get('table_name', '?')}` {tc.get('operation','?').upper()} "
                        f"— identity: {_fmt_identity(tc.get('stable_identity', {}).get('fields', {}))}"
                    )
            lines.append("")

    # ── Skipped ───────────────────────────────────────────────────────────────
    skipped = results.get("skipped_changes", [])
    lines.append(f"## Skipped Changes ({len(skipped)})\n")
    lines.append("_Baseline changes excluded from comparison (e.g., no stable identity)._\n")
    if not skipped:
        lines.append("_None._\n")
    else:
        by_reason: dict[str, list] = defaultdict(list)
        for item in skipped:
            by_reason[item["reason"]].append(item)
        for reason, items in by_reason.items():
            lines.append(f"### {reason} ({len(items)})\n")
            lines.append("| # | Table | Operation | Strategy |")
            lines.append("| --- | --- | --- | --- |")
            for item in items:
                bc = item["baseline_change"]
                lines.append(
                    f"| {item['baseline_index']} "
                    f"| `{bc['schema_name']}.{bc['table_name']}` "
                    f"| {bc['operation'].upper()} "
                    f"| {bc['stable_identity']['strategy']} |"
                )
            lines.append("")

    md_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    baseline_file = Path(args.baseline_file)
    target_file = Path(args.target_file)

    if not confirm_expected_filename(baseline_file):
        return 1
    if not confirm_expected_filename(target_file):
        return 1

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
    md_file = output_file.with_suffix(".md")
    write_compare_markdown(md_file, results)

    print(f"Baseline changes: {results['summary']['baseline_change_count']}")
    print(f"Target changes:   {results['summary']['target_change_count']}")
    print(f"Matched:          {results['summary']['matched_change_count']}")
    print(f"Missing:          {results['summary']['missing_change_count']}")
    print(f"Skipped:          {results['summary']['skipped_change_count']}")
    print(f"Output written to: {output_file}")
    print(f"Report written to: {md_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())