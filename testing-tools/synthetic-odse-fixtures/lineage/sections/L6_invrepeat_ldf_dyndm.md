# L6 — Investigation-repeat, LDF, dyn_dm, page-builder

**Cluster**: `d_investigation_repeat`, `d_inv_place_repeat`, `f_page_case`,
the `ldf_*` family (`ldf_data`, `ldf_group`, `ldf_dimensional_data`,
`d_ldf_meta_data`, `ldf_datamart_column_ref`, the per-condition
`ldf_foodborne/tetanus/mumps/vaccine_prevent_diseases/bmird/hepatitis`,
and the `*_ldf_group` link tables), `summary_report_case` /
`summary_case_group`, `lookup_table_n_rept`, and `aggregate_report_datamart`.
Plus the `dyn_dm_*` SP family, which writes **dynamically-named** datamart
tables and so contributes no statically-enumerable RDB_MODERN columns of
its own.

**Governing characteristic of this cluster**: it is the *page-builder /
dynamic-SQL* corner of RTR. The bulk of the columns here are not produced
by a static `ODSE col → staging col → target col` projection. They are
materialized at runtime by dynamic `ALTER TABLE … ADD` loops and dynamic
`PIVOT` / `UNPIVOT` statements keyed on **page-builder metadata** —
`nrt_page_case_answer` rows (the staging projection of `nbs_page_answer` /
`nbs_ui_metadata`) for the repeating-block dims, and
`nrt_odse_state_defined_field_metadata` (the projection of ODSE
`state_defined_field*`) for the LDF chain. The guardrail in `LINEAGE.md`
applies in full: for these columns the appendix records the **driving
mechanism** and a `DYNAMIC` status rather than forcing a per-column ODSE
map. Per STRATEGY.md, none of these postprocessing/datamart SPs read
`nbs_odse.dbo.*` directly — they read RDB_MODERN-side staging (`nrt_*`)
and already-built dimensions.

This cluster is heavily bug-capped. Bugs #06–#11 and #13 each cap a
specific column set; affected rows carry `BLOCKED:#NN`.

---

## d_investigation_repeat (+ lookup_table_n_rept, l_investigation_repeat*)

`sp_sld_investigation_repeat_postprocessing` is the repeating-block pivot
SP. It reads **only** `nrt_page_case_answer` (joined to `nrt_investigation`
on `act_uid = public_health_case_uid`) and writes the repeating-block dim
plus its lookup/link tables — no participation or act_relationship walk.
For each Investigation whose `investigation_form_cd` is **not** in the SP's
15-value exclusion list (every BMIRD/Hepatitis form plus GEN/MEA/PER/RUB/
RVCT/VAR), it pivots answers into one staged `S_INVESTIGATION_REPEAT` row
per `(PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR)` across four data-type
branches (TEXT / CODED / DATE / NUMERIC).

The catalog statically extracts only **two** columns
(`D_INVESTIGATION_REPEAT_KEY`, `S_INVESTIGATION_REPEAT`) because the
remaining ~251 columns are **added at runtime** by a dynamic ALTER TABLE
loop keyed on `nrt_page_case_answer.rdb_column_nm`
(`010-…-001.sql:1241-1284`) and then filled by the 4-branch dynamic pivot.
In the merged state this dim is **250/253 columns populated over 32 rows** —
i.e. essentially the whole table is `DYNAMIC`, fed by page-builder
metadata, not by any fixed ODSE map. The appendix represents these with a
single `<dynamic:…>` row.

Two bugs shaped this table's history:

- **Bug #10** (`sld_investigation_repeat_key_alloc`, *fixed* 2026-05-22):
  `LOOKUP_TABLE_N_REPT.D_REPT_KEY` had no IDENTITY/DEFAULT, so every new
  row defaulted to the sentinel key `1`; the final
  `WHERE D_INVESTIGATION_REPEAT_KEY != 1` filter then dropped all new rows
  (dim stuck at 2 baseline rows). The 2026-05-21 coverage report captures
  the pre-fix state (1 populated value); the 2026-05-25 merged run reflects
  the post-fix surge to 250/253.
