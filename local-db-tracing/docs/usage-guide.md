# Local Database Tracing - Usage Guide

## Quick Start

### Prerequisites
- Python 3.7+
- SQL Server 2012+ (for CDC features)
- Network access to target database server
- Appropriate database user credentials

### Installation

1. Navigate to the tracing directory:
```bash
cd local-db-tracing
```

2. Install Python dependencies (if needed):
```bash
pip install -r requirements.txt
```

3. Configure environment variables:
```bash
cp .env.sample .env
# Edit .env with your database credentials
```

## Running Trace Operations

### Single Database - CDC Capture

Captures Change Data Capture (CDC) changes from NBS_ODSE database:

```bash
python trace_db_cdc.py
```

**Interactive Prompts**:
- Database host and credentials
- Tables to capture
- LSN boundaries (if resuming)
- Output directory (default: ./output)

**Output**:
- `output/YYYYMMDD-HHMMSS-NBS_ODSE-CDC/`
  - `manifest.json`: Metadata and execution details
  - `summary.txt`: Human-readable report
  - `captures/`: CSV files with changes

### Single Database - Logical Changes

Captures logical changes from RDB_MODERN database:

```bash
python trace_db_logical_changes.py
```

**Interactive Prompts**:
- Database host and credentials
- Time window for comparison
- Tables to analyze
- Comparison depth (shallow vs. deep)

**Output**:
- `output/YYYYMMDD-HHMMSS-RDB_MODERN-LOGICAL/`
  - `manifest.json`: Metadata and execution details
  - `summary.txt`: Human-readable report
  - `changes/`: Logical change details

### Dual Database Tracing

Run both CDC and logical change tracing simultaneously using separate terminal sessions:

**Terminal 1 - CDC Capture**:
```bash
python trace_db_cdc.py
```

**Terminal 2 - Logical Changes** (while Terminal 1 is running):
```bash
python trace_db_logical_changes.py
```

Benefits:
- Parallel capture of both database changes
- Independent LSN/timestamp tracking
- Separate output directories for analysis

**Coordination Tips**:
- Start both around the same time to capture overlapping windows
- Use identical timestamp ranges for comparative analysis
- Compare manifest files to verify capture completeness

### PowerShell Wrapper (Optional)

For combined operation execution via PowerShell:

```powershell
# This executes both traces in background jobs
Start-Job { python trace_db_cdc.py }
Start-Job { python trace_db_logical_changes.py }

# Wait for completion
Get-Job | Wait-Job

# Retrieve results
Get-Job | Receive-Job
```

### Generate RDB Verification SQL

Generate `rdb-selects.sql` from a paired run directory:

```bash
python generate_query_expected.py --paired-run-dir output/20260423-103745-NBS_ODSE-to-RDB_MODERN
```

Generate from a specific manifest path:

```bash
python generate_query_expected.py --combined-manifest output/20260423-103745-NBS_ODSE-to-RDB_MODERN/combined-manifest.json
```

Generate cumulative per-step verification SQL under `logical-<database>/step-<N>/query.sql`:

```bash
python generate_query_expected.py --combined-manifest output/20260423-103745-NBS_ODSE-to-RDB_MODERN/combined-manifest.json --all-steps
```

## Command-Line Options

### CDC Trace

```bash
python trace_db_cdc.py [OPTIONS]
```

**Options**:
- `--host HOST`: Database server hostname
- `--port PORT`: Database port (default: 1433)
- `--username USER`: Database username
- `--password PASS`: Database password (not recommended; use .env)
- `--database DB`: Database name (default: NBS_ODSE)
- `--output-dir DIR`: Output directory for traces
- `--batch-size SIZE`: Records per batch (default: 1000)
- `--no-cleanup`: Retain temporary files after execution

### Logical Changes Trace

```bash
python trace_db_logical_changes.py [OPTIONS]
```

**Options**:
- `--host HOST`: Database server hostname
- `--port PORT`: Database port (default: 1433)
- `--username USER`: Database username
- `--password PASS`: Database password (not recommended; use .env)
- `--database DB`: Database name (default: RDB_MODERN)
- `--output-dir DIR`: Output directory for traces
- `--start-time TIME`: ISO format start timestamp
- `--end-time TIME`: ISO format end timestamp
- `--deep-compare`: Enable column-level comparisons

