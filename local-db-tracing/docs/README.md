# Local Database Tracing Documentation Index

Welcome to the local-db-tracing documentation! This comprehensive guide covers all aspects of the database change tracking and analysis utility.

## Quick Navigation

### Getting Started

**New to the project?** Start here:

1. **[Usage Guide](./usage-guide.md)** - How to run the tracing tools
   - Quick start with CDC and logical changes
   - Dual database monitoring
   - Command-line options
   - Understanding output files

2. **[Architecture Overview](./architecture.md)** - System design and components
   - Core modules and responsibilities
   - Data flow and workflow
   - Performance considerations

### For Developers

**Building and extending the toolset:**

1. **[Development Guide](./development.md)** - Development environment and practices
   - Setup and prerequisites
   - Project structure
   - Common development tasks
   - Code style and standards
   - Debugging techniques

2. **[Testing Guide](./testing-guide.md)** - Comprehensive testing practices
   - Test organization and structure
   - Running and writing tests
   - Coverage analysis
   - CI/CD integration

3. **[SQL Formatting Standards](./sql-formatting-standards.md)** - SQL code conventions
   - Parameter alignment rules
   - Naming conventions
   - Query structure patterns
   - Automated formatting tools

### Reference Guides

**Looking for specific information:**

1. **[Configuration Reference](./configuration-reference.md)** - All configuration options
   - Environment variables
   - Configuration file formats
   - Performance tuning
   - Security best practices

2. **[Troubleshooting Guide](./troubleshooting.md)** - Solutions to common issues
   - Connection problems
   - CDC-related issues
   - Performance problems
   - Output issues
   - Debugging techniques

## Documentation Map

### By Role

**Database Administrators**:
- [Configuration Reference](./configuration-reference.md) - Database setup
- [Troubleshooting Guide](./troubleshooting.md) - Problem solving
- [Usage Guide](./usage-guide.md) - Running the tools

**Python Developers**:
- [Development Guide](./development.md) - Development environment
- [Testing Guide](./testing-guide.md) - Testing practices
- [Architecture Overview](./architecture.md) - System design

**SQL Developers**:
- [SQL Formatting Standards](./sql-formatting-standards.md) - Code standards
- [Configuration Reference](./configuration-reference.md) - Database configuration
- [Troubleshooting Guide](./troubleshooting.md) - SQL-related issues

**DevOps Engineers**:
- [Configuration Reference](./configuration-reference.md) - Environment setup
- [Usage Guide](./usage-guide.md) - Operational workflows
- [Troubleshooting Guide](./troubleshooting.md) - System troubleshooting

### By Topic

