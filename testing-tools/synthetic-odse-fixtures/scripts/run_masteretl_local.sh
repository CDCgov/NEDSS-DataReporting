#!/usr/bin/env bash
# run_masteretl_local.sh — run legacy MasterETL (the SAS container) against the
# locally-loaded NBS_ODSE, with a workaround for an upstream SAS-image bug.
#
# Use after loading fixtures (scripts/merge_and_verify.sh) to check that the
# synthetic ODSE data flows through MasterETL into the legacy RDB database.
#
# ---------------------------------------------------------------------------
# UPSTREAM BUG worked around here (image ghcr.io/cdcent/nbs7-sas-linux:v1.0.4):
#   /home/SAS/2_runtime.sh "Updating DB connections" templates the DB password
#   into report/autoexec.sas with fragile sed patterns, e.g.
#       sed -i "s|DSN=nedss1.*PASSWORD=.*s|...PASSWORD=$odse_pass|g"
#   The trailing `s` anchor is meant to end the match after the password, but
#   it instead matches the `s` INSIDE the baked default `PizzaIsGood33!Good33!`
#   ("PizzaI[s]"), so the greedy `.*s` stops mid-password and the leftover
#   `Good33!` tail survives — yielding PASSWORD=PizzaIsGood33!Good33! for the
#   nedss1 / nbs_srt / nbs_msg ODBC librefs (nbs_rdb's `b` anchor escapes it).
#   Result: SAS LIBNAME auth fails ("Login failed for user 'sa'") and MasterETL
#   aborts before reading any data. No password value avoids it — the bad tail
#   comes from the image's template, not from our env.
#
# This script corrects the ODBC LIBNAME PASSWORD values in autoexec.sas to the
# real password after the container starts, then runs MasterEtl.sh. It is
# idempotent and safe to re-run.
# ---------------------------------------------------------------------------
set -euo pipefail

readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly NEDSS_DR_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"
readonly PASS="${DATABASE_PASSWORD:-PizzaIsGood33!}"
readonly AUTOEXEC="/opt/wildfly-10.0.0.Final/nedssdomain/Nedss/report/autoexec.sas"
readonly REPORT_DIR="$( dirname "$AUTOEXEC" )"
readonly LOGDIR="/opt/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log"
readonly MASTERETL="/opt/wildfly-10.0.0.Final/nedssdomain/Nedss/BatchFiles/MasterEtl.sh"

# Source of the latest SAS / MasterETL code (NEDSSDev main == v6.0.19.x). The
# baked image (nbs7-sas-linux:v1.0.4) carries an older snapshot, so we overlay
# the current code on top of report/ before running, exactly as the NEDSSDev
# build does (pom.xml: reportsrc.dir=source/sas -> reportdest.dir=.../report).
readonly NEDSSDEV_SAS_SRC="${NEDSSDEV_SAS_SRC:-$( cd "$NEDSS_DR_ROOT/.." && pwd )/NEDSSDev/source/sas}"
# Program subtrees to overlay. autoexec.sas is intentionally EXCLUDED: the image
# entrypoint templates report/autoexec.sas (linux ODBC LIBNAMEs) and we repair
# its passwords below, so the configured linux autoexec must survive. Docs/ and
# testdata/ are build-time only and not needed at runtime.
readonly SAS_OVERLAY_DIRS="custom dm dw metadata pgm phdc template util"

log() { printf '\033[1;36m[masteretl]\033[0m %s\n' "$*"; }

cd "$NEDSS_DR_ROOT"

log "Bringing up the sas container (profile-gated)..."
# --force-recreate: a prior `down -v` (e.g. from merge_and_verify.sh) drops and
# recreates the compose network, but the profile-gated sas container is NOT
# recreated by that up, so it lingers bound to the now-deleted network and a
# plain `up sas` fails with "network <id> not found". Recreating it fresh binds
# it to the current network. stderr is left visible so a real failure surfaces
# instead of aborting silently after this line.
docker compose up sas -d --force-recreate >/dev/null

log "Waiting for SAS Connect Spawner to initialize..."
for _ in $(seq 1 30); do
  if docker logs nedss-datareporting-sas-1 2>&1 | grep -q "SAS Connect Spawner has completed initialization"; then
    log "SAS ready."
    break
  fi
  sleep 5
done

