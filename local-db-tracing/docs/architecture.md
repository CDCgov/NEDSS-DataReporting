# Local Database Tracing Toolset Architecture

## Project Overview

The local-db-tracing utility is a comprehensive toolkit for capturing and analyzing database changes in the NEDSS-DataReporting system. It provides detailed change tracking for both CDC (Change Data Capture) operations and logical data transformations.

## Core Components

### Tracing Engines

#### trace_db_cdc.py
Captures CDC changes from a SQL Server database using LSN (Log Sequence Number) boundaries.

**Key Features**:
- Binary log-based change tracking
- Supports incremental captures within LSN ranges
- Persists LSN checkpoints for resumable operations
- Comprehensive capture statistics

**Output**:
- CDC capture files grouped by operation type (INSERT, UPDATE, DELETE)
- Manifest with LSN boundaries and record counts
- Summary report with execution timing

#### trace_db_logical_changes.py
Analyzes logical changes between database snapshots using timestamp-based comparison.

**Key Features**:
- Time-window based change detection
- Deep comparison of rows and column changes
- Relationship tracking across entities
- Transformation validation

**Output**:
- Logical change details with before/after values
- Column-level change metadata
- Relationship mappings between changed entities

### Supporting Modules

#### tracing_capture.py
**Responsibilities**:
- Capture session initialization
- Interactive user prompts for capture parameters
- Change fetching orchestration
- Post-processing coordination

**Key Functions**:
- `fetch_changes_for_captures()`: Retrieves changed rows
- `wait_for_post_processing_idle()`: Ensures completion before exit

#### tracing_logical_changes.py
**Responsibilities**:
- Logical change computation
- Column-level diff generation
- Relationship detection
- Change categorization

**Key Algorithms**:
- Row comparison using primary keys
- Column value transformation tracking
- Entity dependency resolution

#### tracing_output.py
**Responsibilities**:
- Manifest generation
- Summary report writing
- Metadata persistence

**Output Formats**:
- JSON manifest with structured metadata
- Text summary with human-readable insights
- Tab-separated value export for analysis tools

#### tracing_post_processing.py
**Responsibilities**:
- Post-capture cleanup
- Temporary resource removal
- State verification
- Idle detection for background processes

**Monitoring**:
- Waits for container-based post-processing tasks
- Tracks process completion status
- Ensures all artifacts are finalized

#### tracing_state.py
**Responsibilities**:
- LSN checkpoint persistence
- Execution state tracking
- Recovery support for interrupted operations

**State Management**:
- Stores last processed LSN per capture session
- Enables incremental re-runs
- Prevents duplicate processing

#### tracing_paths.py
**Responsibilities**:
- Output directory structure creation
- Timestamped folder naming
- Artifact path construction
- Directory cleanup on error

**Path Conventions**:
```
output/
  YYYYMMDD-HHMMSS-DATABASE-OPERATION/
    manifest.json
    summary.txt
    captures/
      insert_*.csv
      update_*.csv
      delete_*.csv
```

#### tracing_env.py
**Responsibilities**:
- Environment configuration loading
- Database connection defaults
- Credential management
- Configuration validation

**Supported Environment Variables**:
- `DB_HOST`: Database server hostname
- `DB_USERNAME`: Connection username
- `DB_PASSWORD`: Connection password
- `DB_PORT`: Connection port (default: 1433)

#### tracing_constants.py
**Responsibilities**:
- Central configuration constants
- Batch size definitions
- Timeout values
- Format specifications

#### tracing_metadata.py
**Responsibilities**:
- Metadata extraction from database
- Schema and relationship analysis
- Primary key detection
- Column type resolution

#### tracing_models.py
**Responsibilities**:
- Data transfer object definitions
- Type annotations for change records
- Serialization support

**Key Models**:
- `CaptureChange`: Represents a single CDC change
- `LogicalChange`: Represents a logical data transformation
- `ChangeSet`: Groups related changes

### Database Connectivity

#### tracing_sql.py
**Responsibilities**:
- SQL query generation
- Database command execution
- Result set handling
- Connection pooling

**Query Patterns**:
- CDC function calls (cdc.fn_cdc_get_net_changes_*)
- Logical comparison queries
- Metadata extraction

## Workflow Architecture

### Interactive Capture Workflow

1. **Initialization**
   - User provides database credentials
   - System validates connection
   - Determines current LSN/timestamp boundaries

2. **Configuration**
   - User specifies capture parameters (tables, window size, etc.)
   - System calculates processing batches
   - Creates output directory structure

3. **Capture Execution**
   - Parallel processing of change batches
   - Real-time progress reporting
   - Intermediate checkpoint saving

4. **Post-Processing**
   - Cleanup of temporary resources
   - Artifact finalization
   - Summary report generation

5. **Output Generation**
   - Manifest file creation with metadata
   - Summary report with statistics
   - CSV export for analysis tools

### Data Flow

```
Database
   ↓
[Change Detection]
   ├─→ CDC Module ──→ Binary changes
   └─→ Logical Diff ──→ Semantic changes
   ↓
[Change Analysis]
   ├─→ Relationship Resolution
   ├─→ Column-level Mapping
   └─→ Transformation Validation
   ↓
[Output Generation]
   ├─→ Manifest with Metadata
   ├─→ Summary Report
   └─→ CSV Export
   ↓
Output Folder
```

## Testing Infrastructure

### Test Coverage Files
- `test_connection_defaults.py`: Connection configuration validation
- `test_generate_rdb_selects.py`: SELECT query generation
- `test_logical_changes.py`: Logical diff computation
- `test_logical_compare.py`: Cross-database comparison
- `test_logical_markdown.py`: Report formatting
- `test_metadata.py`: Schema extraction
- `test_replay.py`: Change replay functionality
- `test_tracing_post_processing.py`: Post-processing logic
- `test_validate_rdb_selects.py`: Query validation

### Test Utilities
- `test_connection_defaults.py`: Fixtures for database connections
- Configuration validators
- Mock data generators

## Performance Considerations

### Batch Processing
- Configurable batch sizes (default: 1000 rows)
- Memory-efficient streaming for large result sets
- Checkpoint-based resumability

### Concurrency
- Multi-threaded capture for independent databases
- Thread-safe manifest writing
- Coordinated cleanup with synchronization barriers

### Storage
- Disk-efficient CSV export format
- Gzip compression optional for large captures
- Configurable retention policies

## Extensibility

### Adding New Change Detectors
1. Inherit from base `TraceEngine` class
2. Implement `capture_changes()` interface
3. Register with capture coordinator
4. Add corresponding test suite

### Supporting New Databases
1. Create database-specific SQL module
2. Implement connection pooling
3. Add credential management
4. Validate with test connection utility

## Configuration Management

### .env File Format
```
DB_HOST=localhost
DB_PORT=1433
DB_USERNAME=sa
DB_PASSWORD=password123
BATCH_SIZE=1000
OUTPUT_DIR=./output
```

### Runtime Overrides
- Command-line arguments take precedence
- Environment variables used as fallback  
- Built-in defaults as final resort

## Security Considerations

### Credential Handling
- Never log passwords or connection strings
- Use secure credential storage when available
- Validate SSL/TLS for production databases

### Data Privacy
- No sensitive data in logs
- Optional encryption for output files
- Access controls on output directories

## Related Documentation
- [Database Tracing Workflow](./database-tracing-workflow.md)
- [NRT Table Population](./nrt-table-population.md)
- README.md: Command-line usage guide
