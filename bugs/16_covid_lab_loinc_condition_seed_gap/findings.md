# Bug #16 — COVID lab datamarts blocked by missing `condition_cd='11065'` rows in `nrt_srte_Loinc_condition` (SEED-gated, not an RTR code defect)

**Affected:** `COVID_LAB_DATAMART` (0/120), `COVID_LAB_CELR_DATAMART` (0/101, transitive).

**Root cause:** `sp_covid_lab_datamart_postprocessing` (routine 330, lines 78-91) admits a result
observation only when its resulted-test LOINC is mapped to the condition:
`o.cd IN (SELECT loinc_cd FROM nrt_srte_Loinc_condition WHERE condition_cd='11065')`. The SP's
alternate `o.cd IN('')` local-code escape ships empty. `nrt_srte_Loinc_condition` is loaded
verbatim from `NBS_SRTE.dbo.Loinc_condition` (onboarding load ~line 234) and CDC-synced.

**Live-verified:** `NBS_SRTE.dbo.Loinc_condition` has 3449 rows but **0 for condition_cd='11065'**;
the nrt mirror likewise 0; none of the common COVID LOINCs (94309-2, 94500-6, 94531-1, 94533-7)
are mapped. So no ODSE-authored COVID lab result can pass the filter.
`covid_lab_celr_datamart` reads exclusively `FROM dbo.covid_lab_datamart`, so it is blocked
transitively.

**Proof the block is SRTE-only (pipeline already works):** a complete real-fidelity ODSE COVID
lab chain already exists (UIDs 22022000/22022001 from `zz_covid_lab_datamart_unblock.sql`), wired
to both SPs via `LAB_OBS_UIDS` in `scripts/merge_and_verify.sh`. The pipeline correctly produced
`nrt_observation` 22022000 (Order, cd=94309-2, result_observation_uid=22022001,
associated_phc_uids=22003000) + 22022001 (Result). Both datamarts remain 0 purely because
94309-2 ∉ the 11065 LOINC set.

**Secondary downstream defect (moot while LOINC blocks):** the staged lab Order's
`nrt_observation.patient_id` is NULL, which would also fail the patient gate at line 77 (needs a
patient participation on the lab Order).

**Disposition:** OUT OF BOUNDS for the comparison fixtures (requires an SRTE/seed edit), same
class as VAR_DATAMART. Loop Round 4 marks COVID labs as do-not-spawn.

**Suggested seed-owner fix (if the team later allows reference-data seeding):** add COVID-19
LOINCs (94309-2, 94500-6, 94531-1, 94533-7, 94306-8, 94558-4, 95209-3) to
`NBS_SRTE.dbo.Loinc_condition` for `condition_cd='11065'` (production SRTE ships these; the
comparison baseline omits them). Once seeded, the existing unblock chain + a patient
participation on the lab Order would populate both datamarts with no further fixture work
(SP invocations already wired in `merge_and_verify.sh`).
