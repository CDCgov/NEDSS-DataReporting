#!/usr/bin/env bash
# db_lock.sh — atomic locking for parallel agents touching the live DB.
#
# macOS has no `flock(1)`, so we use the only POSIX-atomic primitive
# available everywhere: `mkdir`. Creating a directory is atomic — exactly
# one caller can create a given path; everyone else gets a non-zero
# exit. We sleep+retry until we win, then run the body, then rmdir.
#
# Usage:
#
#   source /path/to/db_lock.sh
#   acquire_db_lock "<who_am_i>"
#   trap 'release_db_lock' EXIT
#   # ...DB work...
#   release_db_lock
#   trap - EXIT
#
# Conventions:
# - Lock dir lives at /tmp/comparison-fixtures-db.lock
# - Holder identity is written to the lock dir's `holder` file for debugging
# - Stale locks (>30 min old) are auto-broken — assume holder died
# - Default poll interval 5s; configurable via DB_LOCK_POLL_SECONDS
# - Default wait timeout 1800s (30 min); configurable via DB_LOCK_TIMEOUT
# - On acquire, prints "[db_lock] acquired by <who>" so subagents log it

set -uo pipefail

readonly _LOCK_DIR="${COMPARISON_FIXTURES_DB_LOCK:-/tmp/comparison-fixtures-db.lock}"
readonly _LOCK_POLL_SECONDS="${DB_LOCK_POLL_SECONDS:-5}"
readonly _LOCK_TIMEOUT="${DB_LOCK_TIMEOUT:-1800}"
readonly _LOCK_STALE_AGE="${DB_LOCK_STALE_AGE:-1800}"

acquire_db_lock() {
  local who="${1:-unknown}"
  local elapsed=0

  while ! mkdir "$_LOCK_DIR" 2>/dev/null; do
    # Lock held by someone else. Check if stale (holder probably died).
    if [[ -d "$_LOCK_DIR" ]]; then
      local age
      age=$(($(date +%s) - $(stat -f %m "$_LOCK_DIR" 2>/dev/null || stat -c %Y "$_LOCK_DIR" 2>/dev/null || echo $(date +%s))))
      if (( age > _LOCK_STALE_AGE )); then
        local prev_holder
        prev_holder=$(cat "$_LOCK_DIR/holder" 2>/dev/null || echo "?")
        printf '[db_lock] breaking stale lock (age=%ds, prev_holder=%s)\n' "$age" "$prev_holder" >&2
        rm -rf "$_LOCK_DIR"
        continue
      fi
    fi

    if (( elapsed >= _LOCK_TIMEOUT )); then
      printf '[db_lock] FAILED to acquire within %ds (held by: %s)\n' \
        "$_LOCK_TIMEOUT" "$(cat "$_LOCK_DIR/holder" 2>/dev/null || echo '?')" >&2
      return 1
    fi

    if (( elapsed == 0 )); then
      printf '[db_lock] waiting (held by: %s)...\n' \
        "$(cat "$_LOCK_DIR/holder" 2>/dev/null || echo '?')" >&2
    fi
    sleep "$_LOCK_POLL_SECONDS"
    elapsed=$((elapsed + _LOCK_POLL_SECONDS))
  done

  printf '%s\n' "$who" > "$_LOCK_DIR/holder"
  printf '[db_lock] acquired by %s (waited %ds)\n' "$who" "$elapsed" >&2
}

release_db_lock() {
  local who="${1:-}"
  if [[ -d "$_LOCK_DIR" ]]; then
    local holder
    holder=$(cat "$_LOCK_DIR/holder" 2>/dev/null || echo '?')
    if [[ -n "$who" && "$who" != "$holder" ]]; then
      printf '[db_lock] WARNING: releasing lock held by %s as %s\n' "$holder" "$who" >&2
    fi
    rm -rf "$_LOCK_DIR"
    printf '[db_lock] released by %s\n' "${who:-$holder}" >&2
  fi
}
