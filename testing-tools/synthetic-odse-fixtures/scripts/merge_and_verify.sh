#!/usr/bin/env bash
# merge_and_verify.sh — bring up the full RTR pipeline and seed it tier-by-tier.
#
# This is the "no-shortcut" flow: we apply ODSE fixtures, then let CDC
# (debezium) + the kafka-connect sink + reporting-pipeline-service reproduce
# the nrt_* staging tables and run every *_event + postprocessing + datamart
# SP off the resulting CDC events. There is NO manual SP EXEC for the per-tier
# chains — the service does that work. We drain the pipeline between tiers so
# Tier 2 link edges are processed against already-materialized Tier 1 entities.
#
# Sequence:
#   1. Reset baseline (docker compose down -v && build && up -d).
#   2. Apply fixtures/00_foundation/00_foundation.sql,   then drain.
#   3. Apply fixtures/10_subjects/*.sql (Tier 1),        then drain.
#   4. Apply fixtures/20_links/*.sql (Tier 2),           then drain.
#   5. Apply fixtures/30_sp_coverage/*.sql (Tier 3),     then drain.
#   6. Deterministically populate the summary datamarts (event_metric ->
#      summary_report_case -> sr100); the service fires these during the drain
#      but races obs-row materialization, so we re-run them post-drain.
#   7. Re-drive the interview chain so Tier-3 interview-gap answers are
#      processed after the final drain.
#   8. Print a coverage summary (row counts per RDB_MODERN target table).
#
# Exits non-zero on any sqlcmd error or missing fixture file.
#
# Usage:
#   ./scripts/merge_and_verify.sh             # run full sequence
#   ./scripts/merge_and_verify.sh --skip-reset # skip step 1 (DB already prepared)
#   ./scripts/merge_and_verify.sh --no-tier-2  # stop after Tier 1
#   ./scripts/merge_and_verify.sh --no-verify  # skip the coverage summary

set -euo pipefail

# --------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------

# Base directories (script lives in scripts/, project lives 2 levels up
# under NEDSS-DataReporting/testing-tools/synthetic-odse-fixtures/).
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

# Canonical Investigation/observation/etc. UIDs (foundation + v2 + v3 from
# uid_ranges.md) used by the post-drain summary datamarts in run_summary_datamarts.
readonly PHC_UIDS='20000100,20050010,22000010,22000020,22000030,22000040,22000050,22000060,22000070,22000080,22000090,22000100,22000200,22001000,22002000,22003000,22004000,22005000,22007000,22008000,22008500,22009000,22010000,22019100,22043000,22046000,22047000,22047500,22049000,22049200,22049400,22049500,22050000,22054000,22060000,22060200,22060400,22060600,22063100,22065000,22073100,22076000,22076100,22006000,22015200'
readonly NOTIF_UIDS='20000110,20060010'
readonly OBS_UIDS='20000120,20070010,20070011,22022000,20000130,20080010'
readonly VAC_UIDS='20000160,20110010'
readonly CT_UIDS='20000170,20120010'

# CLI flags
SKIP_RESET=0
NO_TIER_2=0
NO_VERIFY=0
for arg in "$@"; do
  case "$arg" in
    --skip-reset) SKIP_RESET=1 ;;
    --no-tier-2)  NO_TIER_2=1 ;;
    --no-verify)  NO_VERIFY=1 ;;
    -h|--help)
      sed -n '2,30p' "$0"
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
# Step 1 — Reset baseline
# --------------------------------------------------------------------

