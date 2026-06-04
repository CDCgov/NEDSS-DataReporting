# Bug #24 — routine 040 caps BMIRD_MULTI_VALUE_FIELD to one row per PHC (NULLs bmird_strep_pneumo _2.._8)

`sp_..._postprocessing` routine 040, building `#BMIRD_Multi_Value_field_IDS` (~line 558), does
`ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ORDER BY ...)` then
`SELECT DISTINCT public_health_case_uid, row_num`. Because branch_id is IN the partition, every branch
gets row_num=1, so the DISTINCT collapses to a SINGLE selection_number / MVF row per PHC. Verified live:
BMIRD_MULTI_VALUE_FIELD has exactly 1 row for the bmird PHC even though zz_bmird_fill authors 3
observations per multi-value code.

CONSEQUENCE: bmird_strep_pneumo_datamart columns UNDERLYING_CONDITION_2..8, NON_STERILE_SITE_2/3,
ADD_CULTURE_1_SITE_2/3, ADD_CULTURE_2_SITE_2/3 (13 cols) + TYPE_INFECTION_OTHERS_CONCAT /
STERILE_SITE_OTHERS_CONCAT (2 cols) are permanently NULL regardless of fixture data (answer OR obs) —
the multi-value fan-out never produces selection_number > 1. Likely fix: PARTITION BY
public_health_case_uid only (drop branch_id), or order/number across branches so each gets a distinct
selection_number. Routine change — needs RTR team triage.

ALSO (separate, not this bug): bmird_strep_pneumo_datamart is observation-driven (routine 040 builds
from v_rdb_obs_mapping branch_type_cd='InvFrmQ'; legacy INV_FORM_BMDSP form has zero page-builder rdb
metadata) — there is NO nbs_case_answer path, so its remaining scalar gaps (EARLIEST_RPT_TO_*_DT,
DIE_FRM_THIS_ILLNESS_IND, GENERAL_COMMENTS, HOSPITAL_NAME, FIRST_POSITIVE_CULTURE_DT) require a
PHC-enrich + dedicated-ADT-org fixture (LOOP_round5 'item C' style), not answers. Documented so the loop
does not chase them via answers.
