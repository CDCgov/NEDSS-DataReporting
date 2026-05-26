"""Shift the locally-allocated UID range used by a functional test in place.

UIDs detected from `DECLARE @... bigint = N;` lines in setup.sql files.
The largest contiguous block of declared IDs is treated as the test-local range;
any outlier (e.g. superuser_id) is excluded. All numeric references to those IDs
in setup.sql, query.sql, and expected.json are shifted by --offset, including
numbers embedded in local-ID strings like PSN22000000GA01.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


DECLARE_BIGINT_LITERAL_PATTERN = re.compile(
    r"^DECLARE\s+@[A-Za-z0-9_]+\s+bigint\s*=\s*(?P<value>\d+)\s*;\s*$",
    re.IGNORECASE,
)

NUMBER_PATTERN = re.compile(r"(?<!\d)(\d+)(?!\d)")

TARGET_FILENAMES = ("setup.sql", "query.sql", "expected.json")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Shift the contiguous block of test-allocated UIDs in a functional test "
            "by a fixed integer offset, in place."
        )
    )
    parser.add_argument(
        "--test-dir",
        required=True,
        help="Functional test directory containing step subfolders with setup.sql/query.sql/expected.json",
    )
    parser.add_argument(
        "--offset",
        type=int,
        required=True,
        help="Integer to add to each detected UID (e.g. 100000)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the plan without writing files",
    )
    return parser.parse_args(argv)


def detect_declared_ids(setup_files: list[Path]) -> set[int]:
    ids: set[int] = set()
    for path in setup_files:
        for line in path.read_text(encoding="utf-8").splitlines():
            m = DECLARE_BIGINT_LITERAL_PATTERN.match(line)
            if m:
                ids.add(int(m.group("value")))
    return ids


def largest_contiguous_block(ids: set[int]) -> tuple[int, int]:
    sorted_ids = sorted(ids)
    best_lo = best_hi = sorted_ids[0]
    cur_lo = cur_hi = sorted_ids[0]
    for v in sorted_ids[1:]:
        if v == cur_hi + 1:
            cur_hi = v
        else:
            if cur_hi - cur_lo > best_hi - best_lo:
                best_lo, best_hi = cur_lo, cur_hi
            cur_lo = cur_hi = v
    if cur_hi - cur_lo > best_hi - best_lo:
        best_lo, best_hi = cur_lo, cur_hi
    return (best_lo, best_hi)


def discover_target_files(test_dir: Path) -> list[Path]:
    files: list[Path] = []
    for fn in TARGET_FILENAMES:
        files.extend(sorted(test_dir.rglob(fn)))
    return files


def apply_shift(text: str, mapping: dict[int, int]) -> tuple[str, int]:
    total = 0

    def repl(m: re.Match[str]) -> str:
        nonlocal total
        v = int(m.group(1))
        new_v = mapping.get(v)
        if new_v is None:
            return m.group(0)
        total += 1
        return str(new_v)

    return NUMBER_PATTERN.sub(repl, text), total


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    test_dir = Path(args.test_dir).resolve()
    if not test_dir.is_dir():
        print(f"error: not a directory: {test_dir}", file=sys.stderr)
        return 2

    setup_files = sorted(test_dir.rglob("setup.sql"))
    if not setup_files:
        print(f"error: no setup.sql files found under {test_dir}", file=sys.stderr)
        return 2

    declared = detect_declared_ids(setup_files)
    if not declared:
        print("error: no `DECLARE @... bigint = N;` literals found in setup.sql files", file=sys.stderr)
        return 2

    if args.offset == 0:
        print("offset is 0; nothing to do.")
        return 0

    lo, hi = largest_contiguous_block(declared)
    block_ids = sorted(v for v in declared if lo <= v <= hi)
    outliers = sorted(v for v in declared if not (lo <= v <= hi))

    new_lo = lo + args.offset
    new_hi = hi + args.offset

    if new_lo < 0:
        print(f"error: shift would produce negative IDs (new lo = {new_lo})", file=sys.stderr)
        return 2

    if new_lo <= hi and new_hi >= lo:
        print(
            f"error: shifted range [{new_lo}, {new_hi}] overlaps original [{lo}, {hi}]",
            file=sys.stderr,
        )
        return 2

    mapping = {old: old + args.offset for old in block_ids}
    new_id_strs = {str(v) for v in mapping.values()}
    target_files = discover_target_files(test_dir)

    collisions: list[tuple[Path, str]] = []
    for path in target_files:
        for m in NUMBER_PATTERN.finditer(path.read_text(encoding="utf-8")):
            if m.group(1) in new_id_strs:
                collisions.append((path, m.group(1)))
                break
    if collisions:
        print("error: new IDs already present in files (would collide):", file=sys.stderr)
        for path, v in collisions:
            print(f"  {v} found in {path.relative_to(test_dir)}", file=sys.stderr)
        return 2

    print(f"test-dir: {test_dir}")
    print(f"offset:   {args.offset:+d}")
    print(f"detected contiguous block: [{lo}, {hi}] ({len(block_ids)} ids)")
    print(f"new range:                 [{new_lo}, {new_hi}]")
    if outliers:
        print(f"excluded outliers (not shifted): {outliers}")
    print(f"target files: {len(target_files)}")
    print()

    changed: list[tuple[Path, int]] = []
    for path in target_files:
        original = path.read_text(encoding="utf-8")
        new_text, n = apply_shift(original, mapping)
        if n > 0:
            changed.append((path, n))
            if not args.dry_run:
                path.write_text(new_text, encoding="utf-8")

    for path, n in changed:
        rel = path.relative_to(test_dir)
        verb = "would update" if args.dry_run else "updated"
        suffix = "s" if n != 1 else ""
        print(f"  {verb}: {rel} ({n} replacement{suffix})")

    if args.dry_run:
        print(f"\nDRY RUN — no files written ({len(changed)} files would change).")
        return 0

    old_id_strs = {str(v) for v in mapping.keys()}
    residuals: list[tuple[Path, str]] = []
    for path, _ in changed:
        for m in NUMBER_PATTERN.finditer(path.read_text(encoding="utf-8")):
            if m.group(1) in old_id_strs:
                residuals.append((path, m.group(1)))
                break
    if residuals:
        print("\nwarning: residual references to old IDs found post-shift:", file=sys.stderr)
        for path, v in residuals:
            print(f"  {v} in {path.relative_to(test_dir)}", file=sys.stderr)

    print(f"\nDone. Updated {len(changed)} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
