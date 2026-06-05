# Bug #10 — sp_sld_investigation_repeat_postprocessing: broken D_REPT_KEY surrogate-key allocation

**Status**: Surfaced 2026-05-21 by Agent A. **FIXED 2026-05-22** on
`aw/odse-test-seed` (commit `99ef3517`).

## Symptom

After applying a fixture that authors a Pertussis Investigation
(public_health_case_uid=22006000) with 24 `nrt_page_case_answer` rows
(2 BLOCK_NMs × 3 answer_group_seq_nbr × 4 data types) and running

```sql
EXEC dbo.sp_sld_investigation_repeat_postprocessing
  @batch_id = 22006000, @phc_id_list = N'22006000';
```

the SP correctly pivots 24 answers into 6 staged dim rows in
`S_INVESTIGATION_REPEAT`. It writes 6 corresponding rows to
`D_INVESTIGATION_REPEAT_INC`. But the final INSERT into
`D_INVESTIGATION_REPEAT` reaches **0 rows** — all 6 incremental rows
are filtered out by `WHERE linv.D_INVESTIGATION_REPEAT_KEY != 1` at
line 1349.

## Root cause

`LOOKUP_TABLE_N_REPT.D_REPT_KEY` is declared `INT NOT NULL` with no
`DEFAULT` and no `IDENTITY`. The SP's INSERT at line 1146 supplies
only `PAGE_CASE_UID`, omitting `D_REPT_KEY`:

```sql
INSERT INTO LOOKUP_TABLE_N_REPT (PAGE_CASE_UID)
SELECT PAGE_CASE_UID FROM ...
```

Without a default, SQL Server falls back to … well, on the live DB
the new row ends up with `D_REPT_KEY = 1`. (Need to verify the
exact semantic — possibly an implicit conversion from a NULL that
gets coerced, or an artifact of the schema's `NOT NULL` default
falling through to 0/1 — but empirically every new row gets `1`.)

That 1 propagates downstream:

1. `LOOKUP_TABLE_N_REPT` gets row `(PAGE_CASE_UID=22006000, D_REPT_KEY=1)`.
2. `L_INVESTIGATION_REPEAT_INC` joins LOOKUP_TABLE_N_REPT to get
   `D_INVESTIGATION_REPEAT_KEY` and inherits the sentinel 1.
3. The final `INSERT INTO D_INVESTIGATION_REPEAT` reads
   `L_INVESTIGATION_REPEAT_INC` filtered by
   `WHERE D_INVESTIGATION_REPEAT_KEY != 1` (line 1349) — designed to
   skip the canonical sentinel row — and skips ALL of our new rows
   because they ALL have D_INVESTIGATION_REPEAT_KEY=1.

## Why the team likely hasn't seen this in normal testing

Production probably never invokes
`sp_sld_investigation_repeat_postprocessing` through this code path
because:

1. Neither `merge_and_verify.sh` nor `sp_dyn_dm_main_postprocessing`
   currently invoke it. Whatever production process *does* invoke it
   may avoid this code branch (perhaps `D_REPT_KEY` is populated
   upstream of this SP by a different process, or perhaps the SP is
   never called against a "new PHC" in production — only against PHCs
   that already have a non-1 D_REPT_KEY assigned).
2. The downstream `sp_dyn_dm_repeat{varch,date,numeric}` SPs READ
   from `D_INVESTIGATION_REPEAT` but nothing in the orchestrated chain
   currently WRITES to it.

This is the kind of "no production traffic ever hits this path" bug
that our reverse-engineered fixture flushes out.

## Tables blocked

- `D_INVESTIGATION_REPEAT` — gains no new rows (stays at 2 sentinel
  rows + 1 baseline). Has 252 columns (8 widened by today's fixture
  via the dynamic ALTER TABLE loop) but no populated path beyond the
  baseline.
- `D_INVESTIGATION_REPEAT_INC` — 6 rows present (one per
  PAGE_CASE_UID × BLOCK_NM × ANSWER_GROUP_SEQ_NBR), but all with
  `D_INVESTIGATION_REPEAT_KEY=1`.
- All downstream dyn_dm consumers of `D_INVESTIGATION_REPEAT` for any
  Investigation other than the original sentinel.

## Suggested fix

Two options for the RTR team:

1. **Add IDENTITY to `LOOKUP_TABLE_N_REPT.D_REPT_KEY`** (schema
   change; requires baseline image update). Then the INSERT
   automatically gets a unique key per row.

