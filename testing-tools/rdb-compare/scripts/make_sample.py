"""Build and write the example comparison report deliverables.

Constructs a small, synthetic :class:`~rdb_compare.models.RunReport` that
exercises every :class:`~rdb_compare.models.Verdict` -- a NEW value diff, an
IGNORED ``*_LAST_UPDATE_DT`` column, a KNOWN_BUG, an EXPECTED by-design diff, a
fully skipped staging table, and a row-count difference -- classifies it with a
small inline :class:`~rdb_compare.rules.RuleRegistry`, then writes
``examples/sample_comparison.json`` and ``examples/sample_comparison.md``.

Run from anywhere::

    uv run python scripts/make_sample.py
"""

from __future__ import annotations

import os

from rdb_compare.classifier import classify_run
from rdb_compare.models import (
    CellDiff,
    ColumnDiff,
    Presence,
    RunReport,
    TableResult,
)
from rdb_compare.report import write_json, write_markdown
from rdb_compare.rules import (
    ExpectedDiffRule,
    IgnoreColumnRule,
    KnownBugRule,
    RuleRegistry,
    SkipTableRule,
)
from rdb_compare.rules.predicates import rdb_null_modern_set

_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_EXAMPLES_DIR = os.path.join(_REPO_ROOT, "examples")


def _col(table, name, compared, mismatches, pairs):
    """A :class:`ColumnDiff` with capped CellDiff samples from ``(key, rdb, modern)``."""
    samples = [
        CellDiff(table=table, key=key, column=name, rdb_value=rdb, modern_value=modern)
        for key, rdb, modern in pairs
    ]
    return ColumnDiff(
        table=table,
        column=name,
        compared=compared,
        mismatches=mismatches,
        samples=samples,
    )


def _sample_registry() -> RuleRegistry:
    """A tiny registry covering each non-NEW verdict for the sample."""
    return RuleRegistry(
        [
            SkipTableRule("ETL_*", "ETL staging table -- not a reporting table"),
            IgnoreColumnRule(
                "*_LAST_UPDATE_DT", "ETL load timing, not a data difference", category="env"
            ),
            KnownBugRule(
                "D_PLACE",
                "PLACE_NM",
                "D_PLACE place name not populated by RTR pipeline",
                ticket="PDF-bug-12",
            ),
            ExpectedDiffRule(
                "D_PATIENT",
                "PATIENT_SUFFIX",
                "RTR populates suffix the legacy ETL left NULL (by design)",
                predicate=rdb_null_modern_set,
            ),
        ]
    )


def build_sample_report() -> RunReport:
    """Construct and classify a synthetic run touching every verdict."""
    report = RunReport(
        rdb_db="RDB",
        modern_db="RDB_MODERN",
        generated_at="2026-06-05T12:00:00Z",
        discovered=4,
        skipped=1,
        compared=3,
        tables=[
            # NEW: unexplained value diff. Also has an IGNORED audit column and a
            # row-count difference (modern has one extra key).
            TableResult(
                table="D_PATIENT",
                presence=Presence.BOTH,
                key_columns=("PATIENT_UID",),
                rdb_count=1000,
                modern_count=1001,
                matched_keys=1000,
                rdb_only_keys=0,
                modern_only_keys=1,
                columns=[
                    _col(
                        "D_PATIENT",
                        "FIRST_NM",
                        compared=1000,
                        mismatches=12,
                        pairs=[
                            (("PAT-001",), "ALICE", "ALICIA"),
                            (("PAT-014",), "BOB", "ROBERT"),
                            (("PAT-099",), "CHRIS", "CHRISTOPHER"),
                            (("PAT-120",), "DEE", "DEANNA"),
                        ],
                    ),
                    _col(
                        "D_PATIENT",
                        "RECORD_LAST_UPDATE_DT",
                        compared=1000,
                        mismatches=1000,
                        pairs=[
                            (("PAT-001",), "2024-01-01 03:00:00", "2024-01-01 09:15:22"),
                            (("PAT-002",), "2024-01-01 03:00:00", "2024-01-01 09:15:23"),
                        ],
                    ),
                    _col(
                        "D_PATIENT",
                        "PATIENT_SUFFIX",
                        compared=1000,
                        mismatches=37,
                        pairs=[
                            (("PAT-005",), None, "JR"),
                            (("PAT-067",), None, "III"),
                        ],
                    ),
                ],
            ),
            # KNOWN_BUG only.
            TableResult(
                table="D_PLACE",
                presence=Presence.BOTH,
                key_columns=("PLACE_UID",),
                rdb_count=250,
                modern_count=250,
                matched_keys=250,
                rdb_only_keys=0,
                modern_only_keys=0,
                columns=[
                    _col(
                        "D_PLACE",
                        "PLACE_NM",
                        compared=250,
                        mismatches=250,
                        pairs=[
                            (("PLC-001",), "Mercy Hospital", None),
                            (("PLC-002",), "County Clinic", None),
                        ],
                    ),
                ],
            ),
            # Skipped staging table.
            TableResult(
                table="ETL_CONTROL",
                presence=Presence.BOTH,
                key_columns=("BATCH_ID",),
                rdb_count=5,
                modern_count=5,
                columns=[
                    _col(
                        "ETL_CONTROL",
                        "BATCH_STATUS",
                        compared=5,
                        mismatches=5,
                        pairs=[(("B1",), "DONE", "PENDING")],
                    ),
                ],
            ),
        ],
    )
    return classify_run(report, _sample_registry())


def main() -> None:
    os.makedirs(_EXAMPLES_DIR, exist_ok=True)
    report = build_sample_report()
    json_path = os.path.join(_EXAMPLES_DIR, "sample_comparison.json")
    md_path = os.path.join(_EXAMPLES_DIR, "sample_comparison.md")
    write_json(report, json_path)
    write_markdown(report, md_path)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")


if __name__ == "__main__":
    main()
