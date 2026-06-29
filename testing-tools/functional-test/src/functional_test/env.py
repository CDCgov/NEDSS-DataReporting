"""Database connection defaults from a ``.env`` file / environment.

Uses the same variable names as the ``local-db-tracing`` tools so a single
``.env`` configures both:

  * ``DATABASE_SERVER``   (default ``localhost``)
  * ``DATABASE_PORT``     (default ``3433``)
  * ``DATABASE_USERNAME``
  * ``DATABASE_PASSWORD``

A ``.env`` is located by walking up from the current working directory and then
from this module's location; real environment variables override ``.env``
values. CLI flags, in turn, override these defaults.
"""

from __future__ import annotations

import os
from pathlib import Path

DEFAULT_DATABASE_SERVER = "localhost"
DEFAULT_DATABASE_PORT = "3433"

_CONNECTION_KEYS = (
    "DATABASE_SERVER",
    "DATABASE_PORT",
    "DATABASE_USERNAME",
    "DATABASE_PASSWORD",
)


def find_dotenv(start_path: Path | None = None) -> Path | None:
    starts = [start_path] if start_path is not None else [Path.cwd(), Path(__file__)]
    for start in starts:
        current_path = start.resolve()
        bases = [current_path] if current_path.is_dir() else []
        bases.extend(current_path.parents)
        for parent in bases:
            candidate = parent / ".env"
            if candidate.is_file():
                return candidate
    return None


def parse_dotenv(dotenv_path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in dotenv_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        cleaned_key = key.strip()
        cleaned_value = value.strip().strip('"').strip("'")
        if cleaned_key:
            values[cleaned_key] = cleaned_value
    return values


def load_database_connection_defaults() -> dict[str, str]:
    defaults: dict[str, str] = {}
    dotenv_path = find_dotenv()
    if dotenv_path is not None:
        defaults.update(parse_dotenv(dotenv_path))

    for key in _CONNECTION_KEYS:
        env_value = os.environ.get(key)
        if env_value:
            defaults[key] = env_value

    return defaults


def resolve_server_argument(defaults: dict[str, str]) -> str:
    server = (
        defaults.get("DATABASE_SERVER", DEFAULT_DATABASE_SERVER).strip()
        or DEFAULT_DATABASE_SERVER
    )
    port = defaults.get("DATABASE_PORT", DEFAULT_DATABASE_PORT).strip() or DEFAULT_DATABASE_PORT
    if "," in server:
        return server
    return f"{server},{port}"
