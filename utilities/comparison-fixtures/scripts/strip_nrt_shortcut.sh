#!/usr/bin/env bash
# strip_nrt_shortcut.sh <fixture.sql> [<fixture.sql> ...]
# Removes the hand-authored nrt_* INSERT statements (the CDC-bypass shortcut) from
# fixture files, leaving the ODSE inserts intact. Under the real pipeline, nrt_*
# is reproduced from ODSE via CDC + sp_*_event + the reporting-pipeline-service.
# An nrt_* INSERT block is removed from the "INSERT INTO ...nrt_..." line through
# the first line ending in ';'. Comments are left in place.
set -euo pipefail
for f in "$@"; do
  [[ -f "$f" ]] || { echo "skip (missing): $f" >&2; continue; }
  before=$(grep -ciE 'INSERT[[:space:]]+INTO.*nrt_' "$f" || true)
  awk '
    skip==0 && /INSERT[ \t]+INTO/ && tolower($0) ~ /nrt_/ { skip=1 }
    skip==1 { l=$0; sub(/--.*$/,"",l); sub(/[ \t\r]+$/,"",l); if (l ~ /;$/) skip=0; next }
    { print }
  ' "$f" > "$f.stripped" && mv "$f.stripped" "$f"
  after=$(grep -ciE 'INSERT[[:space:]]+INTO.*nrt_' "$f" || true)
  echo "$f: nrt inserts $before -> $after"
done
