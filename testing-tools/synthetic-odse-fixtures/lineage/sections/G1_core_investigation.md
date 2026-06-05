## G1 — Core Investigation, HIV, Case-Management & Repeat-Link tables

Gap-fill cluster covering ten RDB_MODERN tables that the original appendix
missed: the core investigation fact (`INVESTIGATION`) and its two
confirmation children (`confirmation_method`, `CONFIRMATION_METHOD_GROUP`),
the SRTE-driven `CONDITION` dimension, the `CASE_COUNT` fact, the
`D_CASE_MANAGEMENT` dimension, the STD/HIV `INV_HIV` bridge, and the three
page-builder repeat-link tables (`L_INVESTIGATION_REPEAT`,
`L_INVESTIGATION_REPEAT_INC`, `L_INV_PLACE_REPEAT`).

Column appendix: `lineage/columns/G1_core_investigation.tsv` — 197 rows,
one per (table, column) the catalog records. 193 VERIFIED, 4 INFERRED, 0
DYNAMIC, 0 MASTERETL_ONLY, 0 BLOCKED.

### How to read the chain for this cluster

Every event-sourced table here follows the STRATEGY.md convention: the
`sp_investigation_event` SP reads `nbs_odse.dbo.*` and projects a JSON
view (it is the **ODSE → staging** edge, recorded in `odse_source_col(s)`);
the matching `sp_nrt_*_postprocessing` SP reads only RDB_MODERN-side
`nrt_*` staging (the **staging → RDB_MODERN** edge, recorded in
`nrt_staging_source` + `transform_note`). One subtlety: a single event SP
(`sp_investigation_event`) is the upstream projector for *three* of this
cluster's postprocessing SPs — investigation, case-management, and
case-count all read staging tables (`nrt_investigation`,
`nrt_investigation_case_management`, `nrt_investigation_confirmation`)
that are slices of that one event SP's nested-JSON output. The
case-management columns in particular trace to the
`investigation_case_management` nested projection of
`nbs_odse.dbo.case_management` at event-SP lines 603-691. `CONDITION` is
the exception: it has **no** event-SP partner and reads SRTE staging
mirrors (`nrt_srte_condition_code`, `nrt_srte_program_area_code`), so its
ultimate source is `nbs_srte.dbo.*` rather than ODSE.

### INVESTIGATION — the core investigation fact (71/71 VERIFIED)

`sp_nrt_investigation_postprocessing` is the heaviest SP in this cluster.
It selects `nrt_investigation` into `#temp_inv_table` (SP:46-132),
applying a uniform `NULLIF(x,'')`/`CASE WHEN '' OR 'null'` blank-to-NULL
discipline and two `isnumeric()`-guarded `CAST … AS int` conversions
(`PATIENT_AGE_AT_ONSET`, `ILLNESS_DURATION`). It then UPDATEs existing
rows (SP:428-503) and INSERTs new ones (SP:536-681), allocating
`INVESTIGATION_KEY` from the `nrt_investigation_key` IDENTITY surrogate.
The upstream `sp_investigation_event` resolves nearly every `*_cd` to a
description through `fn_get_value_by_cd_codeset` against a named INV* code
set (e.g. `case_class_cd`→INV163 for `INV_CASE_STATUS`,
`hospitalized_ind_cd`→INV128, `outcome_cd`→INV145 for
`DIE_FRM_THIS_ILLNESS_IND`), plus SRTE desc joins for jurisdiction, state,
county, program-area, and detection method. All 71 catalog columns map
back to `nbs_odse.dbo.public_health_case` (with locator/code-set joins),
and are VERIFIED across the two fixture variants (foundation = NULL-heavy
blank-path; v2 = fully attributed).

A notable **conditional branch** is the legacy coded-observation overlay
(SP:198-385): when `investigation_form_cd` is one of 14 legacy forms
(`INV_FORM_BMDGAS`/`INV_FORM_HEPGEN`/`INV_FORM_RUB`/…), the SP pulls
coded/text/numeric/date observations from `NRT_INVESTIGATION_OBSERVATION`
via the `v_getobs*` views and COALESCEs them over the direct PHC values
for ~12 columns (HSPTLIZD_IND, IMPORT_FRM_*, FOOD_HANDLR_IND, etc.). The
v2 fixture uses the modern `PG_Hepatitis_A_Acute_Investigation` form, so
the overlay does not fire; the direct-PHC path is what is exercised. The
overlay is documented in transform notes but not separately fixture-proven
(coverage_investigation.md "Legacy investigation form" skip).