- **Bug #13** (`sld_investigation_repeat_text_pivot_null_propagation`,
  *open*): the TEXT pivot builds its column list with `@cols += …`, which
  NULL-propagates if any `#text_data_REPT` row has `rdb_column_nm = NULL`.
  The `zz_d_inv_place_repeat_enrich.sql` fixture authors exactly such rows
  on PHC 22006000 (they target a *different* SP via `part_type_cd`), so at
  `merge_and_verify` time the TEXT pivot silently no-ops for that PHC —
  ~56 TEXT columns regress to NULL. In isolation (`@phc_id_list=N'22007000'`)
  the pivot reaches 250/256. These TEXT columns carry `BLOCKED:#13`.

`lookup_table_n_rept` is RTR-written (catalog/odse_unknown_tables.md
corrects the earlier "MasterETL-only" claim), but is **0/2** in the merged
state: the orchestrator does not invoke the `sp_page_builder_postprocessing`
path that persists it during the merge run, so its row only appears under
the fixture's direct tail-EXEC — marked `BLOCKED:#10`.

## d_inv_place_repeat

`sp_repeated_place_postprocessing` is the place-flavoured sibling of the
repeat SP. It pivots `nrt_page_case_answer` rows whose
`PART_TYPE_CD IN ('PlaceAsHangoutOfPHC','PlaceAsSexOfPHC')` (the page-builder
answer metadata) into `PlaceAsHangoutOfPHC` / `PlaceAsSexOfPHC` columns
holding a `PLACE_LOCATOR_UID` string (`place_uid^postal_uid^tele_uid`,
with caret normalization at SP line 48). It then **INNER JOINs `D_PLACE`**
on `PLACE_LOCATOR_UID` and copies the entire `PLACE_*` block (39 columns)
from the matched place row (`035-…-001.sql:515-567`). So the four
pivot-derived columns + the surrogate key are page-builder driven, while
the `PLACE_*` columns trace through the **L5 place dimension** to ODSE via
`sp_place_event`.

