# APP-926 — equivalence + performance harness for `sp_morbidity_report_datamart_postprocessing`

Proves the optimized stored proc produces **byte-identical output** to the original (AC #2) and
measures the speedup, using a synthetic RDB_MODERN dataset seeded directly (no ODSE / no pipeline).

## What the optimization did (all RDB_MODERN, nothing in ODSE)
1. **Covering index** `IX_EVENT_METRIC_EVENT_UID` (migration `tables/263-...`). The `#MORB_EVENT_INIT`
   build `LEFT JOIN EVENT_METRIC ON MR.MORB_RPT_UID = EM.EVENT_UID` scanned all of EVENT_METRIC
   (~42.6M rows in KY) because the clustered PK is `(EVENT_TYPE, EVENT_UID)`. The index makes it a seek
   (the plan's own missing-index hint, 32.7% impact).
2. **Split materialization** in the SP. The `#MORB_EVENT_INIT` WHERE had seven OR'd
   `col IN (SELECT value FROM STRING_SPLIT(@param,','))`. Each `@*_uids` list is now parsed once into a
   typed (bigint) PK-indexed temp (`#uid_obs/#uid_pat/#uid_prov/#uid_org/#uid_inv`) and probed with
   `EXISTS`. `CAST` (not `TRY_CONVERT`) preserves the original's throw-on-malformed-input behavior.
3. **Candidate batch-scoping (`#cand`).** The OR-across-outer-joins made the SP seek-join *every* active
   report (~50k) before filtering to ~250. Now a `#cand` pre-filter collects a **superset** of candidate
   `MORB_RPT_KEY`s via seek-driven UNION branches (each anchored on a small `#uid_*` temp), and the
   projection adds `INNER JOIN #cand`. **The original WHERE is unchanged**, so the per-`(MR,MRE)`-row
   filter still decides output — this is why it stays equivalent even when a report has multiple events.
   Makes runtime scale with batch size, not total report count or dimension size.
4. **MAXDOP-1 hint** on the `#MORB_EVENT_FINAL` build (it was taking a parallel plan that burned ~140ms
   CPU on 251 rows). Hints don't change results; equivalence re-verified after adding it.

## Results — **all 9 scenarios byte-identical** (full-row EXCEPT both directions, diff 0/0)

| # | scenario | orig | new | verdict |
|---|---|---|---|---|
| 1 | obs-only | 3 | 3 | PASS |
| 2 | pat-only | 1 | 1 | PASS |
| 3 | prov-only | 2 | 2 | PASS |
| 4 | org-only | 2 | 2 | PASS |
| 5 | inv-only | 1 | 1 | PASS |
| 6 | mixed | 9 | 9 | PASS |
| 7 | empty | 0 | 0 | PASS |
| 8 | junk-obs | 0 | 0 | PASS |
| 9 | **multi-event** (one report, two MRE rows, only one matches) | 1 | 1 | PASS |

Scenario 9 is the case a naive key-grain rewrite would get wrong; the superset-`#cand` + unchanged-WHERE
design passes it. Determinism (orig vs orig2) also 0/0 on all 9.

Performance (250-UID batch, warm):

| state | full SP | `#MORB_EVENT_INIT` |
|---|---|---|
| baseline | 9,273 ms | ~7,700 ms |
| + index + split-materialization | ~450 ms | ~370 ms |
| + `#cand` batch-scoping + MAXDOP1 | **~114 ms** (~82x) | 16.6 ms |

EVENT_METRIC logical reads 100,847 → 828. The original also deadlocks under parallelism; the optimized SP does not.

## Files / run it
`repro_seed.sql` (base seed: EVENT_METRIC 5M unindexed EVENT_UID, MORBIDITY_REPORT/EVENT 50k),
`seed.sql` (dim enrichment + the multi-event report), `harness.sql` (timing + checksum),
`run_capture.sql` / `compare.sql` (9-scenario capture + EXCEPT diff),
`run_equivalence.sh` (deploy ORIGINAL from origin/rel-7.13 → capture ×2 → deploy OPTIMIZED → capture → diff).
```
bash run_equivalence.sh
```
Needs the `nedss-datareporting-nbs-mssql-1` container with RDB_MODERN + `repro_seed.sql` then `seed.sql` applied.
MAXDOP was set to 1 on RDB_MODERN for deterministic timing / to dodge the original's intra-query parallel deadlock.

## Remaining floor (~114ms; 30ms not reached without correctness risk)
`#MORB_EVENT_FINAL` (~45ms) is a 150-column projection with `CONCAT`/`CHARINDEX`/`TRIM`/`IIF`/`CASE`
over the ~251 candidate rows and 15 joins — intrinsic serial CPU, already batch-scoped, so `#cand`
doesn't help it. Going lower touches result-producing projection logic and would need its own
equivalence pass; not attempted, to keep output guaranteed identical.
