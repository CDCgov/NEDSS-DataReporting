# Configuration Reference

## Environment Variables

### Database Connection

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DB_HOST` | string | localhost | Database server hostname or IP address |
| `DB_PORT` | int | 1433 | SQL Server port number |
| `DB_USERNAME` | string | sa | Database login username |
| `DB_PASSWORD` | string | - | Database login password |
| `DB_NAME` | string | NBS_ODSE (CDC) / RDB_MODERN (Logical) | Target database name |
| `DB_CONNECT_TIMEOUT` | int | 30 | Connection timeout in seconds |

### Tracing Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `BATCH_SIZE` | int | 1000 | Number of records per processing batch |
| `OUTPUT_DIR` | string | ./output | Root directory for trace output |
| `ENABLE_CLEANUP` | bool | true | Delete temporary files after execution |
| `COMPRESSION` | string | none | Compression format (none, gzip, bzip2) |
| `TIMESTAMP_FORMAT` | string | ISO8601 | Output timestamp format |

### Performance Tuning

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `MAX_CONNECTIONS` | int | 5 | Maximum concurrent database connections |
| `TIMEOUT_SECONDS` | int | 300 | Operation timeout in seconds |
| `MAX_RETRIES` | int | 3 | Number of retry attempts on failure |
| `RETRY_DELAY_MS` | int | 1000 | Milliseconds to wait between retries |

### Logging

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `LOG_LEVEL` | string | INFO | Logging verbosity (DEBUG, INFO, WARNING, ERROR) |
| `LOG_FILE` | string | ./logs/tracing.log | Log output file path |
| `LOG_MAX_SIZE` | int | 10 | Maximum log file size in MB |
| `LOG_BACKUP_COUNT` | int | 5 | Number of backup log files to retain |

### CDC-Specific Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `CDC_ENABLED_TABLES` | string | (all) | Comma-separated list of tables to capture (CDC only) |
| `CDC_START_LSN` | string | (auto) | Starting LSN; leave empty for automatic detection |
| `CDC_BLOCKSIZE` | int | 64 | LSN block size for chunked processing |
| `CDC_VALIDATE_ENABLED` | bool | true | Validate CDC is enabled before capturing |

### Logical Changes Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `LOGICAL_START_TIME` | ISO8601 | (auto) | Start timestamp for logical comparison |
| `LOGICAL_END_TIME` | ISO8601 | now | End timestamp for logical comparison |
| `LOGICAL_DEEP_COMPARE` | bool | false | Enable column-level comparison (slower) |
| `LOGICAL_INCLUDE_UNCHANGED` | bool | false | Include unchanged rows in output |

## .env File Format

Example `.env` configuration:

```bash
# Database Connection
DB_HOST=sqlserver.example.com
DB_PORT=1433
DB_USERNAME=tracing_user
DB_PASSWORD=SecurePassword123!

# Tracing Configuration
BATCH_SIZE=2000
OUTPUT_DIR=/data/traces
ENABLE_CLEANUP=true
COMPRESSION=gzip

# Performance
MAX_CONNECTIONS=10
TIMEOUT_SECONDS=600
MAX_RETRIES=5

# Logging
LOG_LEVEL=INFO
LOG_FILE=./logs/tracing.log
```

## Configuration File Formats

### known_lookup_keys.json

Defines lookup table associations for entity resolution:

```json
{
  "person_uid": {
    "table": "dbo.person",
    "lookup_query": "SELECT person_uid, first_name, last_name FROM dbo.person WHERE person_uid = ?",
    "cache_enabled": true
  },
  "investigation_uid": {
    "table": "dbo.investigation",
    "lookup_query": "SELECT investigation_uid, investigations_status FROM dbo.investigation WHERE investigation_uid = ?",
    "cache_enabled": true
  }
}
```

### known_replay_associations.json

Maps relationships for replay operations:

```json
{
  "investigation_to_observation": {
    "source_table": "dbo.investigation",
    "target_table": "dbo.observation",
    "join_condition": "investigation_uid",
    "relationship_type": "one_to_many"
  },
  "person_to_investigation": {
    "source_table": "dbo.person",
    "target_table": "dbo.investigation",
    "join_condition": "person_uid",
    "relationship_type": "one_to_many"
  }
}
```

### tracing_constants.py

Python-based constants configuration:

```python
# Batch Processing
BATCH_SIZE = 1000
MAX_BATCH_ITEMS = 10000

# Timeout Values (seconds)
DEFAULT_TIMEOUT = 300
CONNECTION_TIMEOUT = 30
PROCESSING_TIMEOUT = 600

# LSN Configuration
LSN_BLOCK_SIZE = 64  # Blocks per chunk
MIN_LSN_RANGE = '0x00000000:00000000:0000'

# Output Formats
MANIFEST_VERSION = "1.0"
REPORT_ENCODING = "utf-8"

# Performance
MAX_PARALLEL_OPERATIONS = 5
MEMORY_THRESHOLD_MB = 500
```

## Command-Line Arguments

Command-line arguments override all other configuration sources:

### trace_db_cdc.py

```bash
python trace_db_cdc.py \
  --host <hostname> \
  --port <port> \
  --username <user> \
  --password <pass> \
  --database <db> \
  --output-dir <path> \
  --batch-size <size> \
  --start-lsn <lsn> \
  --end-lsn <lsn> \
  --tables <t1,t2,...> \
  --timeout <seconds> \
  --no-cleanup \
  --verbose
