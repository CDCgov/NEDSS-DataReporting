from __future__ import annotations

import re
from pathlib import Path

from tracing_constants import DEFAULT_STATE_FILE_DIR, LEGACY_STATE_FILE, REPLAY_METADATA_CACHE_PREFIX


def output_name_component(value: str) -> str:
    """Keep run-directory suffixes readable while stripping characters Windows paths cannot use."""

    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "_", value.strip())
    return cleaned or "database"


def database_name_slug(database: str) -> str:
    """Turn database names into safe filenames so per-database state does not depend on shell escaping."""

    cleaned = []
    for character in database:
        if character.isalnum() or character in {"-", "_", "."}:
            cleaned.append(character)
        else:
            cleaned.append("_")
    slug = "".join(cleaned).strip("._-")
    return slug or "database"


def default_state_file_for_database(database: str) -> Path:
    """Separate cleanup state per database so traces for different schemas cannot clobber each other."""

    return DEFAULT_STATE_FILE_DIR / f"enabled-cdc-tables-{database_name_slug(database)}.json"


def replay_metadata_cache_file_for_database(database: str) -> Path:
    """Cache replay metadata per database because PK/FK discovery is expensive but mostly stable."""

    return DEFAULT_STATE_FILE_DIR / f"{REPLAY_METADATA_CACHE_PREFIX}{database_name_slug(database)}.json"


def resolve_state_files(state_file: str | None, database: str) -> tuple[Path, Path | None]:
    """Support explicit state files while still honoring the legacy shared file during migration."""

    if state_file:
        return Path(state_file), None
    return default_state_file_for_database(database), LEGACY_STATE_FILE


def is_excluded_trace_table(schema_name: str, table_name: str) -> bool:
    """Keep known high-noise internal tables out of CDC enablement and capture output."""

    return (schema_name.lower(), table_name.lower()) in {("dbo", "job_flow_log")}


def sanitize_sql_name(name: str) -> str:
    """Make generated variable names safe without hiding their relationship to the source table and value."""

    cleaned = []
    for character in name:
        if character.isalnum() or character == "_":
            cleaned.append(character)
        else:
            cleaned.append("_")
    sanitized = "".join(cleaned).strip("_")
    return sanitized or "value"


def variable_name_for_value(schema_name: str, table_name: str, column_name: str, value: object) -> str:
    return "@" + sanitize_sql_name(f"{schema_name}_{table_name}_{column_name}_{value}")


def derived_variable_name(variable_name: str, suffix: str) -> str:
    """Keep helper variables tied to the main replay variable so generated SQL stays readable."""

    return "@" + sanitize_sql_name(variable_name.lstrip("@") + "_" + suffix)


def output_table_name_for_variable(variable_name: str) -> str:
    """Keep OUTPUT capture tables derived from the main variable so related temp objects stay recognizable."""

    return "@" + sanitize_sql_name(variable_name.lstrip("@") + "_output")
