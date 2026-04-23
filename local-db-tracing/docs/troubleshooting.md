# Troubleshooting Guide

## Connection Issues

### Unable to Connect to Database

**Error**:
```
pyodbc.OperationalError: ('08001', '[08001] [Microsoft][ODBC Driver 17 for SQL Server]Named Pipes Provider: Could not open a connection to SQL Server')
```

**Diagnosis**:
- Run network connectivity test:
  ```bash
  ping <DB_HOST>
  telnet <DB_HOST> 1433
  ```

**Solutions**:

1. **Verify hostname and port**:
   - Confirm host is reachable
   - Check port 1433 is open (not 1433 by default on named instances)
   - For named instances, use: `hostname\INSTANCENAME` or query the SQL Server Browser
   
2. **Check firewall settings**:
   - Allow outbound TCP 1433 (SQL Server default)
   - Verify firewall on database server allows inbound connections
   - Test with: `telnet <DB_HOST> 1433`

3. **Verify database is running**:
   ```sql
   -- On the server, check service status
   SELECT @@SERVERNAME as ServerName, @@VERSION as Version
   ```

4. **Check connection string format**:
   ```bash
   # Correct format
   Server=hostname,1433;Database=NBS_ODSE;User Id=sa;Password=pass
   
   # Not valid (missing comma)
   Server=hostname 1433;...  # Missing comma before port
   ```

5. **Test with explicit host and port**:
   ```bash
   python trace_db_cdc.py \
     --host sqlserver.example.com \
     --port 1433 \
     --username sa \
     --password "password"
   ```

### Authentication Failure

**Error**:
```
pyodbc.Error: ('28000', "[28000] [Microsoft][ODBC Driver 17 for SQL Server]Login failed for user 'sa'")
```

**Solutions**:

1. **Verify credentials**:
   - Confirm username and password are correct
   - Check .env file for typos:
     ```bash
     cat .env | grep "^DB_"
     ```

2. **Check SQL Server authentication mode**:
   ```sql
   -- Must be in Mixed Mode, not Windows Authentication only
   SELECT CASE 
     WHEN @@VERSION LIKE '%Server 2019%' THEN 'SQL Server 2019'
     ELSE 'Other Version'
   END as Version
   ```

3. **Reset password if needed**:
   - Connect as sa (if available)
   - Create new user: `CREATE LOGIN new_user WITH PASSWORD = 'complex_password'`

4. **Check user permissions**:
   ```sql
   -- Verify user exists and is enabled
   SELECT principal_id, name, type, is_disabled 
   FROM sys.server_principals 
   WHERE name = 'tracing_user'
   ```

### TLS/SSL Certificate Errors

**Error**:
```
[08001] [Microsoft][ODBC Driver 17 for SQL Server]SSL Provider: The certificate chain was issued by an authority that is not trusted
```

**Solutions**:

1. **For development/testing** (NOT production):
   ```bash
   # Add to connection string
   Encrypt=no;TrustServerCertificate=yes
   ```

2. **For production, install proper certificate**:
   - Obtain server certificate from certificate authority
   - Add to connection string:
     ```bash
     Encrypt=yes;TrustServerCertificate=no;
     ```

3. **Verify certificate on database server**:
   ```powershell
   # PowerShell on Windows
   Get-Item -Path Cert:\LocalMachine\My | Where-Object { $_.Issuer -like "*SQL*" }
   ```

---

## CDC-Related Issues

### CDC Not Enabled on Database

**Error**:
```
Database error: CDC is not enabled for database 'NBS_ODSE'
```

**Diagnosis**:
```sql
-- Check if CDC is enabled
SELECT is_cdc_enabled FROM sys.databases WHERE name = 'NBS_ODSE'
-- Result: 0 = disabled, 1 = enabled
```

**Solution** (requires db_owner role):
```sql
-- Enable CDC on database
EXEC sys.sp_cdc_enable_db;

-- Verify
SELECT is_cdc_enabled FROM sys.databases WHERE name = 'NBS_ODSE'
-- Result should be: 1
```

### CDC Not Enabled on Specific Table

**Error**:
```
Cannot capture changes for table dbo.person - CDC not enabled
```

**Diagnosis**:
```sql
-- List CDC-enabled tables
SELECT t.name FROM cdc.change_tables ct
JOIN sys.tables t ON ct.source_object_id = t.object_id
WHERE ct.source_schema_id = SCHEMA_ID('dbo')
```

