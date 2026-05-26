# _quarantine

Fixtures here are excluded from `scripts/merge_and_verify.sh` (it globs
`30_sp_coverage/*.sql`; quarantined files carry a non-`.sql` suffix).

## Currently quarantined

- **`zz_hepatitis_datamart_round2.sql.tempdb-blowup`** (2026-05-25).
  Agent Q's hepatitis_datamart round-2 enrich (+61 cols claimed). In a
  full single-batch pipeline run its tail-EXEC chain
  (`sp_f_page_case_postprocessing` → `sp_hepatitis_datamart_postprocessing`,
  both keyed to PHC 22008500) spilled **~70GB into tempdb** and filled
  the host disk to 100%, wedging MSSQL — twice (the recurring blocker
  documented in `../../../BLOCKED.md`). The two SPs run fine
  incrementally on a warm DB (which is how the prior live session got
  Q's +61), but in the cold single-batch merge they run against the
  full dataset and a runaway join/spill blows up tempdb. Quarantined
  per LOOP.md's fixture-error rule to unblock a clean headline from the
  other ~38 Tier-3 fixtures. **Cost:** loses Q's +61 hep cols (live
  coverage falls back toward the pre-Q ~84% range). **Follow-up:**
  needs a bug writeup + an SP fix (or a tempdb cap so it fails loudly
  on just this fixture); restore once the runaway is fixed.

- **`zz_case_lab_datamart_enrich.sql.broken`** — Agent K's
  case_lab_datamart fixture; NOT NULL constraint failure on apply
  (quarantined in the round-2 loop).

## History (2026-05-21, Agent B Phase-2 debug pass)

This directory previously held COVID and Varicella full-chain fixtures
that were quarantined because they regressed the TB cluster in a merged
pipeline run. The root cause turned out to be trivial: both fixtures
were missing `SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON/OFF` around
their `nbs_case_answer` INSERT block (same bug TB had originally — see
commit a7757dbc). The COVID INSERT failed mid-apply with
`Cannot insert explicit value for identity column in table
'NBS_case_answer' when IDENTITY_INSERT is set to OFF`. Because
`scripts/merge_and_verify.sh` runs `set -euo pipefail`, the COVID
fixture failure aborted Step 8 before TB's tail-EXECs ran, leaving
D_TB_PAM / F_TB_PAM / TB_DATAMART at 0 rows. There was no
cross-fixture interference — the two fixtures compose cleanly with
TB once the IDENTITY_INSERT toggle is added.

Both fixtures are now restored to `fixtures/30_sp_coverage/` with the
fix applied. Merged pipeline now lands at 33.6% column coverage
(+5.7pp over the prior 27.9% TB+STD+BMIRD baseline).

Keep this directory empty as a marker. Future quarantines should
allocate new sibling directories.
