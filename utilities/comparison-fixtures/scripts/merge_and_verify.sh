#!/usr/bin/env bash
# merge_and_verify.sh — execute the full Merge contract sequence end-to-end.
#
# Per STRATEGY.md "Merge contract":
#   1. Reset baseline (docker compose down -v && up -d).
#   2. Pre-fixture infrastructure (RDB_DATE recursive CTE +
#      sp_nrt_srte_condition_code_postprocessing).
#   3. Apply fixtures/00_foundation/00_foundation.sql.
#   4. Apply fixtures/10_subjects/*.sql.
#   5. Run Tier 1 chains in dependency order.
#   6. Apply fixtures/20_links/*.sql.
#   7. Re-run Tier 1 chains affected by Tier 2 edges.
#   8. Apply fixtures/30_sp_coverage/*.sql (Tier 3, currently empty).
#   9. Run datamart SPs (currently out of scope — stub).
#
# Exits non-zero on any sqlcmd error or missing fixture file.
#
# Usage:
#   ./scripts/merge_and_verify.sh             # run full sequence
#   ./scripts/merge_and_verify.sh --skip-reset # skip steps 1-2 (DB already prepared)
#   ./scripts/merge_and_verify.sh --no-tier-2  # stop after Tier 1 chains
#
# Output: progress to stdout, errors to stderr. Final summary lists
# row counts per RDB_MODERN target table for the canonical fixture UIDs.

set -euo pipefail

# --------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------

# Base directories (script lives in scripts/, project lives 2 levels up
# under NEDSS-DataReporting/utilities/comparison-fixtures/).
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly FIXTURES_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
readonly NEDSS_DR_ROOT="$( cd "$FIXTURES_ROOT/../.." && pwd )"

# DB serialization. This script resets the baseline with `docker compose down -v`,
# which DROPS the database volume. That must never run concurrently with another
# process touching the DB (a fixture apply, a coverage refresh, a parallel loop
# agent). Acquire the shared db lock for the entire run (see db_lock.sh) so the
# volume drop and the subsequent reload are mutually exclusive with every other
# db_lock holder.
source "$SCRIPT_DIR/db_lock.sh"

readonly FOUNDATION_SQL="$FIXTURES_ROOT/fixtures/00_foundation/00_foundation.sql"
readonly TIER_1_DIR="$FIXTURES_ROOT/fixtures/10_subjects"
readonly TIER_2_DIR="$FIXTURES_ROOT/fixtures/20_links"
readonly TIER_3_DIR="$FIXTURES_ROOT/fixtures/30_sp_coverage"

# Connection
export SQLCMDPASSWORD="${SQLCMDPASSWORD:-PizzaIsGood33!}"
readonly SQLCMD_BASE='sqlcmd -S localhost,3433 -U sa -C'

# CLI flags
SKIP_RESET=0
NO_TIER_2=0
for arg in "$@"; do
  case "$arg" in
    --skip-reset) SKIP_RESET=1 ;;
    --no-tier-2)  NO_TIER_2=1 ;;
    -h|--help)
      sed -n '2,25p' "$0"
      exit 0
      ;;
    *) echo "Unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# --------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------

log() { printf '\033[1;36m[merge]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[merge ERROR]\033[0m %s\n' "$*" >&2; }

# Run a query (-Q). Wrapper around sqlcmd that prefixes SET NOCOUNT ON.
sql_q() {
  local db="$1" q="$2"
  $SQLCMD_BASE -d "$db" -Q "SET NOCOUNT ON; $q"
}

# Apply a .sql file (-i). Fails loudly on any error message in output.
sql_i() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    err "Fixture missing: $file"
    return 1
  fi
  log "  apply: ${file#$FIXTURES_ROOT/}"
  local out
  out=$( $SQLCMD_BASE -i "$file" 2>&1 )
  # Only treat real SQL errors (Msg NNNN, Level >=11) as failures. Do NOT match
  # the bare substrings 'error'/'level' — benign result-set text (e.g. a
  # job_flow_log row "Missing NRT Record ... Error") would otherwise false-fail.
  # 5701/5703 are informational (changed DB context / language).
  echo "$out" | grep -E 'Msg [0-9]+, Level (1[1-9]|2[0-9])' | grep -vE 'Msg 5701|Msg 5703' && {
    err "Apply failed for $file"
    echo "$out" >&2
    return 1
  } || true
}

# --------------------------------------------------------------------
# Step 1 — Reset baseline
# --------------------------------------------------------------------