# ---------------------------------------------------------------------------
# Overlay the latest SAS / MasterETL code (v6.0.19.x) from NEDSSDev onto the
# image's older baked copy. Idempotent: docker cp merges each subtree into
# report/ (overwriting same-named files, leaving image-only files in place).
# The source tree is LF; SAS-on-linux reads LF natively.
# ---------------------------------------------------------------------------
if [[ -d "$NEDSSDEV_SAS_SRC" ]]; then
  log "Overlaying 6.0.19.x SAS code from ${NEDSSDEV_SAS_SRC} onto report/ ..."
  for d in $SAS_OVERLAY_DIRS; do
    [[ -d "$NEDSSDEV_SAS_SRC/$d" ]] || continue
    docker compose cp "$NEDSSDEV_SAS_SRC/$d" "sas:${REPORT_DIR}/" >/dev/null
  done
  # docker cp lands files as root; MasterETL runs as the SAS user, so make the
  # overlaid trees owned/readable by it (best-effort).
  docker compose exec -u root -T sas sh -c \
    "cd '${REPORT_DIR}' && chown -R SAS ${SAS_OVERLAY_DIRS} 2>/dev/null; chmod -R u+rwX,go+rX ${SAS_OVERLAY_DIRS} 2>/dev/null || true"
  log "SAS code overlay complete (subtrees: ${SAS_OVERLAY_DIRS})."
else
  log "WARNING: NEDSSDev SAS source not found at ${NEDSSDEV_SAS_SRC} — running with the image's baked SAS code (set NEDSSDEV_SAS_SRC to override)."
fi

log "Repairing autoexec.sas ODBC LIBNAME passwords (upstream sed-mangling workaround)..."
# Set every `libname <x> ODBC DSN=... UID=... PASSWORD=<token>` to the real
# password, regardless of how the entrypoint mangled it.
docker compose exec -u SAS -T sas sh -c \
  "sed -i -E 's#(libname [a-z_]+ ODBC DSN=[^ ]+ UID=[^ ]+ PASSWORD=)[^ ;]+#\\1${PASS}#g' '${AUTOEXEC}'"

# A correctly-set value is followed by a space or ';'; a leftover-tail mangle
# (e.g. PASSWORD=PizzaIsGood33!Good33!) is the password immediately followed by
# another non-terminator char.
bad=$(docker compose exec -u SAS -T sas sh -c "grep -cE 'PASSWORD=${PASS}[^ ;]' '${AUTOEXEC}' || true" 2>/dev/null | tr -d '\r')
log "autoexec.sas LIBNAME passwords normalized (mangled lines remaining: ${bad:-0})."

# MASTERETL_MONOLITH=1 runs the self-contained MasterEtl.sas (which %includes
# Page_Case.sas + INV_SUMM_DATAMART.sas and their upstream deps) instead of the
# MasterEtl.sh split (MasterEtl1.sas + MasterEtl2.sas), which omits them and so
# never builds F_PAGE_CASE / INV_SUMM_DATAMART.
readonly SAS_BIN="/opt/sas9.4/install/SASHome/SASFoundation/9.4/sasexe/sas"
readonly SAS_CFG="/opt/sas9.4/install/SASHome/SASFoundation/9.4/sasv9.cfg"
if [[ -n "${MASTERETL_MONOLITH:-}" ]]; then
  log "Running monolith MasterEtl.sas (Page_Case + INV_SUMM_DATAMART included)..."
  docker compose exec -u SAS -T sas sh -c \
    "${SAS_BIN} -sysin '${REPORT_DIR}/dw/etl/src/MasterEtl.sas' -nosyntaxcheck -print '${LOGDIR}/MasterEtl.lst' -log '${LOGDIR}/MasterEtl.log' -config '${SAS_CFG}' -autoexec '${AUTOEXEC}'" || true
  readonly ETL_LOGS="MasterEtl"
else
  log "Running MasterETL..."
  docker compose exec -u SAS -T sas sh -c "${MASTERETL}"
  readonly ETL_LOGS="Drop_Create_Tables MasterETL1 SSIS MasterEtl2 DynamicDatamart"
fi

log "MasterETL finished. SAS log ERROR counts:"
total=0
for f in ${ETL_LOGS}; do
  n=$(docker compose exec -u SAS -T sas sh -c "grep -c '^ERROR' '${LOGDIR}/${f}.log' 2>/dev/null || true" 2>/dev/null | tr -d '\r')
  n=${n:-0}
  printf '  %-22s %s ERROR\n' "${f}.log" "$n"
  total=$((total + n))
done
if [[ "$total" -eq 0 ]]; then
  log "SUCCESS — MasterETL ran clean (0 SAS errors)."
else
  log "MasterETL reported $total SAS error(s) — inspect ${LOGDIR}/*.log"
  exit 1
fi
