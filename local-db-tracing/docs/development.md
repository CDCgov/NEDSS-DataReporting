# Development Guide

## Getting Started

### Prerequisites

- Python 3.7 or higher
- SQL Server 2012+ (for CDC features)
- Git for version control
- VS Code or preferred Python IDE

### Project Structure

```
local-db-tracing/
├── docs/                          # Documentation (this folder)
│   ├── architecture.md
│   ├── usage-guide.md
│   ├── configuration-reference.md
│   ├── troubleshooting.md
│   ├── sql-formatting-standards.md
│   ├── testing-guide.md
│   └── development.md
├── trace_db_cdc.py               # CDC capture entry point
├── trace_db_logical_changes.py   # Logical changes entry point
├── tracing_capture.py             # Capture orchestration
├── tracing_output.py              # Output generation
├── tracing_post_processing.py     # Post-processing logic
├── tracing_state.py               # State management
├── tracing_paths.py               # Path utilities
├── tracing_env.py                 # Configuration/environment
├── tracing_constants.py           # Constants
├── tracing_metadata.py            # Metadata extraction
├── tracing_models.py              # Data models
├── tracing_sql.py                 # SQL utilities
├── tracing_logical_changes.py    # Logical diff computation
├── tracing_replay.py              # Change replay
├── test_*.py                      # Test files
├── known_lookup_keys.json         # Lookup table configuration
├── known_replay_associations.json # Relationship configuration
├── .env.sample                    # Environment template
├── .local/                        # Local execution state
│   ├── checkpoint.json            # LSN checkpoint for resumable captures
│   └── execution_history.log      # Log of past executions
├── output/                        # Generated traces (created at runtime)
└── logs/                          # Execution logs (created at runtime)
```

### Development Environment Setup

1. **Clone repository**:
   ```bash
   cd utilities/local-db-tracing
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   pip install -r requirements-dev.txt  # For testing/linting
   ```

4. **Configure environment**:
   ```bash
   cp .env.sample .env
   # Edit .env with your database credentials
   ```

5. **Test setup**:
   ```bash
   python -m pytest test_connection_defaults.py::test_connection -v
   ```

## Architecture Overview

### Module Responsibilities

**Entry Points**:
- `trace_db_cdc.py`: CLI for CDC capture from NBS_ODSE
- `trace_db_logical_changes.py`: CLI for logical changes from RDB_MODERN

**Core Orchestration**:
- `tracing_capture.py`: Coordinates capture workflows
- `tracing_output.py`: Generates manifest and summary reports
- `tracing_post_processing.py`: Manages cleanup and finalization

**Configuration & State**:
- `tracing_env.py`: Environment variable and .env configuration
- `tracing_constants.py`: Application constants
- `tracing_state.py`: LSN checkpoint persistence
- `tracing_paths.py`: File system path management

**Database Operations**:
- `tracing_sql.py`: SQL query generation and execution
- `tracing_metadata.py`: Schema introspection
- `tracing_models.py`: Data transfer objects

**Analysis**:
- `tracing_logical_changes.py`: Logical diff computation
- `tracing_replay.py`: Change replay functionality

### Data Flow

```
CLI Interface (trace_db_*.py)
    ↓
[Interactive Configuration]
    ↓
tracing_capture.py (fetch changes)
    ↓
[Parse CDC/Logical changes]
    ↓
tracing_output.py (generate reports)
    ↓
[Write to disk]
    ↓
tracing_post_processing.py (cleanup)
    ↓
tracing_state.py (save checkpoint)
```

## Core Concepts

### Change Detection Methods

**CDC (Change Data Capture)**:
- Uses SQL Server's built-in CDC features
- Binary log-based tracking with LSN boundaries
- Captures at transaction level
- Only available for specific tables with CDC enabled

**Logical Changes**:
- Timestamp-based comparison between snapshots
- Works on any table without CDC configuration
- Can compare across databases (NBS_ODSE → RDB_MODERN)
- Slower but more flexible

### State Management

**LSN Checkpoints** (CDC only):
```json
{
  "last_processed_lsn": "0x00000050:00000200:0002",
  "last_checkpoint_time": "2024-01-15T14:35:45Z",
  "last_checkpoint_record_count": 4758
}
```

**Execution History**:
```json
{
  "execution_id": "20240115-143022-NBS_ODSE-CDC",
  "start_time": "2024-01-15T14:30:22Z",
  "end_time": "2024-01-15T14:35:45Z",
  "status": "completed",
  "record_count": 4758
}
```

## Common Development Tasks

### Adding a New CLI Option

**Task**: Add `--dry-run` flag to preview changes without capturing

1. **Modify entry point script** (`trace_db_cdc.py`):
   ```python
   import argparse
   
   parser = argparse.ArgumentParser()
   parser.add_argument('--dry-run', action='store_true',
                       help='Preview changes without capturing')
   args = parser.parse_args()
   
   if args.dry_run:
       print("Dry run mode: No data will be captured")
   ```

