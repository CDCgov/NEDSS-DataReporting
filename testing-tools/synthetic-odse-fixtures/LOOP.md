# LOOP: ODSE fixtures must be visible in the classic NBS UI

## Goal

Iterate on the synthetic ODSE fixtures until every authored investigation is **properly
visible in the classic NBS UI**, not merely populating RDB_MODERN. RDB_MODERN coverage is
necessary but not sufficient: the classic NBS app reads `NBS_ODSE` directly, so an
investigation can pass the comparison harness yet never render under its patient.

## What "visible" requires (per investigation) — confirmed empirically

Three conditions on the `public_health_case`, all required:

1. `record_status_cd = 'OPEN'` (domain is `OPEN`/`CLOSED`, NOT the generic `ACTIVE`/`INACTIVE`).
   `investigation_status_cd='O'` should already be set; leave it. Done in-place across the
   fixtures (only the PHC rows; entity/person/participation rows keep `ACTIVE`).
2. A `dbo.participation` `SubjOfPHC` row (`act_class_cd='CASE'`, `subject_class_cd='PSN'`,
   `act_uid=<phc_uid>`, `subject_entity_uid=<patient_uid>`). Already present for the condition
   chains via `zz_investigation_patient_links.sql` and the `zz_*_dedicated_entities.sql` files.
3. `program_jurisdiction_oid` = a **valid structured OID**, NOT the PHC uid. The fixtures set
   it to the PHC uid (self-reference), which the patient file's row-level-security filter
   rejects. Formula:
   `jurisdiction.nbs_uid * 100000 + program_area.nbs_uid`
   (`NBS_SRTE.dbo.jurisdiction_code.code`, `NBS_SRTE.dbo.program_area_code.prog_area_cd`).
   E.g. TB/130001 = 13001*100000+14 = 1300100014.

Caveat: some PHCs use prog_area_cd `COV`/`VAC`/`MAL`, which aren't in `program_area_code`
(no nbs_uid). Those need a program-area remap (varicella -> VPD, etc.) before an OID computes.

Do NOT flip `record_status_cd` on non-PHC rows (entity, person, person_name, participation,
act_id, etc.) — `ACTIVE` is correct there. Only `public_health_case` rows use `OPEN`/`CLOSED`.

## The loop

1. **Load** the current fixtures onto the running stack:
   `./scripts/apply_odse_fixtures.sh` (no `--reset`; keeps the DB warm).
2. **Verify in the UI** via the curl walkthrough (login as `superuser`, no password; search
   the patient; open the patient file; confirm the investigation renders with status Open).
   Full recipe and caveats: OKF `rtr/synthetic-test-data/ui-visibility.md`.
   - Ground-truth check with sqlcmd (tools18, `-C`):
     `SELECT public_health_case_uid, record_status_cd, investigation_status_cd
      FROM NBS_ODSE.dbo.public_health_case;` and the matching `SubjOfPHC` participation.
3. **Diagnose** any investigation that doesn't render: missing `SubjOfPHC` row?
   `record_status_cd <> 'OPEN'`? patient/act uid mismatch?
4. **Fix the fixture** (the `30_sp_coverage/*` chain or `10_subjects/investigation.sql` that
   authors that PHC), keeping RDB_MODERN coverage intact.
5. **Reload and re-verify.** Repeat until every authored investigation renders.

## Done criteria

- Every investigation authored by the fixtures renders in the classic NBS patient file under
  its patient, with status Open.
- RDB_MODERN coverage is unchanged (the comparison harness still passes).
- The OKF `rtr/synthetic-test-data/` docs reflect the final state.

## Notes

- Bring-up gotcha after image updates: `nbs-mssql` fails with `cp ... are the same file`; fix
  with `docker compose down -v --remove-orphans && docker compose pull && docker compose up -d --build`.
- The override file `docker-compose.override.yaml` (gitignored) tightens drain cadence for
  fast iteration and pins the DB to 6.0.19.1.
