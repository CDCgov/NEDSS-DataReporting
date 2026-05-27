# LINEAGE.md — briefing & entrypoint for the data-lineage doc

> **STATUS (2026-05-27): BUILT.** The doc is assembled and complete —
> `lineage/LINEAGE_NARRATIVE.md` (L1–L6 + gap-fill G1–G4) and
> `lineage/LINEAGE_COLUMNS.tsv` (**3,735 rows covering all 118 in-scope
> tables**). The original L1–L6 fan-out left 53 tables un-enumerated; the
> G1–G4 gap-fill (core investigation/HIV/case-mgmt facts, TB/Var PAM
> facts+LDFs, the PAM dimension/group family, and operational/blocked tables)
> closed that. The per-cluster slices (8-col TSV) live in `lineage/sections/`
> and `lineage/columns/`; **`scripts/build_lineage_columns.py` regenerates the
> appendix** from them — concatenating in order L1–L6, G1–G4, adding a derived
> `mapping_kind` column (direct/pivot/code-translate/derived/no-source), and
> emitting both `lineage/LINEAGE_COLUMNS.tsv` (9-col canonical) and
> `lineage/LINEAGE_COLUMNS.jsonl` (for the schema-diff tool). **Do not re-run
> the fan-out below** — the instructions are retained as a record of method.
> To extend: edit/add a slice, then rerun the build script.

> **You are a fresh session picking this up.** This file is your complete
> briefing. It tells you *what* to build, *why it's possible*, *what raw
> material exists*, and *how to fan the work out across ~5-6 subagents*.
> Read this top to bottom, then orchestrate. You should not need to ask
> the user anything to start.

## What we're building

A **data-lineage / mapping document** for the RTR pipeline, in two parts:

1. **`lineage/LINEAGE_NARRATIVE.md`** — a human-readable, per-subject
   narrative: for each subject/datamart, the end-to-end chain
   *ODSE source columns → event SP / staging → `nrt_*` staging →
   postprocessing SP transform → RDB_MODERN target columns*, in prose +
   a small orienting table, citing the fixture and coverage report that
   *prove* each path. ~10-15 pages. For onboarding / handoff / design.

2. **`lineage/LINEAGE_COLUMNS.md`** (or `.tsv`) — a machine-readable
   column-level appendix: one row per populated RDB_MODERN column,
   tracing it back through staging to its ODSE source(s), with the SP +
   fixture that establishes the mapping and a VERIFIED/INFERRED flag.
   This is the artifact the future diff tool consumes.

The user wants **both** (narrative for humans, table for the diff tool).

## Why this is "emergent" and not just in the SQL

The SQL contains each *hop* but never the *end-to-end chain*:

- `sp_*_event` SPs read `nbs_odse.dbo.*` and project JSON → that's the
  **ODSE → staging** edge.