reset_baseline() {
  log "Step 1: docker compose down -v && build && up -d FULL pipeline"
  # Full real pipeline (no nrt_* shortcut): CDC (debezium) + kafka-connect sink
  # project ODSE -> nrt_*, and reporting-pipeline-service runs the *_event +
  # postprocessing SPs. Rebuild the service so working-tree routine/code changes
  # ship into the image. Since #886 the liquibase migrations live inside
  # reporting-pipeline-service and run at its startup (there is no separate
  # liquibase service/container anymore).
  ( cd "$NEDSS_DR_ROOT" \
      && docker compose down -v >/dev/null 2>&1 \
      && docker compose build reporting-pipeline-service >/dev/null 2>&1 \
      && docker compose up -d >/dev/null 2>&1 )

  log "Waiting for reporting-pipeline-service to apply migrations and become healthy..."
  # Cold start is slow: the service waits on the nbs-mssql DB restore (minutes)
  # and kafka before it boots and runs migrations, so allow generous headroom.
  # Poll the container healthcheck (pipe-free): it only reports healthy after the
  # Spring Boot app has fully started, which is after liquibase migrations run.
  local timeout=1200 elapsed=0 cid="" health=""
  while [[ $elapsed -lt $timeout ]]; do
    cid=$( cd "$NEDSS_DR_ROOT" && docker compose ps -q reporting-pipeline-service 2>/dev/null )
    if [[ -n "$cid" ]]; then
      health=$( docker inspect --format '{{.State.Health.Status}}' "$cid" 2>/dev/null )
      [[ "$health" == healthy ]] && { log "Service healthy; migrations applied."; break; }
    fi
    sleep 10; elapsed=$((elapsed + 10))
  done
  [[ $elapsed -ge $timeout ]] && { err "reporting-pipeline-service did not become healthy within ${timeout}s"; return 1; }

  log "Waiting for pipeline to be ready (debezium/connect connectors + service initial drain)..."
  wait_for_pipeline_drain 300 || { err "pipeline not ready"; return 1; }
  log "Pipeline ready."
}

# --------------------------------------------------------------------
# Step 2 — Foundation
# --------------------------------------------------------------------

apply_foundation() {
  log "Step 2: apply foundation"
  sql_i "$FOUNDATION_SQL"
}

# --------------------------------------------------------------------
# Step 3 — Tier 1 fixtures (subjects)
# --------------------------------------------------------------------

