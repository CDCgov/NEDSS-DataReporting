## G4 — Operational, audit & blocked tables

This section covers eight RDB_MODERN tables that sit **outside** the
`ODSE source col → … → RDB_MODERN col` subject-data lineage the rest of
this document traces. Seven of them are RTR-internal **operational /
audit** tables: per-run job logs (`JOB_FLOW_LOG`, `JOB_BATCH_REBUILD_LOG`),
a data-quality side-channel (`ETL_DQ_LOG`), event-processing metric buffers
(`EVENT_METRIC`, `EVENT_METRIC_INC`), a generated calendar dimension
(`RDB_DATE`), and a user/provider profile lookup (`USER_PROFILE`). For
most of these the honest source is **RTR runtime state** — the emitting SP
name, batch ids, timestamps, `@@ROWCOUNT`, error text, or a hard-coded
literal — not an `nbs_odse.dbo.*` column. Where that is the case the
column appendix records the operational source in `transform_note` and
marks the row `INFERRED` rather than confabulating an ODSE chain. The
eighth table, `SR100`, *is* a real condition-summary datamart with a
genuine source chain, but it is **blocked at 0 rows by bug #15** and so is
documented as `BLOCKED:#15` for every column. Two of these tables do carry
honest staging-sourced lineage and are flagged `VERIFIED` accordingly:
`USER_PROFILE` (reads `nrt_auth_user`) and `EVENT_METRIC` /
`EVENT_METRIC_INC` (read the `nrt_investigation` / `nrt_observation` /
`nrt_contact` / `nrt_auth_user` event-staging tables, fully consistent
with the postprocessing-reads-NRT convention).

**ETL_DQ_LOG** (14/15 cols live, ~6200 rows) is a **data-quality
failure side-channel**, not MasterETL-only — correcting `coverage_tier_3.md`,
which mislabeled it. Three RTR routines INSERT into it on a DQ-fail
branch: `sp_s_pagebuilder_postprocessing` (007), the SLD-repeat SP (010),
and `sp_f_std_page_case_postprocessing` (025). When a page-builder answer
fails validation — a non-numeric value where numeric is expected
(`isNumeric(ANSWER_VALUE) != 1`, SP 007 line ~477) or a malformed date
(`ISDATE(ANSWER_TXT) != 1`, line ~817) — the SP logs the offending row:
the investigation's `LOCAL_ID` / `PUBLIC_HEALTH_CASE_UID`, the literal
issue code/description, and the page-builder metadata for the failing
answer (`QUESTION_IDENTIFIER`, the bad `ANSWER_TXT` value itself,
`DATA_LOCATION`, target `rdb_table_nm` / `RDB_COLUMN_NM`, `QUESTION_LABEL`)
plus the run's `@Batch_id` and `GETDATE()`. The source is page-builder
runtime state and the offending value, so columns are `INFERRED` — it only
populates when a fixture deliberately exercises a DQ-fail branch.

**EVENT_METRIC** (28/28) and **EVENT_METRIC_INC** (28/28) are
**event-processing metrics** — one snapshot row per surveillance event
(notification / observation / investigation / contact) capturing its
class, condition, jurisdiction, status, prog-area and timing.
`sp_event_metric_datamart_postprocessing` (037) builds `#TMP_EVENT_METRIC`
from several branches over `nrt_investigation_notification`,
`nrt_observation`, `nrt_investigation`, and `nrt_contact`, resolving code
descriptions via SRTE and user names via `nrt_auth_user`. It INSERTs into
the incremental buffer `EVENT_METRIC_INC` (line 963); the cleanup SP
`sp_event_metric_cleanup_postprocessing` (345) later migrates rows into
the durable `EVENT_METRIC` after a configurable lookback window. These are
operational metrics, not ODSE subject-data, but the staging reads are
real, so most columns are `VERIFIED`. The exception is the
**`ADD_USER_NAME`** column on both tables: the investigation branch at
line ~634 (`FROM dbo.nrt_investigation phc`) selects `add_user_id` but
omits the `LEFT JOIN dbo.nrt_auth_user`, so its rows get
`ADD_USER_NAME = NULL` — this is the layer-2 root cause of **bug #15** and
is flagged `BLOCKED:#15`.

