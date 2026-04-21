# SQL Formatting and Standards

## Overview

This guide documents SQL formatting standards used in the NEDSS-DataReporting tracing utilities and provides tools for maintaining consistency.

## Core Formatting Rules

### Parameter Assignment Alignment

All parameter assignments should align equals signs to **column 24** for improved readability.

**Format**:
```sql
DECLARE @parameter_name         VARCHAR(100),
        @another_parameter      INT,
        @third_parameter        DATETIME
```

**Rationale**: 
- Improves scannability
- Consistent visual structure
- Facilitates line-by-line diffs

### Indentation

- **Tab Character**: Use actual tab characters (not spaces) for consistency with SQL Server Management Studio defaults
- **Nesting Levels**: One tab per logical nesting level
- **Continuation Lines**: Align with opening delimiter

**Examples**:

**CTE (Common Table Expression)**:
```sql
WITH person_changes AS (
    SELECT
        person_uid,
        first_name,
        last_name
    FROM dbo.person
    WHERE modified_date > @start_date
),
investigation_changes AS (
    SELECT
        investigation_uid,
        person_uid,
        investigation_status
    FROM dbo.investigation
    WHERE modified_date > @start_date
)
SELECT *
FROM person_changes pc
INNER JOIN investigation_changes ic
    ON pc.person_uid = ic.person_uid
```

**Conditional Logic**:
```sql
IF @start_date IS NOT NULL
    AND @end_date IS NOT NULL
BEGIN
    SELECT *
    FROM dbo.audit_log
    WHERE audit_date BETWEEN @start_date AND @end_date
END
ELSE
BEGIN
    SELECT *
    FROM dbo.audit_log
    WHERE CAST(audit_date AS DATE) = CAST(GETDATE() AS DATE)
END
```

### Data Type Declarations

Use fully qualified data type declarations with size constraints:

**Correct**:
```sql
DECLARE @person_uid             BIGINT,
        @first_name             VARCHAR(100),
        @last_update            DATETIME2(3),
        @is_active              BIT
```

**Not Recommended**:
```sql
DECLARE @person_uid BIGINT,
        @first_name VARCHAR,  -- Missing size
        @last_update DATETIME,  -- Missing precision
        @is_active BIT
```

### Function and Procedure Names

- **Format**: `schema.object_name` (always include schema prefix)
- **Case**: PascalCase for main identifiers, snake_case for utilities
- **Prefixes**: Use prefixes for clarity:
  - `usp_` for User-Stored Procedures
  - `fn_` for Functions
  - `tr_` for Triggers

**Examples**:
```sql
EXEC dbo.usp_GetPersonChangesByDateRange
    @start_date = @start_date,
    @end_date = @end_date

SELECT dbo.fn_FormatPersonName(first_name, last_name) AS full_name

SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_person(...)
```

### Comments

**Single-line comments**:
```sql
-- This is a single-line comment
SELECT * FROM dbo.person
```

**Multi-line comments**:
```sql
/*
    Multi-line comment for complex logic
    Line 2 of explanation
    Line 3 of explanation
*/
SELECT * FROM dbo.investigation
```

**Inline comments** (use sparingly):
```sql
SELECT
    person_uid,                 -- Primary identifier
    first_name + ' ' + last_name AS full_name,  -- Concatenated name
    modified_date               -- Audit timestamp
FROM dbo.person
```

## Naming Conventions

### Database Objects

| Object Type | Convention | Example |
|------------|-----------|---------|
| Table | `snake_case` | `dbo.nrt_investigation` |
| Column | `snake_case` | `person_uid` |
| Stored Procedure | `usp_PascalCase` | `usp_GetPersonChanges` |
| Function | `fn_PascalCase` | `fn_FormatDate` |
| Trigger | `tr_TableName_Event` | `tr_person_insert` |
| Index | `idx_TableName_Columns` | `idx_person_person_uid` |
| Constraint | `PK/FK/UK_TableName_Columns` | `PK_person` |
| Variable | `@snake_case` | `@person_uid` |
| Parameter | `@snake_case` | `@start_date` |

### Boolean Columns

Use prefixes for clarity:

```sql
-- Correct naming
is_active BIT,
has_children BIT,
was_processed BIT,

-- Avoid
active BIT,  -- Ambiguous
children BIT  -- Not clearly boolean
```

## Query Structure

### SELECT Statement Format

```sql
SELECT
    table_alias.column_1,
    table_alias.column_2,
    table_alias.column_3
FROM dbo.table_name table_alias
LEFT JOIN dbo.related_table related_alias
    ON table_alias.foreign_key = related_alias.primary_key
WHERE table_alias.status = 'ACTIVE'
    AND table_alias.created_date > @start_date
ORDER BY table_alias.created_date DESC,
         table_alias.person_uid ASC
```

### JOINs

**Format**: JOIN keywords on same indentation level

```sql
FROM dbo.person p
INNER JOIN dbo.investigation i
    ON p.person_uid = i.person_uid
LEFT JOIN dbo.observation o
    ON i.investigation_uid = o.investigation_uid
WHERE p.is_active = 1
```

### WHERE Clauses

Combine conditions logically:

```sql
WHERE (p.status = 'ACTIVE' OR p.status = 'INACTIVE')
    AND p.created_date > @start_date
    AND p.is_deleted = 0
    AND i.investigation_count > 0
```

### GROUP BY and HAVING

```sql
SELECT
    person_uid,
    COUNT(*) AS investigation_count,
    MAX(investigation_date) AS latest_investigation
FROM dbo.investigation
WHERE investigation_date > @start_date
GROUP BY person_uid
HAVING COUNT(*) > 5
ORDER BY investigation_count DESC
```

## Common Patterns

### Date Range Queries

