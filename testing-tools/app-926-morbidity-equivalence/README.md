# APP-926 — equivalence + performance harness for `sp_morbidity_report_datamart_postprocessing`

Proves the optimized stored proc produces **byte-identical output** to the original (AC #2) and
measures the speedup, using a synthetic RDB_MODERN dataset seeded directly (no ODSE / no pipeline).

## What the optimization did
1. **Covering index** `IX_EVENT_METRIC_EVENT_UID` (migration `tables/263-...`). The `#MORB_EVENT_INIT`
   build `LEFT JOIN EVENT_METRIC ON MR.MORB_RPT_UID = EM.EVENT_UID` scanned all of EVENT_METRIC
   (~42.6M rows in KY) because the clustered PK is `(EVENT_TYPE, EVENT_UID)`. The index makes it a seek.
2. **Split materialization** in the SP (`routines/048-...`). The `#MORB_EVENT_INIT` WHERE had seven
   OR'd `col IN (SELECT value FROM STRING_SPLIT(@param,','))`. Each `@*_uids` list is now parsed once
   into a typed (bigint) PK-indexed temp (`#uid_obs/#uid_pat/#uid_prov/#uid_org/#uid_inv`) and probed
   with `EXISTS`. `CAST` (not `TRY_CONVERT`) is used so malformed input throws exactly as the original.

## Files
- `repro_seed.sql` — seeds EVENT_METRIC (5M, unindexed EVENT_UID so the scan reproduces),
  MORBIDITY_REPORT / MORBIDITY_REPORT_EVENT (50k). Reports qualify via `@obs_uids`.
- `harness.sql` — timing + output checksum for one 250-UID batch.
- `seed.sql` — enriches the dimension tables (D_PATIENT/D_PROVIDER/D_ORGANIZATION/INVESTIGATION) and
  repoints MRE FK keys so the pat/prov/org/inv branches actually match.
- `run_capture.sql` / `compare.sql` — 8-scenario capture + both-direction `EXCEPT` diff.
- `run_equivalence.sh` — full harness: deploy ORIGINAL (from `origin/rel-7.13`) → capture (twice, for a
  determinism check) → deploy OPTIMIZED (the working-tree SP) → capture → diff.

## Results
Equivalence — **all 8 scenarios byte-identical** (obs / pat / prov / org / inv / mixed / empty / junk):

| scenario | orig_rows | new_rows | diff | verdict |
|---|---|---|---|---|
| 1 obs-only | 3 | 3 | 0/0 | PASS |
| 2 pat-only | 1 | 1 | 0/0 | PASS |
| 3 prov-only | 2 | 2 | 0/0 | PASS |
| 4 org-only | 2 | 2 | 0/0 | PASS |
| 5 inv-only | 1 | 1 | 0/0 | PASS |
| 6 mixed | 9 | 9 | 0/0 | PASS |
| 7 empty | 0 | 0 | 0/0 | PASS |
| 8 junk-obs | 0 | 0 | 0/0 | PASS |

Performance (250-UID batch): full SP **9,273 ms → ~450 ms** with populated dimensions (~20x), the
line-77 `#MORB_EVENT_INIT` statement **~7,700 ms → ~370 ms**. EVENT_METRIC logical reads
**100,847 → 828** (scan → seek). The original also deadlocked under parallelism; the optimized SP does not.

## Run it
```
bash run_equivalence.sh          # deploys both versions, compares (needs the app-926 working tree)
```
Requires the `nedss-datareporting-nbs-mssql-1` container with RDB_MODERN and the repro seed applied
(`repro_seed.sql` then `seed.sql`). MAXDOP is set to 1 for deterministic timing / to avoid the
original's intra-query parallel deadlock; measure under parallelism for production-representative numbers.

## Known further optimization (not applied)
The OR-across-outer-joins still makes the SP process every ACTIVE report per call (scales with total
reports, not batch size — likely a large part of KY's 48h). A UNION-of-seeks pre-filter would fix this
and close the last gap to <300ms, but it is NOT equivalence-safe unless MORBIDITY_REPORT_EVENT is 1:1
per MORB_RPT_KEY (it has no unique constraint). Validate that (or build a multi-event test) before shipping it.
