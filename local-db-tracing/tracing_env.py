from __future__ import annotations

import os
from pathlib import Path


DEFAULT_DATABASE_SERVER = "localhost"
DEFAULT_DATABASE_PORT = "3433"


def find_dotenv(start_path: Path | None = None) -> Path | None:
    current_path = (start_path or Path(__file__)).resolve()
    for parent in (current_path.parent, *current_path.parents):
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

    for key in ("DATABASE_SERVER", "DATABASE_PORT", "DATABASE_USERNAME", "DATABASE_PASSWORD"):
        env_value = os.environ.get(key)
        if env_value:
            defaults[key] = env_value

    return defaults


def resolve_server_argument(defaults: dict[str, str]) -> str:
    server = defaults.get("DATABASE_SERVER", DEFAULT_DATABASE_SERVER).strip() or DEFAULT_DATABASE_SERVER
    port = defaults.get("DATABASE_PORT", DEFAULT_DATABASE_PORT).strip() or DEFAULT_DATABASE_PORT
    if "," in server:
        return server
    return f"{server},{port}"
