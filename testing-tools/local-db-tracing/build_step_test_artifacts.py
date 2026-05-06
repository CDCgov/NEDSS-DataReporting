"""Copy step artifacts into a functional test folder and normalize query outputs."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Copy setup.sql/query.sql/expected.json from tracing step folders into a test step folder "
            "and apply test-friendly transformations."
        )
    )
    parser.add_argument("--setup-step", help="Path to setup step directory containing setup.sql")
    parser.add_argument("--logical-step", help="Path to logical step directory containing query.sql and expected.json")
    parser.add_argument("--test-step", help="Path to test step directory that will receive setup.sql/query.sql/expected.json")
    return parser.parse_args()


def prompt_for_path(value: str | None, prompt_text: str) -> Path:
    current = value.strip() if isinstance(value, str) else ""
    while not current:
        current = input(prompt_text).strip()
    return Path(current).expanduser().resolve()


def require_file(path: Path, label: str) -> None:
    if not path.is_file():
        raise SystemExit(f"{label} not found: {path}")


def transform_query_sql(content: str) -> str:
    lines = content.replace("\r\n", "\n").replace("\r", "\n").split("\n")

    kept: list[str] = []
    for line in lines:
        stripped = line.strip()
        lower = stripped.lower()

        if stripped == "USE [RDB_MODERN];":
            continue

        if lower.startswith("-- generated from"):
            continue
        if lower.startswith("-- source summary"):
            continue
        if lower.startswith("-- logical changes"):
            continue

        if stripped.startswith("--") and ";" in line:
            continue

        kept.append(line)

    transformed = "\n".join(kept)
    transformed = transformed.replace("[dbo]", "[RDB_MODERN].[dbo]")
    transformed = transformed.replace("[RDB_MODERN].[RDB_MODERN].[dbo]", "[RDB_MODERN].[dbo]")
    transformed = transformed.replace("FOR JSON PATH;", ";")
    transformed = transformed.rstrip() + "\n"
    return transformed


def transform_expected_json(content: str) -> str:
    transformed = content.replace('T00:00:00"', 'T00:00:00.000"')
    if not transformed.endswith("\n"):
        transformed += "\n"
    return transformed


def main() -> int:
    args = parse_args()

    setup_step_dir = prompt_for_path(args.setup_step, "setup-step path: ")
    logical_step_dir = prompt_for_path(args.logical_step, "logical-step path: ")
    test_step_dir = prompt_for_path(args.test_step, "test-step path: ")

    setup_src = setup_step_dir / "setup.sql"
    query_src = logical_step_dir / "query.sql"
    expected_src = logical_step_dir / "expected.json"

    require_file(setup_src, "setup.sql")
    require_file(query_src, "query.sql")
    require_file(expected_src, "expected.json")

    test_step_dir.mkdir(parents=True, exist_ok=True)

    setup_dst = test_step_dir / "setup.sql"
    query_dst = test_step_dir / "query.sql"
    expected_dst = test_step_dir / "expected.json"

    shutil.copy2(setup_src, setup_dst)

    query_content = query_src.read_text(encoding="utf-8")
    query_dst.write_text(transform_query_sql(query_content), encoding="utf-8")

    expected_content = expected_src.read_text(encoding="utf-8")
    expected_dst.write_text(transform_expected_json(expected_content), encoding="utf-8")

    print(f"Copied and transformed artifacts into: {test_step_dir}")
    print(f"- setup.sql    <- {setup_src}")
    print(f"- query.sql    <- {query_src}")
    print(f"- expected.json <- {expected_src}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted by user", file=sys.stderr)
        raise SystemExit(130)