**Solution** (requires db_owner role):
```sql
-- Enable CDC on specific table
EXEC sys.sp_cdc_enable_table
  @source_schema = 'dbo',
  @source_name = 'person',
  @role_name = NULL,  -- Or specify a role name
  @supports_net_changes = 1;  -- For net changes capture

-- Verify
EXEC sys.sp_cdc_help_change_capture @source_schema = 'dbo', @source_name = 'person'
```

### No Changes Captured (Empty Result Set)

**Possible Causes**:

1. **LSN range contains no changes**:
   - The specified LSN window may be before any actual changes occurred

   **Debug**:
   ```sql
   -- Check current LSN of database
   SELECT sys.fn_cdc_get_max_lsn() as current_max_lsn
   ```

2. **Capture instance not active**:
   ```sql
   -- Check capture instance status
   SELECT * FROM cdc.change_tables
   ```

3. **Table has not had changes since CDC enabled**:

**Solutions**:

1. **Widen LSN/timestamp window**:
   - When prompted, select a larger time range
   - Or specify explicitly:
     ```bash
     python trace_db_cdc.py \
       --start-lsn "0x00000000:00000000:0000" \
       --end-lsn "0x00000500:00000000:0000"
     ```

2. **Verify table changes independently**:
   ```bash
   # Make a test change to the table
   UPDATE dbo.person SET first_name = UPPER(first_name) WHERE person_uid = 1
   
   # Then re-run trace
   python trace_db_cdc.py
   ```

3. **Check CDC cleanup jobs**:
   ```sql
   -- CDC cleanup may have purged old changes
   SELECT * FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.person')
   ```

### CDC Capture Returns Duplicates

**Symptom**: Same row appears multiple times in output

**Cause**: Concurrent modifications to the same row within capture window

**Solution**:

1. **Use net changes (recommended)**:
   ```sql
   -- Ensure CDC is configured for net changes
   SELECT supports_net_changes FROM cdc.change_tables
   WHERE source_object_id = OBJECT_ID('dbo.person')
   -- Result: 1 = net changes enabled
   ```

2. **If manual deduplication needed**:
   ```bash
   # Sort and uniq on primary key column
   sort <capture_file> | uniq -f 1 > <deduplicated_file>
   ```

---

## Output and Processing Issues

### Post-Processing Timeout

**Error**:
```
Timeout waiting for post-processing to complete (timeout: 300s)
```

**Diagnosis**:
```bash
# Check for hanging background processes
ps aux | grep post_processing
ps aux | grep python

# Check logs
tail -50 logs/tracing.log | grep -i "post.process"
```

**Solutions**:

1. **Increase timeout**:
   ```bash
   python trace_db_cdc.py --timeout 900  # 15 minutes
   ```

2. **Check for stuck processes**:
   ```bash
   # Linux/Mac
   pkill -f "post_processing"
   
   # Windows PowerShell
   Get-Process | Where-Object { $_.ProcessName -like "*python*" } | Stop-Process -Force
   ```

3. **Reduce batch size** (reduces per-batch processing time):
   ```bash
   python trace_db_cdc.py --batch-size 500
   ```

4. **Check disk space** (post-processing may fail with full disk):
   ```bash
   df -h  # Unix/Linux
   Get-Volume  # Windows PowerShell
   ```

### Out of Memory During Capture

**Error**:
```
MemoryError: Unable to allocate memory for batch processing
```

**Solutions**:

1. **Reduce batch size**:
   ```bash
   python trace_db_cdc.py --batch-size 250
   ```

2. **Enable compression**:
   ```bash
   # Via .env
   COMPRESSION=gzip
   ```

3. **Stream output instead of buffering**:
   ```bash
   # Depends on implementation
   python trace_db_cdc.py | tee output.log
   ```

4. **Split large captures**:
   ```bash
   # Run multiple smaller captures with disjoint LSN ranges
   python trace_db_cdc.py --batch-size 100  # First batch
   # After completion, resume:
   python trace_db_cdc.py  # Auto-resumes from checkpoint
   ```

### Output Files Corrupted or Incomplete

**Symptoms**: 
- Missing CSV columns
- Truncated manifest.json
- Summary report empty