```

### trace_db_logical_changes.py

```bash
python trace_db_logical_changes.py \
  --host <hostname> \
  --port <port> \
  --username <user> \
  --password <pass> \
  --database <db> \
  --output-dir <path> \
  --start-time <iso8601> \
  --end-time <iso8601> \
  --tables <t1,t2,...> \
  --deep-compare \
  --include-unchanged \
  --timeout <seconds> \
  --verbose
```

## Configuration Hierarchy

Configurations are resolved in this order (highest to lowest priority):

1. **Command-line arguments** 
   - Explicitly provided flags and options
   - Example: `--batch-size 5000`

2. **Environment variables**
   - Values from `.env` file or system environment
   - Example: `BATCH_SIZE=2000`

3. **Local configuration files**
   - `tracing_constants.py` module
   - `.local/config.json` if present
   - Example: `BATCH_SIZE = 2000`

4. **Built-in defaults**
   - Hard-coded values in source code
   - Example: `DEFAULT_BATCH_SIZE = 1000`

Example resolution:
```
$ BATCH_SIZE=3000 python trace_db_cdc.py --batch-size 5000
# Result: batch_size = 5000 (CLI wins)

$ BATCH_SIZE=3000 python trace_db_cdc.py
# Result: batch_size = 3000 (env var used)

$ python trace_db_cdc.py
# Result: batch_size = 1000 (default used)
```

## Database Connection Strings

### Format

SQL Server connection strings follow the ODBC format:

```
Driver={ODBC Driver 17 for SQL Server};Server=<host>,<port>;Database=<db>;UID=<user>;PWD=<password>
```

### Examples

**Local SQL Server**:
```
Server=localhost,1433;Database=NBS_ODSE;User Id=sa;Password=Password123
```

**Named Instance**:
```
Server=sqlserver\SQLEXPRESS,1433;Database=RDB_MODERN;User Id=tracing_user;Password=Password123
```

**Azure SQL Database**:
```
Server=myserver.database.windows.net,1433;Database=NBS_ODSE;User Id=user@myserver;Password=Password123;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30
```

**Network Address Resolution**:
```
Server=IP_ADDRESS,PORT;Database=NBS_ODSE;User Id=sa;Password=Password123
```

## Performance Tuning Guide

### For Large Tables (>1M rows)

```bash
# .env configuration
BATCH_SIZE=5000
MAX_CONNECTIONS=10
TIMEOUT_SECONDS=900
MAX_RETRIES=5
```

### For Memory-Constrained Environments

```bash
# .env configuration
BATCH_SIZE=250
MAX_CONNECTIONS=2
COMPRESSION=gzip
ENABLE_CLEANUP=true
```

### For Fast Networks (Low Latency)

```bash
# .env configuration
BATCH_SIZE=10000
MAX_CONNECTIONS=20
TIMEOUT_SECONDS=300
DB_CONNECT_TIMEOUT=10
```

### For Slow/Unreliable Networks

```bash
# .env configuration
BATCH_SIZE=500
MAX_CONNECTIONS=5
TIMEOUT_SECONDS=600
MAX_RETRIES=10
RETRY_DELAY_MS=2000
DB_CONNECT_TIMEOUT=60
```

## Security Best Practices

### Credential Management

**DO**:
- Use .env files for local development
- Set file permissions: `chmod 600 .env`
- Use database role with minimum required permissions
- Store production credentials in secure vault

**DON'T**:
- Commit .env files to version control
- Pass passwords via command-line arguments
- Log sensitive connection data
- Store credentials in code

### Example .env Permissions (Unix/Linux)

```bash
# Set restricted permissions
chmod 600 .env

# Verify permissions
ls -la .env
# -rw------- 1 user group 256 Jan 15 14:30 .env
```

### Database User Permissions

Minimum required permissions for tracing user:

```sql
-- SQL Server - Create minimal tracing user
CREATE LOGIN tracing_user WITH PASSWORD = 'SecurePassword123!';
CREATE USER tracing_user FOR LOGIN tracing_user;

-- Grant SELECT on all tables
GRANT SELECT ON SCHEMA::dbo TO tracing_user;

-- For CDC capture, also grant:
GRANT SELECT ON cdc.change_tables TO tracing_user;
GRANT EXECUTE ON cdc.fn_cdc_get_net_changes_* TO tracing_user;
```

## Troubleshooting Configuration

### Enable Debug Logging

```bash
# Via environment variable
LOG_LEVEL=DEBUG python trace_db_cdc.py

# Via .env file
LOG_LEVEL=DEBUG
LOG_FILE=./logs/debug.log
```

### Verify Configuration

```bash
# Check environment variables
env | grep ^DB_

# Check .env file
cat .env | grep -v "^#"

# Run with verbose flag
python trace_db_cdc.py --verbose
```

### Configuration Conflicts

```bash
# If conflicts occur, test resolution:
python -c "
import os
from tracing_env import get_config
config = get_config()
print(f'DB_HOST: {config.db_host}')
print(f'BATCH_SIZE: {config.batch_size}')
"
```

## Related Documentation
- [Usage Guide](./usage-guide.md)
- [Architecture Overview](./architecture.md)
- [Troubleshooting Guide](./troubleshooting.md)
