# Tier 1 — Interview

You are a Tier 1 sub-agent. Your subject is **Interview**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

Interview is moderately-sized — D_INTERVIEW (24 cols) + D_INTERVIEW_NOTE
(7 cols) + F_INTERVIEW_CASE (10 cols). No FK constraints; all
F_INTERVIEW_CASE cross-subject KEY columns are NULLABLE. Should run
cleanly in isolation.

## Subject identity

- **Subject name:** interview
- **Foundation row:** `@dbo_Act_interview_uid = 20000140`
  (`act.act_uid`, `interview.interview_uid`); class `ENC`,
  mood `EVN`. Foundation has many interview columns NULL (Tier 1
  deferred — see `coverage_foundation.md`'s "interview" entry).
- **Foundation Patient/Provider:** referenced soft-ly via
  `interview.subject_person_uid` etc.
- **No internal locators.** Interview is an Act, not an Entity.
- **Your UID block:** `20090000–20099999` per `catalog/uid_ranges.md`.

## SP chain

- Event SP: `dbo.sp_interview_event @ix_uids nvarchar(max), @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/065-sp_interview_event-001.sql`
  - **Param `@ix_uids`** (short for "interview UIDs").
- Postprocessing SPs (2 — different param names!):
  1. `dbo.sp_d_interview_postprocessing @interview_uids, @debug = 0`
     - File: `routines/023-sp_d_interview_postprocessing-001.sql`
     - **Param `@interview_uids`** (different from event SP's `@ix_uids`).
     - Writes `D_INTERVIEW` (24 cols) and `D_INTERVIEW_NOTE` (7 cols).
  2. `dbo.sp_f_interview_case_postprocessing @ix_uids, @debug = 0`
     - File: `routines/024-sp_f_interview_case_postprocessing-001.sql`
     - **Param `@ix_uids`** (matches event SP).
     - Writes `F_INTERVIEW_CASE` (10 cols).

Yes, the two postprocessing SPs use **different param names**. Don't
guess — match the literals.

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.D_INTERVIEW` — primary write target. **Live: 24 / catalog: 21.**
- `dbo.D_INTERVIEW_NOTE` — note dimension. **Live: 7 / catalog: 8.**
- `dbo.F_INTERVIEW_CASE` — fact table. **Live: 10 / catalog: 11.**
  All cross-subject KEY columns are NULLABLE — no INSERT failures
  expected. Most are COALESCEd-to-1 in the SP except `INVESTIGATION_KEY`
  (line 94) which can be NULL.
- `dbo.nrt_interview` — synthetic staging. 25 cols.
- `dbo.nrt_interview_answer` — answer staging. 6 cols.
- `dbo.nrt_interview_note` — note staging. 10 cols.
- `dbo.nrt_interview_key`, `dbo.nrt_interview_note_key` — surrogate-key
  stores; **do not hand-write**.

## CASE-branch opportunity: IX_INTERVIEWEE_ROLE_CD

The F_INTERVIEW_CASE SP at lines 93–110 has CASE branches on
`IX_INTERVIEWEE_ROLE_CD` resolving to `INTERP / PHYS / NURSE / PROXY /
SUBJECT`. Each branch routes the interviewee_uid to a different KEY
column (INTERPRETER_KEY / PHYSICIAN_KEY / NURSE_KEY / PROXY_KEY /
IX_INTERVIEWEE_KEY).

Variant strategy:
- **Foundation Interview**: SUBJECT branch (interviewee_role_cd=NULL or
  'SUBJECT', leaves the key columns at sentinel 1).
- **v2 Interview**: pick a different role to exercise a separate CASE
  branch (e.g., 'PHYS' to populate PHYSICIAN_KEY).
- **v3 Interview** (optional): another role if the variant pattern
  warrants — most subjects went 2 or 3 variants based on need.

Verify the role codes are real in baseline SRTE:
```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_SRTE \
  -Q "SET NOCOUNT ON; SELECT TOP 10 code, code_short_desc_txt
      FROM dbo.code_value_general
      WHERE code_set_nm IN ('IX_ROLE','INTERVIEWEE_ROLE') OR code IN ('SUBJECT','PHYS','NURSE','INTERP','PROXY')
      ORDER BY code"
```

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Interview enrichment**: hang additive child rows off
  `@dbo_Act_interview_uid = 20000140`. Likely needs:
  - The base `interview` row (foundation has it)
  - The matching `nrt_interview` staging row (driver of the chain)
  - Optionally `nrt_interview_note` rows for D_INTERVIEW_NOTE coverage
  - Leave most interview-detail columns NULL on foundation
- **v2 Interview**: a separate fully-attributed Interview in your
  block (e.g., UID 20090010). Set every interview column the
  postprocessing SPs read. Pick a different `interviewee_role_cd` than
  foundation to exercise a CASE branch.

## Forbidden (inherited from template, repeated for clarity)

- **No cross-subject `act_relationship`, `participation`, or
  `nbs_act_entity` rows.**
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row.**
- **No INSERTs into other subjects' RDB_MODERN output tables.**
- Do not write surrogate-key stores.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/interview.sql

# event SP — @ix_uids
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_interview_event @ix_uids = N'20000140,20090010', @debug = 0"

# postprocessing SP for D_INTERVIEW + D_INTERVIEW_NOTE — @interview_uids (NOT @ix_uids)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_d_interview_postprocessing @interview_uids = N'20000140,20090010', @debug = 0"

# postprocessing SP for F_INTERVIEW_CASE — @ix_uids
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_f_interview_case_postprocessing @ix_uids = N'20000140,20090010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.D_INTERVIEW WHERE INTERVIEW_UID IN (20000140, 20090010)" -y 0 -Y 0
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.D_INTERVIEW_NOTE" -y 0 -Y 0
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.F_INTERVIEW_CASE" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/<live_count>` for D_INTERVIEW (24), D_INTERVIEW_NOTE (7),
and F_INTERVIEW_CASE (10).