### confirmation_method & CONFIRMATION_METHOD_GROUP (3/3 each, VERIFIED)

Both are written by the same SP in its second transaction (SP:705-880).
`#temp_cm_table` joins `dbo.investigation` LEFT JOIN
`nrt_investigation_confirmation` (the event SP's
`investigation_confirmation_method` projection of
`nbs_odse.dbo.Confirmation_method` + the `PHC_CONF_M` SRTE desc). New
confirmation codes allocate a `confirmation_method` key via
`nrt_confirmation_method_key` IDENTITY (SP:805-817).
`CONFIRMATION_METHOD_GROUP` is DELETE-then-INSERT per investigation and
COALESCEs `CONFIRMATION_METHOD_KEY` to sentinel 1 when no real CM row
exists (SP:856). **Caveat worth flagging for the diff tool:** the
`#temp_cm_table` query emits one row per Investigation regardless of
whether a confirmation method is present, so an Investigation with no
`nrt_investigation_confirmation` row still gets a sentinel-1
CONFIRMATION_METHOD_GROUP row — documented as a row-count-integrity bug in
`coverage_std_hiv_full_chain.md` (the "sentinel CMG row" finding). It does
not block any column population here.

### CONDITION — SRTE-sourced dimension (14/15 VERIFIED, 1 INFERRED)

`sp_nrt_srte_condition_code_postprocessing` is an infrastructure SP run
once per merge (`@condition_cd_list = '10110'` for Hep A acute). Unlike
the rest of the cluster it reads SRTE staging mirrors, not ODSE: 13
columns are pass-throughs of `nrt_srte_condition_code` (=
`nbs_srte.dbo.condition_code`); `program_area_desc` joins
`nrt_srte_program_area_code`; `condition_key` is the
`nrt_condition_key` IDENTITY surrogate; and `disease_grp_cd`/`_desc` are a
`CASE LEFT(investigation_form_cd,50)` map to `*_Case` group labels
(SP:70-93). One of the 15 catalog columns is NULL in the merged run
(14/15) — most likely `assigning_authority_desc` for the Hep A code,
which lacks an SRTE value; that single column is flagged **INFERRED**.

### CASE_COUNT (13/15 VERIFIED, 2 INFERRED)

`sp_nrt_case_count_postprocessing` reads `NRT_INVESTIGATION` and resolves
13 dimension keys by joining the already-populated RDB_MODERN dimensions
(`INVESTIGATION`, `condition`, `D_PATIENT`, `D_PROVIDER`×3,
`D_ORGANIZATION`×2, `RDB_DATE`×4), each `COALESCE(...,1)`-guarded to
sentinel 1 (SP:52-88). `geocoding_location_key` is a hard-coded literal 1
(no RTR geocoding chain). The two derived count columns —
`investigation_count` and `case_count` — come from
`nrt_investigation.investigation_count`/`case_count`, which the event SP
derives only from the `Summary_Report_Form`→`SUM107` `act_relationship`
chain (event SP:846-867). The merged run leaves these 2 NULL (13/15);
they are flagged **INFERRED** because no fixture authors the summary-form
chain that feeds them.

### D_CASE_MANAGEMENT — needs a case-management ODSE input (62/67 VERIFIED)

`sp_nrt_case_management_postprocessing` reads
`nrt_investigation_case_management` INNER JOIN `INVESTIGATION` (on
CASE_UID) and writes the dimension (SP:52-432). 65 columns pass through
the staging row, `INVESTIGATION_KEY` comes from the INVESTIGATION join,
and `D_CASE_MANAGEMENT_KEY` is the `nrt_case_management_key` IDENTITY
surrogate. **The load-bearing ODSE input is `nbs_odse.dbo.case_management`**:
the entire staging row is the event SP's `investigation_case_management`
nested-JSON projection (event SP:603-691), where each
`case_management.*` column is either passed through or resolved through a
`fn_get_value_by_cvg` code-set lookup (e.g.
`pat_intv_status_cd`→PAT_INTVW_STATUS, `status_900`→STATUS_900,
`fld_foll_up_dispo`→FIELD_FOLLOWUP_DISPOSITION_STDHIV). A handful of
columns also apply `LEFT(x,N)` width truncation in the postprocessing SP
to fit narrow target widths (`init_foll_up_notifiable` LEFT 27,
`initiating_agncy`/`ooj_agency` LEFT 20). The TSV records all 67 columns
VERIFIED against `case_management_staging.sql`; the catalog's "62/67"
reflects 5 columns left NULL in the merged run because the fixture's
short-string UPDATEs do not populate every narrow `*_cd`/date field — the
mapping itself is sound, so each column is attributed to its
`case_management.*` source.

