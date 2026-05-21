# Coverage: LDF answers for Mumps + Foodborne

Generated: 2026-05-21 (overnight loop iteration #2).

## Inputs

- Fixture: `fixtures/30_sp_coverage/ldf_answers_mumps_foodborne.sql`
- UID range: **22008000-22008999** (new Foodborne Investigation; Mumps
  uses the existing stub at 22000030 from
  `multi_condition_investigations.sql`)
- 10 nrt_ldf_data rows (5 Mumps + 5 Foodborne) drawn from
  `nrt_odse_state_defined_field_metadata` for conditions 10180 and
  10470 respectively.

## Outcome (post-merge_and_verify)

**Headline delta: 33.9% → 34.2% (+0.3pp, +13 columns).**

| Table | Before | After | Notes |
| --- | --- | --- | --- |
| `dbo.ldf_foodborne` | 0/7 | **1 row, 11/12 cols** | Schema widened by SP's dynamic ALTER (7→12). Major win. |
| `dbo.ldf_dimensional_data` | 5 rows, 12/16 | 10 rows, 14/16 | +5 rows, +2 cols |
| `dbo.ldf_data` | 5 rows | 15 rows | +10 rows; column coverage unchanged |
| `dbo.ldf_group` | 2 rows | 4 rows | +2 rows |
| `dbo.ldf_mumps` | 0/7 | 0/7 | **Did not populate** — see below |

## Why ldf_mumps didn't populate

The Mumps datamart SP (`295-sp_ldf_mumps_datamart_postprocessing`)
INNER JOINs `LDF_DIMENSIONAL_DATA` to `LDF_DATAMART_TABLE_REF` on
`PHC_CD = condition_cd` where DATAMART_NAME = 'LDF_MUMPS'. The map
has 1 condition for LDF_MUMPS: `10180`. Our fixture wrote 5 mumps
LDF answers with condition_cd=10180 anchored to PHC 22000030 (the
existing Mumps stub). They flow into `ldf_dimensional_data` (we see
+5 rows there). But the Mumps datamart still gets 0 rows.

Likely cause: the Mumps SP at line ~120 filters on
`s.PHC_CD = r.condition_cd AND r.DATAMART_NAME = 'LDF_MUMPS'` —
but `LDF_DIMENSIONAL_DATA.PHC_CD` may not be `'10180'` for our rows.
The PHC_CD column is populated by `sp_nrt_ldf_dimensional_data_postprocessing`
from the LDF metadata's condition_cd, but this depends on how the
SP sets PHC_CD. Investigation deferred (LOOP rule: no non-blocking
debug).

Why Foodborne worked but Mumps didn't is suspicious; could be a
filter pattern difference between SPs `290` and `295`. Worth a
follow-up but out of scope tonight.

## Not addressed

- **ldf_bmird, ldf_hepatitis**: both have ZERO metadata rows for any
  condition in `LDF_DATAMART_TABLE_REF`. Cannot populate without
  seeding baseline metadata, which is out of scope.
- **ldf_vaccine_prevent_diseases**: shows 8/8 already (sentinel-like).
  No work needed.
