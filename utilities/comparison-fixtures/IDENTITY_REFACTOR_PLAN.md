# IDENTITY_INSERT refactor plan (Phase A.0 survey — Round 5, item A)

**Status:** SURVEY ONLY. No fixtures changed. Read-only DB queries only.
**Branch:** `aw/remove-nrt-shortcut`. **Author:** Phase A.0 agent.
**Goal of item A:** eliminate the LESSON-10 hazard — hardcoded `SET IDENTITY_INSERT` on
flood-prone IDENTITY tables, guarded by `IF NOT EXISTS(... <uid_col> = <literal>)`, that
**silently skips its INSERT** once auto-IDENTITY inserts drive `IDENT_CURRENT` past that literal.

---

## 1. IDENTITY-table confirmation (read-only DB)

Query (NBS_ODSE.sys.columns, `is_identity=1`) confirmed which of the candidate tables have an
IDENTITY surrogate PK:

| table | IDENTITY col | is_identity | rows (live) | IDENT_CURRENT (live) | flood-prone? |
| --- | --- | --- | --- | --- | --- |
| **nbs_case_answer** | nbs_case_answer_uid | **1** | 2592 | **22051168** | **YES — heavily** |
| **nbs_act_entity** | nbs_act_entity_uid | **1** | 28 | 22050502 | no (no auto-insert source) |
| **case_management** | case_management_uid | **1** | 16 | 22050001 | no (no auto-insert source) |
| observation | (none) | — | 211 | — | n/a — NOT identity |
| act | (none) | — | 244 | — | n/a — NOT identity |
| act_id | (none) | — | — | — | n/a — NOT identity |
| participation | (none) | — | — | — | n/a — NOT identity |
| act_relationship | (none) | — | — | — | n/a — NOT identity |

**Key finding:** of the LESSON-10 candidates, only **nbs_case_answer, nbs_act_entity,
case_management** are IDENTITY. `observation` and `act` are NOT IDENTITY (they take explicit UIDs
directly — no IDENTITY_INSERT needed or present in the suite), so the obs/act level of LESSON 10's
tick-5 regression actually manifested through... see note below.