- `sp_nrt_*_postprocessing` / `sp_d_*` / `sp_*_datamart_*` SPs read
  `nrt_*` staging (never ODSE — see STRATEGY.md "postprocessing SPs read
  NRT staging only") and write RDB_MODERN → that's the
  **staging → RDB_MODERN** edge.

Nobody wrote down the full `ODSE col → … → RDB_MODERN col` chain. But
**this project reverse-engineered exactly that** while authoring ~38
fixtures: each fixture encodes "these specific ODSE inputs light up these
specific RDB_MODERN columns through this SP." The lineage doc is the
*synthesis* of that scattered knowledge into one map. It is emergent from
the work; it is not a fresh derivation. **Synthesize from the artifacts
below — do not re-derive from the SP source alone.**

## Source artifacts (your raw material)

All paths relative to `utilities/comparison-fixtures/`.

| Artifact | What it gives you |
| --- | --- |
| `catalog/rtr_target_columns.md` (5193 lines) | **Right edge, already done.** Every (table, column) RTR writes + which SP writes it + `Dynamic`/`Guarded` flags. This is the spine of the column appendix — start from it. |
| `STRATEGY.md` | The 4-step comparison pipeline, the tier model, and the load-bearing "postprocessing SPs read NRT staging only, event SPs read ODSE" convention. Read its "RTR transformation chain" + "Convention" sections first. |
| `fixtures/10_subjects/*.sql` (12) | Tier-1: each subject's ODSE inputs + the nrt_* staging row it hand-authors. **The left+middle edges.** Headers document intent. |
| `fixtures/20_links/*.sql` (12) | Tier-2: cross-subject edges (act_relationship / participation / nbs_act_entity) that flip sentinel keys to real FKs. |
| `fixtures/30_sp_coverage/*.sql` (38) | Tier-3: datamart enrichments. Each header documents which SP, which PHC/UID, and which target cols it lights up. **Densest lineage source.** |
| `coverage/coverage_<subject>.md` | Per-fixture: "Columns populated" + "Columns deliberately skipped (with reason)" + "Gaps". The proof that a path works. |
| `coverage/coverage_merged.md` | Current headline (89.6%) + per-table populated/total. Tells you which columns are actually populated (= in scope for the appendix). |
| `catalog/odse_unknown_tables.md` | 94-table classification: MasterETL-only / datamart-SP-driven / Tier-1-2-reachable. Use it to mark columns whose ODSE source is "MasterETL-only (no RTR ODSE path)". |
| `bugs/NN_*/findings.md` | Where a column is *reachable in principle* but blocked by an RTR bug — flag these specially in the appendix (`BLOCKED:#NN`). |
| `liquibase-service/.../005-rdb_modern/routines/*.sql` | Ground truth for the transform when a fixture/coverage report is ambiguous. ~130 SPs. |

## The lineage model (column appendix schema)

Each row of `LINEAGE_COLUMNS.md` traces one RDB_MODERN column:

```
| rdb_modern_table | rdb_modern_col | writing_sp | nrt_staging_source | odse_source_col(s) | transform_note | status | fixture_proof |
```

- **nrt_staging_source** — the `nrt_*` column (or `#tmp` derivation) the
  SP reads for this target. From the postprocessing SP body.
- **odse_source_col(s)** — the `nbs_odse.dbo.*` column(s) that feed that
  staging col, via the matching `sp_*_event` SP's JSON projection. This
  is the hop that requires synthesis (event SP ↔ postprocessing SP).
- **transform_note** — CASE/COALESCE/substring/pivot/code-lookup applied
  (one line; cite SP line if non-obvious).
- **status** — one of:
  - `VERIFIED` — a fixture populates it and a coverage report confirms it.
  - `INFERRED` — the SP clearly maps it but no fixture proves it (or it's
    in a partially-covered table and you couldn't confirm this specific
    col). **Never confabulate an ODSE source — mark INFERRED and say so.**
  - `DYNAMIC` — written via dynamic SQL (`<dynamic:@var>` in the catalog);
    source not statically derivable. Note the driving table if known
    (e.g. nbs_page_answer for dyn_dm_*).
  - `MASTERETL_ONLY` — per odse_unknown_tables.md, no RTR ODSE path.
  - `BLOCKED:#NN` — reachable but capped by bug NN.
- **fixture_proof** — the fixture file (+ coverage report) that
  establishes the mapping, or `—` for INFERRED/DYNAMIC.

The **discipline rule** (mirrors STRATEGY.md "Silent skips are
forbidden"): every column gets a row and an honest status. A confabulated
ODSE→target mapping is worse than an INFERRED flag.

## Subject-cluster agent split (~5-6 read-only subagents)

Spawn with `subagent_type: "general-purpose"`, `isolation: "worktree"`,
`run_in_background: true`. **All agents are READ-ONLY** — they read
fixtures/SPs/coverage and write only their own markdown section + their
appendix slice. They never touch the DB, so they run concurrently with
zero contention.

| Agent | Cluster | Primary SPs | Fixtures to mine | Coverage reports |
| --- | --- | --- | --- | --- |
| **L1 — Labs** | lab100, lab101, case_lab, covid_lab, covid_lab_celr | `sp_lab100_/sp_lab101_/sp_case_lab_/sp_covid_lab_/sp_covid_lab_celr_datamart_postprocessing`, `sp_d_lab_test_`, `sp_d_labtest_result_` | `lab.sql`, `lab_inv.sql`, `zz_lab100_enrich.sql`, `zz_covid_lab_datamart_unblock.sql`, `zz_covid_lab_celr_datamart_unblock.sql` | `coverage_lab*.md` |
| **L2 — Hepatitis** | hepatitis_datamart, hep100, hepatitis_case, ldf_hepatitis | `sp_hepatitis_/sp_hep100_/sp_hepatitis_case_/sp_ldf_hepatitis_datamart_postprocessing` | `zz_hepatitis_datamart_enrich.sql`, `zz_hepatitis_zz_hep100_unblock.sql`, `_quarantine/*round2*` | `coverage_hep_datamart_investigation.md` |
| **L3 — TB / STD-HIV / BMIRD / Var** | tb_datamart, tb_hiv_datamart, d_tb_pam, std_hiv_datamart, bmird_strep_pneumo, var_datamart | `sp_*_datamart_postprocessing` for each, `sp_f_tb_pam_`, `sp_f_var_pam_`, `sp_f_std_page_case_` | `tb_/std_hiv_/bmird_/varicella_investigation_full_chain.sql`, `zz_tb_/zz_std_hiv_/zz_bmird_/zz_var_datamart_enrich.sql` | `coverage_tb_/std_hiv_/bmird_/varicella_full_chain.md` |
| **L4 — COVID family** | covid_case_datamart, covid_contact_datamart, covid_vaccination_datamart, inv_summ | `sp_covid_case_/sp_covid_contact_/sp_covid_vaccination_/sp_inv_summary_datamart_postprocessing` | `covid_investigation_full_chain.sql`, `zz_covid_case_*.sql`, `zz_covid_contact*.sql`, `zz_covid_vaccination_datamart_enrich.sql`, `zz_inv_summ_datamart_unblock.sql` | `coverage_covid_full_chain.md` |
| **L5 — People, links, dims** | d_patient, d_provider, d_organization, d_place, d_interview, d_vaccination, d_contact_record, notification, treatment, morbidity, and all Tier-2 edges | event SPs + `sp_d_*_postprocessing`, `sp_nrt_*_postprocessing` | all `fixtures/10_subjects/*.sql`, all `fixtures/20_links/*.sql`, `zz_d_contact_record_enrich.sql`, `zz_morbidity_report_datamart_enrich.sql`, `zz_enrich_vaccination.sql` | `coverage_{patient,provider,organization,place,interview,contact,notification,treatment,morbidity}*.md`, all link reports |
| **L6 — Investigation-repeat, LDF, dyn_dm, page-builder** | d_investigation_repeat, d_inv_place_repeat, ldf_* cluster, dyn_dm_* family, summary_report_case, aggregate_report | `sp_sld_investigation_repeat_`, `sp_repeated_place_`, `sp_ldf_*`, `sp_dyn_dm_*`, `sp_f_page_case_`, `sp_inv_summary_`, `sp_aggregate_report_` | `d_investigation_repeat.sql`, `zz_d_investigation_repeat_*.sql`, `zz_d_inv_place_repeat_enrich.sql`, `ldf_answers_*.sql`, `zz_ldf_flagged_answers.sql`, `summary_report_case.sql`, `aggregate_report.sql`, `multi_condition_investigations.sql` | `coverage_d_investigation_repeat.md`, `coverage_ldf_*.md`, `coverage_tier_3.md` |

(5 vs 6 agents: L3 is the heaviest — split it into L3a TB+STD-HIV and L3b
BMIRD+Var if you want a 7th, or fold BMIRD+Var into L6's datamart work.
dyn_dm_* and most LDF columns will be largely `DYNAMIC` status — that's
expected, flag and move on rather than forcing an ODSE mapping.)

## Per-agent contract (put this in each agent's prompt)

```
You are Agent <Ln>, a READ-ONLY lineage-documentation agent. You are in a
git worktree. Do NOT touch the database. Do NOT modify fixtures or SPs.

Goal: for your assigned cluster (<tables>), produce two deliverables and
commit them:
  1. lineage/sections/<Ln>_<cluster>.md  — narrative section
  2. lineage/columns/<Ln>_<cluster>.tsv  — column-appendix slice (the
     pipe/tab schema from LINEAGE.md)

Method (synthesize, don't re-derive):
  1. Start from catalog/rtr_target_columns.md — pull every (table,col)
     for your tables. That's your row set for the appendix.
  2. For each target col, read the writing SP body to find the nrt_*
     staging col it reads and the transform applied.
  3. Find the matching sp_*_event SP to map staging col → ODSE col(s).
  4. Confirm against the fixture(s) + coverage report(s) listed for your
     cluster. If a fixture populates it and coverage confirms → VERIFIED
     + cite the fixture. Else INFERRED / DYNAMIC / MASTERETL_ONLY /
     BLOCKED:#NN per LINEAGE.md's status rules.
  5. Narrative: 1-3 paragraphs per table — the story of how rows flow,
     the key gating predicates, the notable transforms, and what's
     blocked/skipped (cross-reference coverage report "deliberately
     skipped" + bugs/).

Discipline: NEVER invent an ODSE source. Unsure → INFERRED. Commit WIP
after each table (worktree work can be lost — see STRATEGY.md agent-A
lesson). Final report (<200 words): tables covered, VERIFIED vs INFERRED
counts, anything that surprised you.
```

## Orchestration steps (you, the entrypoint session)

1. `mkdir -p utilities/comparison-fixtures/lineage/{sections,columns}`.
2. Spawn L1–L6 in parallel (one message, multiple Agent calls,
   `run_in_background: true`, worktree isolation).
3. As each completes: cherry-pick / copy its `sections/` + `columns/`
   files onto the branch. (They're additive and non-overlapping — no
   merge conflicts expected.)
4. **You own the spine** (don't delegate): write
   `lineage/LINEAGE_NARRATIVE.md` intro = the 4-step pipeline context,
   the SP-layer convention (event reads ODSE / postprocessing reads NRT),
   the dynamic/guarded caveats from rtr_target_columns.md's "Method", and
   a table of contents linking the per-cluster sections. Then concatenate
   the cluster sections under it.
5. Concatenate `columns/*.tsv` into `lineage/LINEAGE_COLUMNS.md` (or
   `.tsv`) with the header row. Sanity-check: row count ≈ the populated-col
   count in coverage_merged.md (~4150) plus INFERRED/blocked rows.
6. Commit. **No `Co-Authored-By: Claude` trailer** (user preference on
   this repo).

## Guardrails

- Lineage agents are **read-only**; the coverage work (lab101/sr100, in
  the other session) is the only DB-mutating track. They don't conflict.
- This is **not** a `/loop` task — it's a one-shot parallel fan-out.
  Don't wrap it in LOOP's interval cadence.
- If an agent reports it cannot map a cluster without DB access, that's a
  sign it's trying to re-derive instead of synthesizing from the
  fixtures — redirect it to the coverage reports, which already hold the
  verified populated-column lists.
- Expect `dyn_dm_*` and much of the LDF cluster to be `DYNAMIC` — those
  columns are written by dynamic SQL keyed on `nbs_page_answer` /
  page-builder metadata, not a static ODSE→col map. Document the driving
  mechanism, don't force a column map.

## Current state context (so the doc reflects reality)

- Live coverage **89.6%** (4150/4633 cols) as of 2026-05-25, clean
  from-scratch `merge_and_verify.sh` run on branch `aw/odse-test-seed`.
- `zz_hepatitis_datamart_round2.sql` is **quarantined** (tempdb blowup —
  see BLOCKED.md). Its ~+61 hepatitis_datamart cols are therefore
  currently *not* populated — mark them `BLOCKED` / `INFERRED` in L2's
  slice, not VERIFIED.
- Bugs #11–#14 cap specific columns (aggregate_report; BMIRD ROW_NUMBER;
  sld_investigation_repeat TEXT pivot; d_contact_record STRING_AGG).
  Flag affected columns `BLOCKED:#NN`.
```