Because those `PLACE_*` values originate in another agent's dimension and
this table is only **1/44** in the merged state (the
`zz_d_inv_place_repeat_enrich.sql` fixture's needle-moving depends on an
unshipped orchestrator wire-up of `sp_repeated_place_postprocessing` — the
SP isn't called by `merge_and_verify.sh`), the `PLACE_*` rows are recorded
`INFERRED` (mechanism clear from the SP body, not yet fixture-confirmed
end-to-end), while the pivot columns and surrogate key — which the fixture
demonstrably exercises and `coverage_tier_3.md` documents — are `VERIFIED`.

## f_page_case

`sp_f_page_case_postprocessing` builds the page-case fact (`INSERT_NOCOL`,
`SELECT *` shape) from `nrt_investigation` joined to the dimension key
tables. Its gating filter excludes legacy hepatitis form codes and rows
with non-NULL `CASE_MANAGEMENT_UID` (`012-…-001.sql:85-101`). Foundation's
Investigation was filtered out (NULL form_cd fails `NOT IN`); the
`f_page_case_unblock.sql` fixture UPDATEs `nrt_investigation.investigation_form_cd`
to a modern code so the row passes. Result: **33/35 columns over 7 rows**.
Recorded as a single `<all>` `VERIFIED` row (the SP is `INSERT_NOCOL`, so
the catalog does not enumerate individual columns). Note `f_std_page_case`
is the STD-HIV variant owned by Agent L3 and is **out of L6 scope**.

## LDF chain (ldf_data, ldf_group, ldf_dimensional_data, d_ldf_meta_data,
## ldf_datamart_column_ref, *_ldf_group, per-condition ldf_*)

The LDF chain is the second dynamic spine:

```
nrt_ldf_data (answers in staging; projection of ODSE state_defined_field_data)
  → sp_nrt_ldf_postprocessing            → LDF_DATA + LDF_GROUP + *_ldf_group
nrt_odse_state_defined_field_metadata    → sp_nrt_ldf_dimensional_data_postprocessing
  → LDF_DIMENSIONAL_DATA + D_LDF_META_DATA + LDF_DATAMART_COLUMN_REF
  → per-condition sp_ldf_<cond>_datamart_postprocessing → LDF_<COND>
```

`LDF_DATA`, `LDF_GROUP`, `D_LDF_META_DATA`, `LDF_DATAMART_COLUMN_REF`,
`LDF_DIMENSIONAL_DATA` and the three `*_LDF_GROUP` link tables have a
**static, statically-mappable column set** sourced from
`nrt_odse_state_defined_field_metadata` (the ODSE
`state_defined_field*`/LDF metadata projection) and `nrt_ldf_data`. Those
columns are mapped per-column in the appendix. The metadata/ref tables are
baseline-seeded (2620 / 2662 rows) and largely `VERIFIED`; per-fixture
answer columns are `VERIFIED` where `ldf_answers_tetanus.sql` /
`ldf_answers_mumps_foodborne.sql` / `zz_ldf_flagged_answers.sql` exercise
them, `INFERRED` for the handful of metadata columns no fixture lights up.

The **per-condition `LDF_<COND>` datamart tables are the dynamic tier**:
each is widened by a dynamic ALTER TABLE + pivot keyed on
`LDF_DATAMART_COLUMN_REF` for that condition, so the catalog shows only the
`dynamiccolumnList` placeholder (plus SQL-parser artifacts `END` / `THEN`
from a CASE expression). These are `DYNAMIC`. Several are bug-capped:

- **Bug #06** (`ldf_data_truncation`, *merged*): `LDF_DATA.RECORD_STATUS_CD`
  is `varchar(8)` but the SP maps the 13-char `'LDF_PROCESSED'` into it →
  Msg 2628 truncation. That single column is `BLOCKED:#06` (fixtures author
  `'ACTIVE'` to dodge it).
- **Bug #07** (`ldf_dimensional_data_zero`, *open*): an early-RETURN guard
  treats data-type-filtered LDF UIDs as "missing NRT" and aborts the batch,
  and an INNER (vs LEFT) JOIN on a NULL `ldf_page_id` drops rows. This
  capped `LDF_DIMENSIONAL_DATA` historically (now 14/16 after fixture work);
  the chain's downstream emptiness cascades from here.
- **Bug #08** (`ldf_tetanus_substring`, *open*, **6-SP family**): when a
  per-condition LDF table has only its baseline key columns (no dynamic
  answer columns yet), `SUBSTRING(@dynamiccolumnUpdate, 1, LEN('')-1)`
  computes `SUBSTRING('',1,-1)` → Msg 537. `LDF_TETANUS` carries
  `BLOCKED:#08`; `LDF_BMIRD` and `LDF_HEPATITIS` (both **0/7**) are
  additionally blocked at the source — no `condition_cd` 11717 / 10110 rows
  exist in `nrt_odse_state_defined_field_metadata`, so no dynamic columns
  are ever added and the SUBSTRING fires; populating them needs LDF
  metadata seeding, out of fixture scope. `LDF_FOODBORNE`,
  `LDF_MUMPS`, `LDF_VACCINE_PREVENT_DISEASES` populate (`DYNAMIC`).

## summary_report_case + summary_case_group

`sp_summary_report_case_postprocessing` is a conventional (non-dynamic)
postprocessing SP. It reads `nrt_investigation` filtered to
`case_type_cd='S'`, joined to `nrt_investigation_observation` and the
`nrt_observation_numeric` / `_txt` / `_coded` value tables, plus
`nrt_investigation_notification` and `nrt_srte_state_county_code_value`.
The counts/comments/status are projections of the observation values
(`SUM_RPT_CASE_COUNT = ROUND(ovn_numeric_value_1,0)`,
`SUM_RPT_CASE_COMMENTS = REPLACE(... CR/LF)`, `SUM_RPT_CASE_STATUS = notif_status`);
keys are dimension FKs (`CONDITION_KEY`, `INVESTIGATION_KEY`, date-dim
keys, `SUMMARY_CASE_SRC_KEY` to the sibling `summary_case_group`). The
observation values trace to ODSE via `sp_observation_event` /
`sp_investigation_event`. The `summary_report_case.sql` fixture authors a
`case_type_cd='S'` Investigation with the SUM103/104/105 observations; both
tables are `VERIFIED` (11/12 and 2/2). `NOTIFICATION_SEND_DT_KEY` and
`LDF_GROUP_KEY` are the unfilled cols → `INFERRED`.

## aggregate_report_datamart

`sp_aggregate_report_datamart_postprocessing` builds the aggregate count
grid (24 cells = 8 age groups × HOSPITALIZED/DIED/TOTAL) plus an event
block from a `case_type_cd='A'` Investigation joined to
`nrt_investigation_aggregate`, writing via a dynamic UPDATE keyed on
`@tgt_table_nm='AGGREGATE_REPORT_DATAMART'`. A second SP,
`sp_provider_dim_columns_update_to_datamart`, overlays the 28
`INVESTIGATOR_*` / `PHYSICIAN_*` / `REPORTER_*` provider columns (the only
columns the catalog statically extracts for this table).

The entire table is **0/42** — **Bug #11** (`aggregate_report_datamart_schema_mismatch`,
*open*): the dynamic UPDATE references `NOTIFICATION_UPD_DT_KEY`, a column
the target table does not have (Msg 207, "Invalid column name"); the SP's
try/catch swallows the error and never populates a row, so the provider
overlay has nothing to update either. The `aggregate_report.sql` fixture
authors a correct `case_type_cd='A'` Investigation + aggregate count grid
(and documents the `batch_id` IIF-match gotcha) but cannot land rows until
the schema mismatch is fixed. All 42 columns carry `BLOCKED:#11`.

