## G3 — PAM dimension code & group tables (TB / Varicella)

**Cluster**: the 12 page-answer-driven PAM "code + group" dimension pairs that
hang off the TB and Varicella PAM fact tables (`F_TB_PAM` / `F_VAR_PAM`) and
their root dims (`D_TB_PAM` / `D_VAR_PAM`). Each pair is one *value* dimension
plus its one-column `_GROUP` partner:

| Dimension (6/6 cols) | Group (1/1 col) | Writer SP | Question | PAM family |
| --- | --- | --- | --- | --- |
| `D_ADDL_RISK` | `D_ADDL_RISK_GROUP` | `sp_nrt_d_addl_risk_postprocessing` (146) | TUB167 | TB |
| `D_DISEASE_SITE` | `D_DISEASE_SITE_GROUP` | `sp_nrt_d_disease_site_postprocessing` (145) | TUB119 | TB |
| `D_GT_12_REAS` | `D_GT_12_REAS_GROUP` | `sp_nrt_d_gt_12_reas_postprocessing` (170) | TUB235 | TB |
| `D_HC_PROV_TY_3` | `D_HC_PROV_TY_3_GROUP` | `sp_nrt_d_hc_prov_ty_3_postprocessing` (180) | TUB237 | TB |
| `D_MOVED_WHERE` | `D_MOVED_WHERE_GROUP` | `sp_nrt_d_moved_where_postprocessing` (195) | TUB225 | TB |
| `D_MOVE_CNTRY` | `D_MOVE_CNTRY_GROUP` | `sp_nrt_d_move_cntry_postprocessing` (156) | TUB230 | TB |
| `D_MOVE_CNTY` | `D_MOVE_CNTY_GROUP` | `sp_nrt_d_move_cnty_postprocessing` (175) | TUB228 | TB |
| `D_MOVE_STATE` | `D_MOVE_STATE_GROUP` | `sp_nrt_d_move_state_postprocessing` (185) | TUB229 | TB |
| `D_OUT_OF_CNTRY` | `D_OUT_OF_CNTRY_GROUP` | `sp_nrt_d_out_of_cntry_postprocessing` (190) | TUB114 | TB |
| `D_PCR_SOURCE` | `D_PCR_SOURCE_GROUP` | `sp_nrt_d_pcr_source_postprocessing` (230) | VAR176 | Varicella |
| `D_RASH_LOC_GEN` | `D_RASH_LOC_GEN_GROUP` | `sp_nrt_d_rash_loc_gen_postprocessing` (225) | VAR105 | Varicella |
| `D_SMR_EXAM_TY` | `D_SMR_EXAM_TY_GROUP` | `sp_nrt_d_smr_exam_ty_postprocessing` (200) | TUB129 | TB |

24 tables; 84 columns; **all VERIFIED** in the merged state (every dimension
6/6, every group 1/1 — `coverage_merged.md`).

---

### The shared SP template

These 12 SPs are near-identical clones; reading 145/146/185/225/230 establishes
the whole family. Each one materializes a *single multi-answer PAM question* (a
"repeating-block" page answer) into a value dimension + a group dimension that
collects the per-investigation answer set. Per STRATEGY.md, none of them read
`nbs_odse.dbo.*` — they read RDB_MODERN-side staging only. The pipeline is:

```
nbs_case_answer / PAM page answer  (ODSE-side; one row per answered question)
   → CDC → Debezium → kafka-connect → nrt_page_case_answer  (staging projection)
   → sp_nrt_d_<X>_postprocessing  → D_<X> + D_<X>_GROUP  (RDB_MODERN)
```

Step-by-step, the template is:

1. **`#S_PHC_LIST`** — split the proc argument into a PHC-UID temp table.
   Most SPs take `@phc_uids` and `STRING_SPLIT(@phc_uids, ',')`; a newer subset
   (170, 180, 190, 200, 230) take **`@phc_id_list`** and use
   `SELECT TRIM(value) FROM STRING_SPLIT(@phc_id_list, ',')` inline (no temp
   table) — the only signature deviation in the family. The orchestrator
   passes the correct argument name per SP (see `coverage_tb_full_chain.md`).
2. **`#S_<X>_TRANSLATED`** — select from `NRT_PAGE_CASE_ANSWER` filtered to
   `QUESTION_IDENTIFIER = '<the SP's question>'` and `DATAMART_COLUMN_NM <> 'n/a'`,
   `LEFT JOIN NRT_INVESTIGATION` on `act_uid = public_health_case_uid`
   (with the `isnull(tb.batch_id,1)=isnull(inv.batch_id,1)` batch guard),
   `INNER JOIN #S_PHC_LIST` on `act_uid`. `CAST(act_uid AS BIGINT)` becomes the
   grain key — `TB_PAM_UID` for TB tables, `VAR_PAM_UID` for the two Varicella
   tables. The answer text is decoded against SRTE: join
   `nrt_srte_codeset_group_metadata` on `CODE_SET_GROUP_ID` to resolve
   `CODE_SET_NM`, then join the code-value table on `(CODE_SET_NM, CODE=ANSWER_TXT)`.
3. **`#S_<X>`** — derive `VALUE`. Two transform shapes (see deviations below).
4. **Delete-then-reload** — compute `#TEMP_D_<X>_DEL` (existing dim rows for
   these PHCs), delete the matching rows from the two `NRT_<X>_KEY` /
   `NRT_<X>_GROUP_KEY` surrogate-key staging tables and from `D_<X>`, then
   re-insert fresh surrogate keys (`NRT_<X>_GROUP_KEY` by `TB_PAM_UID`/`VAR_PAM_UID`,
   `NRT_<X>_KEY` by `(PAM_UID, NBS_CASE_ANSWER_UID)`). These IDENTITY-allocated
   keys are RTR-internal surrogates — **no ODSE source**.
5. **Build link temps** — `#D_<X>_PAM_TEMP` from `D_TB_PAM`/`D_VAR_PAM`,
   `#L_<X>_GROUP` and `#L_<X>` join the surrogate keys; missing keys collapse to
   the sentinel `1` via `CASE WHEN … IS NULL THEN 1`.
6. **Load** — INSERT new `D_<X>_GROUP` rows (DISTINCT group keys), then
   UPDATE-existing + INSERT-new into `D_<X>` writing the six columns
   (`<PAM>_PAM_UID`, `D_<X>_KEY`, `SEQ_NBR`, `D_<X>_GROUP_KEY`, `LAST_CHG_TIME`,
   `VALUE`). Finally **push `D_<X>_GROUP_KEY` onto the fact** via
   `UPDATE F_TB_PAM`/`F_VAR_PAM … SET D_<X>_GROUP_KEY = …` joined through
   `D_TB_PAM`/`D_VAR_PAM`, and garbage-collect orphaned group rows.

So for every dimension: `<PAM>_PAM_UID`, `SEQ_NBR`, `LAST_CHG_TIME` carry
through from the page answer; `VALUE` is the decoded answer; the two `_KEY`
columns are RTR surrogate keys; and `D_<X>_GROUP` holds just the surrogate
group key. The driving mechanism is a **fixed page-answer question pivot** —
the value is page-answer-sourced (`nbs_case_answer` → `nrt_page_case_answer`),
*not* a static ODSE column — but because each SP keys on a hard-coded
`QUESTION_IDENTIFIER` (not runtime page-builder metadata) the column set is
fully static, statically mappable, and fixture-proven. These are therefore
**VERIFIED**, not DYNAMIC: the `nbs_case_answer`/PAM-page → `nrt_page_case_answer`
edge is the honest ODSE-side source recorded in the appendix.

### Per-table deviations