2. **Generate D_REPT_KEY in the SP** via `ROW_NUMBER() OVER (ORDER
   BY PAGE_CASE_UID) + (SELECT ISNULL(MAX(D_REPT_KEY), 1) FROM
   LOOKUP_TABLE_N_REPT)` and supply it explicitly in the INSERT
   column list. No schema change; SP-only fix.

Both options preserve backward compatibility (`D_REPT_KEY=1` stays
as the sentinel; new keys are 2, 3, ...). Option 2 is preferred — it
doesn't require coordinating a baseline image refresh.

## Reproduction

See `fixtures/30_sp_coverage/d_investigation_repeat.sql` (UID block
22006000-22006999). Apply against a fresh baseline post-Tier-1, then
run the SP. Check job_flow_log for the
`'GENERATING NEW D_REPT_KEYS'` step's row_count vs
`'INSERT INTO D_INVESTIGATION_REPEAT'` row_count — the former says N,
the latter says 0.

## Architectural follow-on (DONE in commit `99ef3517`)

Step 8.5 added to `merge_and_verify.sh`:

```sh
run_sld_investigation_repeat() {
  log "Step 8.5: populate D_INVESTIGATION_REPEAT via sp_sld_investigation_repeat_postprocessing"
  local batch_id
  batch_id=$(date +%y%m%d%H%M%S)
  sql_q RDB_MODERN "EXEC dbo.sp_sld_investigation_repeat_postprocessing @batch_id = $batch_id, @phc_id_list = N'$PHC_UIDS', @debug = 0" >/dev/null 2>&1 || { ... }
}
```

The dim now populates as part of the canonical merged run.  Future
fixtures that author repeating-block answers will see their data flow
through to D_INVESTIGATION_REPEAT automatically.

## Fix details (the actual landed fix)

The hypothesis in the original "Root cause" section above turned out
to be slightly off — D_REPT_KEY *is* an IDENTITY(1,1) column on
`LOOKUP_TABLE_N_REPT`, not a NOT NULL column without a default.  The
issue is more subtle:

- On a fresh DB, IDENT_CURRENT('LOOKUP_TABLE_N_REPT') = 1.
- The SP's first INSERT yields `D_REPT_KEY = 1` (the identity's
  starting value).
- That 1 propagates through `L_INVESTIGATION_REPEAT_INC` and gets
  filtered out by `WHERE D_INVESTIGATION_REPEAT_KEY != 1` at the
  final dim INSERT (line 1349) — the filter is correct (skip the
  sentinel) but the new row's auto-assigned key collides with it.

Fix: reseed the identity to `max(2, MAX(D_INV_REPEAT_KEY)+1)` after
the `DELETE FROM dbo.LOOKUP_TABLE_N_REPT` and before the INSERT.
DBCC CHECKIDENT semantics depend on table state:
- empty table: next inserted value = new_reseed_value
- non-empty: next = new_reseed_value + 1
Because we DELETE before reseed, the table is empty and the next
INSERT gets exactly `@reseed_to`.  Choosing `max(2, MAX(key)+1)`
avoids the sentinel and avoids collisions with any prior non-sentinel
key.

Also pinned `SET QUOTED_IDENTIFIER ON; GO` at the top of the file —
same lesson as bug #9 — so sqlcmd-driven re-applies don't break the
embedded dynamic SQL.

## Verification (post-fix)

Full merge_and_verify with Step 8.5 active:
- `D_INVESTIGATION_REPEAT`: 2 sentinels → 8 rows (+6 dim rows).
- Column coverage: 1/252 → 12/256 (width grew 252→256 because the
  SP's dynamic ALTER TABLE step now reaches the column-add path).
- All 6 new rows have `D_INVESTIGATION_REPEAT_KEY = 2` and
  `PAGE_CASE_UID = 22006000` (Pertussis fixture).
- Headline coverage: 41.4% → 41.5% (+0.1pp / +7 cols populated).

Side-effect: `LOOKUP_TABLE_N_REPT` and `L_INVESTIGATION_REPEAT_INC`
now correctly end at 0 rows post-run (they're transient staging tables
that the SP DELETEs at the start of each invocation).  Previously
they held 1 row each as a side-effect of the SP bailing mid-run.
This transitions them from "fully covered" to "empty" in the
coverage report — a reporting artifact; the underlying behavior is
correct.
