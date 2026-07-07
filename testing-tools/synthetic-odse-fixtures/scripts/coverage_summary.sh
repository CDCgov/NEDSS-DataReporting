#!/usr/bin/env bash
# coverage_summary.sh — produce a project-wide coverage report against
# the merged-fixture state of RDB_MODERN.
#
# For every in-scope target table in catalog/rtr_target_columns.md,
# count populated rows + populated columns. Outputs a markdown summary
# to coverage/coverage_merged.md.
#
# Pre-condition: scripts/merge_and_verify.sh has run successfully.
# Otherwise the report will show all-empty.
#
# Usage: ./scripts/coverage_summary.sh
# Output: coverage/coverage_merged.md

set -euo pipefail

readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly FIXTURES_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
readonly CATALOG="$FIXTURES_ROOT/catalog/rtr_target_columns.md"
readonly OUTPUT="$FIXTURES_ROOT/coverage/coverage_merged.md"

export SQLCMDPASSWORD="${SQLCMDPASSWORD:-PizzaIsGood33!}"
readonly SQLCMD='sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -h -1'

# Extract the in-scope target table names from the Phase 0 catalog.
# Lines like `### dbo.<TABLE>` under the Per-table breakdown section.
# Skip views, staging tables (nrt_*, tmp_*), dynamic placeholders.
extract_tables() {
  awk '
    /^## Dynamic-SQL targets/    {p=0}
    /^## Intermediate/           {p=0}
    /^## Views/                  {p=0}
    /^## Per-table breakdown/    {p=1; next}
    p && /^### dbo\./ {
      gsub(/^### dbo\./, "")
      gsub(/[ \t\r]*$/, "")
      if ($0 !~ /^v_nrt|^nrt_|^tmp_/) print tolower($0)
    }
  ' "$CATALOG" | sort -u
}

