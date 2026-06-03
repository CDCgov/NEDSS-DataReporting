# Coverage recovery loop — Round 4 (overnight, autonomous, NO-SHORTCUT)

**Active control doc for the current self-paced loop.** Prior rounds: `LOOP_round1.md`,
`LOOP.md` (r2), `LOOP_round3.md` (r3) — all **shortcut-era** and historical. This round runs
on branch `aw/remove-nrt-shortcut` where the `nrt_*` CDC-bypass shortcut is REMOVED.

**Goal**: raise faithful column coverage from the committed **42.1%** baseline
(commit 138dfdc2; 1938/4598) toward **90%**, authoring **ODSE-only** Tier-3 chains that the
**real pipeline** (ODSE → CDC → Debezium → Kafka → service `sp_*_event` + postprocessing +
datamart SPs) turns into datamart coverage. Pivot to P1 saturation / P3 if ROI craters
(see Stop conditions).

**User decisions governing this round** (locked 2026-06-03):
- **Mixed fidelity**: real-fidelity chains for clinically-meaningful datamarts (COVID / STD /
  TB / hepatitis); coverage-oriented generic values for the long tail.
- **FIXTURES ONLY**: do NOT modify the baked DB seed (`containers/db/initialize`) or SRTE
  reference data. Coverage that requires seed/SRTE changes is OUT OF BOUNDS → document as a
  gap, skip. (Kills VAR_DATAMART — needs SRTE `PORT_REQ_IND_CD='T'` for cond 10030.)
- **Aim 90%, pivot at diminishing returns** back to P1 saturation or into P3.

**Cadence**: self-paced via `ScheduleWakeup` (~1200s between ticks).
**Branch**: commit improvements to `aw/remove-nrt-shortcut`.

## THE NO-SHORTCUT CONTRACT (what changed from r1–r3 — READ THIS)
- **NO `nrt_*` INSERTs.** The sink writes `nrt_*` from ODSE via CDC. Authoring `nrt_*` rows is
  the banned shortcut. Fixtures author ODSE only.
- **NO manual `EXEC sp_*`.** The reporting-pipeline-service runs every event/postprocessing/
  datamart SP. Fixtures must NOT call them.
- **Validation = full `scripts/merge_and_verify.sh`** (it does `down -v` + build + up + applies
  ODSE fixtures tier-by-tier + drains the real pipeline). There is no incremental "apply +
  EXEC" shortcut anymore. Trust only a fresh `scripts/coverage_summary.sh` after a clean merge.

## Architecture cheat-sheet (hard-won — do NOT re-derive)
- **Page-builder dims (`D_INV_*`)** populate iff the investigation has `nbs_case_answer` rows on
  the form its **condition** maps to (`NBS_SRTE.condition_code.condition_cd → investigation_form_cd`;
  `sp_investigation_event` routine 056 ~line 516 gates the join on this). The service computes
  `rdb_table_name_list` IN JAVA (`ProcessInvestigationDataUtil.java:459-468`: distinct non-null
  `rdb_table_nm` from the answer array) → `PostProcessingService:351` `pbCache` →
  `executeStoredProcForPageBuilder`. **Tool: `scripts/gen_page_answers.sql -v ACT_UID=<phc>`**
  derives the condition's form and emits the answer complement. Done for all 8 current subjects.
- **Condition datamarts** (covid_case, std_hiv, tb, hepatitis, …) fire iff ALL of:
  1. condition is mapped in `RDB_MODERN.dbo.nrt_datamart_metadata` (161 rows; check `condition_cd`),
  2. **`nrt_investigation.patient_id` is non-NULL** — else `ProcessDatamartData.java:113-115`
     SILENTLY drops the datamart. Patient link = a `SubjOfPHC` participation
     (act=PHC, subject=patient 20000000, PSN/CASE). Done for all 8 subjects via
     `zz_investigation_patient_links.sql`.
  3. the datamart SP's own internal gates are satisfied (see per-datamart notes below).
- **Legacy-form conditions don't route to dims**: TB 10220→INV_FORM_RVCT, Var 10030→INV_FORM_VAR,
  BMIRD 11717→INV_FORM_BMDSP all have ZERO page-builder rdb metadata → `D_INV_*` unreachable for
  them. Their CONDITION datamarts can still fire via the patient path.

## Per-datamart leads (biggest yield first — refine from live survey each tick)
Gaps as of 42.1% baseline (col gap = total − populated):
- **TB family 660 cols**: `tb_datamart` 0/318 + `tb_hiv_datamart` 0/322 are built FROM `F_TB_PAM`
  (`sp_tb_datamart_postprocessing` routine 255 selects `FROM dbo.F_TB_PAM`). `F_TB_PAM` is EMPTY
  (`D_TB_PAM` dim = 155/166 populates, fact does not). **First TB task: make `sp_f_tb_pam_postprocessing`
  populate** (routine: gates on `investigation_form_cd='INV_FORM_RVCT'` — our TB PHC 22001000
  matches — but the fact needs prerequisite measures/keys: treatment, dispositions, specific obs).