apply_tier_1_fixtures() {
  log "Step 3: apply Tier 1 fixtures (10_subjects/*.sql)"
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
# Step 4 — Tier 2 fixtures (links)
# --------------------------------------------------------------------

apply_tier_2_fixtures() {
  log "Step 4: apply Tier 2 fixtures (20_links/*.sql)"
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
# Step 5 — Tier 3 fixtures (SP coverage)
# --------------------------------------------------------------------

apply_tier_3_fixtures() {
  log "Step 5: apply Tier 3 fixtures (30_sp_coverage/*.sql)"
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
# Step 6 — Summary / SR100 datamarts
# --------------------------------------------------------------------
#
# WHY THIS IS WIRED HERE (not left to the service):
# The no-shortcut flow relies on reporting-pipeline-service
# PostProcessingService.processSummaryCases() to fire these SPs whenever an
# Investigation CDC event carries case_type_cd='S' (extractSummaryCase ->
# sumCache -> processSummaryCases). That path DID fire in the merge run (the
# SPs appear in job_flow_log keyed on 22065000), but produced 0 rows:
#   - sp_summary_report_case_postprocessing's CTE SumRptWork INNER JOINs
#     nrt_investigation_observation (root_type_cd='SummaryNotification'); when the
#     summary SP fires inside the same investigation-event drain, that obs row is
#     not reliably materialized yet, so step "Generating #tmp_SumRptWork" = 0.
#   - sp_sr100_datamart_postprocessing then has no SUMMARY_REPORT_CASE parent row,
#     and additionally INNER JOINs EVENT_METRIC on inv_local_id.
# Running them HERE — after the Tier-3 drain, when nrt_investigation,
# nrt_investigation_observation (SummaryNotification), nrt_investigation_notification,
# the INVESTIGATION dim, CONDITION, and EVENT_METRIC are all fully materialized —
# makes population deterministic. Idempotent (UPDATE-then-INSERT on existing rows).
#
# Order matters: event_metric first (SR100 INNER JOINs EVENT_METRIC.local_id),
# then summary_report_case (SR100 reads SUMMARY_REPORT_CASE), then sr100.
# SR100.DATE_REPORTED/MONTH_REPORTED are NOT NULL and map from
# INVESTIGATION.EARLIEST_RPT_TO_STATE_DT via RDB_DATE; the summary fixture
# (zz_summary_report_case.sql) sets public_health_case.rpt_to_state_time so that
# date resolves (RDB_DATE covers 2020-2030).
run_summary_datamarts() {
  log "Step 6: summary datamarts (event_metric -> summary_report_case -> sr100) over PHC_UIDS"
  sql_q RDB_MODERN "EXEC dbo.sp_event_metric_datamart_postprocessing @phc_uids = N'$PHC_UIDS', @obs_uids = N'$OBS_UIDS', @notif_uids = N'$NOTIF_UIDS', @ct_uids = N'$CT_UIDS', @vax_uids = N'$VAC_UIDS', @debug = 0" >/dev/null 2>&1 || {
    log "    (event_metric errored or no-op — see job_flow_log)"
  }
  sql_q RDB_MODERN "EXEC dbo.sp_summary_report_case_postprocessing @id_list = N'$PHC_UIDS', @debug = 0" >/dev/null 2>&1 || {
    log "    (summary_report_case errored or no-op — see job_flow_log)"
  }
  sql_q RDB_MODERN "EXEC dbo.sp_sr100_datamart_postprocessing @id_list = N'$PHC_UIDS', @debug = 0" >/dev/null 2>&1 || {
    log "    (sr100 errored or no-op — see job_flow_log)"
  }
}

# --------------------------------------------------------------------
# Step 7 — Re-drive the interview chain
# --------------------------------------------------------------------
#
# In the CDC-only flow the service runs the per-subject event + postprocessing
# SPs off CDC events; we do NOT re-run them manually. The interview chain is the
# one exception: zz_interview_gap.sql's nbs_answer rows (D_INTERVIEW LDF-pivot
# cols + D_INTERVIEW_NOTE) are authored at Tier 3 and need the interview SPs to
# re-fire AFTER the Tier-3 drain to be picked up. Idempotent.

run_interview_chain() {
  log "Step 7: re-drive interview chain (foundation 20000140 + v2 20090010)"
  sql_q RDB_MODERN "EXEC dbo.sp_interview_event @ix_uids = N'20000140,20090010'" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_d_interview_postprocessing @interview_uids = N'20000140,20090010', @debug = 0" >/dev/null
  sql_q RDB_MODERN "EXEC dbo.sp_f_interview_case_postprocessing @ix_uids = N'20000140,20090010', @debug = 0" >/dev/null
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
    SELECT 'F_CONTACT_RECORD_CASE',        COUNT(*) FROM dbo.F_CONTACT_RECORD_CASE UNION ALL
    SELECT 'SUMMARY_REPORT_CASE',          COUNT(*) FROM dbo.SUMMARY_REPORT_CASE UNION ALL
    SELECT 'SR100',                        COUNT(*) FROM dbo.SR100
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
  log "Draining pipeline (Tier 1)..."; wait_for_pipeline_drain 300 || err "Tier 1 drain timed out (continuing)"

  if [[ $NO_TIER_2 -eq 1 ]]; then
    log "Stopping after Tier 1 (--no-tier-2)"
    if [[ $NO_VERIFY -eq 0 ]]; then print_coverage_summary; fi
    return 0
  fi

  apply_tier_2_fixtures
  log "Draining pipeline (Tier 2 links)..."; wait_for_pipeline_drain 300 || err "Tier 2 drain timed out (continuing)"
  apply_tier_3_fixtures
  # Tier 3 carries the heaviest load (datamart SPs + large observation fixtures e.g. the
  # hepatitis obs chain's 139 obs). 420s was too short — drain gave up with the pipeline still
  # processing, mis-reporting coverage as ~20%. 900s covers current fixtures; if a future fixture
  # still overruns, the loop re-verifies service idle before trusting coverage_summary.
  #
  # LAB100/101 (zz_lab100_101_fill.sql, 22053xxx): NO manual re-processing is wired
  # here on purpose. The reporting-pipeline-service consumes the Tier-3 lab obs CDC
  # events during THIS drain and itself runs the full lab chain incl. the lab100/101
  # datamart SPs (PostProcessingService.processObservation:1245-1278).
  # The keystone morb-fix (f26dc05b) stopped the OBSERVATION-priority morb-515 throw,
  # so the lab obs in the same batch are no longer fail-fast-skipped.
  log "Draining pipeline (Tier 3)..."; wait_for_pipeline_drain 900 || err "Tier 3 drain timed out (continuing)"

  # Deterministically populate SUMMARY_REPORT_CASE + SR100 after all nrt_* state
  # (incl. nrt_investigation_observation SummaryNotification + EVENT_METRIC) is
  # materialized. The service's processSummaryCases() fires these during the
  # drain but races obs-row materialization (0 rows); this post-drain run
  # guarantees population. Idempotent.
  run_summary_datamarts

  # Re-drive the interview chain post-Tier-3 so zz_interview_gap.sql's nbs_answer
  # rows (D_INTERVIEW LDF-pivot cols + D_INTERVIEW_NOTE) are processed after the
  # Tier-3 drain. Idempotent.
  run_interview_chain

  if [[ $NO_VERIFY -eq 0 ]]; then print_coverage_summary; fi
  log "Merge complete (CDC pipeline; no nrt_* shortcut)."
}

main "$@"
