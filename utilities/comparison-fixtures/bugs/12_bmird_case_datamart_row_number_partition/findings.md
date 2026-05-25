# Bug #12 — sp_bmird_case_datamart_postprocessing: ROW_NUMBER PARTITION BY branch_id collapses multi-value rows

**Status**: Surfaced 2026-05-24 by Agent G. Not fixed. Open. Real RTR bug.

## Symptom

`dbo.BMIRD_STREP_PNEUMO_DATAMART` columns `UNDERLYING_CONDITION_2..8`,
`NON_STERILE_SITE_2..3`, `ADD_CULTURE_1_SITE_2..3`, `ADD_CULTURE_2_SITE_2..3`
(13 columns total) cannot populate beyond the `_1` row, regardless of
how many answer rows are authored upstream.

Reproduce by applying `fixtures/30_sp_coverage/zz_bmird_strep_pneumo_datamart_enrich.sql`
(commit `a39fb68c`) which adds 10+ answer rows that should yield
multi-value cells. After running the BMIRD SP chain, BMIRD_MULTI_VALUE_FIELD
has only 1 row per Investigation, so the pivot at SP-140 only fills
the `_1` slot.

## Root cause

`liquibase-service/src/main/resources/db/005-rdb_modern/routines/040-sp_bmird_case_datamart_postprocessing-001.sql`,
line 555-558:

```sql
ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id
                   ORDER BY branch_id) AS row_num
```

The intent appears to be: number the distinct branch observations per
PHC so the downstream PIVOT can assign each to slot `_1`, `_2`, `_3`...
But PARTITION BY *includes* `branch_id`, so every row is alone in its
partition → row_num is always 1.

The downstream `DISTINCT (phc_uid, row_num)` then collapses to a single
BMIRD_MULTI_VALUE_FIELD row per Investigation, no matter how many
branches existed in the source.

The same PARTITION BY pattern appears inside the PIVOT subquery at line
1213-1218.

## Suggested fix

Change PARTITION BY to exclude `branch_id` — partition by the
Investigation only, order by branch_id:

```sql
ROW_NUMBER() OVER (PARTITION BY public_health_case_uid
                   ORDER BY branch_id) AS row_num
```

Apply the same fix at line 1213-1218 (inside the PIVOT subquery).

## Tables blocked

- `BMIRD_STREP_PNEUMO_DATAMART` — 13 columns stuck unpopulated:
  `UNDERLYING_CONDITION_2..8`, `NON_STERILE_SITE_2..3`,
  `ADD_CULTURE_1_SITE_2..3`, `ADD_CULTURE_2_SITE_2..3`.

## Cross-condition impact

The same partition bug likely exists in sibling SPs (BMIRD_NEISS_MENIN,
BMIRD_HAEM_INFLU). Audit on fix.

## Discovery

Found while authoring `zz_bmird_strep_pneumo_datamart_enrich.sql`
during the round-2 multi-agent loop. The fixture authored 10 distinct
UNDERLYING_CONDITION_BMD batch-entry observations; without this bug,
they'd fill `_1` through `_8` on the datamart. With the bug, only `_1`
populates.

The fixture documents the expected behavior in its header (the
"Round-2 CODED/NUMERIC/DATE additions" block) — if the bug is fixed
upstream, the existing fixture data should fill those 13 columns
automatically (no fixture change needed).