- **COVID labs 315 cols**: `covid_lab_datamart` 0/120 + `covid_lab_celr_datamart` 0/101 +
  `covid_contact_datamart` 0/94. Need lab/observation ODSE chains (Observation + Obs_value_* +
  participation linking the lab to the COVID patient/investigation 22003000). REAL fidelity.
- **Hepatitis 357 cols**: `hep100` 0/187 + `hepatitis_datamart` 39/209. Hep observation chains.
- **std_hiv_datamart** 55/248 (193): partial — fill remaining columns (more STD page answers /
  STD-specific obs). REAL fidelity.
- **covid_case_datamart** 209/383 (174): partial — more COVID discrete-data answers / obs.
- **d_investigation_repeat** 81/245 (164): repeating-block answers (`answer_group_seq_nbr`).
- **bmird_strep_pneumo_datamart** 46/140 (94): BMIRD obs chain.
- OUT OF BOUNDS / skip: `var_datamart` 0/231 (SEED-gated, fixtures-only), `aggregate_report_datamart`
  0/42 (RTR bug #11 phantom cols — bug-blocked), `f_var_pam` (var family).

## Stop conditions (check at top of every firing)
1. `utilities/comparison-fixtures/STOP_LOOP` exists → write end note to journal, STOP (omit ScheduleWakeup).
2. **90% reached** → write success note, STOP.
3. Iteration cap: 30 firings (running count in journal).
4. Plateau: **3 consecutive ticks** with zero net new populated columns AND no agents in flight
   → write a pivot note (recommend P1-saturation or P3) and STOP.
5. Pipeline broken: `merge_and_verify` fails twice in a row → write `BLOCKED.md`, STOP.

## Per-iteration protocol (each firing)
1. **Read this file.** Check stop conditions.
2. **Reconcile finished authoring agents** (TaskList + notifications): confirm each fixture is in
   `fixtures/30_sp_coverage/` and is ODSE-only (no `nrt_*` INSERT, no `EXEC sp_`).
3. **Validate the batch (BARRIER — only when NO authoring agent is in flight)**:
   `acquire_db_lock` (source `scripts/db_lock.sh`) → `bash scripts/merge_and_verify.sh` →
   `bash scripts/coverage_summary.sh` → `release_db_lock`. (The merge does `down -v`; agents must
   never read the DB during it — that's why this is a barrier.)
   - Headline cols UP and nothing regressed → `git add` new fixtures + refreshed
     `coverage/coverage_merged.md` → commit with before→after numbers.
   - A fixture caused an apply error or a regression → move it to
     `fixtures/30_sp_coverage/_quarantine/<name>.sql.<reason>`, re-validate, then commit the rest.
   - Mark reconciled agents' tasks completed.
4. **Survey gaps** from `coverage/coverage_merged.md` (total−populated desc). Skip in-flight
   targets, OUT-OF-BOUNDS (var/aggregate), and MasterETL-only tables (`catalog/odse_unknown_tables.md`).
5. **Top up to ~3 authoring agents** (parallel; they write FILES, never touch the live DB). Each
   agent's contract:
   "Author ONE ODSE-only Tier-3 fixture at `fixtures/30_sp_coverage/<name>.sql` targeting
   <datamart gap>. Branch is no-shortcut: author ONLY NBS_ODSE rows (entities + participations +
   observations/answers as needed) in your reserved UID block — NO `nrt_*` INSERTs, NO
   `EXEC sp_*`, NO liquibase/seed/SRTE edits. Read the target datamart's SP
   (`liquibase-service/.../routines/`) to learn exactly what ODSE data it requires, and an
   existing full-chain fixture as a template. Omit GENERATED ALWAYS period cols. Be additive —
   never UPDATE shared dims. Report: the ODSE entities authored, which condition/SP should pick
   them up, and any RTR gap (write to `bugs/`, do NOT edit liquibase). Do NOT apply to the DB —
   the orchestrator validates under the lock via a full merge."
   Reserve each agent's UID block in `catalog/uid_ranges.md` AND below in the SAME turn.
6. **Append one line** to the journal. **ScheduleWakeup ~1200s**, prompt = the `/loop …` input verbatim.

## Hard rules (DO NOT VIOLATE)
- NO `nrt_*` INSERTs. NO manual `EXEC sp_*`. NO liquibase-routine edits (surface RTR bugs to
  `bugs/NN_<name>/findings.md`). NO seed/SRTE edits (fixtures-only).
- DO NOT message the user mid-loop. Blocked → write `BLOCKED.md` + STOP. NO `AskUserQuestion`.
- USE the DB lock for the merge; agents NEVER touch the live DB (read or write) — the merge's
  `down -v` would corrupt their reads. Merge is a barrier: no agents in flight.
- Fixtures ADDITIVE only (new UID-block entities). Omit GENERATED ALWAYS period cols. Never UPDATE
  shared dims (D_PATIENT, F_*_PAM, shared USER_PROFILE) — regressed var 2→0 in r3.
- One bad fixture → quarantine + continue. DO NOT mass-revert. Two agents never target the same datamart.

## Available UID blocks (Round 4) — reserve here + in catalog/uid_ranges.md in the same turn
| Block | Status |
| --- | --- |
| 22040000 - 22040999 | free |
| 22041000 - 22041999 | free |
| 22042000 - 22042999 | free |
| 22043000 - 22043999 | free |
| 22044000 - 22044999 | free |
| 22045000+ | add a new row to catalog/uid_ranges.md when allocated |

## Iterations journal
(append one line per firing: tick #, agents spawned/reconciled, coverage before→after)
- baseline: 42.1% (1938/4598), commit 138dfdc2; all 8 investigation subjects have page answers
  (`zz_page_answers_datamart_routing.sql`) + patient links (`zz_investigation_patient_links.sql`).
  Condition datamarts firing: COVID_CASE, STD_HIV, D_TB_PAM, HEPATITIS. Stack healthy post-merge.

## LESSONS (carry forward; r3 lessons that still apply marked ✓)
1. ✓ `merge_and_verify` does NOT refresh `coverage_merged.md` — ALWAYS run `coverage_summary.sh`
   after; trust only a fresh measurement.
2. ✓ Fixtures MUST be additive (new UID-block entities); never UPDATE shared dims.
3. ✓ Omit GENERATED ALWAYS period cols from inserts (Msg 13536).
4. ✓ Validate on a CLEAN merge before committing; incremental applies leave dirty rows + miss
   pipeline ordering.
5. NEW: condition datamarts need `nrt_investigation.patient_id` (SubjOfPHC link) or they are
   silently skipped — verify the link exists for any new investigation subject.
6. NEW: page answers must be on the CONDITION's form (use `gen_page_answers.sql`, which derives
   it) — answers on any other form resolve `rdb_table_nm=NULL` and route nothing.
7. NEW: many condition-datamart SPs build FROM a fact/dim (e.g. `tb_datamart` ← `F_TB_PAM`). Check
   the SP's `FROM`/joins to find the real prerequisite before authoring blind.
- tick 1 (partial reconcile): spawned 3 authoring agents (TB fact, COVID labs, hepatitis).
  - COVID labs (covid_lab 0/120, celr 0/101): **OUT OF BOUNDS** — SEED-gated. sp_covid_lab_datamart
    filters result LOINC ∈ nrt_srte_Loinc_condition WHERE condition_cd='11065', and the baseline
    SRTE ships 0 such rows (production has them). Filed bugs/16_covid_lab_loinc_condition_seed_gap.
    No-op fixture removed. Do NOT re-spawn (alongside var/aggregate).
  - TB fact (tb_datamart 0/318 + tb_hiv 0/322 + f_tb_pam): fixture zz_tb_fact_chain.sql READY.
    Root cause: F_TB_PAM key = nrt_investigation.nac_page_case_uid, set by sp_investigation_event
    from nbs_act_entity rows — TB PHC 22001000 had none. Adds 3 nbs_act_entity (UIDs 22040000-02,
    real org/provider keys) + last_chg bump. ODSE-only, no seed. Awaiting hepatitis agent before
    the barrier merge.
  - NEW LEAD: nbs_act_entity → nac_page_case_uid may gate facts for OTHER investigations too —
    check after TB validates.
- tick 1 RECONCILED & COMMITTED (daec7f89): 42.1% -> **52.4%** (empty 27->23), no regression.
  TB family unlocked (zz_tb_fact_chain: nbs_act_entity -> nac_page_case_uid -> F_TB_PAM ->
  tb_datamart + tb_hiv_datamart). Hepatitis chain committed but hep100/HEPATITIS_CASE still 0
  (obs InvFrmQ graph not landing in HEPATITIS_CASE — FOLLOW-UP). COVID labs OUT OF BOUNDS (bug #16).
  ⚠️ Merge drain (420s) timed out under the hep obs flood and mis-reported 20%; true 52.4% only
  after the service drained to idle. FIXED: Tier-3 drain bumped to 900s.

## LESSON 8 (CRITICAL): trust coverage only after the service is IDLE
A heavy fixture (many observations) can outlast the Tier-3 drain timeout in merge_and_verify, so
`print_coverage_summary` runs against a half-processed pipeline and reports a FALSE LOW number
(saw 20% vs true 52.4%). ALWAYS, before reconciling/committing/declaring a regression: confirm
`docker logs --tail 8 <service>` shows ≥3 recent "No ids to process from the topics", then
re-run `bash scripts/coverage_summary.sh` and trust THAT. A coverage DROP right after a big
observation fixture is drain-timeout until proven otherwise — re-measure before quarantining.
- tick 2 UID allocations: R4-D hepatitis-fix 22043xxx, R4-E std_hiv 22044xxx, R4-F covid_case 22045xxx.
- tick 2 (wave-2 reconcile, barrier merge running): 3 agents done.
  - R4-D hepatitis: ROOT CAUSE = old chain used cond 10110 (Hep A) which fails routine 039's
    INV_FORM_HEP% gate AND nrt_datamart_metadata maps 10110 only to Hepatitis_Datamart (not
    Hepatitis_Case). FIX: new investigation under cond 10481 (->INV_FORM_HEPGEN, maps to
    Hepatitis_Case) = zz_hepatitis_case_chain.sql (PHC 22043000); old chain quarantined; 22043000
    added to PHC_UIDS. NOT seed-gated.
  - R4-E std_hiv: zz_std_hiv_fill.sql, 112 answers (UIDs 22044xxx) — expects ~113 of 193 cols.
  - R4-F covid_case: zz_covid_case_fill.sql, 105 repeating-group answers (UIDs 22045xxx) for
    _1/_2/_3 columns — expects covid_case 209->~314.
  - Validation merge in flight (sentinel /tmp/loop_tick2_merge.done); reconcile/commit next tick.

## LESSON 9 (HIGH-VALUE LEAD): single D_INV_* dims need answer_group_seq_nbr IS NULL
sp_s_pagebuilder_postprocessing (routine 007) builds the single (non-repeating) D_INV_* dim rows
ONLY from nbs_case_answer with ANSWER_GROUP_SEQ_NBR **IS NULL** (text line ~103, coded ~191/193).
But gen_page_answers.sql emits answer_group_seq_nbr=**0**, so generic answers route to
D_INVESTIGATION_REPEAT, NOT the single dims. The D_INV_* dims that DID populate came from the
curated full_chain answers (which carry NULL group-seq). => ENHANCING gen_page_answers.sql to also
emit a NULL-group variant would populate the single D_INV_* dims for ALL routable investigations
(STD/COVID/Pertussis/HepA) — a broad multi-table gain. CAUTION: repeating-block datamart columns
(e.g. covid_case_datamart _1/_2/_3) DO need group_seq 1/2/3 — so it's NULL for single dims,
1/2/3 for repeating blocks, NOT "always NULL". Candidate for the next authoring wave.
- tick 2 COMMITTED (261a6bcb): 52.4% -> 61.6% (HEPATITIS_CASE+hep100 0->1, std_hiv 55->178,
  covid_case 209->318). No regression.
- CEILING FINDING: out-of-bounds cols = var_datamart 231 + covid_lab/celr/contact 315 +
  aggregate_report 42 = ~588 (~12.8%). So fixtures-only ceiling ~= 87.2%, NOT 90%. Push to ~87%;
  the last ~3 pts need the seed edits (var SRTE PORT_REQ_IND_CD, covid LOINC->11065, agg bug #11).
- tick 3: spawned R4-G hepatitis_datamart fill (22046xxx), R4-H d_investigation_repeat fill
  (22047xxx), R4-I bmird_strep_pneumo fill (22048xxx).
- tick 3 COMMITTED (6f893f55): 61.6% -> 65.2% (hepatitis_datamart 1->2 rows, d_inv_repeat 55->85,
  bmird filled). Gains tapering (10.3/9.2/3.6) but net-positive, no regression.
- tick 4: spawned R4-J d_inv_repeat-more-forms (22049xxx), R4-K tb dimensional tail (22050xxx),
  R4-L covid_contact (22051xxx). Reachable ceiling ~87% (var/covid_lab*/aggregate out of bounds).
- tick 4 COMMITTED (542ea424): 65.2% -> 67.2% (d_inv_repeat 85->229 rows, covid_contact 0->1).
  tb_datamart stayed 1 row (R4-K 2nd TB investigation 22050000 did NOT land a datamart row - DEBUG).
  Gains tapering: 10.3/9.2/3.6/2.0. Reachable remaining ~1022 cols (~22pts) -> ceiling ~89%.
- tick 5: spawned R4-M tb-tail-debug (22052xxx), R4-N lab100+lab101 (22053xxx), R4-O
  hepatitis_datamart remainder (22054xxx).