### RDB Select Generation

```bash
python generate_query_expected.py [OPTIONS]
```

**Options**:
- `--paired-run-dir DIR`: Paired run directory containing `combined-manifest.json`
- `--combined-manifest FILE`: Explicit path to `combined-manifest.json` (overrides `--paired-run-dir`)
- `--output-file FILE`: Output path for generated SQL (default is next to manifest)
- `--all-steps`: Also emit cumulative per-step `query.sql` and `expected.json` files

## Understanding Output

### Manifest File (manifest.json)

```json
{
  "execution_id": "20240115-143022-NBS_ODSE-CDC",
  "database": "NBS_ODSE",
  "operation_type": "CDC",
  "start_lsn": "0x00000045:00000100:0001",
  "end_lsn": "0x00000050:00000200:0002",
  "start_time": "2024-01-15T14:30:22Z",
  "end_time": "2024-01-15T14:35:45Z",
  "total_duration_seconds": 323,
  "record_counts": {
    "inserts": 1250,
    "updates": 3421,
    "deletes": 87
  },
  "tables_captured": [
    "dbo.person",
    "dbo.investigation",
    "dbo.observation"
  ]
}
```

### Summary Report (summary.txt)

```
Database Trace Summary Report
==============================

Trace ID: 20240115-143022-NBS_ODSE-CDC
Database: NBS_ODSE
Operation: CDC Capture

Time Window:
  Start: 2024-01-15 14:30:22
  End:   2024-01-15 14:35:45
  Duration: 5 minutes 23 seconds

LSN Range:
  Start: 0x00000045:00000100:0001
  End:   0x00000050:00000200:0002

Change Summary:
  Total Inserts: 1,250
  Total Updates: 3,421
  Total Deletes: 87
  Total Changes: 4,758

Top Modified Tables:
  1. dbo.person (2,100 changes)
  2. dbo.investigation (1,850 changes)
  3. dbo.observation (808 changes)
```

### Change Records (captures/insert_*.csv)

```csv
table_name,primary_key,columns_changed,change_type,change_time
dbo.person,person_uid=123456,"['firstName', 'lastName']",UPDATE,2024-01-15T14:31:00Z
dbo.investigation,investigation_uid=789012,"['status']",UPDATE,2024-01-15T14:31:05Z
dbo.observation,observation_uid=345678,"['value', 'result_status']",INSERT,2024-01-15T14:31:10Z
```

## Workflow Scenarios

### Scenario 1: Investigate SQL Table Population

Task: Understand how the `nrt_investigation` table gets populated with Rubella cases

Steps:
1. Run CDC trace on `nbs_odse`:
   ```bash
   python trace_db_cdc.py
   # When prompted, select: dbo.nrt_investigation table
   ```

2. Review the manifest for record counts:
   ```bash
   cat output/YYYYMMDD-HHMMSS-NBS_ODSE-CDC/manifest.json | grep -A5 nrt_investigation
   ```

3. Examine captured changes:
   ```bash
   head -20 output/YYYYMMDD-HHMMSS-NBS_ODSE-CDC/captures/insert_*.csv | grep -i rubella
   ```

4. Cross-reference with logical changes:
   ```bash
   python trace_db_logical_changes.py
   # Select: nrt_investigation table for comparison
   ```

### Scenario 2: Parallel Database Monitoring

Task: Simultaneously monitor changes in both NBS_ODSE (source) and RDB_MODERN (reporting)

Steps:
1. Start CDC capture on NBS_ODSE (Terminal 1):
   ```bash
   python trace_db_cdc.py
   ```

2. In parallel, start logical analysis on RDB_MODERN (Terminal 2):
   ```bash
   python trace_db_logical_changes.py
   ```

3. Wait for both to complete (typically 5-10 minutes)

4. Compare output manifests:
   ```bash
   jq '.record_counts' output/*/manifest.json
   ```

5. Analyze transformation fidelity:
   ```bash
   # Check CDC source counts vs. logical target counts
   # If counts differ, transformation issues in RDB_MODERN
   ```

