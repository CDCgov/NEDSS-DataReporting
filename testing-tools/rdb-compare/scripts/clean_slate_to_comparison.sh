#!/usr/bin/env bash
# clean_slate_to_comparison.sh
# ---------------------------------------------------------------------------
# One command: clean slate -> populated RDB_MODERN (RTR) + RDB (MasterETL) ->
# rdb-compare report on disk.
#
# THE THREE STAGES (order matters):
#   1. merge_and_verify.sh   -> RDB_MODERN, via the real CDC/RTR pipeline.
#                               Does `docker compose down -v` FIRST, so it WIPES
#                               everything (incl. RDB). MUST run before MasterETL.
#   2. run_masteretl_local.sh -> RDB, via the legacy SAS/MasterETL container,
#                               reading the SAME NBS_ODSE that stage 1 loaded.
#   3. rdb-compare           -> out/comparison.{json,md}: RDB vs RDB_MODERN.
#
# Both RDB and RDB_MODERN live in the one mssql instance (localhost,3433,
# sa / PizzaIsGood33!), so the compare does cross-DB joins.
#
# RAM: the heavy combo is the full CDC stack + the SAS container at the same
# time (this is what OOM'd a small host before). By default this script STOPS
# the CDC pipeline services after stage 1 (RDB_MODERN is already persisted in
# mssql) so only mssql + SAS are up during MasterETL — much lower peak. Pass
# --keep-pipeline to leave them running. Watch `docker stats` if unsure.
#
# USAGE:
#   ./clean_slate_to_comparison.sh                 # full run, stages 1->2->3
#   ./clean_slate_to_comparison.sh --skip-merge    # RDB_MODERN already good
#   ./clean_slate_to_comparison.sh --skip-masteretl# only refresh RDB_MODERN+compare
#   ./clean_slate_to_comparison.sh --compare-only  # both DBs already populated
#   ./clean_slate_to_comparison.sh --keep-pipeline # don't stop CDC svcs for SAS
#
# Logs: /tmp/c2c_*.log . Final report: testing-tools/rdb-compare/out/comparison.md
# ---------------------------------------------------------------------------
set -uo pipefail   # NOT -e: MasterETL returns non-zero on expected SAS errors.

# --- paths ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RDB_COMPARE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
REPO_ROOT="$( cd "$RDB_COMPARE_DIR/../.." && pwd )"
FIXTURES_DIR="$REPO_ROOT/testing-tools/synthetic-odse-fixtures"
MERGE="$FIXTURES_DIR/scripts/merge_and_verify.sh"
MASTERETL="$FIXTURES_DIR/scripts/run_masteretl_local.sh"
MASTERETL_BRANCH="aw/masteretl-local-fixtures"

# --- db ---
SQLPASS='PizzaIsGood33!'
sql() { docker compose -f "$REPO_ROOT/docker-compose.yaml" exec -T nbs-mssql \
  /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SQLPASS" -C -h -1 -W \
  -Q "SET NOCOUNT ON; $1" 2>&1 | tr -d '\r'; }

# --- flags ---
SKIP_MERGE=0; SKIP_MASTERETL=0; KEEP_PIPELINE=0
for a in "$@"; do case "$a" in
  --skip-merge)     SKIP_MERGE=1 ;;
  --skip-masteretl) SKIP_MASTERETL=1 ;;
  --compare-only)   SKIP_MERGE=1; SKIP_MASTERETL=1 ;;
  --keep-pipeline)  KEEP_PIPELINE=1 ;;
  -h|--help)        sed -n '2,40p' "$0"; exit 0 ;;
  *) echo "unknown flag: $a" >&2; exit 2 ;;
esac; done

log()  { printf '\033[1;36m[c2c]\033[0m %s\n' "$*"; }
ram()  { free -h | awk '/^Mem:/{printf "RAM used=%s avail=%s\n",$3,$7}'; }
die()  { printf '\033[1;31m[c2c] FATAL:\033[0m %s\n' "$*" >&2; exit 1; }

cd "$REPO_ROOT" || die "cannot cd to repo root $REPO_ROOT"
command -v docker >/dev/null || die "docker not found"
[[ -x "$MERGE" ]] || die "missing $MERGE"

log "repo: $REPO_ROOT"; ram