The SPs are templated to the point of being clones; only three axes vary, all
captured in the appendix `transform_note`:

- **Argument name** — 170/180/190/200/230 use `@phc_id_list` (+ `TRIM`); the
  other seven use `@phc_uids`. No effect on the column map.
- **`VALUE` transform shape** — two forms:
  - **CASE form** (145, 146, 170, 180, 190, 200, 230):
    `CASE WHEN CODE_SET_GROUP_ID IS NULL OR ='' THEN ANSWER_TXT ELSE
    CODE_SHORT_DESC_TXT END` — falls back to the raw answer text when the
    answer is free-text (no code set).
  - **Direct form** (156, 175, 185, 195, 225): `CODE_SHORT_DESC_TXT AS VALUE`
    with no fallback (these questions are always coded).
- **Code-value source table** — most decode against
  `nrt_srte_code_value_general` (alias yields `CODE_SHORT_DESC_TXT`). Two
  geography questions decode against **`nrt_srte_state_county_code_value`**
  instead: `D_MOVE_CNTY` (175, county) keeps `CODE_SHORT_DESC_TXT`, while
  `D_MOVE_STATE` (185, state) aliases **`CODE_DESC_TXT`** (the only SP that
  reads `CODE_DESC_TXT` rather than `CODE_SHORT_DESC_TXT`).
- **PAM family / grain column** — `D_PCR_SOURCE` (230) and `D_RASH_LOC_GEN`
  (225) are the two **Varicella** tables: grain key `VAR_PAM_UID`, joined to
  `D_VAR_PAM`, fact pushed to `F_VAR_PAM`. The other ten are **TB**:
  `TB_PAM_UID`, `D_TB_PAM`, `F_TB_PAM`.

### Verification

Both PAM families are proven end-to-end. `tb_investigation_full_chain.sql`
authors one `nbs_case_answer` + `nrt_page_case_answer` pair per TUB question
(TUB114/119/129/167/225/228/229/230/235/237 all present) and runs the ten TB
cluster SPs; `coverage_tb_full_chain.md` records each TB dim at 6/6 with sample
`VALUE`s (`D_DISEASE_SITE='Pulmonary'`, `D_ADDL_RISK='Diabetes Mellitus'`,
`D_MOVE_CNTRY='UNITED STATES'`, `D_MOVE_STATE='Georgia'`,
`D_MOVED_WHERE='Out of the U.S.'`, `D_HC_PROV_TY_3='Private Outpatient'`,
`D_GT_12_REAS='Non-adherence'`, `D_SMR_EXAM_TY='Pathology/Cytology'`).
`varicella_investigation_full_chain.sql` authors VAR105 + VAR176 and runs the
two Varicella SPs; `coverage_varicella_full_chain.md` records
`D_RASH_LOC_GEN='Trunk'` and `D_PCR_SOURCE='Scab'`, each 6/6, plus the group
keys flowing onto `F_VAR_PAM`. `coverage_merged.md` confirms all 24 tables at
6/6 (dims) / 1/1 (groups) in the full merged run.

*Note*: `coverage_tb_full_chain.md` labels `D_DISEASE_SITE` as "7/7"; this is a
typo in that report — the catalog (the appendix spine) and the SP both define
six columns for the table, and `coverage_merged.md` lists it as 6/6.

### Status summary for this cluster

- **VERIFIED (84/84)**: every column of all 24 tables. The dim grain/answer
  columns trace to the PAM page answer (`nbs_case_answer` → `nrt_page_case_answer`)
  via a fixed `QUESTION_IDENTIFIER` pivot + SRTE code decode; the `_KEY` /
  `_GROUP_KEY` columns are RTR-internal surrogates (no ODSE source, correctly
  recorded as such). No INFERRED, DYNAMIC, MASTERETL_ONLY, or BLOCKED rows —
  the family is wholly fixture-proven and bug-free, and **as templated as
  expected**.
