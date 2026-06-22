"""On-the-fly remapping of a functional test's allocated UID block.

When a test is run against a database that already contains its original UID
range, the IDs can be shifted to a new starting value without editing the files
on disk. The current starting id is detected as the low end of the largest
contiguous block of ``DECLARE @... bigint = N;`` literals across the test's
``setup.sql`` files (shared IDs such as a superuser are excluded). Every numeric
reference to a block id in ``setup.sql``, ``query.sql`` and ``expected.json`` is
shifted by the same offset, including IDs embedded in strings like
``PSN1000004000GA01``.

This mirrors the detection used by
``testing-tools/local-db-tracing/shift_test_ids.py``, but applies the shift in
memory rather than rewriting files.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

SETUP_FILE = "setup.sql"

# Matches `DECLARE @some_uid bigint = 1000004000;` lines in setup.sql.
_DECLARE_BIGINT_LITERAL_PATTERN = re.compile(
    r"^DECLARE\s+@[A-Za-z0-9_]+\s+bigint\s*=\s*(?P<value>\d+)\s*;\s*$",
    re.IGNORECASE,
)

# Matches a whole integer token (not part of a longer digit run), so IDs
# embedded in strings like PSN1000004000GA01 are still shifted.
_NUMBER_PATTERN = re.compile(r"(?<!\d)(\d+)(?!\d)")


@dataclass
class IdRemapper:
    """Shifts a test's allocated UIDs to a new starting id, on the fly."""

    mapping: dict[int, int]
    orig_start: int
    new_start: int
    offset: int

    def apply(self, text: str) -> str:
        def repl(match: re.Match[str]) -> str:
            value = int(match.group(1))
            new_value = self.mapping.get(value)
            return str(new_value) if new_value is not None else match.group(0)

        return _NUMBER_PATTERN.sub(repl, text)


def _detect_declared_ids(setup_files: list[Path]) -> set[int]:
    ids: set[int] = set()
    for path in setup_files:
        for line in path.read_text(encoding="utf-8").splitlines():
            match = _DECLARE_BIGINT_LITERAL_PATTERN.match(line)
            if match:
                ids.add(int(match.group("value")))
    return ids


def _largest_contiguous_block(ids: set[int]) -> tuple[int, int]:
    sorted_ids = sorted(ids)
    best_lo = best_hi = sorted_ids[0]
    cur_lo = cur_hi = sorted_ids[0]
    for value in sorted_ids[1:]:
        if value == cur_hi + 1:
            cur_hi = value
        else:
            if cur_hi - cur_lo > best_hi - best_lo:
                best_lo, best_hi = cur_lo, cur_hi
            cur_lo = cur_hi = value
    if cur_hi - cur_lo > best_hi - best_lo:
        best_lo, best_hi = cur_lo, cur_hi
    return best_lo, best_hi


def build_id_remapper(test_dir: Path, new_start_id: int) -> IdRemapper:
    """Build a remapper that shifts ``test_dir``'s UID block to ``new_start_id``.

    The current starting id is detected as the low end of the largest contiguous
    block of ``DECLARE @... bigint = N;`` literals across the test's setup files.
    Raises ``ValueError`` if no such literals are found.
    """
    setup_files = sorted(test_dir.rglob(SETUP_FILE))
    if not setup_files:
        raise ValueError(f"No {SETUP_FILE} files found under {test_dir}")

    declared = _detect_declared_ids(setup_files)
    if not declared:
        raise ValueError(
            f"No 'DECLARE @... bigint = N;' literals found under {test_dir}; cannot remap IDs"
        )

    lo, hi = _largest_contiguous_block(declared)
    offset = new_start_id - lo
    block_ids = [value for value in declared if lo <= value <= hi]
    mapping = {old: old + offset for old in block_ids}
    return IdRemapper(mapping=mapping, orig_start=lo, new_start=new_start_id, offset=offset)
