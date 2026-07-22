"""Layout planning for bulk data generation (``--bulk``).

Each *copy* of the suite is every selected test's setup data shifted to a
fresh UID range. Copies are laid out so they can never collide with the
originals or with each other:

  * ``stride`` — the widest test's ID footprint within its 1000-wide block.
    Consecutive copies shift by ``stride``, tiling each block.
  * ``slots`` — how many copies fit inside one block (``1000 // stride``).
  * ``span`` — once a block region is full, the next copy jumps past the
    whole occupied range (highest block end minus lowest block start), where
    the tiling starts over.

Copy ``i`` therefore uses offset ``base + (i // slots) * span +
(i % slots) * stride``: regions tile disjointly, blocks are distinct within
a region, and slots tile within a block, so every copy lands on virgin IDs.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .remapper import (
    BLOCK_SIZE,
    SETUP_FILE,
    _detect_block_start,
    _detect_declared_ids,
)


@dataclass
class TestSetup:
    """One test's setup scripts plus its detected UID block."""

    name: str
    block_start: int
    block_width: int  # IDs actually used: max in-block id - block_start + 1
    steps: list[tuple[str, str]]  # (step name, setup.sql text) in step order


def load_test_setup(test_dir: Path) -> TestSetup:
    steps = []
    for step_dir in sorted(p for p in test_dir.iterdir() if p.is_dir()):
        setup_path = step_dir / SETUP_FILE
        if setup_path.is_file():
            steps.append((step_dir.name, setup_path.read_text()))
    if not steps:
        raise ValueError(f"No {SETUP_FILE} files found under {test_dir}")

    start = _detect_block_start(test_dir)
    declared = _detect_declared_ids(sorted(test_dir.rglob(SETUP_FILE)))
    in_block = {i for i in declared if start <= i < start + BLOCK_SIZE}
    return TestSetup(
        name=test_dir.name,
        block_start=start,
        block_width=max(in_block) - start + 1,
        steps=steps,
    )


@dataclass
class BulkPlan:
    tests: list[TestSetup]
    stride: int
    slots: int
    span: int

    def offset_for(self, copy_index: int, base: int = 0) -> int:
        region, slot = divmod(copy_index, self.slots)
        return base + region * self.span + slot * self.stride


def build_bulk_plan(test_dirs: list[Path]) -> BulkPlan:
    tests = [load_test_setup(d) for d in test_dirs]

    ordered = sorted(tests, key=lambda t: t.block_start)
    for prev, cur in zip(ordered, ordered[1:]):
        if cur.block_start < prev.block_start + BLOCK_SIZE:
            raise ValueError(
                f"Tests {prev.name!r} (block {prev.block_start}) and {cur.name!r} "
                f"(block {cur.block_start}) have overlapping UID blocks; their bulk "
                f"copies would collide. Select only one of them with -t."
            )

    stride = max(t.block_width for t in tests)
    lo = min(t.block_start for t in tests)
    hi = max(t.block_start for t in tests)
    return BulkPlan(
        tests=tests,
        stride=stride,
        slots=max(1, BLOCK_SIZE // stride),
        span=hi + BLOCK_SIZE - lo,
    )