**Diagnosis**:
```bash
# Check file integrity
ls -lh output/YYYYMMDD*/  # Verify file sizes
file output/YYYYMMDD*/manifest.json  # Verify JSON format
jq . output/YYYYMMDD*/manifest.json  # Validate JSON

# Check for write errors
tail logs/tracing.log | grep -i "error\|exception"
```

**Solutions**:

1. **Verify disk space was available**:
   ```bash
   df -h .  # Check available space in output directory
   ```

2. **Re-run capture** (with checkpoints):
   ```bash
   python trace_db_cdc.py  # Resumes from last checkpoint
   ```

3. **Manual cleanup if needed**:
   ```bash
   # Backup corrupted output
   mv output/YYYYMMDD/ output/YYYYMMDD_.backup
   
   # Re-run capture
   python trace_db_cdc.py
   ```

---

## Logical Changes Issues

### Comparison Returns No Changes (But Changes Exist)

**Error**: Logical change trace shows 0 changes despite time window spanning modifications

**Diagnosis**:
```bash
# Manually check for changes in time window
SELECT COUNT(*) FROM dbo.person 
WHERE ModifiedDate BETWEEN @start_time AND @end_time
```

**Solutions**:

1. **Verify timestamp columns exist**:
   ```sql
   -- Check what timestamp columns are captured
   SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
   WHERE TABLE_NAME = 'person' AND COLUMN_NAME LIKE '%[Dd]ate%time%'
   ```

2. **Ensure time zones match**:
   - Local time vs. UTC
   - Database server vs. client system time
   ```bash
   # Use ISO 8601 format (includes timezone)
   python trace_db_logical_changes.py --start-time "2024-01-15T14:30:00Z"
   ```

3. **Expand time window**:
   ```bash
   python trace_db_logical_changes.py \
     --start-time "2024-01-15T00:00:00Z" \
     --end-time "2024-01-16T00:00:00Z"
   ```

### Deep Compare Takes Too Long

**Symptom**: `--deep-compare` flag causes extremely slow execution

**Root Cause**: Column-level comparisons require additional queries per row

**Solutions**:

1. **Reduce scope to specific tables**:
   ```bash
   python trace_db_logical_changes.py \
     --deep-compare \
     --tables "dbo.person,dbo.investigation"
   ```

2. **Use shallow compare for large result sets**:
   ```bash
   # First run without deep compare
   python trace_db_logical_changes.py \
     --start-time "2024-01-15T14:30:00Z" \
     --end-time "2024-01-15T15:00:00Z"
   
   # Then drill into specific changes with deep compare
   ```

3. **Increase timeout and reduce batch size**:
   ```bash
   python trace_db_logical_changes.py \
     --deep-compare \
     --batch-size 100 \
     --timeout 1200
   ```

4. **Create index on timestamp columns** (if permitted):
   ```sql
   CREATE INDEX idx_person_modifieddate 
   ON dbo.person(ModifiedDate) 
   WHERE is_deleted = 0
   ```

### Column-Level Changes Not Detected

**Symptom**: `deep_compare` flag enabled, but no column-level differences reported

**Cause**: Column value comparison may fail for complex types

**Debug**:
```bash
# Enable debug logging
LOG_LEVEL=DEBUG python trace_db_logical_changes.py --deep-compare
```

**Solutions**:

1. **Check for unsupported column types**:
   ```sql
   -- Query information about problematic columns
   SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH 
   FROM INFORMATION_SCHEMA.COLUMNS 
   WHERE TABLE_NAME = 'observation' 
   AND DATA_TYPE IN ('image', 'varbinary', 'xml')
   ```

2. **Exclude problematic columns**:
   ```bash
   # Via known_lookup_keys.json configuration
   # Exclude binary/xml columns from comparison
   ```

---

## Performance Issues

### Trace Runs Very Slowly

**Diagnosis**:
```bash
# Check system resources
top         # Linux/Mac
Get-Process -Name "python" | Select-Object CPU, PM  # Windows PowerShell

# Check SQL Server performance
# Inside SQL Server Management Studio:
DBCC INPUTBUFFER(<spid>)  -- Check query being executed
```

**Solutions**:

1. **Increase batch size** (fewer round-trips):
   ```bash
   python trace_db_cdc.py --batch-size 5000
   ```

2. **Reduce concurrent connections**:
   ```bash
   # .env
   MAX_CONNECTIONS=2
   ```

