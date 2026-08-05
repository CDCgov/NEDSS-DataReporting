# APP-926 — sp_morbidity_report_datamart_postprocessing equivalence unit tests

These `app926_morbidity_datamart_*` folders are DataDrivenUnitTests golden-file fixtures
that pin the output of `dbo.sp_morbidity_report_datamart_postprocessing` while the SP is
optimized under APP-926. Each folder runs `setup.sql` (seed RDB_MODERN + `EXEC` the SP),
then `query.sql` against `RDB_MODERN.dbo.MORBIDITY_REPORT_DATAMART`, and asserts the
JSON-serialized result equals `expected.json`.

The SP builds the datamart from MORBIDITY_REPORT (MR) + MORBIDITY_REPORT_EVENT (MRE) +
dimensions (D_PATIENT, D_PROVIDER, D_ORGANIZATION, INVESTIGATION, EVENT_METRIC). A report
qualifies when ANY of these hold, AND `MORB_RPT_KEY <> 1` AND `RECORD_STATUS_CD = 'ACTIVE'`:

- `inv.CASE_UID` in `@inv_uids` (via MRE.INVESTIGATION_KEY)
- `pat.PATIENT_UID` in `@pat_uids` (MRE.PATIENT_KEY)
- `prov.PROVIDER_UID` in `@prov_uids` (MRE.PHYSICIAN_KEY OR MRE.REPORTER_KEY)
- `org.ORGANIZATION_UID` in `@org_uids` (MRE.MORB_RPT_SRC_ORG_KEY OR MRE.HSPTL_KEY)
- `CAST(MR.MORB_RPT_UID AS bigint)` in `@obs_uids`

## Folders (one qualifying branch each)

| folder | branch exercised | param set | expected rows |
|---|---|---|---|
| `app926_morbidity_datamart_obs`        | `@obs_uids` + RECORD_STATUS/param filters | `@obs='9261001,9261003'` | 1 |
| `app926_morbidity_datamart_pat`        | `@pat_uids` via MRE.PATIENT_KEY | `@pat='9262010'` | 1 |
| `app926_morbidity_datamart_prov`       | `@prov_uids` via PHYSICIAN_KEY and REPORTER_KEY | `@prov='9263010,9263011'` | 2 |
| `app926_morbidity_datamart_org`        | `@org_uids` via MORB_RPT_SRC_ORG_KEY and HSPTL_KEY | `@org='9264010,9264011'` | 2 |
| `app926_morbidity_datamart_inv`        | `@inv_uids` via MRE.INVESTIGATION_KEY | `@inv='9265010'` | 1 |
| `app926_morbidity_datamart_mixed`      | all five branches at once | one uid per branch | 5 |
| `app926_morbidity_datamart_multievent` | one report, two MRE rows, only one matches | `@pat='9267010'` | 1 |
| `app926_morbidity_datamart_empty`      | all params empty, nothing qualifies | all `''` | COUNT = 0 |

Each folder owns a distinct MORB_RPT_KEY / dimension-key band (9261xxx … 9268xxx), disjoint
from the sentinel key=1 dimension members, so the fixtures never collide and `query.sql` can
scope by key range (the same discipline as `app734_investigation_repeat`).

### `multievent` — why it matters
Report 9267001 has two MORBIDITY_REPORT_EVENT rows: one whose PATIENT_KEY resolves to a
D_PATIENT in `@pat_uids`, one pointing at sentinel key 1. The SP applies the qualifying WHERE
at MR×MRE grain, so exactly one datamart row emits, carrying the matching MRE's data. A naive
key-grain rewrite would emit both rows or the wrong MRE's data; this golden guards against that.

### `empty` — why it's a COUNT
`DataDrivenUnitTests` reads the query result via `QueryRunner`, which calls `.get()` on the
per-statement result and throws if a statement returns zero rows. A datamart SELECT that
legitimately returns nothing would therefore error rather than assert cleanly. So `query.sql`
asserts `SELECT COUNT(*) = 0` for the case's key range instead of a bare row SELECT.

## Skipped scenario: junk-obs (malformed `@obs_uids`)
The equivalence harness (`seer/app-926/run_capture.sql`) has a ninth scenario that passes a
malformed obs list, `'abc,,-1,999999999999'`. `CAST('abc' AS bigint)` raises a conversion
error that the SP's own `TRY/CATCH` swallows: the datamart is left untouched and the proc
returns a single error-shaped row (`datamart = 'Error'`, populated `stored_procedure`). That is
throw-and-recover behavior, not a datamart-output shape, so it doesn't fit the golden-output
pattern and is intentionally omitted here. If it ever needs coverage, assert on JOB_FLOW_LOG
ERROR rows / the returned error row, not on MORBIDITY_REPORT_DATAMART contents.

## How the goldens were validated
For every folder: seed on a clean key range, `EXEC` the SP, capture
`SELECT … FROM MORBIDITY_REPORT_DATAMART` as JSON. Captured once with the OPTIMIZED SP
(the 048 migration) and once with the ORIGINAL SP (`seer/app-926/sp_original.sql`); the two
captures were byte-identical for all 8 folders, so each `expected.json` reflects the ORIGINAL
SP's behavior, not just the optimized one.

`query.sql` selects a curated string/bigint column set (no datetime), so the goldens are
deterministic and independent of `GETDATE()`-derived columns.
