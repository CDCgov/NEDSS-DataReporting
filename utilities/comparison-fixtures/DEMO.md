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

Read out the numbers (as of 2026-05-21 overnight loop end):
- In-scope target tables: 118
- Fully covered: **66** (up from 48 at start of yesterday's session)
- Partially covered: **35** (up from 23)
- Empty: **16** (down from 46)
- Overall column coverage: **41.4%** (up from 21.8%, +909 columns / +90%)

Quick wins to point at — Phase-2 unblocks from today:

```bash
grep -E "f_tb_pam|d_disease_site|d_addl_risk|bmird_strep|std_hiv_datamart|inv_hiv|f_std_page_case" coverage/coverage_merged.md
```

Talking points:
- `f_tb_pam`: **20/20** (full) — TB PAM fact table, was 0
- `d_disease_site` + `d_addl_risk`: **6/6** each — TB-PAM cluster dims, were 0
- `f_std_page_case`: **52/52** (full) — STD/HIV fact, was 0 (orchestrator typo fix)
- `tb_datamart`: **61/318**, `tb_hiv_datamart`: **65/322** — Step 9 ordering fix
- `std_hiv_datamart`: **78/248** — Syphilis primary chain
- `bmird_strep_pneumo_datamart`: **69/140** — BMIRD chain
- `var_datamart`: **61/231** — Varicella chain
- `covid_case_datamart`: **53/383** — COVID chain
- `inv_hiv`: **17/19** — HIV columns
- `lookup_table_n_rept`, `l_investigation_repeat_inc`: **full** — Agent A unlocks

### 5. Bugs as a byproduct (~45s) — pane B then A

```bash
ls bugs/
```

Visually: 11 bug investigation directories.

```bash
cat bugs/README.md | head -30
```

> "We found 11 RTR bugs documented in bugs/, plus 2 more surfaced
> during Phase-2 work (BMIRD INSERT-without-dedup; CMG sentinel
> duplication). Five merged upstream; three squashed into this
> branch as standalone fixes; the rest documented with repros.
> They range from one-line logging defects (bug 5a: `IF @debug`
> resetting `@@ROWCOUNT`) to architectural (bug 9: dynamic UNPIVOT
> assumes uniform column types; bug 10: sp_sld_investigation_repeat
> surrogate-key allocation defaults to 1; bug 11: sp_aggregate_report
> references a column that doesn't exist in the target table)."

### 6. What's next (~30s) — talk only

- Bug #9 fix (dyn_dm UNPIVOT) — unblocks `DM_INV_*` family
- Multi-condition fan-out completion (Varicella, COVID, STD/HIV
  landed today; BMIRD and minor families remain)
- MasterETL-side column catalog (Phase 0 mirror) → tells us which
  empty tables are RTR coverage gaps vs MasterETL-only
- The actual comparison tool itself (RDB vs RDB_MODERN diff,
  modeled on NEDSS-DataCompare)

## Commands cheat-sheet (in order)

```bash
cd /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures

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
