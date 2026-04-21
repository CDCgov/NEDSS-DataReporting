# Testing Guide

## Overview

The local-db-tracing utility uses comprehensive automated testing to ensure reliability and correctness of change capture and analysis operations.

## Test Organization

### Test Files

| Test File | Purpose |
|-----------|---------|
| `test_connection_defaults.py` | Database connection configuration and validation |
| `test_generate_rdb_selects.py` | SELECT query generation for RDB_MODERN |
| `test_logical_changes.py` | Logical change computation and diffing |
| `test_logical_compare.py` | Cross-database comparison logic |
| `test_logical_markdown.py` | Report generation and formatting |
| `test_metadata.py` | Schema extraction and metadata handling |
| `test_replay.py` | Change replay functionality |
| `test_tracing_post_processing.py` | Post-capture cleanup and finalization |
| `test_validate_rdb_selects.py` | RDB_MODERN query validation |

## Running Tests

### Run All Tests

```bash
# Basic run with verbose output
python -m pytest -v

# Run with coverage report
python -m pytest --cov=. --cov-report=html

# Run specific test file
python -m pytest test_logical_changes.py -v

# Run specific test function
python -m pytest test_logical_changes.py::test_detect_column_changes -v
```

### Continuous Testing

```bash
# Watch for file changes and rerun tests
pytest-watch

# Or manual polling
while inotifywait -r -e modify .; do
    clear
    python -m pytest -v
done
```

### Test Markers

Mark tests by category for selective running:

```bash
# Run only fast tests (unit tests)
python -m pytest -m "unit" -v

# Run only slow tests (integration tests)
python -m pytest -m "integration" -v

# Run only CDC-related tests
python -m pytest -m "cdc" -v

# Skip database-dependent tests
python -m pytest -m "not requires_db" -v
```

## Test Categories

### Unit Tests

Tests isolated functionality without external dependencies.

**Examples**:
- `test_logical_changes.py`: Diff algorithm validation
- `test_metadata.py`: Metadata parsing
- `test_logical_markdown.py`: Report formatting

**Run unit tests only**:
```bash
python -m pytest -m "unit" -v
```

### Integration Tests

Tests complete workflows with actual database connections.

**Examples**:
- `test_tracing_post_processing.py`: End-to-end post-processing
- `test_connection_defaults.py`: Real database connections
- `test_replay.py`: Actual change replay

**Prerequisites**:
- Database server running and accessible
- Test database created (typically test_nedss)
- Connection credentials configured in .env

**Run integration tests**:
```bash
# Requires database setup
python -m pytest -m "integration" -v --db-config .env.test
```

## Common Test Patterns

### Testing Database Connections

**File**: `test_connection_defaults.py`

```python
def test_connection_with_defaults():
    """Test connection using environment variable defaults"""
    config = get_connection_defaults()
    assert config.host == 'localhost'
    assert config.port == 1433

def test_connection_override_via_parameter():
    """Test connection configuration override"""
    config = get_connection_defaults(host='custom.server.com')
    assert config.host == 'custom.server.com'

def test_connection_string_generation():
    """Test correct ODBC connection string format"""
    conn_str = build_connection_string(
        host='server.local',
        username='sa',
        password='pass123'
    )
    assert 'Server=server.local' in conn_str
    assert 'Uid=sa' in conn_str
```

### Testing Logical Changes

**File**: `test_logical_changes.py`

```python
def test_detect_new_row():
    """Test detection of newly inserted row"""
    old_snapshot = []
    new_snapshot = [{'person_uid': 1, 'name': 'John'}]
    
    changes = compute_changes(old_snapshot, new_snapshot)
    
    assert len(changes) == 1
    assert changes[0].change_type == 'INSERT'
    assert changes[0].row_id == 1

def test_detect_column_change():
    """Test detection of column value changes"""
    old_row = {'person_uid': 1, 'name': 'John', 'age': 30}
    new_row = {'person_uid': 1, 'name': 'John', 'age': 31}
    
    columns_changed = identify_changed_columns(old_row, new_row)
    
    assert 'age' in columns_changed
    assert 'name' not in columns_changed

def test_handle_null_values():
    """Test proper NULL handling in comparisons"""
    old_row = {'field': 'value'}
    new_row = {'field': None}
    
    columns_changed = identify_changed_columns(old_row, new_row)
    
    assert 'field' in columns_changed  # NULL != 'value'

def test_compare_datetime_values():
    """Test datetime comparison with precision"""
    old_row = {'timestamp': datetime(2024, 1, 15, 14, 30, 22, 123456)}
    new_row = {'timestamp': datetime(2024, 1, 15, 14, 30, 22, 123457)}
    
    columns_changed = identify_changed_columns(old_row, new_row)
    
    # Depends on precision configuration
    assert 'timestamp' in columns_changed  # Or not, depending on config
```