2. **Pass to capture module** (`tracing_capture.py`):
   ```python
   def fetch_changes_for_captures(connection, dry_run=False):
       if dry_run:
           # Query changes but don't persist
           preview_results = connection.execute(query)
           return preview_results
       else:
           # Standard capture flow
   ```

3. **Add test** (`test_tracing_capture.py`):
   ```python
   def test_dry_run_mode_preview_only(mock_connection):
       """Verify dry-run mode doesn't modify output"""
       changes = fetch_changes_for_captures(mock_connection, dry_run=True)
       
       assert changes is not None
       # Verify output directory not created
       assert not Path('output').exists()
   ```

### Adding a New Output Format

**Task**: Add CSV export format in addition to JSON manifest

1. **Create export function** (`tracing_output.py`):
   ```python
   import csv
   
   def export_to_csv(changes, output_path):
       """Export changes to CSV format"""
       with open(output_path, 'w', newline='') as f:
           writer = csv.DictWriter(f, fieldnames=['table_name', 'operation', 'row_id'])
           writer.writeheader()
           writer.writerows(changes)
   ```

2. **Update output generation**:
   ```python
   def generate_output_artifacts(capture_result, output_dir):
       # Existing manifest generation
       write_manifest(capture_result, output_dir / 'manifest.json')
       
       # New CSV export
       export_to_csv(capture_result.changes, output_dir / 'changes.csv')
   ```

3. **Add tests** (`test_output.py`):
   ```python
   def test_export_to_csv_structure():
       changes = [{'table': 'person', 'operation': 'INSERT'}]
       export_to_csv(changes, 'test.csv')
       
       with open('test.csv') as f:
           rows = list(csv.DictReader(f))
       
       assert len(rows) == 1
       assert rows[0]['table'] == 'person'
   ```

### Extending Change Detection

**Task**: Add support for a new data source (e.g., PostgreSQL)

1. **Create new detector module** (`tracing_postgres.py`):
   ```python
   from abc import ABC, abstractmethod
   
   class ChangeDetector(ABC):
       @abstractmethod
       def detect_changes(self, start_time, end_time):
           pass
   
   class PostgresChangeDetector(ChangeDetector):
       def __init__(self, connection):
           self.connection = connection
       
       def detect_changes(self, start_time, end_time):
           query = """
               SELECT * FROM audit_log 
               WHERE changed_at BETWEEN %s AND %s
           """
           return self.connection.execute(query, [start_time, end_time])
   ```

2. **Register detector** (`tracing_capture.py`):
   ```python
   from tracing_postgres import PostgresChangeDetector
   
   DETECTORS = {
       'mssql_cdc': MSSQLCDCDetector,
       'mssql_logical': MSSQLLogicalDetector,
       'postgres': PostgresChangeDetector,  # New
   }
   
   def get_detector(db_type, connection):
       return DETECTORS[db_type](connection)
   ```

3. **Add test suite** (`test_postgres_detector.py`):
   ```python
   @pytest.mark.integration
   def test_postgres_change_detection(postgres_connection):
       detector = PostgresChangeDetector(postgres_connection)
       changes = detector.detect_changes(start_time, end_time)
       
       assert len(changes) >= 0
   ```

## Code Style and Standards

### Python Style Guide

Follow PEP 8 with these project-specific conventions:

**Imports**:
```python
# Standard library
import os
import sys
from pathlib import Path

# Third-party
import pyodbc
import pandas as pd

# Local
from tracing_env import get_config
from tracing_models import CaptureChange
```

**Naming**:
- Functions: `snake_case` (e.g., `fetch_changes_for_captures`)
- Classes: `PascalCase` (e.g., `ChangeDetector`)
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `DEFAULT_BATCH_SIZE`)
- Private: `_leading_underscore` (e.g., `_internal_method`)

**Type Hints**:
```python
from typing import List, Dict, Optional

def process_changes(
    changes: List[Dict[str, any]], 
    output_dir: Path,
    dry_run: bool = False
) -> Optional[Path]:
    """Process changes and return output path."""
    pass
```

**Docstrings** (Google style):
```python
def fetch_changes_for_captures(
    connection: pyodbc.Connection,
    start_lsn: str,
    end_lsn: str
) -> List[CaptureChange]:
    """Fetch CDC changes between LSN boundaries.
    
    Args:
        connection: ODBC database connection
        start_lsn: Starting LSN (format: 0x00000000:00000000:0000)
        end_lsn: Ending LSN (format: 0x00000000:00000000:0000)
    
    Returns:
        List of CaptureChange objects representing changes
    
    Raises:
        ValueError: If LSN format is invalid
        pyodbc.Error: If database query fails
    
    Example:
        >>> changes = fetch_changes_for_captures(conn, start, end)
        >>> len(changes)
        1234
    """
```

### Code Quality Tools

**Linting with pylint**:
```bash
# Check code style
pylint trace_db_cdc.py

# Generate report
pylint --reports=y trace_db_cdc.py
```