3. **Schedule during off-peak hours**:
   - Reduces database contention
   - More resources available for capture

4. **Verify network performance**:
   ```bash
   # Test latency to database server
   ping <DB_HOST>
   
   # Test bandwidth
   # Transfer test file to/from database server
   ```

### High CPU Usage

**Solutions**:

1. **Reduce batch size** (less buffering):
   ```bash
   python trace_db_cdc.py --batch-size 250
   ```

2. **Limit concurrent threads**:
   ```bash
   MAX_CONNECTIONS=2 python trace_db_cdc.py
   ```

3. **Use process priority control**:
   ```bash
   # Linux/Mac
   nice -n 10 python trace_db_cdc.py
   
   # Windows PowerShell
   $pythonProcess = Get-Process -Name python
   $pythonProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
   ```

### High Memory Usage

**Solutions** (in order of effectiveness):

1. **Enable compression**:
   ```bash
   COMPRESSION=gzip python trace_db_cdc.py
   ```

2. **Reduce batch size**:
   ```bash
   python trace_db_cdc.py --batch-size 100
   ```

3. **Increase `OUTPUT_DIR` scan frequency** (flush to disk more often):
   ```bash
   # Depends on implementation - may not be configurable
   ```

4. **Monitor memory usage**:
   ```bash
   # Linux - watch memory in real-time
   watch -n 1 'ps aux | grep python | grep trace_db'
   
   # Windows - PowerShell alternative
   while($true) { Clear-Host; Get-Process -Name python | Format-Table; Start-Sleep -Seconds 1 }
   ```

---

## File System Issues

### Permission Denied on Output Directory

**Error**:
```
PermissionError: [Errno 13] Permission denied: 'output/20240115-143022'
```

**Solutions**:

1. **Check directory permissions**:
   ```bash
   ls -ld output/
   # Should show something like: drwxr-xr-x
   ```

2. **Create output directory with proper permissions**:
   ```bash
   mkdir -p output
   chmod 755 output
   ```

3. **Run with appropriate user**:
   ```bash
   # If running as different user, ensure they have write permissions
   sudo chown $USER:$USER output
   ```

### Disk Space Exhausted

**Error**:
```
IOError: [Errno 28] No space left on device
```

**Solutions**:

1. **Check available disk space**:
   ```bash
   df -h .
   du -sh output/  # Size of existing traces
   ```

2. **Clean up old traces**:
   ```bash
   # List traces by size
   du -sh output/*/ | sort -rh | head -10
   
   # Remove old traces (backup first!)
   tar -czf output/old-traces-backup.tar.gz output/YYYYMMDD-*/
   rm -rf output/YYYYMMDD-*/
   ```

3. **Enable compression to reduce size**:
   ```bash
   COMPRESSION=gzip python trace_db_cdc.py
   ```

4. **Use external disk for output**:
   ```bash
   python trace_db_cdc.py --output-dir /mnt/external-disk/traces
   ```

---

## Logging and Debugging

### Enable Debug Logging

```bash
# Via environment variable
LOG_LEVEL=DEBUG python trace_db_cdc.py

# Via .env file
echo "LOG_LEVEL=DEBUG" >> .env

# Capture to file for analysis
LOG_LEVEL=DEBUG python trace_db_cdc.py > debug_output.txt 2>&1
tail -f debug_output.txt  # Watch in real-time
```

### Common Log Patterns

```bash
# View errors in logs
grep -i "error\|exception\|failed" logs/tracing.log

# View warnings
grep -i "warning" logs/tracing.log

# View specific operation (e.g., connection)
grep -i "connect\|login" logs/tracing.log

# Timeline of operations
grep "2024-01-15 14:" logs/tracing.log
```

### Collecting Diagnostic Information

```bash
# Gather system information
echo "=== Python Version ===" && python --version
echo "=== Database Connection ===" && python -c "import pyodbc; print(pyodbc.drivers())"
echo "=== Configuration ===" && cat .env | grep -v "^#"
echo "=== Recent Logs ===" && tail -100 logs/tracing.log
echo "=== Disk Space ===" && df -h .
echo "=== Process Info ===" && ps aux | grep python
```

---

## Related Documentation
- [Usage Guide](./usage-guide.md)
- [Architecture Overview](./architecture.md)
- [Configuration Reference](./configuration-reference.md)