### Testing Post-Processing

**File**: `test_tracing_post_processing.py`

```python
@pytest.mark.integration
def test_wait_for_post_processing_completion():
    """Test blocking until post-processing completes"""
    # Start background post-processing job
    job = start_post_processing_job()
    
    # Wait for completion with timeout
    is_complete = wait_for_post_processing_idle(timeout_seconds=30)
    
    assert is_complete is True
    assert job.is_alive() is False

@pytest.mark.integration
def test_post_processing_cleanup():
    """Test cleanup of temporary files after post-processing"""
    temp_dir = create_temp_processing_dir()
    
    # Create temporary files
    temp_file_1 = temp_dir.joinpath('temp_capture_1.csv')
    temp_file_2 = temp_dir.joinpath('temp_capture_2.csv')
    
    # Perform post-processing cleanup
    cleanup_temporary_files(temp_dir)
    
    # Verify cleanup
    assert not temp_file_1.exists()
    assert not temp_file_2.exists()
```

### Testing Output Generation

**File**: `test_logical_markdown.py`

```python
def test_generate_summary_report():
    """Test summary report generation"""
    manifest = {
        'start_time': '2024-01-15T14:30:00Z',
        'end_time': '2024-01-15T14:35:00Z',
        'record_counts': {
            'inserts': 100,
            'updates': 250,
            'deletes': 10
        }
    }
    
    summary = generate_summary_report(manifest)
    
    assert '2024-01-15' in summary
    assert '100' in summary  # Insert count
    assert '250' in summary  # Update count
    assert '10' in summary   # Delete count

def test_generate_manifest_json():
    """Test manifest JSON generation"""
    execution_data = {
        'database': 'NBS_ODSE',
        'operation_type': 'CDC',
        'start_lsn': '0x00000045:00000100:0001',
        'end_lsn': '0x00000050:00000200:0002',
        'total_changes': 360
    }
    
    manifest = generate_manifest(execution_data)
    
    # Verify valid JSON
    json_str = json.dumps(manifest)
    parsed = json.loads(json_str)
    
    assert parsed['database'] == 'NBS_ODSE'
    assert parsed['total_changes'] == 360
```

## Test Fixtures

Common test fixtures for reducing code duplication:

### Database Fixtures

```python
import pytest

@pytest.fixture
def test_db_connection():
    """Provide test database connection"""
    conn = create_connection('test_nedss')
    yield conn
    conn.close()

@pytest.fixture
def person_test_data():
    """Provide sample person records for testing"""
    return [
        {'person_uid': 1, 'first_name': 'John', 'last_name': 'Doe'},
        {'person_uid': 2, 'first_name': 'Jane', 'last_name': 'Smith'},
        {'person_uid': 3, 'first_name': 'Bob', 'last_name': 'Johnson'}
    ]
```

### Mock Data Fixtures

```python
@pytest.fixture
def sample_cdc_changes():
    """Provide sample CDC changes for testing"""
    return [
        {'operation': 2, 'person_uid': 1, 'columns': {'name': 'John'}},  # Insert
        {'operation': 4, 'person_uid': 1, 'columns': {'name': 'Jonathan'}},  # Update
        {'operation': 1, 'person_uid': 2, 'columns': {'name': 'Jane'}}  # Delete
    ]

@pytest.fixture
def temp_output_dir(tmp_path):
    """Provide temporary directory for test output"""
    output_dir = tmp_path / "output"
    output_dir.mkdir()
    return output_dir
```

## Mock vs Real Database Testing

### Approach 1: Always Mock (Fastest)

```python
from unittest.mock import Mock, patch

def test_capture_changes_with_mock():
    """Test capture logic with mocked database"""
    mock_connection = Mock()
    mock_cursor = Mock()
    mock_cursor.fetchall.return_value = [
        (1, 'person', 'INSERT', b'...'),
        (2, 'person', 'UPDATE', b'...'),
    ]
    mock_connection.cursor.return_value = mock_cursor
    
    changes = fetch_changes_for_captures(mock_connection)
    
    assert len(changes) == 2
    mock_cursor.execute.assert_called_once()
```

### Approach 2: Real Database (Most Comprehensive)

```python
@pytest.mark.integration
def test_capture_changes_real_db(test_db_connection):
    """Test with actual database connection"""
    # Insert test data
    insert_test_person(test_db_connection, person_uid=999)
    
    # Capture changes
    changes = fetch_changes_for_captures(test_db_connection)
    
    # Verify capture
    assert any(c['person_uid'] == 999 for c in changes)
    
    # Cleanup
    delete_test_person(test_db_connection, person_uid=999)
```

### Approach 3: Hybrid (Balanced)