# For one table, return: row_count, total_cols, populated_cols (cols with ≥1 non-NULL row)
# Output: TAB-separated "<rows>\t<total_cols>\t<populated_cols>"
inspect_table() {
  local tbl="$1"

  # First, does the table exist in live RDB_MODERN?
  local exists
  exists=$( $SQLCMD -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.tables WHERE name='$tbl'" 2>/dev/null | tr -dc '0-9' )
  if [[ "$exists" != "1" ]]; then
    echo -e "MISSING\t0\t0"
    return
  fi

  # Total columns
  local total_cols
  total_cols=$( $SQLCMD -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('dbo.$tbl')" 2>/dev/null | tr -dc '0-9' )

  # Row count
  local row_count
  row_count=$( $SQLCMD -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.[$tbl]" 2>/dev/null | tr -dc '0-9' )

  if [[ "$row_count" == "0" ]]; then
    echo -e "0\t$total_cols\t0"
    return
  fi

  # Populated columns: SUM(CASE WHEN col IS NOT NULL THEN 1 ELSE 0 END) for each column,
  # then count how many SUMs are > 0.
  local populated_sql
  populated_sql=$( $SQLCMD -Q "
    SET NOCOUNT ON;
    DECLARE @sql nvarchar(max) = N'SELECT ';
    SELECT @sql = @sql + 'CASE WHEN SUM(CASE WHEN [' + name + '] IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END + '
      FROM sys.columns WHERE object_id=OBJECT_ID('dbo.$tbl');
    SET @sql = LEFT(@sql, LEN(@sql)-2) + ' AS populated FROM dbo.[$tbl]';
    EXEC sp_executesql @sql;
  " 2>/dev/null | tr -dc '0-9\n' | grep -v '^$' | head -1 )

  echo -e "${row_count}\t${total_cols}\t${populated_sql:-0}"
}

main() {
  local tables
  tables=$(extract_tables)
  local total
  total=$(echo "$tables" | wc -l | tr -d ' ')

  echo "[coverage] Inspecting $total in-scope tables..." >&2

  # Categorize as we go
  local fully_covered=()
  local partially_covered=()
  local empty=()
  local missing=()

  # Tracking for summary stats
  local total_columns_in_scope=0
  local total_columns_covered=0

  # Build the per-table table content
  local table_rows=""
  local table_count=0
  while IFS= read -r tbl; do
    [[ -z "$tbl" ]] && continue
    table_count=$((table_count + 1))
    if (( table_count % 10 == 0 )); then
      echo "[coverage]   ... $table_count / $total" >&2
    fi

    local result
    result=$(inspect_table "$tbl")
    local rows total_cols pop_cols
    IFS=$'\t' read -r rows total_cols pop_cols <<< "$result"

    if [[ "$rows" == "MISSING" ]]; then
      missing+=("$tbl")
      table_rows+="| dbo.$tbl | MISSING | - | - |"$'\n'
      continue
    fi

    total_columns_in_scope=$((total_columns_in_scope + total_cols))
    total_columns_covered=$((total_columns_covered + pop_cols))

    if [[ "$rows" == "0" ]]; then
      empty+=("$tbl")
      table_rows+="| dbo.$tbl | 0 | $total_cols | 0/$total_cols |"$'\n'
    elif [[ "$pop_cols" == "$total_cols" ]]; then
      fully_covered+=("$tbl")
      table_rows+="| dbo.$tbl | $rows | $total_cols | **$pop_cols/$total_cols** |"$'\n'
    else
      partially_covered+=("$tbl")
      table_rows+="| dbo.$tbl | $rows | $total_cols | $pop_cols/$total_cols |"$'\n'
    fi
  done <<< "$tables"

  echo "[coverage]   done. Writing $OUTPUT" >&2

  cat > "$OUTPUT" <<HEADER
# Coverage: merged fixture (full chain)

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')

This report is produced by \`scripts/coverage_summary.sh\` against the
RDB_MODERN state after \`scripts/merge_and_verify.sh\` has run end-to-end.
It iterates every in-scope target table from
\`catalog/rtr_target_columns.md\` and counts populated rows + populated
columns.

A column is "populated" if at least one row has a non-NULL value for it.

## Summary

- In-scope target tables: $total
- Fully covered (all columns populated for at least one row): ${#fully_covered[@]}
- Partially covered (some columns populated): ${#partially_covered[@]}
- Empty (table exists, 0 rows): ${#empty[@]}
- Missing (table not present in live RDB_MODERN): ${#missing[@]}

- Total columns across in-scope tables: $total_columns_in_scope
- Columns with ≥1 populated row: $total_columns_covered
- Overall column coverage: $(awk -v a=$total_columns_covered -v b=$total_columns_in_scope 'BEGIN { if (b>0) printf "%.1f%%", 100*a/b; else print "n/a" }')

## Per-table coverage

| Table | Rows | Total cols | Populated cols |
| ----- | ---- | ---------- | -------------- |
${table_rows}

## Categorization

### Fully covered (${#fully_covered[@]})

Tables where every column has at least one row with a non-NULL value.

HEADER

  if [[ ${#fully_covered[@]} -gt 0 ]]; then
    printf -- '- dbo.%s\n' "${fully_covered[@]}" >> "$OUTPUT"
  else
    echo "_(none)_" >> "$OUTPUT"
  fi

  cat >> "$OUTPUT" <<SECTION

### Partially covered (${#partially_covered[@]})

Tables with rows but at least one column never populated. These are the
candidates for Tier 3 gap-driven coverage work.

SECTION

  if [[ ${#partially_covered[@]} -gt 0 ]]; then
    printf -- '- dbo.%s\n' "${partially_covered[@]}" >> "$OUTPUT"
  else
    echo "_(none)_" >> "$OUTPUT"
  fi

  cat >> "$OUTPUT" <<SECTION

### Empty (${#empty[@]})

Tables that exist in RDB_MODERN but have zero rows after the merged
chain runs. Most are datamart-side fact tables that depend on Merge
contract step 9 (Datamart SPs — out of scope for v1).

SECTION

  if [[ ${#empty[@]} -gt 0 ]]; then
    printf -- '- dbo.%s\n' "${empty[@]}" >> "$OUTPUT"
  else
    echo "_(none)_" >> "$OUTPUT"
  fi

  cat >> "$OUTPUT" <<SECTION

### Missing from live schema (${#missing[@]})

Tables listed in the Phase 0 catalog but absent from baseline 6.0.18.1.
These are catalog/schema drift findings — the SP body references them
but the live DDL doesn't include them.

SECTION

  if [[ ${#missing[@]} -gt 0 ]]; then
    printf -- '- dbo.%s\n' "${missing[@]}" >> "$OUTPUT"
  else
    echo "_(none)_" >> "$OUTPUT"
  fi

  echo "" >> "$OUTPUT"
  echo "[coverage] Done. Report: $OUTPUT" >&2
}

main "$@"
