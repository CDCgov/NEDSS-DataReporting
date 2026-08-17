#!/usr/bin/env python3
"""Run every functional test's setup.sql repeatedly against a database.

This wraps ``functional-test --skip-query --refresh-last-chg-time`` so you
can execute every test's seed data across several iterations without waiting
for the reporting pipeline to process the queries. It is useful when an
external ETL process is what needs to observe the freshly inserted rows.

Example: run all test setups 3 times, starting at a 10,000,012 ID shift and
moving each iteration's IDs a further 1,000 apart so they never collide:

    uv run run_setup_iterations.py \
        -d ../../reporting-pipeline-service/src/test/resources/testData/functional \
        -i 3 \
        -s 10000012

Every test's IDs live in one contiguous span of 1,000-wide blocks (see
testData/functional/README.md), so a per-iteration ``--shift-step`` smaller
than that whole span would make one test's shifted range land on another
test's range from an earlier iteration. By default this script scans all the
tests under ``-d`` and picks a step that clears the entire span; pass
``--shift-step`` explicitly to override.

Running the script twice with the same ``-s`` against a persistent database
will also collide with rows left behind by the first run. If ``-s`` is
omitted, the next safe shift is read from a local state file (written after
every run) so repeated invocations never reuse IDs; the very first run, with
no state yet, falls back to a value derived from the current time.

Per-iteration failures are summarized; the process exits non-zero if any
iteration failed.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

from functional_test.remapper import BLOCK_SIZE, _detect_block_start
from functional_test.runner import discover_tests

STATE_FILE = Path(__file__).resolve().parent / ".run_setup_iterations_state.json"


def _load_next_shift(state_file: Path) -> int | None:
    """Return the next safe shift recorded by a previous run, if any."""
    try:
        data = json.loads(state_file.read_text())
    except (OSError, ValueError):
        return None
    value = data.get("next_shift")
    return int(value) if isinstance(value, int) else None


def _save_next_shift(state_file: Path, value: int) -> None:
    state_file.write_text(json.dumps({"next_shift": value}))


def _auto_shift_id() -> int:
    """Pick a base shift that's unique to this invocation.

    Derived from the current time (milliseconds since epoch) so repeated
    invocations against a persistent database never reuse the same IDs as a
    previous run, even if that run's rows were never cleaned up.
    """
    return int(time.time() * 1000)


def _auto_shift_step(data_dir: Path) -> int:
    """Pick a shift step that clears every test's ID block under ``data_dir``.

    Using a step smaller than the full span between the lowest and highest
    block start would make one test's shifted range collide with another
    test's range from a previous iteration (this bit us: blocks here are only
    1000 apart, so a step of 1000 moved test N's iteration-2 range onto test
    N+1's iteration-1 range). Round the span up to the next 1000 and add one
    more block of headroom.
    """
    starts = [_detect_block_start(test_dir) for test_dir in discover_tests(data_dir)]
    span = max(starts) - min(starts) + BLOCK_SIZE
    return -(-span // BLOCK_SIZE) * BLOCK_SIZE + BLOCK_SIZE


def _effective_shift(args: argparse.Namespace, iteration: int) -> int:
    """Return the ID shift to use for ``iteration`` (1-based).

    ``args.shift_id``/``args.shift_step`` are resolved (auto-computed if not
    given) before this is called, so the base is offset by ``shift_step`` for
    each iteration after the first, ensuring repeated iterations never reuse
    the same IDs.
    """
    return args.shift_id + (iteration - 1) * args.shift_step


def _run_once(args: argparse.Namespace, iteration: int) -> int:
    cmd = [
        "uv",
        "run",
        "functional-test",
        "-d",
        str(args.data_dir),
        "--skip-query",
        "--refresh-last-chg-time",
        "-s",
        str(_effective_shift(args, iteration)),
    ]
    if args.server is not None:
        cmd.extend(["-S", args.server])
    if args.user is not None:
        cmd.extend(["-U", args.user])
    if args.password is not None:
        cmd.extend(["-P", args.password])
    if args.database is not None:
        cmd.extend(["--database", args.database])

    label = f"iteration {iteration}/{args.iterations} (shift={_effective_shift(args, iteration)})"
    print(f"\n=== {label} ===")
    sys.stdout.flush()
    result = subprocess.run(cmd)  # noqa: S603
    if result.returncode != 0:
        print(f"WARNING: {label} exited with code {result.returncode}")
        sys.stdout.flush()
    return result.returncode


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run every functional test's setup.sql repeatedly.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-d",
        "--data-dir",
        dest="data_dir",
        type=Path,
        required=True,
        help="Directory containing functional test data (the 'functional' folder).",
    )
    parser.add_argument(
        "-i",
        "--iterations",
        type=int,
        default=1,
        help="How many times to run all test setups.",
    )
    parser.add_argument(
        "-s",
        "--shift-id",
        dest="shift_id",
        type=int,
        default=None,
        help=(
            "Shift every test's UIDs by this integer delta on the first iteration. "
            "Defaults to the next safe shift recorded in --state-file, or (with no "
            "state yet) a value derived from the current time — either way, each "
            "invocation gets a fresh ID range that won't collide with a previous run's "
            "leftover rows."
        ),
    )
    parser.add_argument(
        "--shift-step",
        dest="shift_step",
        type=int,
        default=None,
        help=(
            "Additional ID shift applied on each iteration after the first, so "
            "repeated iterations don't reuse the same IDs. Defaults to a value "
            "auto-computed from the test blocks found under -d, large enough "
            "that no test's shifted range ever collides with another test's "
            "range from a previous iteration."
        ),
    )
    parser.add_argument(
        "-S",
        "--server",
        dest="server",
        default=None,
        help="Database address: host, host:port or host,port.",
    )
    parser.add_argument(
        "-U",
        "--user",
        dest="user",
        default=None,
        help="Database user (needs write on NBS_ODSE).",
    )
    parser.add_argument(
        "-P",
        "--password",
        dest="password",
        default=None,
        help="Database password.",
    )
    parser.add_argument(
        "--database",
        default=None,
        help="Initial database for the connection.",
    )
    parser.add_argument(
        "--state-file",
        dest="state_file",
        type=Path,
        default=STATE_FILE,
        help=(
            "Local file tracking the next safe --shift-id across invocations "
            "(not shared/committed — add to .gitignore if you point this elsewhere)."
        ),
    )
    parser.add_argument(
        "--no-state",
        dest="use_state",
        action="store_false",
        default=True,
        help="Ignore and don't update --state-file; fall back to the time-based shift.",
    )
    args = parser.parse_args()

    if args.iterations < 1:
        parser.error("--iterations must be >= 1")

    if args.shift_id is None:
        state_shift = _load_next_shift(args.state_file) if args.use_state else None
        if state_shift is not None:
            args.shift_id = state_shift
            print(f"Using --shift-id={args.shift_id} from {args.state_file}")
        else:
            args.shift_id = _auto_shift_id()
            print(f"Auto-computed --shift-id={args.shift_id} from the current time (no prior state)")

    if args.shift_step is None:
        args.shift_step = _auto_shift_step(args.data_dir)
        print(f"Auto-computed --shift-step={args.shift_step} from test blocks under {args.data_dir}")

    failures = 0
    for i in range(1, args.iterations + 1):
        code = _run_once(args, i)
        if code != 0:
            failures += 1

    if args.use_state:
        next_shift = _effective_shift(args, args.iterations + 1)
        _save_next_shift(args.state_file, next_shift)
        print(f"Recorded next safe --shift-id={next_shift} in {args.state_file}")

    print("\n=== Summary ===")
    print(f"Completed {args.iterations} iteration(s); {failures} failed.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
