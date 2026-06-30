# rdb-compare

A local tool that compares the legacy **RDB** (produced by MasterETL/SAS) against
**RDB_MODERN** (produced by the RTR reporting pipeline), documenting which tables
and which columns differ. It classifies every difference as **NEW**
(unexplained, needs attention), **EXPECTED** (documented by-design),
**KNOWN_BUG** (documented probable bug), or **IGNORED** (skip table, surrogate-key
offset, ETL timestamp, audit column).

It is the local-development counterpart to
[CDCgov/NEDSS-DataCompare](https://github.com/CDCgov/NEDSS-DataCompare): it reuses
that project's per-table key columns and comparison SQL approach, but drops the
S3/Kafka/Spring machinery for a single tool that reads two databases in
the same SQL Server instance and emits JSON + Markdown.

## How it works

The comparison is **UID-keyed and column-by-column** (matching the SQL templates
in the RTR reporting-differences Confluence page): rows are matched on a table's
business/UID key(s), never the surrogate `*_KEY` columns, which carry documented
offsets. Every non-key column is compared NULL-aware via a cross-database
join (`RDB.dbo.X JOIN RDB_MODERN.dbo.X ON key`).

The known/expected differences live in a **declarative rule registry**
(`rdb_compare/rules/`) rather than if/else sprawl: each known difference is a
typed `Rule` instance (`SkipTableRule`, `IgnoreColumnRule`, `ExpectedDiffRule`,
`KnownBugRule`) in `rdb_compare/rules/catalog.py`, sourced from the
reporting-differences page and the DataCompare config. Classification is a
separate, pure pass over the raw comparison results.

## Usage

```bash
uv sync
uv run rdb-compare --host localhost --port 3433 --user sa \
    --rdb RDB --modern RDB_MODERN --out ./out
```

Outputs `out/comparison.json` (full machine-readable results) and
`out/comparison.md` (human report: per-table summary, per-column mismatch counts,
sample mismatched rows, each diff classified).

Run `uv run rdb-compare --help` for all options (table include/exclude globs,
sample cap, verdict filtering, etc.).

## Tests

```bash
uv run pytest
```

The comparison engine, rule registry, classifier, and report renderers are all
unit-tested without a live database (fixture data); the DB layer is integration
-tested separately against the dev SQL Server.