reset_baseline() {
  log "Step 1: docker compose down -v && build && up -d FULL pipeline"
  # Full real pipeline (no nrt_* shortcut): CDC (debezium) + kafka-connect sink
  # project ODSE -> nrt_*, and reporting-pipeline-service runs the *_event +
  # postprocessing SPs. Rebuild liquibase + service so working-tree routine/code
  # changes ship into the images.
  ( cd "$NEDSS_DR_ROOT" \
      && docker compose down -v >/dev/null 2>&1 \
      && docker compose build liquibase reporting-pipeline-service >/dev/null 2>&1 \
      && docker compose up -d >/dev/null 2>&1 )

  log "Waiting for liquibase migrations..."
  local timeout=600 elapsed=0
  while [[ $elapsed -lt $timeout ]]; do
    [[ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1)" == Exited* ]] && { log "Liquibase done."; break; }
    sleep 10; elapsed=$((elapsed + 10))
  done
  [[ $elapsed -ge $timeout ]] && { err "Liquibase did not complete within ${timeout}s"; return 1; }

  log "Waiting for pipeline to be ready (debezium/connect connectors + service initial drain)..."
  wait_for_pipeline_drain 300 || { err "pipeline not ready"; return 1; }
  log "Pipeline ready."
}

# Poll the reporting-pipeline-service log until it reports the idle signal
# ("No ids to process from the topics.") 3 times in a row, i.e. CDC + the
# service have drained all pending work. Arg: timeout seconds (default 300).
wait_for_pipeline_drain() {
  local timeout="${1:-300}" elapsed=0
  local svc=nedss-datareporting-reporting-pipeline-service-1
  while [[ $elapsed -lt $timeout ]]; do
    if [[ "$(docker logs --tail 6 "$svc" 2>&1 | grep -c 'No ids to process from the topics')" -ge 3 ]]; then
      return 0
    fi
    sleep 8; elapsed=$((elapsed + 8))
  done
  return 1
}

# --------------------------------------------------------------------
# Step 2 — Pre-fixture infrastructure
# --------------------------------------------------------------------

run_infrastructure_sps() {
  log "Step 2: pre-fixture infrastructure"
  log "  populate RDB_DATE via recursive CTE (sp_get_date_dim is broken)"
  # Insert sentinel row at DATE_KEY=1 first — postprocessing SPs use
  # COALESCE(<lookup>, 1) for missing dates and the FK constraint requires
  # DATE_KEY=1 to exist.
  # Populate all 11 derived calendar columns so coverage_summary.sh shows
  # RDB_DATE as fully covered (year/month/day/quarter/week/etc.).
  sql_q RDB_MODERN "
    INSERT INTO dbo.RDB_DATE (DATE_KEY, DATE_MM_DD_YYYY) VALUES (1, NULL);
    WITH dates AS (
      SELECT CAST('2020-01-01' AS DATE) AS dt
      UNION ALL
      SELECT DATEADD(day, 1, dt) FROM dates WHERE dt < '2030-12-31'
    )
    INSERT INTO dbo.RDB_DATE (
      DATE_KEY, DATE_MM_DD_YYYY,
      DAY_OF_WEEK, DAY_NBR_IN_CLNDR_MON, DAY_NBR_IN_CLNDR_YR,
      WK_NBR_IN_CLNDR_MON, WK_NBR_IN_CLNDR_YR,
      CLNDR_MON_NAME, CLNDR_MON_IN_YR, CLNDR_QRTR, CLNDR_YR
    )
    SELECT
      DATEDIFF(day, '2010-01-01', dt) + 1,
      dt,
      DATEPART(weekday, dt),
      DATEPART(day, dt),
      DATEPART(dayofyear, dt),
      ((DATEPART(day, dt) - 1) / 7) + 1,
      DATEPART(week, dt),
      DATENAME(month, dt),
      DATEPART(month, dt),
      DATEPART(quarter, dt),
      DATEPART(year, dt)
    FROM dates
    OPTION (MAXRECURSION 0);
  " >/dev/null

  log "  populate CONDITION via sp_nrt_srte_condition_code_postprocessing"
  # Multi-condition fan-out: seed conditions for every condition-gated
  # datamart so each can populate when fed a matching Investigation:
  #   10110 Hepatitis A acute       (sp_hepatitis_*)
  #   10100 Hepatitis B acute       (Hep B/C datamart family)
  #   10101 Hepatitis C acute
  #   10220 Tuberculosis            (sp_tb_*)
  #   10030 Varicella               (sp_var_datamart)
  #   10180 Mumps                   (sp_ldf_mumps)
  #   10190 Pertussis               (sp_pertussis_case_datamart)
  #   10140 Measles (Rubeola)       (sp_measles_case_datamart)
  #   10200 Rubella                 (sp_rubella_case_datamart)
  #   10370 Rubella congenital      (sp_crs_case_datamart)
  #   11065 COVID-19                (sp_covid_case_datamart)
  #   11066 MIS-C COVID-19
  #   10311 Syphilis primary        (sp_std_hiv_datamart — STD)
  #   10561 HIV pediatric           (sp_std_hiv_datamart — HIV)
  #   10274 Chlamydia
  #   10280 Gonorrhea
  #   11717 Strep pneumoniae        (sp_bmird_strep_pneumo_datamart)
  sql_q RDB_MODERN "EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110,10100,10101,10220,10030,10180,10190,10140,10200,10370,11065,11066,10311,10561,10274,10280,11717', @debug = 0;" >/dev/null

  local rdb_date_count cond_count
  rdb_date_count=$(sql_q RDB_MODERN "SELECT COUNT(*) FROM dbo.RDB_DATE" | tr -dc '0-9' )
  cond_count=$(sql_q RDB_MODERN "SELECT COUNT(*) FROM dbo.CONDITION" | tr -dc '0-9' )
  log "  RDB_DATE rows: $rdb_date_count, CONDITION rows: $cond_count"
}

# --------------------------------------------------------------------
# Step 3 — Foundation
# --------------------------------------------------------------------

apply_foundation() {
  log "Step 3: apply foundation"
  sql_i "$FOUNDATION_SQL"
}

# --------------------------------------------------------------------
# Step 4 — Tier 1 fixtures
# --------------------------------------------------------------------

apply_tier_1_fixtures() {
  log "Step 4: apply Tier 1 fixtures (10_subjects/*.sql)"
  shopt -s nullglob
  local files=( "$TIER_1_DIR"/*.sql )
  shopt -u nullglob
  if [[ ${#files[@]} -eq 0 ]]; then
    err "No Tier 1 fixtures found in $TIER_1_DIR"
    return 1
  fi
  for f in "${files[@]}"; do
    sql_i "$f"
  done
  log "  Applied ${#files[@]} Tier 1 fixtures."
}

# --------------------------------------------------------------------
# Step 5 — Tier 1 chains
# --------------------------------------------------------------------
#
# Subject  | event SP                   | event param          | postprocessing SP(s)                   | postprocessing param
# ---------|----------------------------|----------------------|-----------------------------------------|---------------------
# org      | sp_organization_event      | @org_id_list         | sp_nrt_organization_postprocessing      | @id_list
# provider | sp_provider_event          | @user_id_list        | sp_nrt_provider_postprocessing          | @id_list
# patient  | sp_patient_event           | @user_id_list        | sp_nrt_patient_postprocessing           | @id_list
# place    | sp_place_event             | @id_list             | sp_nrt_place_postprocessing             | @id_list
# inv      | sp_investigation_event     | @phc_id_list         | sp_nrt_investigation_postprocessing     | @id_list
# notif    | sp_notification_event      | @notification_list   | sp_nrt_notification_postprocessing      | @notification_uids
# lab      | sp_observation_event       | @obs_id_list         | sp_d_lab_test_postprocessing AND        | @obs_ids
#                                                              | sp_d_labtest_result_postprocessing      | @obs_ids
# morb     | sp_observation_event       | @obs_id_list         | sp_d_morbidity_report_postprocessing    | @pMorbidityIdList
# interview| sp_interview_event         | @ix_uids             | sp_d_interview_postprocessing AND       | @interview_uids
#                                                              | sp_f_interview_case_postprocessing      | @ix_uids
# treatment| sp_treatment_event         | @treatment_uids      | sp_nrt_treatment_postprocessing         | @treatment_uids
# vaccine  | sp_vaccination_event       | @vac_uids            | sp_d_vaccination_postprocessing AND     | @vac_uids
#                                                              | sp_f_vaccination_postprocessing         | @vac_uids
# contact  | (BROKEN — skip)            |                      | sp_d_contact_record_postprocessing AND  | @contact_uids
#                                                              | sp_f_contact_record_case_postprocessing | @contact_uids
#
# Order: organization → provider → patient → place → investigation → notification
#        → lab → morbidity → interview → treatment → vaccination → contact

# Each function emits a single $SQLCMD_BASE call; the CSV of UIDs is the canonical foundation+v2 UIDs from uid_ranges.md.

run_organization_chain() {
  log "  organization (foundation 20000020 + v2 20030010)"
  sql_q RDB_MODERN "EXEC dbo.sp_organization_event @org_id_list = N'20000020,20030010'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0" >/dev/null
}

run_provider_chain() {
  log "  provider (foundation 20000010 + v2 20010010)"
  sql_q RDB_MODERN "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0" >/dev/null
}

run_patient_chain() {
  log "  patient (foundation 20000000 + v2 20020010 + v3 20020020)"
  sql_q RDB_MODERN "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010,20020020'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010,20020020', @debug = 0" >/dev/null
}

run_place_chain() {
  log "  place (foundation 20000030 + v2 20040010)"
  sql_q RDB_MODERN "EXEC dbo.sp_place_event @id_list = N'20000030,20040010'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_nrt_place_postprocessing @id_list = N'20000030,20040010', @debug = 0" >/dev/null
}

run_investigation_chain() {
  log "  investigation (foundation 20000100 + v2 20050010)"
  sql_q RDB_MODERN "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0" >/dev/null
}

run_notification_chain() {
  log "  notification (foundation 20000110 + v2 20060010)"
  # Event SP returns 0 rows pre-Tier-2 (INNER JOIN on act_relationship);
  # postprocessing SP also fails pre-Tier-2 due to FK on INVESTIGATION_KEY.
  # In merged sequence (post-Tier-2 inv_notification edge), this works.
  sql_q RDB_MODERN "EXEC dbo.sp_notification_event @notification_list = N'20000110,20060010'" >/dev/null || true
  sql_q RDB_MODERN "EXEC dbo.sp_nrt_notification_postprocessing @notification_uids = N'20000110,20060010', @debug = 0" >/dev/null || true
}

# NOTE (Round 5, Phase B): this function is DEAD CODE on the no-shortcut flow.
# main() does NOT call run_tier_1_chains/rerun_tier_1_chains (its only callers),
# so run_lab_chain never executes — the reporting-pipeline-service runs the lab
# chain (sp_observation_event -> sp_d_lab_test_postprocessing ->
# sp_d_labtest_result_postprocessing -> sp_lab100/101_datamart_postprocessing,
# PostProcessingService.processObservation:1245-1278) off the Tier-3 CDC events.
# The zz_lab100_101_fill.sql obs UIDs (22053010,22053011,22053500,22053501,
# 22053502) are therefore reproduced/processed by CDC in the Step-9 drain; they
# are listed here only for catalog parity with the live obsCache LAB_REPORT path.
run_lab_chain() {
  log "  lab (foundation 20000120 + v2 Order 20070010 + Tier-3 lab fill 22053xxx)"
  sql_q RDB_MODERN "EXEC dbo.sp_observation_event @obs_id_list = N'20000120,20070010,22053010,22053011,22053500,22053501,22053502'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_d_lab_test_postprocessing @obs_ids = N'20000120,20070010,22053010,22053011,22053500,22053501,22053502', @debug = 0" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_d_labtest_result_postprocessing @obs_ids = N'20000120,20070010,22053010,22053011,22053500,22053501,22053502', @debug = 0" >/dev/null
}

run_morbidity_chain() {
  log "  morbidity (foundation 20000130 + v2 Order 20080010)"
  # Pre-Tier-2 morb_inv: postprocessing fails on PATIENT_KEY no-COALESCE.
  sql_q RDB_MODERN "EXEC dbo.sp_observation_event @obs_id_list = N'20000130,20080010'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_d_morbidity_report_postprocessing @pMorbidityIdList = N'20000130,20080010', @debug = 0" >/dev/null || true
}

run_interview_chain() {
  log "  interview (foundation 20000140 + v2 20090010)"
  sql_q RDB_MODERN "EXEC dbo.sp_interview_event @ix_uids = N'20000140,20090010'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_d_interview_postprocessing @interview_uids = N'20000140,20090010', @debug = 0" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_f_interview_case_postprocessing @ix_uids = N'20000140,20090010', @debug = 0" >/dev/null
}

run_treatment_chain() {
  log "  treatment (foundation 20000150 + v2 20100010 + v3 20100020)"
  sql_q RDB_MODERN "EXEC dbo.sp_treatment_event @treatment_uids = N'20000150,20100010,20100020', @debug = 0" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_nrt_treatment_postprocessing @treatment_uids = N'20000150,20100010,20100020', @debug = 0" >/dev/null
}

run_vaccination_chain() {
  log "  vaccination (foundation 20000160 + v2 20110010)"
  # Pre-Tier-2 vaccination_links: event SP returns 0 rows (INNER filter
  # on SubOfVacc nbs_act_entity). Postprocessing reads nrt_vaccination
  # directly, so it produces D_VACCINATION + F_VACCINATION rows regardless.
  sql_q RDB_MODERN "EXEC dbo.sp_vaccination_event @vac_uids = N'20000160,20110010', @debug = 0" >/dev/null || true
  sql_q RDB_MODERN "EXEC dbo.sp_d_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_f_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0" >/dev/null
}

run_contact_chain() {
  log "  contact (foundation 20000170 + v2 20120010)"
  # Event SP is BROKEN upstream (cross-DB function ref to fn_get_value_by_cd_codeset).
  # Skip event SP. Postprocessing SPs read nrt_contact directly.
  sql_q RDB_MODERN "EXEC dbo.sp_d_contact_record_postprocessing @contact_uids = N'20000170,20120010', @debug = 0" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_f_contact_record_case_postprocessing @contact_uids = N'20000170,20120010', @debug = 0" >/dev/null
}

run_tier_1_chains() {
  log "Step 5: run Tier 1 chains in dependency order"
  run_organization_chain
  run_provider_chain
  run_patient_chain
  run_place_chain
  run_investigation_chain
  run_notification_chain
  run_lab_chain
  run_morbidity_chain
  run_interview_chain
  run_treatment_chain
  run_vaccination_chain
  run_contact_chain
}

# --------------------------------------------------------------------
# Step 6 — Tier 2 fixtures
# --------------------------------------------------------------------

apply_tier_2_fixtures() {
  log "Step 6: apply Tier 2 fixtures (20_links/*.sql)"
  shopt -s nullglob
  local files=( "$TIER_2_DIR"/*.sql )
  shopt -u nullglob
  if [[ ${#files[@]} -eq 0 ]]; then
    err "No Tier 2 fixtures found in $TIER_2_DIR"
    return 1
  fi
  for f in "${files[@]}"; do
    sql_i "$f"
  done
  log "  Applied ${#files[@]} Tier 2 fixtures."
}

# --------------------------------------------------------------------
# Step 7 — Re-run Tier 1 chains affected by Tier 2 edges
# --------------------------------------------------------------------
#
# After Tier 2 edges wire cross-subject relationships, the chains that
# were blocked or partial pre-Tier-2 should now produce full coverage:
#   - notification: was 0/6 + 0/8 → expected 6/6 + 8/8 (inv_notification edge)
#   - morbidity: was 30/30 + 0/17 + 0/8 → expected 30/30 + 17/17 + 0/8
#                (morb_inv edge; MORB_RPT_USER_COMMENT remains 0/8 due to RTR bug)
#   - vaccination: event SP was 0 rows → 2 rows (vaccination_links edge)
#   - lab/treatment: cross-subject KEY columns flip sentinel→real
#
# Re-run them all to capture the updated state.

rerun_tier_1_chains() {
  log "Step 7: re-run Tier 1 chains affected by Tier 2 edges"
  # Run all chains again — idempotent; postprocessing SPs UPDATE existing
  # rows when they re-fire, so re-running is safe and captures the new
  # coverage values.
  run_notification_chain
  run_morbidity_chain
  run_lab_chain
  run_treatment_chain
  run_vaccination_chain
  run_interview_chain
}

# --------------------------------------------------------------------
# Step 8 — Tier 3 fixtures
# --------------------------------------------------------------------

apply_tier_3_fixtures() {
  log "Step 8: apply Tier 3 fixtures (30_sp_coverage/*.sql)"
  shopt -s nullglob
  local files=( "$TIER_3_DIR"/*.sql )
  shopt -u nullglob
  if [[ ${#files[@]} -eq 0 ]]; then
    log "  (no Tier 3 fixtures yet — skipping)"
    return 0
  fi
  for f in "${files[@]}"; do
    sql_i "$f"
  done
}

# --------------------------------------------------------------------
# Step 9 — Datamart SPs
# --------------------------------------------------------------------
#
# Datamart SPs read from already-populated Tier 1 dimensions and produce
# fact tables (HEPATITIS_DATAMART, F_PAGE_CASE, etc.). Most are
# condition-gated; with v1's single-condition fan-out (Hep A acute,
# condition_cd='10110'), only the Hep-related ones populate. Others run
# cleanly but emit 0 rows — same shape as Tier 1 chains running with no
# matching data.
#
# Param-name conventions vary widely:
#   @phc_uids / @phc_id_list / @phc_id / @phc_ids   — Investigation UIDs
#   @vac_uids                                       — Vaccination UIDs
#   @obs_uids / @observation_id_list / @lab_test_uids — Observation UIDs
#   @id_list                                        — varies
#   Multi-arg SPs: event_metric, inv_summary, morb_datamart take all of
#   {phc, obs, notif, ct, vax, pat, prov, org, inv}.
#
# Canonical UIDs (foundation + v2 + v3 from uid_ranges.md):
#   PHC:           20000100, 20050010
#   Patient:       20000000, 20020010, 20020020
#   Provider:      20000010, 20010010
#   Organization:  20000020, 20030010
#   Notification:  20000110, 20060010
#   Lab obs:       20000120, 20070010
#   Morb obs:      20000130, 20080010
#   Vaccination:   20000160, 20110010
#   Contact:       20000170, 20120010
#   Treatment:     20000150, 20100010, 20100020
#   Interview:     20000140, 20090010

readonly PHC_UIDS='20000100,20050010,22000010,22000020,22000030,22000040,22000050,22000060,22000070,22000080,22000090,22000100,22000200,22001000,22002000,22003000,22004000,22005000,22007000,22008000,22008500,22009000,22010000,22019100,22043000,22046000,22047000,22047500,22049000,22049200,22049400,22049500,22050000,22054000,22060000,22060200,22060400,22060600'
readonly PAT_UIDS='20000000,20020010,20020020'
readonly PRV_UIDS='20000010,20010010'
readonly ORG_UIDS='20000020,20030010'
readonly NOTIF_UIDS='20000110,20060010'
# NOTE: used only by run_datamart_sps() which is DEAD CODE (never called by main();
# the lab100/101 datamart SPs are run by the service per-CDC-batch, not here).
# Tier-3 lab-fill Result/I_Result test UIDs (22053011 LAB100, 22053501 LAB101)
# added for catalog parity; the live datamart run keys on the service's labIds.
readonly LAB_OBS_UIDS='20000120,20070010,20070011,22022000,22029401,22053011,22053501'
readonly MORB_OBS_UIDS='20000130,20080010'
readonly OBS_UIDS='20000120,20070010,20070011,22022000,20000130,20080010'
readonly VAC_UIDS='20000160,20110010'
readonly CT_UIDS='20000170,20120010'

# Run a datamart SP, suppressing common "no rows" errors that come from
# condition-gating (only Hep A populates with v1's single-condition fan-out).
# Returns 0 even if the SP no-ops; only fails on real apply errors.
run_dm_sp() {
  local sp="$1" args="$2"
  log "  $sp"
  sql_q RDB_MODERN "EXEC dbo.$sp $args" >/dev/null 2>&1 || {
    # Don't fail the whole run if a datamart SP errors — many will hit
    # condition-gated NULL rows. Log and continue.
    log "    (errored or no-op — see job_flow_log)"
  }
}

# --------------------------------------------------------------------
# Step 8.5 — Populate D_INVESTIGATION_REPEAT for all PHC_UIDS
# --------------------------------------------------------------------
#
# Reads from S_INVESTIGATION_REPEAT (populated by page-builder upstream)
# and writes D_INVESTIGATION_REPEAT + L_INVESTIGATION_REPEAT_INC +
# LOOKUP_TABLE_N_REPT.  Was previously not in the orchestrated chain
# (nothing in Step 9 invokes it); see bugs/10_*/findings.md
# "Architectural follow-on".
#
# Runs AFTER Tier 3 fixtures so any repeating-block answers authored
# by Tier 3 are visible to the SP.
run_sld_investigation_repeat() {
  log "Step 8.5: populate D_INVESTIGATION_REPEAT via sp_sld_investigation_repeat_postprocessing"
  local batch_id
  batch_id=$(date +%y%m%d%H%M%S)
  sql_q RDB_MODERN "EXEC dbo.sp_sld_investigation_repeat_postprocessing @batch_id = $batch_id, @phc_id_list = N'$PHC_UIDS', @debug = 0" >/dev/null 2>&1 || {
    log "    (errored or no-op — see job_flow_log)"
  }
}

# Step 8.6 — Populate D_INV_PLACE_REPEAT via sp_repeated_place_postprocessing.
# Sibling of Step 8.5. The SP exists but was never wired into the
# orchestrator; result was D_INV_PLACE_REPEAT stuck at 1/42 (sentinel
# only). Discovered by agent-D2 (2026-05-24). The SP filters on
# part_type_cd IN ('PlaceAsHangoutOfPHC','PlaceAsSexOfPHC') over
# nrt_page_case_answer, joining to D_PLACE by composite PLACE_LOCATOR_UID.
run_repeated_place_postprocessing() {
  log "Step 8.6: populate D_INV_PLACE_REPEAT via sp_repeated_place_postprocessing"
  local batch_id
  batch_id=$(date +%y%m%d%H%M%S)
  sql_q RDB_MODERN "EXEC dbo.sp_repeated_place_postprocessing @batch_id = $batch_id, @phc_id_list = N'$PHC_UIDS', @debug = 0" >/dev/null 2>&1 || {
    log "    (errored or no-op — see job_flow_log)"
  }
}

run_datamart_sps() {
  log "Step 9: datamart SPs (40 SPs, condition-gated; only Hep-related populate with v1 single-condition fan-out)"

  # Investigation-PHC fact assembly (foundational for downstream datamarts)
  # Case management dim — reads nrt_investigation_case_management staging
  # (authored by Phase-2 fixtures); populates D_CASE_MANAGEMENT.
  run_dm_sp sp_nrt_case_management_postprocessing          "@id_list = N'$PHC_UIDS', @debug = 0"

  run_dm_sp sp_f_page_case_postprocessing                  "@phc_ids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_f_std_page_case_postprocessing              "@phc_id_list = N'$PHC_UIDS', @debug = 0" 2>/dev/null

  # Hepatitis (condition_cd='10110' is Hep A acute — these will populate)
  run_dm_sp sp_hepatitis_datamart_postprocessing           "@phc_id = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_hepatitis_case_datamart_postprocessing      "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_hep100_datamart_postprocessing              "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_ldf_hepatitis_datamart_postprocessing       "@phc_uids = N'$PHC_UIDS', @debug = 0"

  # Generic / per-condition case datamarts (will no-op for non-matching conditions)
  run_dm_sp sp_generic_case_datamart_postprocessing        "@phc_ids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_morbidity_report_datamart_postprocessing    "@obs_uids = N'$MORB_OBS_UIDS', @pat_uids = N'$PAT_UIDS', @prov_uids = N'$PRV_UIDS', @org_uids = N'$ORG_UIDS', @inv_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_aggregate_report_datamart_postprocessing    "@id_list = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_summary_report_case_postprocessing          "@id_list = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_sr100_datamart_postprocessing               "@id_list = N'$PHC_UIDS', @debug = 0"

  # Lab datamarts
  run_dm_sp sp_case_lab_datamart_postprocessing            "@phc_id = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_lab100_datamart_postprocessing              "@labtestuids = N'$LAB_OBS_UIDS', @debug = 0"
  run_dm_sp sp_lab101_datamart_postprocessing              "@lab_test_uids = N'$LAB_OBS_UIDS', @debug = 0"

  # Investigation summary + case_count + event_metric (all multi-arg)
  run_dm_sp sp_inv_summary_datamart_postprocessing         "@phc_uids = N'$PHC_UIDS', @notif_uids = N'$NOTIF_UIDS', @obs_uids = N'$OBS_UIDS', @debug = 0"
  run_dm_sp sp_nrt_case_count_postprocessing               "@phc_id_list = N'$PHC_UIDS'"
  run_dm_sp sp_event_metric_datamart_postprocessing        "@phc_uids = N'$PHC_UIDS', @obs_uids = N'$OBS_UIDS', @notif_uids = N'$NOTIF_UIDS', @ct_uids = N'$CT_UIDS', @vax_uids = N'$VAC_UIDS', @debug = 0"

  # PAM fact tables — MUST run before the condition-specific datamarts
  # (sp_tb_datamart_postprocessing reads F_TB_PAM; sp_var_datamart_postprocessing
  # reads F_VAR_PAM; sp_tb_hiv_datamart_postprocessing reads TB_DATAMART which
  # depends on F_TB_PAM). Bug #10: previously these ran AFTER the datamarts,
  # causing TB_DATAMART / TB_HIV_DATAMART (and likely VAR_DATAMART) to produce
  # 0 rows because their #PATIENT/#PROVIDER etc. temp tables INNER JOIN F_TB_PAM.
  run_dm_sp sp_f_tb_pam_postprocessing                     "@phc_id_list = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_f_var_pam_postprocessing                    "@phc_id_list = N'$PHC_UIDS', @debug = 0"

  # Condition-specific datamarts (will no-op without matching conditions)
  run_dm_sp sp_std_hiv_datamart_postprocessing             "@phc_id = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_var_datamart_postprocessing                 "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_tb_datamart_postprocessing                  "@phc_id_list = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_tb_hiv_datamart_postprocessing              "@phc_id_list = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_bmird_case_datamart_postprocessing          "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_bmird_strep_pneumo_datamart_postprocessing  "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_pertussis_case_datamart_postprocessing      "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_rubella_case_datamart_postprocessing        "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_crs_case_datamart_postprocessing            "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_measles_case_datamart_postprocessing        "@phc_uids = N'$PHC_UIDS', @debug = 0"

  # COVID datamarts (condition-gated to COVID; no-op for v1)
  run_dm_sp sp_covid_case_datamart_postprocessing          "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_covid_contact_datamart_postprocessing       "@phcid_list = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_covid_vaccination_datamart_postprocessing   "@vac_uids = N'$VAC_UIDS', @patient_uids = N'$PAT_UIDS', @debug = 0"
  run_dm_sp sp_covid_lab_celr_datamart_postprocessing      "@obs_uids = N'$LAB_OBS_UIDS', @debug = 0"
  run_dm_sp sp_covid_lab_datamart_postprocessing           "@observation_id_list = N'$LAB_OBS_UIDS', @debug = 0"

  # LDF datamarts (Phase 2 LDF expansion will populate these properly;
  # for now they no-op without LDF answers seeded)
  run_dm_sp sp_ldf_generic_datamart_postprocessing         "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_ldf_bmird_datamart_postprocessing           "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_ldf_mumps_datamart_postprocessing           "@phc_uids = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_ldf_foodborne_datamart_postprocessing       "@phc_id_list = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_ldf_tetanus_datamart_postprocessing         "@phc_id_list = N'$PHC_UIDS', @debug = 0"
  run_dm_sp sp_ldf_vaccine_prevent_diseases_datamart_postprocessing "@phc_id_list = N'$PHC_UIDS', @debug = 0"

  # Dynamic-datamart chain (sp_dyn_dm_main → invest_form / case_mgmt /
  # page_builder / provider / org / repeat* / createdm / dimension_update).
  # Populates DM_INV_<DATAMART_NAME> wide tables. Each datamart is keyed
  # to a specific FORM_CD via v_nrt_nbs_page; only Investigations whose
  # investigation_form_cd matches a row in that view will participate.
  # For v1: HEPATITIS_A_ACUTE (Hep A v2 + foundation) and STD (Syphilis
  # primary stub) populate. Other DATAMART_NMs (HEPATITIS_B_*, HIV,
  # ARBO_HUMAN, etc.) require Investigations with the corresponding
  # PG_*_Investigation form_cd — Phase 2 fixture additions.
  log "  dyn_dm chain — discover applicable datamarts via v_nrt_nbs_page"
  local dm_names
  dm_names=$(sql_q RDB_MODERN "SET NOCOUNT ON; SELECT DISTINCT v.DATAMART_NM FROM dbo.nrt_investigation i JOIN dbo.v_nrt_nbs_page v ON v.FORM_CD = i.investigation_form_cd ORDER BY v.DATAMART_NM" 2>/dev/null | tr -d '\r' | awk 'NF && !/^-/ && !/^$/ && !/rows affected/ && !/Changed database/ {print $1}')
  if [[ -z "$dm_names" ]]; then
    log "    (no Investigations match a v_nrt_nbs_page DATAMART_NM — skipping dyn_dm chain)"
  else
    for dm in $dm_names; do
      run_dm_sp sp_dyn_dm_main_postprocessing "@datamart_name = N'$dm', @phc_id_list = N'$PHC_UIDS', @debug = 'false'"
    done
  fi
}

# --------------------------------------------------------------------
# Final coverage summary
# --------------------------------------------------------------------

print_coverage_summary() {
  log "Coverage summary — row counts in RDB_MODERN target tables:"
  sql_q RDB_MODERN "
    SELECT 'D_PATIENT'             AS tbl, COUNT(*) AS rows FROM dbo.D_PATIENT WHERE PATIENT_UID >= 20000000 UNION ALL
    SELECT 'D_PROVIDER',                   COUNT(*) FROM dbo.D_PROVIDER WHERE PROVIDER_UID >= 20000000 UNION ALL
    SELECT 'D_ORGANIZATION',               COUNT(*) FROM dbo.D_ORGANIZATION WHERE ORGANIZATION_UID >= 20000000 UNION ALL
    SELECT 'D_PLACE',                      COUNT(*) FROM dbo.D_PLACE WHERE PLACE_UID >= 20000000 UNION ALL
    SELECT 'INVESTIGATION',                COUNT(*) FROM dbo.INVESTIGATION WHERE CASE_UID >= 20000000 UNION ALL
    SELECT 'NOTIFICATION',                 COUNT(*) FROM dbo.NOTIFICATION UNION ALL
    SELECT 'NOTIFICATION_EVENT',           COUNT(*) FROM dbo.NOTIFICATION_EVENT UNION ALL
    SELECT 'LAB_TEST',                     COUNT(*) FROM dbo.LAB_TEST WHERE LAB_TEST_UID >= 20000000 UNION ALL
    SELECT 'LAB_TEST_RESULT',              COUNT(*) FROM dbo.LAB_TEST_RESULT WHERE LAB_TEST_UID >= 20000000 UNION ALL
    SELECT 'MORBIDITY_REPORT',             COUNT(*) FROM dbo.MORBIDITY_REPORT WHERE morb_rpt_KEY > 1 UNION ALL
    SELECT 'MORBIDITY_REPORT_EVENT',       COUNT(*) FROM dbo.MORBIDITY_REPORT_EVENT UNION ALL
    SELECT 'D_INTERVIEW',                  COUNT(*) FROM dbo.D_INTERVIEW UNION ALL
    SELECT 'F_INTERVIEW_CASE',             COUNT(*) FROM dbo.F_INTERVIEW_CASE UNION ALL
    SELECT 'TREATMENT',                    COUNT(*) FROM dbo.TREATMENT WHERE TREATMENT_UID >= 20000000 UNION ALL
    SELECT 'TREATMENT_EVENT',              COUNT(*) FROM dbo.TREATMENT_EVENT UNION ALL
    SELECT 'D_VACCINATION',                COUNT(*) FROM dbo.D_VACCINATION WHERE VACCINATION_UID >= 20000000 UNION ALL
    SELECT 'F_VACCINATION',                COUNT(*) FROM dbo.F_VACCINATION UNION ALL
    SELECT 'D_CONTACT_RECORD',             COUNT(*) FROM dbo.D_CONTACT_RECORD UNION ALL
    SELECT 'F_CONTACT_RECORD_CASE',        COUNT(*) FROM dbo.F_CONTACT_RECORD_CASE
    ORDER BY tbl;
  "

  log "Connective-table row counts (NBS_ODSE):"
  sql_q NBS_ODSE "
    SELECT 'act_relationship'              AS tbl, COUNT(*) AS rows FROM dbo.act_relationship UNION ALL
    SELECT 'participation',                        COUNT(*) FROM dbo.participation UNION ALL
    SELECT 'nbs_act_entity',                       COUNT(*) FROM dbo.nbs_act_entity
    ORDER BY tbl;
  "
}

# --------------------------------------------------------------------
# Main
# --------------------------------------------------------------------

main() {
  log "merge_and_verify.sh — running full Merge contract sequence"
  log "fixtures root: $FIXTURES_ROOT"

  # Hold the shared db lock for the whole run. With a full reset this guards the
  # destructive `docker compose down -v` (volume drop); with --skip-reset it still
  # guards the load mutations. Released on any exit (success, error, or signal).
  local lock_who="merge_and_verify[$$]"
  [[ $SKIP_RESET -eq 0 ]] && lock_who="$lock_who FULL-RESET(down -v)" || lock_who="$lock_who load-only"
  acquire_db_lock "$lock_who" || { log "ERROR: could not acquire db lock; aborting"; exit 1; }
  trap 'release_db_lock' EXIT

  # No-NRT-shortcut flow: apply ODSE fixtures, then let CDC + the
  # reporting-pipeline-service reproduce nrt_* and run the *_event +
  # postprocessing + datamart SPs. We drain between tiers so Tier 2 edges are
  # processed against already-materialized Tier 1 entities. No manual SP EXEC.
  if [[ $SKIP_RESET -eq 0 ]]; then
    reset_baseline
  else
    log "Skipping baseline reset (--skip-reset)"
  fi

  apply_foundation
  apply_tier_1_fixtures
  log "Step 5: draining pipeline (Tier 1)..."; wait_for_pipeline_drain 300 || err "Tier 1 drain timed out (continuing)"

  if [[ $NO_TIER_2 -eq 1 ]]; then
    log "Stopping after Tier 1 (--no-tier-2)"
    print_coverage_summary
    return 0
  fi

  apply_tier_2_fixtures
  log "Step 7: draining pipeline (Tier 2 links)..."; wait_for_pipeline_drain 300 || err "Tier 2 drain timed out (continuing)"
  apply_tier_3_fixtures
  # Tier 3 carries the heaviest load (datamart SPs + large observation fixtures e.g. the
  # hepatitis obs chain's 139 obs). 420s was too short — drain gave up with the pipeline still
  # processing, mis-reporting coverage as ~20%. 900s covers current fixtures; if a future fixture
  # still overruns, the loop re-verifies service idle before trusting coverage_summary.
  #
  # LAB100/101 (zz_lab100_101_fill.sql, 22053xxx): NO manual re-processing is wired
  # here on purpose. The reporting-pipeline-service consumes the Tier-3 lab obs CDC
  # events during THIS drain and itself runs the full lab chain incl. the lab100/101
  # datamart SPs (PostProcessingService.processObservation:1245-1278). The fixture
  # header's "re-run lab postprocessing after Step-9" ORCH_TODO predated the
  # CDC-only flow and the dead manual EXEC helpers — adding it would be a no-op.
  # The keystone morb-fix (f26dc05b) stopped the OBSERVATION-priority morb-515 throw,
  # so the lab obs in the same batch are no longer fail-fast-skipped.
  log "Step 9: draining pipeline (Tier 3)..."; wait_for_pipeline_drain 900 || err "Tier 3 drain timed out (continuing)"

  print_coverage_summary
  log "Merge complete (CDC pipeline; no nrt_* shortcut)."
}

main "$@"