```python
@pytest.fixture
def isolated_test_db(test_db_connection):
    """Provide isolated transaction for testing"""
    test_db_connection.begin_transaction()
    yield test_db_connection
    test_db_connection.rollback()  # Cleanup without persisting

@pytest.mark.integration
def test_with_isolated_transaction(isolated_test_db):
    """Test with real DB but automatic cleanup"""
    insert_test_data(isolated_test_db)
    result = capture_changes(isolated_test_db)
    assert result is not None
    # Automatic rollback after test
```

## Test Configuration

### pytest.ini

```ini
[pytest]
# Test discovery patterns
python_files = test_*.py
python_classes = Test*
python_functions = test_*

# Markers for test categorization
markers =
    unit: Unit tests (no external dependencies)
    integration: Integration tests (requires database)
    cdc: CDC-related tests
    logical: Logical change tests
    slow: Slow running tests
    requires_db: Tests requiring database connection

# Timeout for tests (requires pytest-timeout)
timeout = 300

# Coverage options
addopts = --strict-markers

# Minimum Python version
minversion = 3.7
```

### conftest.py

Central configuration for all tests:

```python
import pytest
import os
from pathlib import Path

# Load test environment
pytest_plugins = ['pytest_cov', 'pytest_timeout']

@pytest.fixture(scope="session")
def test_env():
    """Load test environment variables"""
    env_file = Path('.env.test')
    if env_file.exists():
        from dotenv import load_dotenv
        load_dotenv(env_file)

def pytest_configure(config):
    """Register custom markers"""
    config.addinivalue_line("markers", "unit: unit test")
    config.addinivalue_line("markers", "integration: integration test")

def pytest_collection_modifyitems(config, items):
    """Add markers based on test names"""
    for item in items:
        if "integration" in item.nodeid:
            item.add_marker(pytest.mark.integration)
        elif any(x in item.nodeid for x in ["cdc", "capture"]):
            item.add_marker(pytest.mark.cdc)
```

## Coverage Analysis

### Generate Coverage Report

```bash
# Run tests with coverage
python -m pytest --cov=. --cov-report=html --cov-report=term-missing

# View HTML report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
start htmlcov/index.html  # Windows
```

### Coverage Thresholds

```bash
# Fail if coverage drops below 80%
python -m pytest --cov=. --cov-fail-under=80

# Or configure in pytest.ini:
# [coverage:run]
# fail_under = 80
```

### Coverage Exclusion

Mark lines to exclude from coverage:

```python
def rarely_executed_function():
    if impossible_condition:  # pragma: no cover
        raise Exception("This should never happen")
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mssql:
        image: mcr.microsoft.com/mssql/server:2019-latest
        env:
          SA_PASSWORD: TestPassword123!
          ACCEPT_EULA: Y
        options: >-
          --health-cmd "/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P TestPassword123! -Q 'SELECT 1'"
          --health-interval 10s
          --health-timeout 3s
          --health-retries 10
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.9
      
      - name: Install dependencies
        run: |
          pip install -r requirements-dev.txt
      
      - name: Run tests
        run: pytest --cov=. --cov-report=xml
        env:
          DB_HOST: localhost
          DB_USERNAME: sa
          DB_PASSWORD: TestPassword123!
      
      - name: Upload coverage
        uses: codecov/codecov-action@v2
```

## Test Development Workflow

### TDD (Test-Driven Development)

1. **Write failing test**:
   ```python
   def test_new_feature():
       result = new_function()
       assert result == expected
   ```

2. **Run test to confirm failure**:
   ```bash
   pytest test_file.py::test_new_feature -v
   # Expected: FAILED
   ```

3. **Implement feature**:
   ```python
   def new_function():
       return expected  # Minimal implementation
   ```

4. **Run test to confirm passing**:
   ```bash
   pytest test_file.py::test_new_feature -v
   # Expected: PASSED
   ```

5. **Refactor as needed**:
   - Maintain test passing
   - Improve code quality

## Debugging Failed Tests

### Verbose Output

```bash
# Very verbose with print statements
pytest -vv -s test_file.py::test_function

# Show local variables on failure
pytest -l test_file.py

# Drop into debugger on failure
pytest --pdb test_file.py
```

### Inspect Test State

```python
import pytest

def test_with_debugging():
    result = complex_operation()
    
    # Unconditional breakpoint
    pytest.set_trace()  # Execution pauses here, inspect variables
    
    assert result == expected
```

### Capture Output

```python
def test_with_output_capture(capsys):
    """Test captures stdout/stderr"""
    print("Debug message")
    captured = capsys.readouterr()
    
    assert "Debug message" in captured.out
```

## Related Documentation
- [Architecture Overview](./architecture.md)
- [Development Guide](./development.md)