```sql
-- Pattern 1: Between dates
WHERE modified_date BETWEEN @start_date AND @end_date

-- Pattern 2: Greater than and less than
WHERE modified_date >= @start_date
    AND modified_date < @end_date + 1  -- Excludes end date

-- Pattern 3: With time component
WHERE modified_date >= @start_date
    AND modified_date < DATEADD(DAY, 1, @end_date)
```

### Null Handling

```sql
-- Correct: NULL-safe comparisons
WHERE column_name IS NULL
WHERE column_name IS NOT NULL

-- Avoid: Direct NULL comparison
WHERE column_name = NULL  -- Always FALSE; use IS NULL instead
```

### CASE Statements

```sql
SELECT
    person_uid,
    CASE
        WHEN age < 18 THEN 'Minor'
        WHEN age < 65 THEN 'Adult'
        ELSE 'Senior'
    END AS age_group
FROM dbo.person
```

### CTE Usage (CTEs First)

```sql
WITH recent_changes AS (
    SELECT
        person_uid,
        MAX(modified_date) AS max_modified
    FROM dbo.audit_log
    WHERE modified_date > DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
    GROUP BY person_uid
)
SELECT
    p.person_uid,
    p.first_name,
    rc.max_modified
FROM dbo.person p
INNER JOIN recent_changes rc
    ON p.person_uid = rc.person_uid
```

## Performance Considerations

### Index-Friendly Queries

```sql
-- Prefer: Indexed column and exact operators
WHERE person_uid = @person_uid
    AND created_date >= @start_date

-- Avoid: Functions on indexed columns (prevents index usage)
WHERE YEAR(created_date) = 2024  -- Can't use index efficiently
WHERE CAST(created_date AS DATE) = CAST(GETDATE() AS DATE)  -- Can't use index

-- Better alternative:
WHERE created_date >= '2024-01-01'
    AND created_date < '2025-01-01'
```

### EXISTS vs IN

```sql
-- Prefer EXISTS for large subqueries
SELECT *
FROM dbo.investigation i
WHERE EXISTS (
    SELECT 1
    FROM dbo.person p
    WHERE p.person_uid = i.person_uid
        AND p.is_active = 1
)

-- IN is fine for small lists
WHERE status IN ('ACTIVE', 'PENDING', 'INVESTIGATING')
```

### Efficient Aggregations

```sql
-- Efficient: Specific columns in GROUP BY
SELECT
    person_uid,
    COUNT(*) AS record_count
FROM dbo.investigation
GROUP BY person_uid  -- Include only necessary columns

-- Less efficient: Unnecessary columns
SELECT
    person_uid,
    first_name,
    last_name,
    COUNT(*) AS record_count
FROM dbo.person
WHERE first_name IS NOT NULL
GROUP BY person_uid, first_name, last_name
```

## Automated Formatting Tools

### PowerShell Script: Align Equals Signs

For aligning parameter declarations and assignments to column 24:

```powershell
# Script: Format-SqlFile.ps1
# Usage: .\Format-SqlFile.ps1 -FilePath "script.sql"

param(
    [string]$FilePath,
    [int]$ColumnPosition = 24
)

$content = Get-Content $FilePath -Raw
$lines = $content -split "`n"
$formatted = @()

foreach ($line in $lines) {
    if ($line -match '^(\s*DECLARE|SELECT|WHERE)\s+@\w+') {
        # Extract components
        $match = $line -match '(\s*)(@\w+)(\s*)(=|,)'
        if ($match) {
            $indent = $matches[1]
            $varName = $matches[2]
            $operator = $matches[4]
            $rest = $line.Substring($line.LastIndexOf($operator))
            
            # Pad to column position
            $paddedLine = "{0}{1,-20} {2}" -f $indent, $varName, $rest
            $formatted += $paddedLine
        } else {
            $formatted += $line
        }
    } else {
        $formatted += $line
    }
}

$output = $formatted -join "`n"
Set-Content -Path $FilePath -Value $output
Write-Host "Formatted: $FilePath"
```

### Usage

```powershell
# Format a single file
.\Format-SqlFile.ps1 -FilePath "trace_query.sql"

# Format all SQL files in directory
Get-ChildItem *.sql | ForEach-Object {
    .\Format-SqlFile.ps1 -FilePath $_.FullName
}
```

## Code Review Checklist

When reviewing SQL code:

- [ ] Parameter declarations aligned at column 24
- [ ] All table references include schema prefix
- [ ] No functions applied to indexed columns in WHERE clauses
- [ ] NULL comparisons use IS NULL/IS NOT NULL
- [ ] Data types include size constraints (VARCHAR(100), not VARCHAR)
- [ ] CTEs defined before main SELECT
- [ ] Meaningful table aliases (table prefix, not sequential letters)
- [ ] Comments provided for complex logic
- [ ] No hardcoded dates; use variables or DATEADD()
- [ ] Proper indentation with tabs
- [ ] BETWEEN preferred over >= AND <
- [ ] ORDER BY specified if result order matters

## Standards Migration

### Formatting Existing Code

To format existing SQL files to meet these standards:

1. **Identify target files**:
   ```bash
   find . -name "*.sql" -type f
   ```

2. **Backup original**:
   ```bash
   cp file.sql file.sql.bak
   ```

3. **Apply formatting**:
   ```powershell
   .\Format-SqlFile.ps1 -FilePath "file.sql"
   ```

4. **Verify changes**:
   ```bash
   diff file.sql file.sql.bak | less
   ```

5. **Test execution**:
   - Run in SQL Server Management Studio
   - Verify no syntax errors
   - Check execution plans unchanged

## Related Documentation
- [Configuration Reference](./configuration-reference.md)
- [Architecture Overview](./architecture.md)
