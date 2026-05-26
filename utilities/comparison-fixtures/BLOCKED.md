# RESOLVED — disk-full outage cleared 2026-05-25

**The 2026-05-25 ~00:30 PDT disk-full block is resolved.** The user
freed host disk; the DB was rebuilt from a fresh baseline and the full
pipeline now runs clean end-to-end. Live coverage **89.6%**
(4150/4633 cols), verified by `scripts/coverage_summary.sh` against a
from-scratch `merge_and_verify.sh` run. See the commit
`Fix clean-rebuild blockers; live coverage 89.6%`.

History of the block and how it was cleared is below for the record.

## What was wrong

`/dev/disk3s5` repeatedly hit 100% during heavy fixture-apply activity.
The culprit was **SQL Server tempdb growing without bound** (~70GB) on a
cold single-batch run — specifically the tail-EXEC chain of
`zz_hepatitis_datamart_round2.sql`
(`sp_f_page_case_postprocessing` → `sp_hepatitis_datamart_postprocessing`,
PHC 22008500). On the prior live loop these SPs ran incrementally on a
warm DB and never accumulated; the deterministic cold rebuild ran them
against the full dataset and tempdb spilled until ENOSPC crashed MSSQL.

## How it was cleared

1. User freed host disk. `docker compose down -v` destroyed the bloated
   volume; macOS TRIM then auto-reclaimed it (Docker.raw 73G → 9G,
   host free 1.2Gi → ~70Gi).
2. Fixed two latent bugs a clean rebuild exposed (FK ordering in
   hep100; OID-string-into-bigint in lab100 — see the fix commit).
3. **Quarantined `zz_hepatitis_datamart_round2.sql`** (the tempdb-blowup
   fixture) per LOOP.md's fixture-error rule. This is the only thing
   still outstanding — see below.
4. Re-ran `merge_and_verify.sh` clean (all steps, zero errors, disk
   steady ~68Gi) → 89.6%.

## Still outstanding (follow-up, not blocking)

- **`zz_hepatitis_datamart_round2.sql` is quarantined**, so Agent Q's
  ~+61 hepatitis_datamart cols are NOT in the 89.6% (we still exceeded
  85% without them). Restoring it needs either an upstream fix to the
  runaway tempdb spill in `sp_hepatitis_datamart_postprocessing` /
  `sp_f_page_case_postprocessing`, or a tempdb MAX_SIZE cap so the SP
  fails loudly on just that fixture instead of crashing the host.
  A bug writeup under `bugs/` is warranted.

## RTR bugs discovered this session (unchanged)

- Bug #12 (BMIRD ROW_NUMBER PARTITION) — Agent G
- Bug #13 (sld_investigation_repeat TEXT pivot NULL prop) — H + V
- Bug #14 (d_contact_record STRING_AGG 8000-byte truncation) — U

Each documented in `bugs/NN_*/findings.md`.