**Installation & Setup**:
- [Usage Guide - Quick Start](./usage-guide.md#quick-start)
- [Development Guide - Environment Setup](./development.md#getting-started)

**Running Traces**:
- [Usage Guide - Running Trace Operations](./usage-guide.md#running-trace-operations)
- [Usage Guide - Workflow Scenarios](./usage-guide.md#workflow-scenarios)

**Configuration**:
- [Configuration Reference - Environment Variables](./configuration-reference.md#environment-variables)
- [Configuration Reference - Performance Tuning](./configuration-reference.md#performance-tuning-guide)

**Architecture & Design**:
- [Architecture Overview](./architecture.md)
- [Development Guide - Architecture Overview](./development.md#architecture-overview)

**Debugging & Troubleshooting**:
- [Troubleshooting Guide](./troubleshooting.md)
- [Development Guide - Debugging Techniques](./development.md#debugging-techniques)

**Testing**:
- [Testing Guide](./testing-guide.md)
- [Development Guide - Testing](./development.md)

**Code Quality**:
- [SQL Formatting Standards](./sql-formatting-standards.md)
- [Development Guide - Code Style](./development.md#code-style-and-standards)

## Common Tasks

### Task: Set up local development environment

1. Read: [Development Guide - Getting Started](./development.md#getting-started)
2. Read: [Configuration Reference - Environment Variables](./configuration-reference.md#environment-variables)
3. Run: `python -m pytest test_connection_defaults.py -v` to verify setup

### Task: Run CDC trace to capture database changes

1. Read: [Usage Guide - Quick Start](./usage-guide.md#quick-start)
2. Run: `python trace_db_cdc.py`
3. Review: `output/YYYYMMDD-HHMMSS-NBS_ODSE-CDC/manifest.json`

### Task: Run dual database comparison

1. Read: [Usage Guide - Dual Database Tracing](./usage-guide.md#dual-database-tracing)
2. Open terminal 1: `python trace_db_cdc.py`
3. Open terminal 2: `python trace_db_logical_changes.py`
4. Compare outputs in `output/` directory

### Task: Generate RDB verification SQL with literal values

1. Read: [Usage Guide - Generate RDB Verification SQL](./usage-guide.md#generate-rdb-verification-sql)
2. Run: `python generate_rdb_selects.py --combined-manifest output/<paired-run>/combined-manifest.json --literal-values`
3. Review: `output/<paired-run>/rdb-selects.sql` and `output/<paired-run>/expected.json`

### Task: Troubleshoot connection issues

1. Read: [Troubleshooting - Connection Issues](./troubleshooting.md#connection-issues)
2. Check: [Configuration Reference - Database Connection Strings](./configuration-reference.md#database-connection-strings)
3. Verify: Hostname, port, username, password in `.env` file

### Task: Add new feature to tracing tools

1. Read: [Development Guide - Architecture Overview](./development.md#architecture-overview)
2. Read: [Development Guide - Common Development Tasks](./development.md#common-development-tasks)
3. Read: [Testing Guide](./testing-guide.md)
4. Follow: [Development Guide - Code Style](./development.md#code-style-and-standards)

### Task: Optimize slow trace execution

1. Read: [Troubleshooting - Performance Issues](./troubleshooting.md#performance-issues)
2. Read: [Configuration Reference - Performance Tuning](./configuration-reference.md#performance-tuning-guide)
3. Review: [Development Guide - Performance Optimization](./development.md#performance-optimization)

### Task: Format SQL scripts consistently

1. Read: [SQL Formatting Standards](./sql-formatting-standards.md)
2. Use: [PowerShell formatting script](./sql-formatting-standards.md#powershell-script-align-equals-signs)
3. Review: [Code Review Checklist](./sql-formatting-standards.md#code-review-checklist)

## File Organization

```
docs/
├── README.md                        # This file
├── QUICK_START.md                  # 5-minute quick start guide
├── architecture.md                 # System design and components
├── usage-guide.md                  # How to use the tools
├── configuration-reference.md      # All configuration options
├── troubleshooting.md              # Problem diagnosis and solutions
├── sql-formatting-standards.md     # SQL code conventions
├── testing-guide.md                # Testing practices
└── development.md                  # Development guide
```

## Key Concepts

### CDC (Change Data Capture)
Binary log-based change tracking from SQL Server using LSN (Log Sequence Number) boundaries. Provides transaction-level visibility into database modifications.

→ Learn more: [Architecture - CDC Capture](./architecture.md#trace_db_cdcpy)

### Logical Changes
Timestamp-based comparison between database snapshots to identify semantic changes. Works across databases and doesn't require CDC configuration.

→ Learn more: [Architecture - Logical Changes](./architecture.md#trace_db_logical_changespy)

### Manifest
JSON metadata file describing capture execution (timing, record counts, LSN ranges, tables captured).

→ Learn more: [Usage Guide - Understanding Output](./usage-guide.md#understanding-output)

### Post-Processing
Cleanup and finalization phase after change capture, including artifact writing and state persistence.

→ Learn more: [Architecture - Post-Processing](./architecture.md#tracing_post_processingpy)

## Common Workflows

### Workflow 1: Daily Change Audit

**Goal**: Track what changed in the database today

**Steps**:
1. Run CDC trace: `python trace_db_cdc.py`
2. Review manifest: `cat output/*/manifest.json | jq`
3. Export to CSV: See [Configuration Reference - Output Formats](./configuration-reference.md)
4. Archive output: `tar -czf traces-$(date +%Y%m%d).tar.gz output/*/`

→ Learn more: [Usage Guide - Scenario 1](./usage-guide.md#scenario-1-investigate-sql-table-population)

### Workflow 2: Cross-Database Validation

**Goal**: Verify data replication from source to reporting database

**Steps**:
1. Run CDC on NBS_ODSE: Terminal 1 → `python trace_db_cdc.py`
2. Run logical changes on RDB_MODERN: Terminal 2 → `python trace_db_logical_changes.py`
3. Compare record counts in manifests
4. Analyze transformation fidelity

→ Learn more: [Usage Guide - Scenario 2](./usage-guide.md#scenario-2-parallel-database-monitoring)

### Workflow 3: Resumable Large Captures

**Goal**: Capture large volumes with checkpoint recovery

**Steps**:
1. Start capture with smaller batch: `python trace_db_cdc.py --batch-size 500`
2. If interrupted, resume: Run command again, answer "Resume? Y"
3. Captures merge automatically upon completion

→ Learn more: [Usage Guide - Scenario 3](./usage-guide.md#scenario-3-resumable-long-running-capture)

## Getting Help

### Finding Information

1. **Search these docs**: Use Ctrl+F to search within documentation
2. **Check related links**: Each document has "Related Documentation" section
3. **Review examples**: Practical examples are provided in Usage and Development guides

### Troubleshooting Steps

1. **Symptom identification**: Read [Troubleshooting Guide](./troubleshooting.md) for symptoms similar to your issue
2. **Configuration verification**: Check [Configuration Reference](./configuration-reference.md) to verify settings
3. **Enable debug logging**: Add `LOG_LEVEL=DEBUG` to `.env` and review logs

### Reporting Issues

When reporting issues, include:
- Python version: `python --version`
- Database version: `SELECT @@VERSION`
- Configuration: Sanitized contents of `.env` (remove passwords)
- Error messages: Full output with stack trace
- Steps to reproduce: Clear reproduction steps
- Expected vs. actual behavior

## Tips and Tricks

### Understanding LSN Format

LSN (Log Sequence Number) format: `0x00000000:00000000:0000`
- First part: Virtual Log File (VLF) identifier
- Second part: Offset within VLF
- Third part: Slot identifier

### Parallel Execution

Run multiple traces simultaneously using PowerShell jobs:
```powershell
Start-Job { python trace_db_cdc.py }
Start-Job { python trace_db_logical_changes.py }
Wait-Job
```

→ Learn more: [Usage Guide - PowerShell Wrapper](./usage-guide.md#powershell-wrapper-optional)

### Performance Tuning

Quick optimizations:
- Increase `BATCH_SIZE` for faster execution
- Reduce for memory-constrained systems
- Run during off-peak hours
- Create indexes on timestamp/audit columns

→ Learn more: [Configuration Reference - Performance Tuning](./configuration-reference.md#performance-tuning-guide)

### Compression

Save disk space with output compression:
```bash
COMPRESSION=gzip python trace_db_cdc.py
```

→ Learn more: [Configuration Reference - Compression](./configuration-reference.md)

## Version History

| Version | Date | Key Changes |
|---------|------|-------------|
| 1.0 | 2024-01-15 | Initial documentation release |

## License

This documentation is part of the NEDSS-DataReporting project. See main LICENSE file in repository root.

## Contact

For questions or feedback about these docs, contact the NEDSS-DataReporting team or create an issue in the repository.

---

**Last Updated**: January 15, 2024  
**Documentation Version**: 1.0  
**Maintained By**: NEDSS-DataReporting Team