## dyn_dm_* family (no own RDB_MODERN columns)

The 12 `sp_dyn_dm_*` SPs (`createdm`, `main`, `case_management`,
`invest_form`, `invest_clear`, `org_data`, `provider_data`,
`page_builder_d_inv`, `repeatdate`, `repeatnumeric`, `repeatvarch`,
`dimension_update`) generate and populate **dynamically-named** datamart
tables (`DM_INV_<datamart_nm>`, etc.) whose names and column lists are
assembled at runtime from `nrt_dyn_dm_column_metadata` / page-builder
metadata and `@tgt_table_nm`. The catalog therefore lists them only under
"Dynamic-SQL targets (table name resolved at runtime)" — they contribute
**no static `(table, col)` rows** to this appendix. Their inputs are the
already-built `D_INVESTIGATION_REPEAT` (read by `repeatvarch/repeatdate/
repeatnumeric`) and the page-case dims. They are wholly `DYNAMIC` by
construction and are documented here as a mechanism rather than per-column.

- **Bug #09** (`dyn_dm_unpivot_type`, *fixed* 2026-05-21):
  `sp_dyn_dm_repeatvarch_postprocessing` built a dynamic UNPIVOT over a
  column list whose member columns carried mismatched types (Msg 8167),
  rolling back the outer transaction (Msg 266). The fix unblocked the
  orchestrator Step-9 `sp_dyn_dm_*` chain.

---

## Status summary for this cluster

- **VERIFIED**: static-mapped columns proven by a fixture + coverage report
  — the LDF metadata/data/group/ref tables, `*_ldf_group` links,
  `summary_report_case` / `summary_case_group`, `f_page_case`, and the
  pivot-derived + surrogate-key columns of the repeat dims.
- **DYNAMIC** (expected to dominate): `d_investigation_repeat`'s ~251
  pivot columns, `d_inv_place_repeat`'s pivot columns, and the populating
  per-condition LDF tables (`ldf_foodborne/mumps/vaccine_prevent_diseases`).
  Driven by `nrt_page_case_answer` / `nrt_odse_state_defined_field_metadata`,
  no static ODSE→col map. The `dyn_dm_*` family is dynamic in its entirety.
- **INFERRED**: `d_inv_place_repeat`'s `PLACE_*` block (sourced from
  `D_PLACE`, not yet fixture-confirmed here), plus a small set of LDF
  metadata columns and two `summary_report_case` keys no fixture lights up.
  Never confabulated an ODSE source for these.
- **BLOCKED**: `ldf_data.record_status_cd` (#06); `ldf_tetanus`,
  `ldf_bmird`, `ldf_hepatitis` (#08, the latter two also source-starved);
  `lookup_table_n_rept` (#10, orchestrator wire-up); all of
  `aggregate_report_datamart` (#11); `d_investigation_repeat`'s TEXT pivot
  columns at merge time (#13). Bugs #07 (open) and #09 (fixed) shape the LDF
  and dyn_dm chains respectively.

Note: there is **no bug #14** — the `LINEAGE.md` reference is incorrect;
`aggregate_report` is #11 and the `sld_investigation_repeat` TEXT pivot is
#13. `bugs/` holds dirs 01–13.