**JOB_FLOW_LOG** (14/15 cols live, ~25,825 rows) is the pipeline's
**operational run-log**, written by ~37 RTR routines as flow logging.
Every postprocessing / datamart SP opens with a `START` row, writes a row
after each step with the step number, step name and `@@ROWCOUNT`, and
closes with a `COMPLETE` row; on failure the `BEGIN CATCH` writes an
`ERROR` row carrying `@FullErrorMessage` (assembled from `ERROR_NUMBER` /
`SEVERITY` / `STATE` / `LINE` / `MESSAGE`) and the truncated id-list in
`MSG_DESCRIPTION1`. Every value is RTR runtime state — batch id,
timestamps, the SP's own `@dataflow_name` / `@package_name` literals,
status literals, step counters — so all columns are `INFERRED` with the
operational source noted. There is no ODSE input.

**JOB_BATCH_REBUILD_LOG** is **MISSING from the live RDB** and has **no
RTR writer**. The only routine that touches it,
`sp_sld_investigation_repeat_postprocessing` (010), merely *reads* /
conditionally `UPDATE`s it inside an `IF OBJECT_ID('job_batch_rebuild_log')
IS NOT NULL` guard (lines 41-69) to decide whether to rebuild the
page-builder repeating-question dimension — it never INSERTs. The table is
therefore a MasterETL-side artifact from RTR's perspective; it is
documented as a single `MASTERETL_ONLY` appendix row.

**RDB_DATE** (11/11) is a **generated calendar/date dimension with no ODSE
source**. `sp_get_date_dim` takes `@start`/`@end` year integers and walks a
date spine in a `WHILE` loop, deriving every column from the iterated date
(`DATENAME`, `DATEPART`, `DAY`, `MONTH`, `YEAR`, and a legacy
Saturday-counting week rule). `DATE_KEY = 1` is reserved for the
NULL/unknown date row; real dates start at `DATE_KEY = 2` for 1990-01-01.
Columns are `VERIFIED` against the live 4019-row dimension but the
appendix `odse_source_col(s)` honestly reads "(generated utility — no ODSE
source)". (Note: the STRATEGY baseline records an RTR bug in this SP under
6.0.18.1 that forces the merge orchestrator to populate `RDB_DATE` via a
recursive CTE instead; the column logic above is the SP's intent.)

**USER_PROFILE** (8/8) is the one operational-adjacent table with
**genuine staging-sourced lineage**. `sp_user_profile_postprocessing` (027)
reads `dbo.nrt_auth_user` (the auth-user staging table — the ODSE
`auth_user` projection) for `FIRST_NM`, `LAST_NM`, `LAST_CHG_TIME`,
`NEDSS_ENTRY_ID` and `PROVIDER_UID`, derives `USER_NM` via a
last/first-name CASE, and joins `D_PROVIDER` on `PROVIDER_UID` to attach
`PROVIDER_KEY` (`COALESCE(...,1)` sentinel) and `PROVIDER_QUICK_CODE`. It
dedupes to one row per `NEDSS_ENTRY_ID`. All eight columns are `VERIFIED`.

**SR100** (0/20) is the **blocked condition-summary report datamart**.
`sp_sr100_datamart_postprocessing` (155) builds `#temp_sr100` (one row,
verified to build) by joining `SUMMARY_REPORT_CASE`, `INVESTIGATION`,
`SUMMARY_CASE_GROUP`, `dbo.condition`, `RDB_DATE`, `nrt_srte_state_county_code_value`,
`v_code_value_general`, `CASE_COUNT`, and `EVENT_METRIC` (INNER JOIN on
`em.local_id = I.inv_local_id`). The chain resolves, but the final INSERT
fails: **`SR100.ADD_USER_NAME` is NOT NULL while
`EVENT_METRIC.ADD_USER_NAME` is NULL** (the bug-#15 line-634 branch never
joined `nrt_auth_user`), raising **Msg 515** which the SP's outer
`TRY/CATCH` swallows — so the pipeline sees success while SR100 stays
empty at 0 rows. Per `bugs/15_event_metric_add_user_name_null/findings.md`,
this is **not** a fixture-fixable gap (seeding `nrt_auth_user` and setting
`add_user_id` was verified to leave `EVENT_METRIC.ADD_USER_NAME` NULL); it
requires an RTR fix (uniformly apply the line-819 `nrt_auth_user` join to
every `#TMP_EVENT_METRIC` branch, relax the SR100 NOT NULL, or
`COALESCE(...,'')` the SR100 insert). Every SR100 column is therefore
flagged `BLOCKED:#15`, with `ADD_USER_NAME` itself called out as the
blocking column.
