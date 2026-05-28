# Live demo cheat-sheet — APP-471 (~5 min)

Audience: DevOps + NBS/NBS7/RTR-fluent stakeholder at CDC. No slides;
live terminal walkthrough. Talking points draw from `METHODOLOGY.md`.

## Pre-demo prep (do BEFORE the meeting)

1. Run `merge_and_verify.sh` ~10 min before; have the freshly-regenerated
   `coverage_merged.md` ready. (~5 min wall-clock.)
2. Open three terminal panes or tabs:
   - **A**: file viewer — keep `METHODOLOGY.md` open for reference.
   - **B**: the main demo terminal (CWD: `utilities/comparison-fixtures/`).
   - **C**: an editor (cursor/vscode) with `fixtures/30_sp_coverage/tb_investigation_full_chain.sql` open, scrolled to ~line 280 (the act/PHC INSERTs).
3. Have `bugs/README.md` open in pane A or as a tab.
4. Verify `coverage/coverage_merged.md` shows fresh numbers (top of
   file → "Summary" → fully-covered count). Note them down so you're
   not squinting during the demo.

## The flow

### 1. Frame the problem (~45s) — talk only, no terminal

> "We need to diff RDB (MasterETL) against RDB_MODERN (RTR) to validate
> the migration. That requires an ODSE state that exercises every column
> RTR can write. Production data hits a narrow happy path — most CASE
> branches stay unvisited. So we author synthetic ODSE inserts. But the
> hard problem isn't 'make plausible-looking ODSE rows' — it's 'make
> rows that, after a multi-hop transformation chain we didn't write,
> populate a specific RDB_MODERN column.'"

> "We worked the chain in reverse — start at the RDB_MODERN write
> targets, walk back through the SP code, discover what ODSE inputs
> cause each target column to populate."

### 2. Show the scope catalogs (~45s) — pane B

```bash
# Phase 0: static-extract every (table, column) RTR writes
wc -l catalog/rtr_target_columns.md
head -40 catalog/rtr_target_columns.md
```

Point at: "118 tables, ~4600 columns. Every coverage report measures
against this."

```bash
# Phase B: legal edge codes, grounded in baseline SRTE
head -30 catalog/edge_types.md
```

Point at: "Agents pick edges from this catalog. No invented codes."

### 3. Show a real fixture (~90s) — pane C

Open `fixtures/30_sp_coverage/tb_investigation_full_chain.sql` in pane C.

Talking points while scrolling:

- **Top of file**: docstring explaining what's being authored (full
  ODSE chain + nrt staging + NBS_case_answer for RVCT-form TUB*
  questions).
- **Line ~95-170**: the ODSE side — `act`, `public_health_case`,
  `act_id`, `case_management`. Note `condition_cd='10220'` (TB acute,
  SRTE-verified).
- **Line ~183-260**: `NBS_case_answer` rows — one per RVCT TUB* question
  we want a downstream d_topic SP to read. Note `SET IDENTITY_INSERT ON`.
- **Line ~280-450**: `nrt_investigation` row — note `patient_id =
  20000000` (load-bearing — the foundation Patient; without this the
  hep-datamart cascade drops the row).
- **Bottom**: tail-EXEC of the 14 d_topic SPs. We do NOT tail-EXEC
  `sp_tb_datamart` or `sp_f_tb_pam` here — those are owned by Step 9
  of the orchestrator. (Discovered the hard way today.)

Brief tangent if asked: "Why hand-author `nrt_*` rows instead of
running CDC?" → "Production CDC is Debezium → Kafka → kafka-connect.
Standing that up locally adds 4 services and 60-90s per cycle. We
bypass it — the diff target is the postprocessing SP's transformation
logic, not CDC payload fidelity. Iteration drops from minutes to
seconds."

### 4. Show the orchestrator + results (~90s) — pane B

```bash
# What the orchestrator does, end to end
sed -n '1,60p' scripts/merge_and_verify.sh
```

Point at the comment block describing the 9-step Merge contract. Then:

```bash
# Headline coverage numbers
head -12 coverage/coverage_merged.md
```

Read out the numbers (latest verified from-scratch run, 2026-05-27):
- In-scope target tables: 118
- Fully covered: **76**
- Partially covered: **36**
- Empty: **5** (`aggregate_report_datamart`, `ldf_bmird`, `ldf_hepatitis`, `lookup_table_n_rept`, `sr100` — each tied to a specific open bug or the quarantined hep fixture)
- Missing from live schema: **1** (`job_batch_rebuild_log` — not in baseline 6.0.18.1)
- Overall column coverage: **89.9%** (4,165 / 4,633 columns)

Quick wins to point at:

```bash
grep -E "morbidity_report_datamart|covid_vaccination_datamart|inv_summ_datamart|covid_case_datamart|d_investigation_repeat|tb_datamart|bmird_strep|hepatitis_datamart" coverage/coverage_merged.md
```

