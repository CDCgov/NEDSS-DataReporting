# Bug #6: LDF_DATA.RECORD_STATUS_CD truncation

**Status**: **Merged on main** (PR #827, commit `bb882115`).
**Severity (historical)**: High (latent in baseline; manifests on first LDF data flow).
**Surfaced by**: comparison-fixtures Tier 3 LDF answers (Tetanus) fixture.

## Bug

`dbo.sp_nrt_ldf_postprocessing` at line 1132 maps
`nrt_ldf_data.metadata_record_status_cd` (typically holds the canonical
upstream value `'LDF_PROCESSED'` = 13 chars) into the target column
`dbo.LDF_DATA.RECORD_STATUS_CD` which is `varchar(8)`. INSERT fails
with Msg 2628 truncation error.

```
Error Number:   2628
Error Severity: 16
Error State:    1
Error Line:     1089 (SP-internal)
Error Message:  String or binary data would be truncated in table
                'RDB_MODERN.dbo.LDF_DATA', column 'RECORD_STATUS_CD'.
```

(SP-internal line 1089 = the `INSERT INTO dbo.ldf_data` statement at
file line 1097.)

## Schema evidence

`INFORMATION_SCHEMA.COLUMNS` against the live DB:

| TABLE_NAME | COLUMN_NAME | DATA_TYPE | max_len |
| --- | --- | --- | --- |
| `LDF_DATA` | `RECORD_STATUS_CD` | varchar | **8** |
| `nrt_ldf_data` | `metadata_record_status_cd` | varchar | 20 |
| `nrt_odse_state_defined_field_metadata` | `record_status_cd` | varchar | 20 |

`LDF_DATA.RECORD_STATUS_CD` also carries a CHECK constraint:
`CHK_LDFDATA_RECORD_STATUS: ([RECORD_STATUS_CD]='INACTIVE' OR [RECORD_STATUS_CD]='ACTIVE')`.

## Source-of-truth analysis

All **2754 baseline `nrt_odse_state_defined_field_metadata` rows hold
the literal `'LDF_PROCESSED'` (13 chars)**. Zero rows hold `'ACTIVE'`.
The varchar(8) column was sized for the CHECK-constrained values
`'ACTIVE'` / `'INACTIVE'`, not for the upstream ETL processing flag.
This is a mapping bug, not a width oversight.

The SP's intent is clearly to record an `ACTIVE/INACTIVE` lifecycle
status on each `LDF_DATA` row (matching the CHECK constraint). It
mistakenly reads `metadata_record_status_cd` (the metadata's
ETL-processed flag) instead of the answer's own status.

## Suggested fix (Option B, recommended)

Change the SP to map from the LDF answer's own `record_status_cd`
column instead of the metadata's processing flag.

In `liquibase-service/src/main/resources/db/005-rdb_modern/routines/015-sp_nrt_ldf_postprocessing-001.sql`:

- **Line 863** (and corresponding **line 1006** UPDATE): change
  `ld.metadata_record_status_cd` to `ld.record_status_cd`.
- The peer column `nrt_ldf_data.record_status_cd` is the LDF-answer's
  own active/inactive status (varchar(20) but populated with
  `'ACTIVE'`/`'INACTIVE'` semantics), semantically aligned with the
  destination's CHECK constraint.
- The SP already filters on this column at line 873
  (`where ld.RECORD_STATUS_CD is not null`) but never selects it.

## Alternatives (not recommended)

- **Option A** (widen the column): change `LDF_DATA.RECORD_STATUS_CD`
  to `varchar(20)` and drop or relax the CHECK constraint. Mechanically
  fixes the truncation but stores semantically wrong data
  (`'LDF_PROCESSED'` is a metadata-processing flag, not an answer
  status). Would silently break downstream consumers that expect
  `ACTIVE`/`INACTIVE`.
- **Option C** (`LEFT(metadata_record_status_cd, 8)`): silently
  truncates to `'LDF_PROC'`. Then the CHECK constraint rejects it
  anyway. Reject.

## Latency

`LDF_DATA` is empty in pristine RDB_MODERN (only the hand-coded
sentinel row at `LDF_DATA_KEY=1` with `record_status_cd='ACTIVE'`).
The bug only manifests when `sp_nrt_ldf_postprocessing` runs against
`nrt_ldf_data` rows whose `metadata_record_status_cd` is the canonical
upstream value `'LDF_PROCESSED'`. The Tier 3 fixture
`fixtures/30_sp_coverage/ldf_answers_tetanus.sql` was the first to drive
rows through this SP and works around the bug by hard-coding
`metadata_record_status_cd='ACTIVE'` in the authored `nrt_ldf_data`
rows (a workaround the fixture comment flags as RTR bug).

## Reproduction

See `repro.sql` in this directory. Run with:

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -i repro.sql
```

Repro design:
- Uses fresh `business_object_uid=29999999` so no collision with
  existing fixture state.
- Picks an unused baseline `ldf_uid` dynamically so the SP's metadata
  join succeeds.
- Sources `nrt_ldf_data.record_status_cd='ACTIVE'` (passes SP filter
  at line 873) but `metadata_record_status_cd='LDF_PROCESSED'` (the
  canonical 13-char value that triggers the truncation).
- Cleans up all rows it created (verified post-run: 0 residual rows
  in `nrt_ldf_data`, `nrt_ldf_data_key`, `nrt_ldf_group_key`,
  `ldf_group`).
- Surfaces the error from both the SP's diagnostic SELECT and from
  `dbo.job_flow_log`.
