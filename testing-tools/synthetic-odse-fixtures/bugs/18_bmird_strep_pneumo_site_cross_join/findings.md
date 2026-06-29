# Bug #18: sp_bmird_strep_pneumo_datamart_postprocessing cross-joins the site datasets, repeating multi-value cells

**Status**: Surfaced 2026-06-18. **Fixed on `aw/odse-test-seed`** (routine edit, no PR yet). Real RTR bug.

## Symptom

On `dbo.BMIRD_STREP_PNEUMO_DATAMART`, when an investigation has more than one
value for any of the additional-site questions, the three site families
(`NON_STERILE_SITE_1..3`, `ADD_CULTURE_1_SITE_1..3`, `ADD_CULTURE_2_SITE_1..3`)
come out with a single value **repeated across every slot** instead of the
distinct selections.

Observed for Strep pneumo investigation `22005000` (fixture
`zz_bmird_fill.sql`, one-observation-with-N-coded-values shape):

```
NON_STERILE_SITE_1/2/3 = Amniotic fluid | Amniotic fluid | Amniotic fluid   (should be Amniotic fluid | Middle ear | Other)
ADD_CULTURE_1_SITE_1/2/3 = Blood | Blood | Blood                            (should be Blood | Bone | Cerebral Spinal Fluid)
```

`UNDERLYING_CONDITION_1..8` is **not** affected: it is pivoted by a separate,
correct single-column path (`#BMD127` -> ROW_NUMBER -> MAX(CASE)). Only the
three combined site columns are wrong.

## Relationship to bug #12

This is the next bug in the BMIRD multi-value chain, exposed by resolving #12.
Bug #12 (`sp_bmird_case_datamart_postprocessing` `ROW_NUMBER() OVER (PARTITION BY
public_health_case_uid, branch_id)`) collapses multi-value answers so only the
`_1` slot ever fills. With the data authored as one observation carrying N
distinct `obs_value_coded` rows (the shape legacy MasterETL requires; see
`zz_bmird_fill.sql`), all N values share one `branch_id`, so routine 040's
`ROW_NUMBER() OVER (PARTITION BY phc, branch_id)` now correctly yields 1..N and
`BMIRD_MULTI_VALUE_FIELD` gets N distinct rows. That unblocks `_2`/`_3` and
exposes #18: the site pivot in routine 140 was never correct for >1 value, it
just never ran on multi-value data before.

## Root cause

`rdb/routines/140-sp_bmird_strep_pneumo_datamart_postprocessing-001.sql`,
"Generating #DM_BR7" step. The three per-field datasets are built independently:

```sql
SELECT distinct bc.INVESTIGATION_KEY, a.NON_STERILE_SITE AS NON_STERILE_SITE_ into #DM_BMD125 ...
SELECT distinct bc.INVESTIGATION_KEY, a.STREP_PNEUMO_1_CULTURE_SITES AS ADD_CULTURE_1_SITE_ into #DM_BMD142 ...
SELECT distinct bc.INVESTIGATION_KEY, a.STREP_PNEUMO_2_CULTURE_SITES AS ADD_CULTURE_2_SITE_ into #DM_BMD144 ...
```

then merged **on INVESTIGATION_KEY only**:

```sql
select d.INVESTIGATION_KEY, a.NON_STERILE_SITE_, b.ADD_CULTURE_1_SITE_, c.ADD_CULTURE_2_SITE_
into #DM_BR7
from #BMIRD_PATIENT1 d
     left outer join #DM_BMD125 a on a.INVESTIGATION_KEY = d.INVESTIGATION_KEY
     left outer join #DM_BMD142 b on b.INVESTIGATION_KEY = d.INVESTIGATION_KEY
     left outer join #DM_BMD144 c on c.INVESTIGATION_KEY = d.INVESTIGATION_KEY
...
ROW_NUMBER() OVER (PARTITION BY INVESTIGATION_KEY
                   ORDER BY coalesce(NON_STERILE_SITE_, ADD_CULTURE_1_SITE_, ADD_CULTURE_2_SITE_)) AS COUNTER
```

Joining only on `INVESTIGATION_KEY` is a **Cartesian product**: with 3 non-sterile
sites x 3 culture-1 sites x 3 culture-2 sites you get 27 rows per investigation.
The `ROW_NUMBER ... ORDER BY coalesce(...)` then picks `COUNTER` 1/2/3 off that
cross-joined block, and because the leading `coalesce` value dominates the order,
the same value lands in every slot. With a single value per field (the only case
exercised before the one-obs-N-values fixture) it is 1x1x1 = 1 row and the bug is
invisible.

## Fix (applied on `aw/odse-test-seed`)

Rank each site dataset per investigation, then align the three by `(INVESTIGATION_KEY, rn)`
instead of cross-joining, so the Nth non-sterile site, Nth culture-1 site and Nth
culture-2 site share one `COUNTER` row:

```sql
SELECT INVESTIGATION_KEY, NON_STERILE_SITE_,
       ROW_NUMBER() OVER (PARTITION BY INVESTIGATION_KEY ORDER BY NON_STERILE_SITE_) AS rn
into #DM_BMD125
FROM (SELECT distinct bc.INVESTIGATION_KEY, a.NON_STERILE_SITE AS NON_STERILE_SITE_ ...) z;
-- (same for #DM_BMD142 / #DM_BMD144)

select k.INVESTIGATION_KEY, k.rn AS COUNTER, a.NON_STERILE_SITE_, b.ADD_CULTURE_1_SITE_, c.ADD_CULTURE_2_SITE_
into #DM_BR7
from (SELECT INVESTIGATION_KEY, rn FROM #DM_BMD125
      UNION SELECT INVESTIGATION_KEY, rn FROM #DM_BMD142
      UNION SELECT INVESTIGATION_KEY, rn FROM #DM_BMD144) k
     left outer join #DM_BMD125 a on a.INVESTIGATION_KEY = k.INVESTIGATION_KEY and a.rn = k.rn
     left outer join #DM_BMD142 b on b.INVESTIGATION_KEY = k.INVESTIGATION_KEY and b.rn = k.rn
     left outer join #DM_BMD144 c on c.INVESTIGATION_KEY = k.INVESTIGATION_KEY and c.rn = k.rn;
```

The downstream `MAX(CASE WHEN COUNTER = n ...)` pivot is unchanged; it now reads
the aligned rank. Verified: NSS = Amniotic fluid | Middle ear | Other, ADD_CULTURE_1
= Blood | Bone | Cerebral Spinal Fluid.

## File affected

`reporting-pipeline-service/src/main/resources/db/changelog/migrations/v17.3/rdb/routines/140-sp_bmird_strep_pneumo_datamart_postprocessing-001.sql` (the `#DM_BMD125/142/144` + `#DM_BR7` block)
