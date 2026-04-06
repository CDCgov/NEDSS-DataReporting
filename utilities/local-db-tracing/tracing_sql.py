from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Iterable

from tracing_models import SqlCmdError


class SqlCmdClient:
    """Centralize sqlcmd execution so every metadata and CDC query uses the same calling convention."""

    def __init__(self, executable: str, server: str, database: str, user: str, password: str):
        self.executable = executable
        self.server = server
        self.database = database
        self.user = user
        self.password = password

    def query(self, sql: str, database: str | None = None) -> str:
        target_db = database or self.database
        with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=False, encoding="utf-8") as handle:
            handle.write(sql)
            script_path = Path(handle.name)

        command = [
            self.executable,
            "-S",
            self.server,
            "-d",
            target_db,
            "-U",
            self.user,
            "-P",
            self.password,
            "-b",
            "-w",
            "65535",
            "-s",
            "\t",
            "-y",
            "0",
            "-Y",
            "0",
            "-i",
            str(script_path),
        ]

        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                check=False,
            )
        finally:
            script_path.unlink(missing_ok=True)

        if result.returncode != 0:
            stderr = (result.stderr or "").strip()
            stdout = (result.stdout or "").strip()
            message = stderr or stdout or f"sqlcmd failed with exit code {result.returncode}"
            raise SqlCmdError(message)

        return result.stdout


def sql_quote(value: str) -> str:
    """Escape literal strings because most metadata queries are assembled dynamically."""

    return value.replace("'", "''")



def sql_identifier(value: str) -> str:
    """Bracket-escape SQL Server identifiers before embedding database names in administrative SQL."""

    return value.replace("]", "]]" )


def quote_identifier(identifier: str) -> str:
    """Bracket identifiers because replay SQL is assembled dynamically and must survive reserved words."""

    return f"[{identifier.replace(']', ']]')}]"



def sql_literal(value: object) -> str:
    """Translate JSON-like payload values back into SQL literals for the reconstructed replay section."""

    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    return f"N'{sql_quote(str(value))}'"



def require_sqlcmd(executable: str) -> str:
    """Fail early when sqlcmd is missing so the user does not get partial tracing state."""

    resolved = shutil.which(executable)
    if not resolved:
        raise SystemExit(f"sqlcmd executable not found: {executable}")
    return resolved



def run_process(command: list[str]) -> subprocess.CompletedProcess[str]:
    """Run a local process with consistent text handling for docker and sqlcmd helper commands."""

    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )



def read_tsv(raw_output: str, expected_columns: int | None = None) -> Iterable[list[str]]:
    """Strip sqlcmd noise while keeping tab-delimited payloads intact for metadata and CDC parsing."""

    cleaned: list[str] = []
    for line in raw_output.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.endswith("rows affected)") or stripped.endswith("row affected)"):
            continue
        if set(stripped) <= {"-", "\t", " "}:
            continue
        cleaned.append(line.rstrip("\r"))

    for line in cleaned:
        if expected_columns and expected_columns > 1:
            yield [part.strip() for part in line.split("\t", expected_columns - 1)]
        else:
            yield [part.strip() for part in line.split("\t")]