### Scenario 3: Resumable Long-Running Capture

Task: Capture large volumes with checkpoint recovery

Steps:
1. Start initial capture:
   ```bash
   python trace_db_cdc.py --batch-size 500
   ```

2. If interrupted, resume:
   - The tool automatically detects the last processed LSN
   - Run again; it will prompt to resume from checkpoint
   ```bash
   python trace_db_cdc.py
   # When prompted: "Resume from previous LSN? [Y/n]" → Y
   ```

3. Captures merge automatically; no duplicate processing

## Configuration

### Environment Variables (.env)

```env
# Database Connection
DB_HOST=localhost
DB_PORT=1433
DB_USERNAME=sa
DB_PASSWORD=your_password_here

# Tracing Configuration
BATCH_SIZE=1000
OUTPUT_DIR=./output
ENABLE_CLEANUP=true

# Performance
MAX_CONNECTIONS=5
TIMEOUT_SECONDS=300
```

### Configuration Precedence

1. Command-line arguments (highest priority)
2. Environment variables
3. Configuration files (.env)
4. Built-in defaults (lowest priority)

## Performance Tuning

### Large Table Captures

For tables with millions of rows:

```bash
# Increase batch size to reduce overhead
python trace_db_cdc.py --batch-size 5000

# Or use command-line timeout
python trace_db_cdc.py --batch-size 2000 --timeout 600
```

### Memory Optimization

For constrained environments:

```bash
# Reduce batch size and force cleanup
python trace_db_cdc.py --batch-size 250 --enable-cleanup

# Stream output directly (if supported)
python trace_db_logical_changes.py | gzip > output.jsonl.gz
```

### Parallel Captures (Different Tables)

```bash
# Terminal 1: Capture person tables
python trace_db_cdc.py --table person --output-dir ./output/person_capture &

# Terminal 2: Capture investigation tables
python trace_db_cdc.py --table investigation --output-dir ./output/inv_capture &

# Terminal 3: Capture observation tables
python trace_db_cdc.py --table observation --output-dir ./output/obs_capture &

# Wait for all to complete
wait
```

## Troubleshooting

### Connection Issues

**Error**: "Unable to connect to server"

**Solutions**:
1. Verify hostname and port:
   ```bash
   ping <DB_HOST>
   telnet <DB_HOST> 1433
   ```
2. Check credentials in .env file
3. Ensure firewall allows SQL Server port (1433)
4. Validate user permissions on database

### CDC Capture Returns No Changes

**Possible Causes**:
1. LSN range too small (no changes in window)
2. CDC not enabled on database
3. Selected tables don't have CDC enabled

**Solutions**:
1. Verify CDC is enabled:
   ```sql
   SELECT name, is_cdc_enabled FROM sys.databases WHERE name = 'NBS_ODSE'
   ```
2. Check CDC-enabled tables:
   ```sql
   SELECT name FROM cdc.change_tables
   ```
3. Expand LSN or timestamp window

### Post-Processing Timeout

**Error**: "Post-processing did not complete within timeout"

**Solutions**:
1. Increase timeout:
   ```bash
   python trace_db_cdc.py --timeout 900
   ```
2. Check for failed background processes:
   ```bash
   ps aux | grep post_processing
   ```
3. Review logs in .local/ directory

## Output Analysis

### Counting Changes by Table

```bash
# Using jq on manifest
jq '.record_counts' output/YYYYMMDD*/manifest.json

# Manual count from CSV
wc -l output/YYYYMMDD*/captures/*.csv
```

### Finding Specific Changes

```bash
# Search for person_uid across captures
grep "person_uid=123456" output/YYYYMMDD*/captures/*.csv

# Find all updates to specific column
grep "firstName" output/YYYYMMDD*/captures/update_*.csv
```

### Comparing Two Captures

```bash
# Check for consistent change counts
diff <(jq '.record_counts' output/capture1/manifest.json) \
     <(jq '.record_counts' output/capture2/manifest.json)
```

## Related Documentation
- [Architecture Overview](./architecture.md)
- [Database Tracing Workflow](./database-tracing-workflow.md)
- [Troubleshooting Guide](./troubleshooting.md)