### INV_HIV — STD/HIV bridge over a MasterETL-only dimension (17/19 VERIFIED)

`sp_std_hiv_datamart_postprocessing` populates `INV_HIV` by joining
`F_STD_PAGE_CASE` (which carries `D_INV_HIV_KEY` and `INVESTIGATION_KEY`)
to the `D_INV_HIV` dimension and copying its 15 `HIV_*` columns
(SP:62-159). `INVESTIGATION_KEY` traces back to
`public_health_case.public_health_case_uid` through the INVESTIGATION dim;
`D_INV_HIV_KEY` and all `HIV_*` values originate in **`D_INV_HIV`, which
is a MasterETL-only dimension with no RTR ODSE writer** — the fixture
hand-authors the `D_INV_HIV` row directly (per the
coverage_std_hiv_full_chain.md convention that Tier-3 dimensional-cluster
fixtures may write these MasterETL-only tables when the RTR datamart chain
reads from them). Because the fixture proves all 17 catalog columns
populate end-to-end, they are recorded VERIFIED with the MasterETL-only
provenance noted in `odse_source_col(s)`. The catalog's "17/19" reflects 2
physical table columns RTR's SELECT list never writes (e.g.
HIV_HIV_STAT_INV_IN_EHARS) — not in the catalog write-set, so not in this
slice.

### L_INVESTIGATION_REPEAT / _INC / L_INV_PLACE_REPEAT (repeat-link tables)

`sp_sld_investigation_repeat_postprocessing` builds the two
investigation-repeat link tables. `PAGE_CASE_UID` on both is the
`nrt_investigation.public_health_case_uid` (→
`public_health_case.public_health_case_uid`), filtered out of 15 legacy
`investigation_form_cd` values (SP:84-91); the answer payload itself comes
from `nrt_page_case_answer` (NRT_PAGE). `D_INVESTIGATION_REPEAT_KEY` is a
surrogate from `LOOKUP_TABLE_N_REPT` (SP:1165-1203). Both tables are 2/2
VERIFIED (merged coverage: `l_investigation_repeat` 1→2,
`l_investigation_repeat_inc` 0→1). Note the link tables are **not** capped
by the repeat-dim bugs: **bug #10** (`D_REPT_KEY` surrogate pins to
sentinel 1, dropping rows from the wide `D_INVESTIGATION_REPEAT` dim) and
**bug #13** (TEXT-pivot NULL propagation) both affect
`D_INVESTIGATION_REPEAT`'s value columns, not these two-column link
tables, which populate cleanly.

`L_INV_PLACE_REPEAT` is written by `sp_repeated_place_postprocessing`. Its
`D_INV_PLACE_REPEAT_KEY` is a `DENSE_RANK()`-allocated surrogate (SP:393-412)
and is populated (the sentinel row), but `PAGE_CASE_UID` —
sourced from `nrt_page_case_answer.act_uid` via the
`PlaceAsHangoutOfPHC`/`PlaceAsSexOfPHC` part-type pivot (SP:46-67) — is
**NULL in the merged run (1/2)**. Two things keep it unpopulated:
`sp_repeated_place_postprocessing` is not wired into
`merge_and_verify.sh` (the ORCH_TODO in `zz_d_inv_place_repeat_enrich.sql`),
and the place-repeat answer rows + a matching `D_PLACE.PLACE_LOCATOR_UID`
must both exist for the SP's INNER JOIN to emit a non-sentinel row.
`PAGE_CASE_UID` is therefore flagged **INFERRED** — the mapping is read
from the SP body but no merged fixture proves it.
