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
  before=$(grep -ciE 'INSERT[[:space:]]+INTO.*nrt_|^[[:space:]]*EXEC[[:space:]]+(dbo\.)?sp_' "$f" || true)
  # Remove (a) nrt_* INSERT blocks and (b) manual postprocessing/event SP EXEC
  # blocks — both are CDC-bypass shortcuts. Under the real pipeline the SPs are
  # run by the reporting-pipeline-service, not the fixtures. Skip from the
  # match line through the first line ending in ';' (ignoring ';' in -- comments).
  awk '
    skip==0 && (( /INSERT[ \t]+INTO/ && tolower($0) ~ /nrt_/ ) || ( $0 ~ /^[ \t]*EXEC[ \t]+(dbo\.)?[Ss][Pp]_/ )) { skip=1 }
    skip==1 { l=$0; sub(/--.*$/,"",l); sub(/[ \t\r]+$/,"",l); if (l ~ /;$/) skip=0; next }
    { print }
  ' "$f" > "$f.stripped" && mv "$f.stripped" "$f"
  after=$(grep -ciE 'INSERT[[:space:]]+INTO.*nrt_|^[[:space:]]*EXEC[[:space:]]+(dbo\.)?sp_' "$f" || true)
  echo "$f: nrt inserts $before -> $after"
done
