# Bug #3 — `sp_d_morbidity_report_postprocessing` self-defeating join+filter at lines 802-816

## TL;DR

`MORB_RPT_USER_COMMENT` can never populate. The SP step "Generating
`##SAS_morb_Rpt_User_Comment`" joins the Morb report root row to a child
observation on `root.morb_rpt_uid = obs.observation_uid` (which only ever
matches the **Order** row, since `morb_rpt_uid` IS the Order's UID), then
filters `obs.obs_domain_cd_st_1 IN ('C_Order','C_Result')`. The Order row
cannot satisfy that filter — its `obs_domain_cd_st_1` is `'Order'`. The
query returns 0 rows by construction, the temp table is empty, and the
downstream INSERT into `MORB_RPT_USER_COMMENT` is a no-op.

The bug is independent of the Tier 1 isolation `PATIENT_KEY` blocker
(`coverage_morbidity.md` LINK_REQUIRED #166). Even when the
`MORBIDITY_REPORT_EVENT` INSERT succeeds end-to-end (Tier 2 `morb_inv`
edge wired + Patient chain + RDB_DATE seeded — see
`coverage_morb_inv.md` § OUT_OF_SCOPE), the user-comment INSERT still
runs but inserts 0 rows.

Also worth noting upstream: **filename / SP-name mismatch** —
`016-sp_nrt_morbidity_report_postprocessing-001.sql` defines a SP whose
body is `dbo.sp_d_morbidity_report_postprocessing`. The "nrt" prefix in
the filename and the "d" prefix in the SP name don't match. Not the
subject of this bug, but flagged for upstream cleanup.

## File and line citation

- File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/016-sp_nrt_morbidity_report_postprocessing-001.sql`
- SP: `dbo.sp_d_morbidity_report_postprocessing`
- Step: 19 — "Generating `##SAS_morb_Rpt_User_Comment`"
- Lines: 802-816

## Annotated walkthrough — lines 802-816

```sql
802         SET @sql = N'
803         SELECT  root.morb_Rpt_Key,
804                 root.morb_rpt_uid,
805                 obs.activity_to_time     AS user_comments_dt,
806                 obs.add_user_id          AS user_comments_by,
807                 REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13) + CHAR(10),'' ''), CHAR(10), '' '')
808                                          AS external_morb_rpt_comments,
809                 root.record_status_cd
810         INTO '+@SAS_morb_Rpt_User_Comment+'
811         FROM '+@tmp_Morbidity_Report+'  as root
812            INNER JOIN #morb_obs_reference            AS obs ON root.morb_rpt_uid = obs.observation_uid     -- (1) self-defeating
813             INNER JOIN #updated_morb_observation_list AS ls ON ls.observation_uid = obs.observation_uid     -- (2) trivially true
814             INNER JOIN #tmp_nrt_observation_txt       AS ovt ON ovt.observation_uid = obs.observation_uid   -- (3) requires text on Order itself
815         WHERE
816           ovt.ovt_value_txt IS NOT NULL
817           AND obs.obs_domain_cd_st_1 IN (''C_Order'', ''C_Result'');';   -- (4) cannot be true given (1)
```

Why each line forces the result set to be empty:

1. **Line 812 — `root.morb_rpt_uid = obs.observation_uid`.** `root` is
   `tmp_Morbidity_Report`, which the SP populates upstream from the
   filtered `nrt_observation` set where `obs_domain_cd_st_1 = 'Order'`
   AND `ctrl_cd_display_form = 'MorbReport'` (SP lines 281-282), with
   `morb_rpt_uid = obs.observation_uid` (SP line 267). So
   `root.morb_rpt_uid` IS the Order observation's UID. The join therefore
   binds `obs` to **the Order row itself** — never to the C_Order or
   C_Result child rows.

2. **Line 813 — `ls.observation_uid = obs.observation_uid`.** `obs` is
   already the Order row (per (1)); the Order's UID is in
   `#updated_morb_observation_list` because that list is the union of
   `nrt_morbidity_observation` (the input list) plus all UIDs reachable
   via the `followup_observation_uid` / `result_observation_uid` CSV
   traversal (SP lines 89-106). So this join is trivially satisfied.
   Even if it were a tighter constraint, the bug is upstream at (1).

3. **Line 814 — `ovt.observation_uid = obs.observation_uid`.** Joins the
   text staging row to `obs` (= the Order). The Order observation
   ordinarily has no `nrt_observation_txt` row of its own (the
   user-comment text lives on the C_Result child observation, UID
   20080021 in the Tier 1 fixture). So even the inner join can fail
   at this step. But again, the deeper problem is (1)+(4).

4. **Line 817 — `obs.obs_domain_cd_st_1 IN ('C_Order','C_Result')`.**
   Given `obs` is bound to the Order row by (1), and an observation row
   has exactly one `obs_domain_cd_st_1` value (`'Order'` for the Order
   row), this predicate is **always false**. Each `observation_uid` is a
   primary key in `nrt_observation` and carries a single
   `obs_domain_cd_st_1`; there is no row in `nrt_observation` whose
   `observation_uid = 20080010` AND whose `obs_domain_cd_st_1` is
   `'C_Order'` or `'C_Result'`.

The intent is clearly to traverse from the Order down to its
C_Order/C_Result **children** and read the user-comment text from the
C_Result's `nrt_observation_txt` row. But the join condition at line 812
binds `obs` to the Order itself, not to a child, so the WHERE filter at
line 817 contradicts the join.

## Empirical proof

Reproduced against the Tier 1 morbidity fixture
(`fixtures/00_foundation/00_foundation.sql` +
`fixtures/10_subjects/morbidity.sql`). Full repro is in `repro.sql` in
this directory. Headline observations:

| Check | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| `nrt_observation_txt` row count for C_Result UID 20080021 | 1 row (`ovt_value_txt = 'Tier 1 Morbidity v2 — clinician user comment.'`) | 1 row, exact text matches | source data IS populated |
| `act_relationship` rows wiring Order <- C_Order <- C_Result | 2 rows: `(20080020 -> 20080010, COMP)` and `(20080021 -> 20080020, COMP)` | both present | the chain IS wired |
| Direct count of `nrt_observation` rows where `observation_uid = 20080010 AND obs_domain_cd_st_1 IN ('C_Order','C_Result')` | 0 by construction | 0 | self-defeating filter confirmed |
| `MORB_RPT_USER_COMMENT` row count after `EXEC sp_d_morbidity_report_postprocessing @pMorbidityIdList = N'20000130,20080010'` | 1 row for v2 Morb | 0 rows | bug confirmed end-to-end |
| `dbo.job_flow_log` rows for the SP's user-comment steps (19, 20, 26, 27) | non-zero `row_count` on at least one of the populating steps | `row_count = 0` on all four | bug confirmed in the SP's own audit log |

Counterfactual probe (also in `repro.sql`): a query using the
**correct** traversal (two-hop `act_relationship` from Order through
C_Order to C_Result) DOES find the C_Result row with its
`nrt_observation_txt` populated. So the failure is purely the SP's join
semantics, not missing fixture data.

## Suggested fix

Two reasonable approaches, in rough order of preference:

### Option A — traverse `act_relationship` directly (recommended)

Replace lines 810-817 with a query that joins from `root` (the Order)
through `act_relationship` to the C_Order child, then through a second
`act_relationship` to the C_Result grandchild, and reads the text from
the C_Result's `nrt_observation_txt`. Sketch:

```sql
SET @sql = N'
SELECT  root.morb_Rpt_Key,
        root.morb_rpt_uid,
        cr.activity_to_time   AS user_comments_dt,
        cr.add_user_id        AS user_comments_by,
        REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13)+CHAR(10), '' ''), CHAR(10), '' '')
                              AS external_morb_rpt_comments,
        root.record_status_cd
INTO '+@SAS_morb_Rpt_User_Comment+'
FROM '+@tmp_Morbidity_Report+' AS root
  INNER JOIN nbs_odse.dbo.act_relationship ar1
       ON ar1.target_act_uid = root.morb_rpt_uid
      AND ar1.type_cd        = ''COMP''
  INNER JOIN #morb_obs_reference co
       ON co.observation_uid     = ar1.source_act_uid
      AND co.obs_domain_cd_st_1  = ''C_Order''
  INNER JOIN nbs_odse.dbo.act_relationship ar2
       ON ar2.target_act_uid = co.observation_uid
      AND ar2.type_cd        = ''COMP''
  INNER JOIN #morb_obs_reference cr
       ON cr.observation_uid     = ar2.source_act_uid
      AND cr.obs_domain_cd_st_1  = ''C_Result''
  INNER JOIN #tmp_nrt_observation_txt ovt
       ON ovt.observation_uid = cr.observation_uid
WHERE ovt.ovt_value_txt IS NOT NULL;';
```

Notes / nuances:

- `activity_to_time` and `add_user_id` should come from the C_Result
  (or the C_Order — RTR's intent isn't entirely clear; the original
  code aliased `obs.*` from a single child, so picking the C_Result is
  the most faithful reading of "user comment").
- The `INNER JOIN #updated_morb_observation_list` was redundant in the
  original (see walkthrough item 2) and is dropped here.
- The `act_relationship.type_cd` filter (`COMP`) is the convention
  Morbidity uses for Order -> C_Order -> C_Result wiring per the Tier 1
  fixture. RTR may want to confirm that's the only valid type_cd, or
  expand the predicate.

### Option B — bind through the existing CSV traversal

The SP already builds `#updated_morb_observation_list` by traversing
`nrt_observation.followup_observation_uid` / `result_observation_uid`
CSVs (lines 89-106). Walk the C_Order/C_Result subset of that list
directly, and re-join up to the Order via a self-join on the followup
chain — but that's awkward because the SP doesn't preserve the
`Order -> child` mapping, just the union. Option A is cleaner.

### Option C (not recommended) — minimal patch on the existing query

Remove the broken join and pull the user comment from
`#tmp_nrt_observation_txt` correlated to the Order via a subquery that
checks the C_Result's UID against the Order's
`followup_observation_uid` CSV. Possible but fragile (string parsing,
no `act_relationship` validation).

## Resolution path for the comparison-fixtures project

This is upstream RTR territory. Once Option A (or equivalent) lands in
the SP, the existing Tier 1 morbidity fixture will exercise all 8 live
columns of `MORB_RPT_USER_COMMENT` for the v2 Morb row (UID 20080010)
end-to-end without further fixture changes. The Tier 1 coverage report
(`coverage/coverage_morbidity.md`) and Tier 2 edge coverage report
(`coverage/coverage_morb_inv.md`) both already document the expected
8/8 column outcome conditional on this SP fix.