Talking points:
- `morbidity_report_datamart`: **133/133** (full)
- `covid_vaccination_datamart`: **60/60** (full)
- `inv_summ_datamart`: **58/58** (full)
- `f_std_page_case`: **52/52**, `f_tb_pam`: **20/20** — both full
- `d_disease_site`, `d_addl_risk`: **6/6** each (full)
- `covid_case_datamart`: **379/383** (~99%)
- `d_investigation_repeat`: **250/253** — the 3 remaining NULL cols are gated by bug #13 (TEXT-pivot NULL propagation)
- `tb_datamart`: **277/318**, `tb_hiv_datamart`: **281/322**
- `std_hiv_datamart`: **231/248**, `var_datamart`: **210/231**
- `bmird_strep_pneumo_datamart`: **126/140** — the 14 remaining are gated by bug #12 (ROW_NUMBER PARTITION collapse)
- `hep100`: **185/187**; `hepatitis_datamart`: **144/209** — the rest is in the quarantined `zz_hepatitis_datamart_round2.sql` fixture
- `aggregate_report_datamart` (0/42) and `sr100` (0/20) — blocked by bugs #11 and #15 respectively, not by missing fixture data

### 5. Bugs as a byproduct (~45s) — pane B then A

```bash
ls bugs/
```

Visually: 14 bug investigation directories (numbered #1–#13 and #15;
#14 was assigned in the STRATEGY progress log to a `d_contact_record`
STRING_AGG truncation issue but never promoted to its own dir).

```bash
cat bugs/README.md | head -30
```

> "We found 14 RTR bug investigations under `bugs/`. 3 fixes merged
> upstream (PRs #769, #826, #827), 6 fixed on this branch as
> standalone squashed commits (#3, #5, #7, #8, #9, #10), 5 still open
> and documented with repros (#1 resolved as a non-issue; #11, #12,
> #13, #15 awaiting RTR fixes). They range from one-line logging
> defects (bug 5a: `IF @debug` resetting `@@ROWCOUNT`) to architectural
> (bug 9: dynamic UNPIVOT assumes uniform column types — fixed; bug 13:
> dynamic TEXT-pivot column-list NULL-propagates without raising an
> error — still open; bug 15: `sp_event_metric_datamart_postprocessing`
> leaves ADD_USER_NAME NULL and the downstream SR100 SP swallows the
> NOT NULL violation — still open)."

### 6. What's next (~30s) — talk only

- Restore the quarantined `zz_hepatitis_datamart_round2.sql` fixture
  — recovers ~+61 hep cols (would push the headline past 90%). Blocked
  on a `sp_hepatitis_datamart_postprocessing` tempdb blowup (~70GB on a
  cold dataset); needs an SP fix or a tempdb cap.
- Fix the four open RTR bugs: **#11** (aggregate_report schema
  mismatch), **#12** (BMIRD ROW_NUMBER PARTITION), **#13** (TEXT-pivot
  NULL propagation — ~50 cols on D_INVESTIGATION_REPEAT for free),
  **#15** (event_metric/SR100 ADD_USER_NAME NULL).
- MasterETL-side column catalog (Phase 0 mirror) → tells us which
  empty tables are RTR coverage gaps vs MasterETL-only.
- The actual comparison tool itself (RDB vs RDB_MODERN diff, modeled
  on NEDSS-DataCompare). This is where today's coverage state goes.
- Remaining condition families (Pertussis, Measles, Rubella) —
  lower yield now that the baseline is at ~90%.

## Commands cheat-sheet (in order)

```bash
cd <repo-root>/NEDSS-DataReporting/utilities/comparison-fixtures

# (1) Scope
wc -l catalog/rtr_target_columns.md
head -40 catalog/rtr_target_columns.md
head -30 catalog/edge_types.md

# (2) Fixture — open in editor pane (or use bat for syntax highlight)
$EDITOR fixtures/30_sp_coverage/tb_investigation_full_chain.sql

# (3) Orchestrator + results
sed -n '1,60p' scripts/merge_and_verify.sh
head -12 coverage/coverage_merged.md
grep -E "tb_datamart|d_tb_pam|d_disease_site|d_addl_risk" coverage/coverage_merged.md

# (4) Bugs
ls bugs/
head -30 bugs/README.md
```

## If something breaks during the demo

- **Coverage report missing**: `ls coverage/coverage_merged.md` — if
  stale, run `./scripts/coverage_summary.sh` (~30 sec).
- **Orchestrator log questions**: `tail -30 /tmp/merge_verify_*.log`
  shows last run's output.
- **"Why is this column NULL?"**: open the relevant SP file in
  `liquibase-service/.../routines/` and find the column's source.
  The Phase 0 catalog (`catalog/rtr_target_columns.md`) tells you
  which SP writes which column.

## Anticipated questions + answers

- **"How long does the full pipeline take?"** ~5 min wall-clock from
  `docker compose down -v` to `coverage_merged.md` regenerated.
- **"What about the production CDC pipeline?"** Out of scope — we
  bypass it and hand-author `nrt_*` rows. CDC fidelity is verified
  elsewhere.
- **"Can this run in CI?"** Yes — no external dependencies beyond
  the baseline image. Just needs Docker.
- **"Where does the diff tool live?"** Doesn't exist yet — separate
  workstream, modeled on NEDSS-DataCompare. This project provides
  the ODSE state input.
- **"What if RTR maintainers change a routine?"** liquibase reapplies
  routines on container build (we rebuild the liquibase image on
  every reset). If they rename `nrt_*` columns, our fixtures break
  loudly at apply time — no abstraction layer hiding it.