# ===========================================================================
# STAGE 1 — RDB_MODERN via the RTR/CDC pipeline (down -v + full stack)
# ===========================================================================
if (( ! SKIP_MERGE )); then
  log "STAGE 1: merge_and_verify.sh (down -v; populate RDB_MODERN via CDC). ~5-20 min."
  if ! "$MERGE" 2>&1 | tee /tmp/c2c_merge.log | grep -E '\[merge\]|error|Error' ; then :; fi
  grep -q "Merge complete" /tmp/c2c_merge.log || die "merge_and_verify did not reach 'Merge complete' — see /tmp/c2c_merge.log"
  mp=$(sql "SELECT COUNT(*) FROM (SELECT t.name FROM RDB_MODERN.sys.tables t JOIN RDB_MODERN.sys.partitions p ON p.object_id=t.object_id AND p.index_id IN (0,1) GROUP BY t.name HAVING SUM(p.rows)>0) x;")
  log "RDB_MODERN populated tables: $mp"; ram
  [[ "${mp//[^0-9]/}" -gt 100 ]] || die "RDB_MODERN looks empty ($mp populated) after merge"
else
  log "STAGE 1 skipped (--skip-merge). Assuming RDB_MODERN already populated."
fi

# ===========================================================================
# STAGE 1.5 — free RAM for SAS: stop the CDC pipeline (mssql keeps the data)
# ===========================================================================
if (( ! SKIP_MASTERETL )) && (( ! KEEP_PIPELINE )); then
  log "STAGE 1.5: stopping CDC pipeline services (mssql stays up; RDB_MODERN persists) to free RAM for SAS."
  docker compose stop kafka-connect debezium reporting-pipeline-service kafka wildfly >/dev/null 2>&1 || true
  ram
fi

# ===========================================================================
# STAGE 2 — RDB via MasterETL (SAS container). Heavy/RAM step.
# ===========================================================================
if (( ! SKIP_MASTERETL )); then
  # Ensure the MasterETL wrapper exists (it lives on a sibling branch).
  if [[ ! -f "$MASTERETL" ]]; then
    log "extracting run_masteretl_local.sh from $MASTERETL_BRANCH"
    git show "$MASTERETL_BRANCH:utilities/comparison-fixtures/scripts/run_masteretl_local.sh" \
      > "$MASTERETL" 2>/dev/null || die "could not extract run_masteretl_local.sh from $MASTERETL_BRANCH"
    chmod +x "$MASTERETL"
  fi

  # Known gotcha: a stale sas container from a prior run holds a dead network
  # ref -> "network ... not found". Remove it so the new one attaches cleanly.
  if docker ps -a --format '{{.Names}}' | grep -qx 'nedss-datareporting-sas-1'; then
    log "removing stale sas container (network-ref guard)"
    docker rm -f nedss-datareporting-sas-1 >/dev/null 2>&1 || true
  fi

  log "STAGE 2: run_masteretl_local.sh (SAS up, autoexec fix, MasterEtl.sh -> RDB). ~5-15 min."
  log "  NOTE: MasterETL reports ~100+ SAS errors for disease families the fixtures don't seed"
  log "  (BMIRD/strep, ABCs, congenital) and EXITS NON-ZERO. That is EXPECTED — we verify RDB"
  log "  by row counts, not by exit code."
  "$MASTERETL" 2>&1 | tee /tmp/c2c_masteretl.log | grep -E '\[masteretl\]|ERROR' || true

  rp=$(sql "SELECT COUNT(*) FROM (SELECT t.name FROM RDB.sys.tables t JOIN RDB.sys.partitions p ON p.object_id=t.object_id AND p.index_id IN (0,1) GROUP BY t.name HAVING SUM(p.rows)>0) x;")
  inv=$(sql "SELECT COUNT(*) FROM RDB.dbo.INVESTIGATION;")
  log "RDB populated tables: $rp   (RDB.INVESTIGATION rows: $inv)"; ram
  [[ "${rp//[^0-9]/}" -gt 100 ]] || die "RDB looks empty ($rp populated) after MasterETL — inspect /tmp/c2c_masteretl.log and the SAS logs"
else
  log "STAGE 2 skipped (--skip-masteretl). Assuming RDB already populated."
fi

# ===========================================================================
# STAGE 3 — the comparison
# ===========================================================================
log "STAGE 3: rdb-compare RDB vs RDB_MODERN."
cd "$RDB_COMPARE_DIR" || die "cannot cd to $RDB_COMPARE_DIR"
uv run rdb-compare --host localhost --port 3433 --user sa \
  --rdb RDB --modern RDB_MODERN --out ./out --progress --query-timeout 120 \
  2>&1 | tee /tmp/c2c_compare.log

echo
log "DONE. Report: $RDB_COMPARE_DIR/out/comparison.md (+ comparison.json)"
log "Interpret per testing-tools/synthetic-odse-fixtures/ docs:"
log "  expect NEW diffs to cluster (encoding mojibake from SAS latin1, NULL-vs-''),"
log "  and RDB-only/MODERN-only presence gaps that are legitimate RTR-vs-MasterETL"
log "  coverage differences (catalog/odse_unknown_tables.md lists MasterETL-only tables)."
ram
