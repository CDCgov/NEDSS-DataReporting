# Bug #25: sp_dyn_dm_createdm_postprocessing 206 "Operand type clash: date is incompatible with float"

REPRODUCIBLE (every run) for STD + HEPATITIS_B_PERINATAL dynamic datamarts; sp_dyn_dm_main (50000 @ line
715) just re-raises it ("Error in sp_dyn_dm_createdm_postprocessing"). This throw POISONS the
postprocessing batch: under the (intentional) fail-fast, innocent co-batched entities are then deferred
to retry/backfill, which is the indirect coverage cost. NOTE: bug #20 was REVERTED; the fail-fast is by
design, so eliminating poisons like this is the principled way to reduce collateral.

ROOT CAUSE (routine/environment defect, NOT bad fixture data; proven structural / bind-time):
routine 245 sp_dyn_dm_createdm_postprocessing, "UPDATING <tgt>" step. It builds the UPDATE SET-list
(lines 319-328) as a blind `tgt.[col] = src.[col]` for every column present in BOTH the incoming temp
and the target, then runs `UPDATE tgt SET ... FROM <incoming> src LEFT JOIN <tgt> tgt` (339-353) with NO
type reconciliation.
- src (incoming) columns are correctly typed `date`, from sp_dyn_dm_repeatdate_postprocessing's pivot,
  driven by form metadata (v_nrt_d_inv_repeat_metadata, data_type=DATE) for PG_STD_Investigation /
  ...B_Perinatal. Columns: STD_HX_DIAGNOSIS_DT_1/2/3, STD_HX_TREATMENT_DT_1/2/3, SPECIMEN_COLLECT_DT_*,
  RESULT_DT_*, AST_SPEC_COLLECT_DT_*, SYM_OBS_ONSET_DT_* (STD); VAC_ADMINISTERED_DT_* (Hep B Perinatal).
- tgt (DM_INV_STD / DM_INV_HEPATITIS_B_PERINATAL) are LEGACY pre-seeded shells from the 2023-01-10
  baseline snapshot (sys.tables.create_date=2023-01-10, 0 rows, NO DDL in the repo). In that snapshot
  the placeholder LDF columns were materialized as `float`. createdm takes the "target exists" branch
  (skips the SELECT * INTO at ~line 208), so it runs `date -> float` and throws 206.
- PROVEN independent of fixture values: the repeat-date temp has 0 rows but still carries all 18 `date`
  columns (pivot column-list is form-metadata-driven, not row-driven); a standalone zero-row
  `UPDATE tgt SET tgt.c(float)=src.c(date)` reproduces 206 State 2 exactly. Editing/removing fixture
  date answers does NOT fix it. STD + HEP share the identical root.

SCOPE: DM_INV_STD / DM_INV_HEPATITIS* are NOT in the coverage target list (legacy/OOB dynamic datamarts,
not measured). So fixing this does not directly add measured coverage; its value is removing the poison
that (under the intentional fail-fast) starves innocent co-batched entities, giving more stable coverage.

FIX OPTIONS (no fixture change; the incoming metadata-driven type is authoritative, the legacy float is
the error):
1. Routine fix (in-bounds, sanctioned for a filed bug): make createdm type-aware. Before the UPDATE, for
   each column in both src and tgt whose declared types differ, `ALTER TABLE <tgt> ALTER COLUMN [c]
   <incoming_type>` (safe: targets are 0-row shells). Extends the existing "ADD NECESSARY COLUMNS" path
   to also RECONCILE mismatched types. BLAST RADIUS: affects ALL dynamic datamarts createdm builds, so it
   needs care/testing (verify no datamart legitimately wants a target type differing from its metadata
   type; unlikely but legacy code is unpredictable).
2. Environment/seed fix (OUT OF BOUNDS here): drop/re-type the legacy DM_INV_* shells so createdm
   rebuilds them via SELECT * INTO with correct `date` types (the IF-NOT-EXISTS branch never fires today).

RECOMMENDATION: option 1 (type-aware createdm) with a data-driven test (float-shell target + date
incoming -> no 206 + column re-typed to date), but it's a legacy-routine change with broad reach,
worth a conscious decision before landing. Confidence in the diagnosis: very high (full evidence chain
in the investigation: located the failing step in job_flow_log, enumerated the date<->float column
pairs via INFORMATION_SCHEMA, confirmed 2023-seeded 0-row shells, reproduced with a standalone UPDATE).

## Update (2026-06-05): attempted fix; deeper than a targeted patch (deferred)
Attempted a type-reconciliation step in createdm (re-type the target column to the incoming,
metadata-authoritative type before the UPDATE). It works mechanically but is NOT a clean targeted
fix: the legacy DM_INV_* shells are mistyped in BOTH directions and the routine's structure resists
a surgical patch:
1. BIDIRECTIONAL clash: not only `date incoming -> float target` (the original symptom) but also
   `float incoming -> date target` ("Operand type clash: float is incompatible with date" surfaces
   once the first direction is fixed). The shell's column types are arbitrarily wrong vs the metadata
   throughout.
2. ROW-SIZE: re-typing all type mismatches (the general fix) widens DM_INV_STD past the 8060-byte
   limit ("max row size exceeds 8060") and breaks the table; the shell is already near the limit.
3. NESTED TRANSACTION: createdm's COMMITs are nested inside sp_dyn_dm_main's transaction, so the
   re-type rolls back together with the UPDATE's failure, so the column-type change does not persist
   across the failure path, defeating an in-transaction re-type.

CONCLUSION: a robust fix is a broader rework of the dynamic-datamart createdm (full type
reconciliation that respects the 8060 limit and the transaction structure), or correcting the legacy
DM_INV_* baseline DDL so the shells carry the metadata-authoritative types. That is out of scope for a
targeted bug fix. DM_INV_* are OUT OF BOUNDS (not in the coverage target set); the only cost of leaving
#25 open is the fail-fast collateral the 206 causes under the intentional batch fail-fast (bug #20).
Deferred with this fuller root cause.