**Type checking with mypy**:
```bash
# Check type hints
mypy tracing_*.py

# Strict mode
mypy --strict tracing_*.py
```

**Code formatting with autopep8/black**:
```bash
# Auto-format code
black trace_db_*.py tracing_*.py

# Check without modifying
black --check trace_db_*.py
```

**Configuration** (`.pylintrc` or `setup.cfg`):
```ini
[pylint]
max-line-length = 100
disable = C0103  # Invalid-name (for @variableName style)

[mypy]
python_version = 3.7
warn_return_any = True
warn_unused_configs = True
```

## Debugging Techniques

### Debug Mode

Enable debug logging during development:

```bash
LOG_LEVEL=DEBUG python trace_db_cdc.py
```

### Print-Based Debugging

```python
import logging

logger = logging.getLogger(__name__)

def fetch_changes(connection):
    logger.debug(f"Starting change fetch from LSN: {start_lsn}")
    
    try:
        changes = connection.execute(query)
        logger.debug(f"Fetched {len(changes)} changes")
        return changes
    except Exception as e:
        logger.error(f"Error fetching changes: {e}", exc_info=True)
        raise
```

### Debugger Breakpoints

Using Python debugger:

```python
import pdb

def complex_function():
    result = initial_computation()
    pdb.set_trace()  # Execution pauses, inspect 'result'
    return process(result)
```

**Common pdb commands**:
- `l`: List current code
- `n`: Next line
- `s`: Step into function
- `c`: Continue
- `p variable`: Print variable
- `h`: Help

### IDE Debugging (VS Code)

**Debug configuration** (`launch.json`):
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: CDC Trace",
            "type": "python",
            "request": "launch",
            "program": "${workspaceFolder}/trace_db_cdc.py",
            "console": "integratedTerminal",
            "env": {
                "LOG_LEVEL": "DEBUG"
            }
        }
    ]
}
```

## Performance Optimization

### Profiling

Profile code to identify bottlenecks:

```python
import cProfile
import pstats

def run_trace_with_profiling():
    profiler = cProfile.Profile()
    profiler.enable()
    
    # Run operation
    fetch_changes_for_captures(connection)
    
    profiler.disable()
    stats = pstats.Stats(profiler)
    stats.sort_stats('cumulative')
    stats.print_stats(20)  # Top 20 functions
```

### Memory Profiling

```python
from memory_profiler import profile

@profile
def fetch_changes(connection):
    # This function's memory usage will be tracked
    changes = list(connection.execute(query))
    return changes

# Run with:
# python -m memory_profiler trace_db_cdc.py
```

### Optimization Strategies

1. **Batch Processing**:
   ```python
   # Instead of processing one at a time
   for change in all_changes:      # Slow
       process(change)
   
   # Batch and process
   for batch in chunks(all_changes, batch_size=1000):  # Fast
       process_batch(batch)
   ```

2. **Connection Pooling**:
   ```python
   from pyodbc import pooling
   
   pooling.DEFAULT_POOL_SIZE = 5
   connection = pooling.get_connection(connection_string)
   ```

3. **Index Usage**:
   ```sql
   -- Ensure queries use indexes
   CREATE INDEX idx_audit_date ON audit_log(audit_date)
   WHERE is_active = 1  -- Filtered index for common queries
   ```

## Contributing New Features

### Feature Development Workflow

1. **Create branch for feature**:
   ```bash
   git checkout -b feature/new-capability
   ```

2. **Develop with tests**:
   ```bash
   # Write test first (TDD)
   pytest test_new_feature.py -v
   
   # Implement feature
   # Run tests to verify
   pytest test_new_feature.py -v
   ```

3. **Run full test suite**:
   ```bash
   pytest --cov=. --cov-fail-under=80
   ```

4. **Code quality checks**:
   ```bash
   black tracing_*.py
   pylint tracing_*.py
   mypy tracing_*.py
   ```

5. **Update documentation**:
   - Update relevant .md files
   - Add docstrings to code
   - Update README.md if needed

6. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add new feature: descriptive message"
   git push origin feature/new-capability
   ```

7. **Create pull request** with:
   - Clear description of changes
   - Link to related issues
   - Test results
   - Documentation updates

## Troubleshooting Development Issues

### Import Errors

```bash
# Verify Python path
python -c "import sys; print(sys.path)"

# Install package in development mode
pip install -e .

# Check installed packages
pip list | grep tracing
```

### Module Not Found

```bash
# Ensure __init__.py exists
touch tracing/__init__.py

# Add to PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

### Test Discovery Issues

```bash
# Verify test file naming
ls test_*.py

# Run specific test
pytest ./test_file.py::TestClass::test_method

# Force discovery
pytest --collect-only
```

## Related Documentation
- [Testing Guide](./testing-guide.md)
- [Architecture Overview](./architecture.md)
- [SQL Formatting Standards](./sql-formatting-standards.md)
