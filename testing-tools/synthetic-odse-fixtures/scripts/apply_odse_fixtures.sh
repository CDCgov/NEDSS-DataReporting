#!/usr/bin/env bash
# apply_odse_fixtures.sh — load the synthetic ODSE fixture tiers into an
# already-running RTR stack, without resetting the database volume and without
# the coverage summary. This is the iterate-on-a-live-stack companion to
# merge_and_verify.sh, which always drops the volume and verifies.
#
# It delegates to merge_and_verify.sh so the tier / drain / post-drain logic
# lives in one place; this wrapper only flips the defaults.
#
# Usage:
#   ./scripts/apply_odse_fixtures.sh             # load fixtures onto the running stack
#   ./scripts/apply_odse_fixtures.sh --reset     # docker compose down -v && build && up first
#   ./scripts/apply_odse_fixtures.sh --verify    # also print the coverage summary at the end
#   ./scripts/apply_odse_fixtures.sh --no-tier-2 # stop after Tier 1
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

reset=0
verify=0
passthrough=()
for arg in "$@"; do
  case "$arg" in
    --reset)     reset=1 ;;
    --verify)    verify=1 ;;
    --no-tier-2) passthrough+=( --no-tier-2 ) ;;
    -h|--help)   sed -n '2,14p' "$0"; exit 0 ;;
    *)           echo "Unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# Default to merge_and_verify's "skip the destructive reset" and "skip coverage"
# paths; --reset / --verify opt back into the full behaviour.
args=()
if [[ $reset  -eq 0 ]]; then args+=( --skip-reset ); fi
if [[ $verify -eq 0 ]]; then args+=( --no-verify ); fi
if [[ ${#passthrough[@]} -gt 0 ]]; then args+=( "${passthrough[@]}" ); fi

if [[ ${#args[@]} -gt 0 ]]; then
  exec "$SCRIPT_DIR/merge_and_verify.sh" "${args[@]}"
else
  exec "$SCRIPT_DIR/merge_and_verify.sh"
fi