**Flood mechanics (why only nbs_case_answer is flood-prone):**
- `nbs_case_answer` is the ONLY one of the three with an **auto-IDENTITY insert source** in the
  suite. Four fixtures INSERT it WITHOUT IDENTITY_INSERT (auto-assign), driving `IDENT_CURRENT` high:
  - `zz_page_answers_datamart_routing.sql` — **1376** rows (the main flood; LESSON 10's culprit)
  - `zz_hepatitis_datamart_fill2.sql` — 93 rows
  - `zz_hepatitis_datamart_fill.sql` — 85 rows
  - `zz_tb_datamart_fill.sql` — 1 row (already LESSON-10-converted to auto)
  Live `IDENT_CURRENT('nbs_case_answer') = 22051168`, and live distribution shows **1169 rows
  >= 22050000** and **973 flood rows in 22045000–22049999** — i.e. the auto flood now occupies the
  SAME numeric space as several hardcoded IDENTITY_INSERT blocks (std_hiv 22044000, d_inv_repeat_fill2
  up to 22049999). Those hardcoded blocks survived in the *current* merge only because they happened
  to apply before the flood crossed their literal; that is order-fragile and is exactly the latent bug.
- `nbs_act_entity` and `case_management` have **no auto-IDENTITY insert source** — every INSERT in
  the suite uses IDENTITY_INSERT with a hardcoded UID, so their counters advance only via those pins.
  Collision is therefore only possible if two pinned blocks reuse the same UID (none do) — they are
  **not flood-prone**. They are lower priority, but should still be de-hardcoded for robustness
  (Batch 4) since their UIDs sit just under `IDENT_CURRENT`.

**Schema FK check:** NBS_ODSE has **zero foreign keys** referencing the PK of nbs_case_answer,
nbs_act_entity, or case_management. So at the schema level the surrogate UID of all three is a pure
surrogate (never an FK target). "REFERENCED" below therefore means *referenced by the literal within
the fixture suite itself* (cross/intra-fixture), not a DB-level FK.

---

## 2. Inventory — every active `SET IDENTITY_INSERT ... ON` block

**42 active `ON` statements** (excluding `_quarantine/` and comments), across 22 files. Grouped by
target table:

| count | table |
| --- | --- |
| 18 | case_management |
| 18 | nbs_case_answer |
| 6 | nbs_act_entity |
| 1 | nrt_lab_test_result_group_key (RDB_MODERN — special, see below) |
| 1 | nrt_lab_test_key (RDB_MODERN — special, see below) |

### 2a. nbs_case_answer blocks (the flood-prone table — TOP PRIORITY)

| file | line(s) | UID range (pinned) | guard | LEAF / REF | notes / proposed fix |
| --- | --- | --- | --- | --- | --- |
| `zz_covid_case_fill.sql` | 90 | 22045000–22045104 | **none** (unconditional) | LEAF | drop IDENTITY_INSERT → auto; add `IF NOT EXISTS` on natural key `(act_uid=22003000, nbs_question_uid, answer_group_seq_nbr)`. Idempotency currently relies on `down -v` only. |
| `zz_std_hiv_fill.sql` | 120 | 22044000–22044360 | `IF NOT EXISTS(... uid = 22044000)` | LEAF | **classic LESSON-10 trap** (22044000 < IDENT_CURRENT). Drop IDENTITY_INSERT; re-guard on `(act_uid=22004000, nbs_question_uid)`. |
| `zz_d_inv_repeat_fill.sql` | 188, 363 | within 20000000–26671000 (per-PHC) | per-PHC `IF NOT EXISTS(public_health_case ...)` (NOT on answer uid) | LEAF | answers keyed (act_uid,nbs_question_uid,answer_group_seq_nbr 1/2/3). Drop IDENTITY_INSERT; existing PHC-level guard already protects idempotency. |
| `zz_d_inv_repeat_fill2.sql` | 181, 413, 621, 756 | within 20000000–22049999 (overlaps flood!) | per-PHC `IF NOT EXISTS(public_health_case ...)` | LEAF | 4 PHC blocks (STEC/Cyclo/Salm/Malaria). **Range overlaps the 973 flood rows in 22045–22049999.** Drop IDENTITY_INSERT; keep PHC-level guard. |
| `zz_var_datamart_enrich.sql` | 72, 197, 248 | 22009100–22009210 | `IF NOT EXISTS(... uid BETWEEN/= literal)` | LEAF | 3 blocks. Drop IDENTITY_INSERT; re-guard on `(act_uid, nbs_question_uid)` per block. NB also does post-INSERT UPDATEs keyed on uid — repoint those to the natural key too. |
| `zz_tb_datamart_enrich.sql` | 62, 252, 331 | 22011000–22011300 | `IF NOT EXISTS(... uid = literal)` (252/331 guard on `nrt_page_case_answer`, RDB_MODERN) | LEAF | line 62 = ODSE nbs_case_answer (convert). Lines 252/331 INSERT `[NBS_ODSE].[dbo].[nbs_case_answer]` but guard on `nrt_page_case_answer` (RDB) — convert ODSE insert to auto + guard on the ODSE natural key. |
| `zz_hepatitis_datamart_enrich.sql` | 223 | within 20000000–22008999 | block under `IF NOT EXISTS(act uid=22008500)` etc. | LEAF | 1 nbs_case_answer block. Drop IDENTITY_INSERT; re-guard on `(act_uid=22008500, nbs_question_uid)`. |
| `covid_investigation_full_chain.sql` | 225 | 22003100–22003121 | (chain-level; single block) | LEAF | curated COVID answers. Drop IDENTITY_INSERT → auto; guard `(act_uid=22003000, nbs_question_uid, answer_group_seq_nbr)`. |
| `tb_investigation_full_chain.sql` | 186 | 220010xx | (chain-level) | LEAF | same pattern, act_uid=22001000. |
| `varicella_investigation_full_chain.sql` | 191 | 220021xx | (chain-level) | LEAF | same pattern, act_uid=22002000. |

All 10 nbs_case_answer files are **LEAF** — the answer surrogate UID is never referenced as an FK or
as a literal in any other fixture (verified: no schema FK; the pipeline keys page answers on
`(act_uid, nbs_question_uid, seq_nbr/group)`). The R4 generation fixtures (R4-G/H/J:
`zz_hepatitis_datamart_fill*.sql`, `zz_d_inv_repeat_fill.sql` for newer PHCs) already omit the
surrogate and auto-assign — these are the conversion template.

### 2b. nbs_act_entity blocks

| file | line | UID range | guard | LEAF / REF | notes / proposed fix |
| --- | --- | --- | --- | --- | --- |
| `20_links/contact_links.sql` | 175 | 21010000–21010005 | **none** | LEAF | surrogate consumed by SP via (act_uid,type_cd). 21xxx is BELOW IDENT_CURRENT 22050502 so auto won't reclaim it (auto only ascends), but block is un-guarded → drop IDENTITY_INSERT, guard `(act_uid, entity_uid, type_cd)`. |
| `20_links/interview_links.sql` | 154 | 21008000–21008005 | none | LEAF | same. |
| `20_links/vaccination_links.sql` | 147 | 21007000–21007003 | none | LEAF | same. |
| `20_links/phc_roles_nae.sql` | 215 | 21009000–21009005 | none | LEAF | same. |
| `zz_tb_fact_chain.sql` | 105 | 22040000–22040002 | per-block | **REFERENCED (intra-file only)** | 22040000 referenced ONLY inside this same file's header/comment as its allocation; the row is consumed by the SP via (act_uid=22001000,type_cd). Effectively LEAF for FK purposes — convert to auto + natural-key guard `(act_uid, entity_uid, type_cd)`. |
| `zz_tb_datamart_fill.sql` | 265 | 22050500–22050502 | per-block | **REFERENCED (intra-file only)** | 22050500 referenced ONLY inside this same file (allocation note). Same as above — convert to auto + natural-key guard. |

nbs_act_entity: **all 6 are LEAF on the surrogate** (the two flagged REFERENCED only reference their
own UID within the same file's documentation, not as a cross-fixture FK). Because nbs_act_entity has
no auto-flood source, collision risk is low TODAY, but the 20_links blocks use a LOW range (21xxx)
that is below the current counter — converting them to auto + natural-key guard removes the un-guarded
PK-collision risk and the LESSON-10 silent-skip risk uniformly.

### 2c. case_management blocks

All 18 use a hardcoded `case_management_uid` and an IDENTITY_INSERT. case_management has **no
auto-flood source** so these are the lowest risk, but they sit just under `IDENT_CURRENT=22050001`.
The PK is never an FK target (schema-verified). Representative UIDs:

| file | line | cm UID | guard | LEAF / REF |
| --- | --- | --- | --- | --- |
| `10_subjects/investigation.sql` | 222 | 20050011 (`@dbo_Case_management_v2_uid`) | none | LEAF |
| `covid_investigation_full_chain.sql` | 185 | 22003001 | chain | LEAF |
| `bmird_investigation_full_chain.sql` | 177 | 22005001 | chain | LEAF |
| `pertussis_investigation_full_chain.sql` | 85 | 22007001 | chain | LEAF |
| `tb_investigation_full_chain.sql` | 154 | 22001001 | chain | LEAF |
| `varicella_investigation_full_chain.sql` | 157 | 22002001 | chain | LEAF |
| `std_hiv_investigation_full_chain.sql` | 169 | 22004001 | chain | LEAF |
| `d_investigation_repeat.sql` | 165 | (per-PHC) | chain | LEAF |
| `zz_hepatitis_datamart_enrich.sql` | 158 | 22008501 | `IF NOT EXISTS(... uid=22008501)` | LEAF |
| `zz_d_inv_repeat_fill.sql` | 172, 349 | per-PHC | per-PHC PHC guard | LEAF |
| `zz_d_inv_repeat_fill2.sql` | 166, 399, 607, 742 | per-PHC | per-PHC PHC guard | LEAF |
| `zz_tb_datamart_fill.sql` | 205 | 22050001 | per-block | LEAF |

All 18 case_management blocks are **LEAF** (cm UID never an FK target; consumed by event SP via
`public_health_case_uid` join, not by cm_uid literal). Convert to auto-IDENTITY; re-guard on the
natural key `public_health_case_uid` (1 cm row per PHC).

### 2d. Special case — RDB_MODERN lab key tables (NOT part of the hazard)

| file | line | table | classification |
| --- | --- | --- | --- |
| `10_subjects/lab.sql` | 458 | `nrt_lab_test_result_group_key` (RDB_MODERN) | **N/A — leave as-is** |
| `10_subjects/lab.sql` | 462 | `nrt_lab_test_key` (RDB_MODERN) | **N/A — leave as-is** |

These are an **empty `ON;` + `OFF;` + `DELETE` high-water idiom** (no hardcoded INSERT, no guard) used
to advance a Liquibase-seeded NULL IDENTITY counter past a PK-conflict seed row — a documented
baseline-data quirk in v6.0.18.1. They INSERT nothing and are not in NBS_ODSE. **Out of scope for
item A — do not touch.**

---

## 3. Summary counts

- **Total active IDENTITY_INSERT `ON` blocks:** 42 (across 22 files; excludes `_quarantine/`).
- **By table:** nbs_case_answer 18 · case_management 18 · nbs_act_entity 6 · lab key tables 2 (N/A).
- **LEAF:** 40 (all nbs_case_answer 18, all case_management 18, all nbs_act_entity 6 — the 2
  nbs_act_entity "REFERENCED" are intra-file-only and FK-safe, i.e. convertible like LEAF).
- **REFERENCED (true cross-fixture FK target):** 0 — schema has no FKs to these PKs, and no fixture
  uses another fixture's pinned surrogate as an FK. (The 2 intra-file references in zz_tb_*
  are self-documentation, not data links.)
- **Flood-prone table:** **nbs_case_answer ONLY** (IDENT_CURRENT 22051168; flooded by
  `zz_page_answers_datamart_routing.sql` 1376 + hep fill 178 rows). nbs_act_entity and
  case_management are not flooded (no auto-insert source).
- **N/A (not the hazard):** 2 (RDB_MODERN lab-key high-water idiom).

**Bottom line:** there are **no genuinely REFERENCED IDENTITY_INSERT blocks** requiring a
`SCOPE_IDENTITY()`/OUTPUT capture rewrite or a reserved-high-range relocation. Every block can be
converted to **auto-IDENTITY + a natural/business-key `IF NOT EXISTS` guard** (the R4-M fix pattern).
This makes the whole refactor coverage-NEUTRAL and low-risk.

---

## 4. Conversion recipe (apply per block)

**nbs_case_answer (LEAF):**
1. Delete `SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;` / `... OFF;`.
2. Remove `nbs_case_answer_uid` from the INSERT column list AND its value from every VALUES tuple.
3. Replace any guard `IF NOT EXISTS(... nbs_case_answer_uid = <literal>)` with a natural-key guard:
   `IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer
       WHERE act_uid = <phc> AND nbs_question_uid = <q> [AND answer_group_seq_nbr = <g>])`.
   For multi-row blocks, guard on the block's first (act_uid, nbs_question_uid[, group]) sentinel —
   matching the existing per-block sentinel convention.
4. If the block does post-INSERT `UPDATE ... WHERE nbs_case_answer_uid = <literal>` (only
   `zz_var_datamart_enrich.sql`), repoint those to `WHERE act_uid=... AND nbs_question_uid=...`.

**case_management (LEAF):** same pattern; drop the uid, guard on `public_health_case_uid` (1:1 PHC).

**nbs_act_entity (LEAF):** same pattern; drop the uid, guard on `(act_uid, entity_uid, type_cd)`.

**Template fixtures already doing this (copy their shape):** `zz_hepatitis_datamart_fill.sql`,
`zz_hepatitis_datamart_fill2.sql`, and the newer PHC blocks in `zz_d_inv_repeat_fill.sql`
(R4-G/H/J generation) — all omit the surrogate and auto-assign successfully.

---

## 5. Batched conversion plan (smallest-risk first; validate each with a barrier merge)

Each batch is **coverage-NEUTRAL**: it must HOLD >=67.7% with **no table regressing**. A drop means a
converted block now mis-links or silently skips → revert/fix that batch.

| batch | scope | files | risk | why ordered here |
| --- | --- | --- | --- | --- |
| **A.1** | nbs_case_answer — the flood-overlap files (HIGHEST hazard, biggest payoff) | `zz_std_hiv_fill.sql`, `zz_covid_case_fill.sql`, `zz_d_inv_repeat_fill.sql`, `zz_d_inv_repeat_fill2.sql` | low (LEAF, PHC/natural-key guard) | these pin UIDs that the live flood already overlaps (22044000, 22045xxx, 22049xxx) → the most order-fragile blocks; fixing them first removes the active LESSON-10 footgun. Coverage-neutral. |
| **A.2** | nbs_case_answer — enrich files | `zz_var_datamart_enrich.sql`, `zz_tb_datamart_enrich.sql`, `zz_hepatitis_datamart_enrich.sql` | low-med (var_enrich also has UID-keyed UPDATEs to repoint) | enrich blocks with explicit uid guards just under the flood; var_enrich needs the extra UPDATE repoint, so isolate it in this batch. |
| **A.3** | nbs_case_answer — full_chain curated answers | `covid_investigation_full_chain.sql`, `tb_investigation_full_chain.sql`, `varicella_investigation_full_chain.sql` | low (curated, well-known act_uids) | these define core subjects; convert after the zz_* fillers prove the pattern so a regression here is unambiguous. |
| **A.4** | nbs_act_entity + case_management (non-flood tables, robustness) | contact/interview/vaccination/phc_roles `*_links.sql`; `zz_tb_fact_chain.sql`, `zz_tb_datamart_fill.sql` (act_entity); all 18 case_management blocks across the full_chain + investigation.sql + d_inv_repeat + zz_tb_datamart_fill | low (not flood-prone today) | no auto-flood source → no active silent-skip, but de-hardcoding removes the un-guarded PK-collision risk on the low 21xxx act_entity range and future-proofs both tables. Can be split (A.4a act_entity, A.4b case_management) if a batch is large. |

**Coverage-neutral vs touches-referenced:** ALL batches are coverage-neutral; **none** touch a true
cross-fixture/FK-referenced UID (there are none). The only "referenced" UIDs (zz_tb 22040000 /
22050500) are intra-file self-documentation — update the header comment when converting, but no data
link breaks.

**Out of scope (do NOT convert):** the 2 RDB_MODERN lab-key idiom blocks in `10_subjects/lab.sql`
(section 2d); `_quarantine/*` files (re-evaluate only if/when un-quarantined for item B).

**A is DONE** when no hardcoded IDENTITY_INSERT remains on nbs_case_answer (and ideally nbs_act_entity
+ case_management) AND a clean merge holds >=67.7% with no regression.
