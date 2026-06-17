#!/usr/bin/env python3
"""
run_sql_files.py — Run SQL files in a directory in alphabetical order.

This script executes all .sql files in a specified directory against NBS_ODSE
in alphabetical order, using connection details from the .env file in the
NEDSS-DataReporting root.

Usage:
  python run_sql_files.py <directory>
  python run_sql_files.py testing-tools\synthetic-odse-fixtures\fixtures\30_sp_coverage

The script:
  1. Reads DB_USER and DATABASE_PASSWORD from .env (in NEDSS-DataReporting root)
  2. Extracts server and port from DB_URL_ODSE (defaults to localhost:3433)
  3. Collects all .sql files in alphabetical order
  4. Executes each via sqlcmd, stopping on any error
  5. Reports results with timing

Requires:
  - sqlcmd installed and in PATH
  - .env file in NEDSS-DataReporting root (or parent of testing-tools)
  - SQL Server accessible at the configured server:port
"""

import sys
import os
import re
import subprocess
import time
from pathlib import Path


def load_env(root_dir):
    """
    Load .env file and extract database connection details.
    
    Returns:
        dict: {'user': ..., 'password': ..., 'server': ..., 'port': ...}
    
    Raises:
        FileNotFoundError: If .env not found in root_dir
        ValueError: If required keys missing or malformed
    """
    env_path = Path(root_dir) / ".env"
    if not env_path.exists():
        raise FileNotFoundError(f".env not found at {env_path}")
    
    config = {}
    
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' not in line:
                continue
            key, value = line.split('=', 1)
            config[key.strip()] = value.strip().strip('"').strip("'")
    
    # Extract database connection details
    user = config.get('DATABASE_USERNAME')
    password = config.get('DATABASE_PASSWORD')
    server = config.get('DATABASE_SERVER', 'localhost')
    port = config.get('DATABASE_PORT', '3433')
    
    if not user or not password:
        raise ValueError("DATABASE_USERNAME and/or DATABASE_PASSWORD not found in .env")
    
    return {
        'user': user,
        'password': password,
        'server': server,
        'port': port
    }


def get_sql_files(directory):
    """
    Get all .sql files in directory, sorted alphabetically.
    
    Args:
        directory: Path to directory containing .sql files
    
    Returns:
        list: Sorted list of Path objects for .sql files
    
    Raises:
        NotADirectoryError: If path is not a directory
        FileNotFoundError: If directory not found
    """
    dir_path = Path(directory)
    
    if not dir_path.exists():
        raise FileNotFoundError(f"Directory not found: {directory}")
    
    if not dir_path.is_dir():
        raise NotADirectoryError(f"Not a directory: {directory}")
    
    sql_files = sorted(dir_path.glob('*.sql'))
    
    if not sql_files:
        print(f"⚠ No .sql files found in {directory}")
    
    return sql_files


def run_sql_file(file_path, config):
    """
    Execute a single .sql file via sqlcmd.
    
    Args:
        file_path: Path to .sql file
        config: Database connection config (user, password, server, port)
    
    Returns:
        tuple: (success: bool, output: str, error: str)
    """
    server_spec = f"{config['server']},{config['port']}"
    
    # Build sqlcmd command
    # sqlcmd -S server,port -U username -P password -i filename
    cmd = [
        'sqlcmd',
        '-S', server_spec,
        '-U', config['user'],
        '-P', config['password'],
        '-i', str(file_path),
        '-C'  # Trust server certificate
    ]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout per file
        )
        
        # Check for SQL error messages (Msg NNNN, Level >=11)
        # Ignore benign messages like 5701 (changed DB) or 5703 (language)
        output = result.stdout + result.stderr
        
        # Look for real SQL errors (Level 11+)
        if re.search(r'Msg \d+, Level (1[1-9]|2[0-9])', output):
            # Filter out non-error matches (benign log lines)
            if not re.search(r'Msg (5701|5703)', output):
                return False, result.stdout, result.stderr
        
        if result.returncode != 0 and result.stderr:
            return False, result.stdout, result.stderr
        
        return True, result.stdout, result.stderr
    
    except subprocess.TimeoutExpired:
        return False, "", f"Timeout (300s) executing {file_path.name}"
    except FileNotFoundError:
        return False, "", "sqlcmd not found in PATH. Install SQL Server command-line tools."
    except Exception as e:
        return False, "", str(e)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    sql_dir = sys.argv[1]
    
    # Find root directory (NEDSS-DataReporting)
    current_dir = Path(__file__).resolve()
    # Walk up: scripts -> synthetic-odse-fixtures -> testing-tools -> NEDSS-DataReporting
    root_dir = current_dir.parent.parent.parent.parent
    
    try:
        config = load_env(root_dir)
    except (FileNotFoundError, ValueError) as e:
        print(f"❌ Config error: {e}", file=sys.stderr)
        sys.exit(1)
    
    try:
        sql_files = get_sql_files(sql_dir)
    except (FileNotFoundError, NotADirectoryError) as e:
        print(f"❌ Directory error: {e}", file=sys.stderr)
        sys.exit(1)
    
    if not sql_files:
        sys.exit(0)
    
    print(f"📁 Running {len(sql_files)} SQL files from: {sql_dir}")
    print(f"🔗 Server: {config['server']},{config['port']} | User: {config['user']}")
    print("-" * 70)
    
    start_time = time.time()
    success_count = 0
    fail_count = 0
    
    for i, sql_file in enumerate(sql_files, 1):
        file_start = time.time()
        print(f"[{i}/{len(sql_files)}] Running: {sql_file.name}...", end=" ", flush=True)
        
        success, stdout, stderr = run_sql_file(sql_file, config)
        elapsed = time.time() - file_start
        
        if success:
            print(f"✅ ({elapsed:.2f}s)")
            success_count += 1
        else:
            print(f"❌ ({elapsed:.2f}s)")
            fail_count += 1
            print(f"      Error: {stderr.split(chr(10))[0][:100]}")
            print(f"\n🛑 Stopping on first error. Review error above.")
            sys.exit(1)
    
    total_elapsed = time.time() - start_time
    print("-" * 70)
    print(f"✨ Complete: {success_count} succeeded in {total_elapsed:.2f}s")
    
    sys.exit(0 if fail_count == 0 else 1)


if __name__ == '__main__':
    main()
