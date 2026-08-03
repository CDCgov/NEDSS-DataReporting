# Pipeline manual seed

`seed_patients_providers_authusers.sql` is a hand-run script, not an automated JUnit fixture — it
is not discovered by `DataDrivenFunctionalTests`/`DataDrivenUnitTests` (which only scan
`reporting-pipeline-service/src/test/resources/testData/{functional,unit}`), and isn't referenced
by any test suite. Run it directly against a live/dev `NBS_ODSE` database to seed data for manually
reviewing what the real CDC/Debezium pipeline produces in `RDB_MODERN` (and, via `MasterEtl.sh`,
the legacy `RDB`), rather than asserting against a fixed `expected.json`.

It should still follow the UID-range convention documented in
`../../reporting-pipeline-service/src/test/resources/testData/functional/README.md` and register
its reserved range there — that registry is the single source of truth for avoiding UID collisions
across all test data in this repo.

## `seed_patients_providers_authusers.sql`

Creates 5 patients, 5 providers, and 5 authorized users with deliberately varied field/child-table
coverage (see the script's header comment) for manual pipeline review. UID range:
`1000020000`–`1000020304` (includes a minimal Act/Public_health_case/Participation per patient at
`1000020300`–`304`, so the legacy `MasterEtl.sh` SAS pipeline picks patients up into
`RDB.D_PATIENT` — see the script's header note #6). Re-runnable: it cleans up and re-inserts its
own rows each run, refreshing "last updated" timestamps to the current time.

```
sqlcmd -S <server> -U sa -P '<password>' -C -i seed_patients_providers_authusers.sql
```

Supports an optional `ApplyRandomChanges` sqlcmd argument that, after (re-)creating the 10 person
records, applies random UPDATEs (name, birth date, race, address, contact info) to simulate a real
edit event and exercise the pipeline's UPDATE path, not just its INSERT path:
```
sqlcmd -S <server> -U sa -P '<password>' -C -v ApplyRandomChanges=1 \
  -i seed_patients_providers_authusers.sql
```
Omit `-v ApplyRandomChanges=...` (or pass `=0`) to skip it and only (re-)create the baseline
records. See the script's header for why this isn't wired up via `:setvar` as well.
