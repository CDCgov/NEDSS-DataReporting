"""On-the-fly remapping of a functional test's allocated UID block.

When a test is run against a database that already contains its original UID
range, the IDs can be shifted to a new starting value without editing the files
on disk.

Per ``testData/functional/README.md`` each functional test is allocated a block
of 1000 IDs (e.g. morbidityReport uses 1000005000-1000005999). The test's
starting ID is detected from the ``DECLARE @... bigint = N;`` literals in its
``setup.sql`` files: those IDs are clustered (a test's IDs all fall within one
1000-wide block, while a shared id such as the superuser sits far away and forms
its own cluster), and the start is the low end of the largest cluster.

Every integer that falls inside the detected block — in ``setup.sql``,
``query.sql`` and ``expected.json``, including IDs embedded in strings like
``PSN1000004000GA01`` — is shifted by the same offset. Numbers outside the block
(superuser IDs, generated OIDs, dates, codes) are left untouched.

The ID detection mirrors ``testing-tools/local-db-tracing/shift_test_ids.py``,
but the shift is applied in memory rather than by rewriting files.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

SETUP_FILE = "setup.sql"

# Number of IDs allocated to each functional test (see testData README).
BLOCK_SIZE = 1000

# Functional-test IDs are allocated in ranges above 1,000,000,000 (see testData
# README). Declared IDs below this are shared/seed values (e.g. the superuser)
# that must not be shifted.
TEST_ID_THRESHOLD = 1_000_000_000

# Matches `DECLARE @some_uid bigint = 1000004000;` lines in setup.sql. The
# trailing semicolon is optional: some test setups omit it.
_DECLARE_BIGINT_LITERAL_PATTERN = re.compile(
    r"^DECLARE\s+@[A-Za-z0-9_]+\s+bigint\s*=\s*(?P<value>\d+)\s*;?\s*$",
    re.IGNORECASE,
)

# Matches a whole integer token (not part of a longer digit run), so IDs
# embedded in strings like PSN1000004000GA01 are still shifted.
_NUMBER_PATTERN = re.compile(r"(?<!\d)(\d+)(?!\d)")


@dataclass
class IdRemapper:
    """Shifts a test's allocated UID block to a new starting id, on the fly."""

    orig_start: int
    new_start: int
    offset: int
    block_size: int = BLOCK_SIZE

    def in_block(self, value: int) -> bool:
        return self.orig_start <= value < self.orig_start + self.block_size

    def apply(self, text: str) -> str:
        def repl(match: re.Match[str]) -> str:
            value = int(match.group(1))
            return str(value + self.offset) if self.in_block(value) else match.group(0)

        return _NUMBER_PATTERN.sub(repl, text)


def _detect_declared_ids(setup_files: list[Path]) -> set[int]:
    ids: set[int] = set()
    for path in setup_files:
        for line in path.read_text(encoding="utf-8").splitlines():
            match = _DECLARE_BIGINT_LITERAL_PATTERN.match(line)
            if match:
                ids.add(int(match.group("value")))
    return ids


def _largest_cluster(ids: set[int], gap: int) -> list[int]:
    """Group sorted IDs into clusters split wherever a gap of >= ``gap`` occurs.

    Returns the cluster with the most IDs (ties broken by lowest start). A
    test's IDs all sit within one ``gap``-wide block, so they cluster together;
    this guards against a setup that happens to reference more than one block.
    """
    sorted_ids = sorted(ids)
    clusters: list[list[int]] = [[sorted_ids[0]]]
    for value in sorted_ids[1:]:
        if value - clusters[-1][-1] >= gap:
            clusters.append([value])
        else:
            clusters[-1].append(value)
    return max(clusters, key=lambda cluster: (len(cluster), -cluster[0]))


def _detect_block_start(test_dir: Path) -> int:
    """Return the low end of ``test_dir``'s UID block.

    The start is the low end of the largest cluster of
    ``DECLARE @... bigint = N;`` literals (in the test ID range) across the
    test's setup files. Raises ``ValueError`` if no such literals are found.
    """
    setup_files = sorted(test_dir.rglob(SETUP_FILE))
    if not setup_files:
        raise ValueError(f"No {SETUP_FILE} files found under {test_dir}")

    declared = _detect_declared_ids(setup_files)
    if not declared:
        raise ValueError(
            f"No 'DECLARE @... bigint = N;' literals found under {test_dir}; cannot remap IDs"
        )

    candidates = {value for value in declared if value >= TEST_ID_THRESHOLD}
    if not candidates:
        raise ValueError(
            f"No test-range IDs (>= {TEST_ID_THRESHOLD}) declared under {test_dir}; cannot remap IDs"
        )

    return _largest_cluster(candidates, gap=BLOCK_SIZE)[0]


def build_id_remapper(test_dir: Path, new_start_id: int) -> IdRemapper:
    """Build a remapper that shifts ``test_dir``'s UID block to ``new_start_id``."""
    lo = _detect_block_start(test_dir)
    return IdRemapper(orig_start=lo, new_start=new_start_id, offset=new_start_id - lo)


def build_shift_remapper(test_dir: Path, delta: int) -> IdRemapper:
    """Build a remapper that shifts ``test_dir``'s UID block by ``delta``.

    Unlike :func:`build_id_remapper`, the offset is the same for every test, so
    this works when running multiple tests at once.
    """
    lo = _detect_block_start(test_dir)
    return IdRemapper(orig_start=lo, new_start=lo + delta, offset=delta)
