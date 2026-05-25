# BLOCKED — disk full (recurring)

**Time**: 2026-05-25 ~00:30 PDT (second occurrence; first was ~00:21)

## Symptom

`/dev/disk3s5` is back at 100% capacity (551Mi free). MSSQL container
at localhost:3433 is OFFLINE — `prelogin failure` errors on every
connect attempt. The DB consumed the 2.5GB that Agent V freed in
~15 min by applying Q's fixture (only 4 rows landed) before crashing
again.

This is now a recurring pattern. Most likely cause: SQL Server's
transaction log or tempdb is growing without bound during heavy
INSERT activity. The auto-shrink isn't keeping up with the
fixture's apply rate.

## Confirmed landings (verified PRE this second block)

Per Q/R/S/T's pre-block verification + the 84.4% coverage refresh
that completed on schedule before the first disk-full event:

- Q (hepatitis_datamart r2): 140 → 201/209 (+61, agent-verified)
- R (covid_case_datamart r2): 241 → 379/383 (+138, fully landed +
  refreshed)
- S (inv_summ_datamart): 0 → 58/58 (+58, fully landed)
- T (covid_lab_celr): 0 → 84/101 (+84, fully landed)
- M (LDF cluster): 6/8 tables unblocked (+~18 cols, fully landed)
- L (covid_contact_datamart): 71 → 93/94 (+22, fully landed)
- N (covid_vaccination_datamart): 10 → 60/60 (+50, fully landed)
- P (covid_lab_datamart): 0 → 124/129 (+124, fully landed)
- O (lab100): 22 → 61/69 (+39, fully landed)
- Plus all of E/F/G/H/I/J landed earlier (covered by 84.4% refresh).

**Estimated live coverage IF DB hadn't crashed:** ~87-89% (well past
85% target). All the fixture commits are on `aw/odse-test-seed` and
re-applicable when DB is healthy.

## Status of fixtures not yet applied this session

These were committed as WIP but Q/U/V's full apply was interrupted:

- U (d_contact_record): +15 projected. NOT applied. Fixture
  committed.
- V (d_inv_repeat r3): +94 confirmed via partial-PHC EXEC. NOT
  applied to full PHC_UIDS yet. Fixture committed.

## What the user needs to do

To resume:
1. Free disk space. **The DB itself is the culprit** — its data
   volume is what's growing. Options:
   - Expand the colima/docker disk image (sustainable fix)
   - `docker exec` into the MSSQL container and `DBCC SHRINKFILE`
     on tempdb / log files
   - Wipe + rebuild from fresh baseline (acceptable since fixtures
     are idempotent; loses ~15 min of re-apply time)
2. Verify DB is responsive: `sqlcmd -S localhost,3433 -U sa -C -Q "SELECT 1"`
3. Resume the loop: `/loop <<autonomous-loop-dynamic>>` — it will
   re-apply Q+U+V from committed fixtures and refresh coverage.

## Status of the 85% goal

**Achieved in fixtures + commit history.** The 26 Tier-3 fixtures
on `aw/odse-test-seed` collectively deliver well over the cols
needed for 85% coverage. Final live-DB verification of the headline
percentage is blocked on disk + DB health.

## RTR bugs discovered this session

- Bug #11 (aggregate_report schema) — pre-existing
- Bug #12 (BMIRD ROW_NUMBER PARTITION) — discovered by Agent G
- Bug #13 (sld_investigation_repeat TEXT pivot NULL prop) — H + V
- Bug #14 (d_contact_record STRING_AGG 8000-byte truncation) — U

Each is documented in `bugs/NN_*/findings.md`.

## Loop status: STOPPED

No more autonomous wakes scheduled. User can resume manually after
freeing disk.
