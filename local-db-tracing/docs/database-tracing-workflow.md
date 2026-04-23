# Database Tracing Workflow

## Overview
This document describes the workflow for tracing changes across databases in the NEDSS-DataReporting project, specifically tracking changes from NBS_ODSE (source) to RDB_MODERN (target).

## Problem Statement
When working with two databases (`NBS_ODSE` and `RDB_MODERN`), developers need to:
1. Capture CDC (Change Data Capture) changes from NBS_ODSE
2. Simultaneously track logical changes in RDB_MODERN
3. Previously required opening two separate terminals and running commands in parallel

## Solution Approach

### Single Command Execution
The goal is to consolidate both tracing operations into a single command that:
- Captures trace_db_cdc output from one database (NBS_ODSE)
- Captures trace_db_logical_changes output from another database (RDB_MODERN)
- Handles both processes in parallel
- Coordinates artifact output to a combined run folder

### Output Structure
```
output/
  combined-run-timestamp-NBS_ODSE-RDB_MODERN/
    cdc-NBS_ODSE/
      summary.txt
      manifest.json
      [other CDC artifacts]
    logical-RDB_MODERN/
      summary.txt
      [logical change artifacts]
    consolidated-summary.txt
```

## Key Modules

### Shared Tracing Modules
- **tracing_capture.py**: Handles capture initialization and cleanup
- **tracing_state.py**: Manages state tracking across processes
- **tracing_output.py**: Writes summary and manifest files
- **tracing_post_processing.py**: Handles post-processing and idle detection
- **tracing_paths.py**: Manages path construction for outputs

### Main Tracer Scripts
- **trace_db_cdc.py**: Captures CDC changes from a source database
- **trace_db_logical_changes.py**: Captures logical changes from a target database

## Implementation Considerations

### Synchronization
- Global timestamp captured before both processes start
- CDC uses LSN-based tracking from source database
- Logical changes use time-based tracking from target database
- Both processes write their start/end times for cross-referencing

### Database Credentials
- Requires separate connection contexts for each database
- Uses tracing_env.py for environment configuration
- Supports custom database credentials via environment variables

### Output Deduplication
- Encourages use of distinct databases (NBS_ODSE ≠ RDB_MODERN)
- Prevents duplicate artifact generation
- Single combined summary tracks both operations

## Next Steps

### Building SELECT Queries
After capturing changes:
1. Identify new/updated rows in RDB_MODERN using the logical changes summary
2. Extract IDs from summary.txt
3. Build SELECT statements using those IDs to retrieve full row data
4. Manually create DECLARE statements for the SELECT queries

### Data Validation
- Compare CDC changes from NBS_ODSE with logical changes in RDB_MODERN
- Verify all expected rows were replicated
- Track any discrepancies or transformation issues

## References
- README.md: User-facing command documentation
- test_connection_defaults.py: Connection configuration tests
- trace_db_dual.py: Combined tracer implementation (future)
