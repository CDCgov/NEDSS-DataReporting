from __future__ import annotations

import re
from pathlib import Path


CDC_METADATA_COLUMNS = {
    "__$start_lsn",
    "__$seqval",
    "__$operation",
    "__$update_mask",
    "__$command_id",
}

DEFAULT_STARTING_UID = 1234
DEFAULT_SUPERUSER_ID = 10009282
DEFAULT_ELR_USER_ID = 10000015

LOCAL_TRACING_DIR = Path(__file__).resolve().parent
LOCAL_RUNTIME_DIR = LOCAL_TRACING_DIR / ".local"
DEFAULT_STATE_FILE_DIR = LOCAL_RUNTIME_DIR
LEGACY_STATE_FILE = LOCAL_TRACING_DIR / "enabled-cdc-tables.json"
DEFAULT_KNOWN_ASSOCIATIONS_FILE = LOCAL_TRACING_DIR / "known_replay_associations.json"
REPLAY_METADATA_CACHE_PREFIX = "replay-metadata-"
REPLAY_METADATA_CACHE_VERSION = 5

# CDC is not turned on for these tables.
# Keys are normalized to lowercase to support case-insensitive matching.
EXCLUDED_TRACE_TABLES: frozenset[tuple[str, str]] = frozenset({
    (schema_name.lower(), table_name.lower())
    for schema_name, table_name in {
        ("dbo", "job_flow_log"),
    }
})

# CDC is not turned on for tables matching these prefixes.
# Each entry is (schema_name, table_name_prefix) and is normalized to lowercase.
EXCLUDED_TRACE_TABLE_PREFIXES: frozenset[tuple[str, str]] = frozenset({
    (schema_name.lower(), table_name_prefix.lower())
    for schema_name, table_name_prefix in {
        ("dbo", "tmp_DynDM"),
    }
})

# CDC is on for these tables, but they are excluded from setup.sql because
# they are populated as side-effects of replaying other entities.
# Keys are normalized to lowercase to support case-insensitive matching.
DEFAULT_CORE_REPLAY_IGNORED_TABLES: frozenset[tuple[str, str]] = frozenset({
    (schema_name.lower(), table_name.lower())
    for schema_name, table_name in {
        ("dbo", "EDX_entity_match"),
        ("dbo", "EDX_patient_match"),
    }
})

# These tables are excluded from query.sql and expected.json.
# Keys are normalized to lowercase to support case-insensitive matching.
EXCLUDED_ARTIFACT_TABLES: frozenset[tuple[str, str]] = frozenset({
    (schema_name.lower(), table_name.lower())
    for schema_name, table_name in {
        ("dbo", "activity_log_detail"),
        ("dbo", "activity_log_master"),
        ("dbo", "job_flow_log"),
        ("dbo", "job_batch_log"),

        # See https://cdc-nbs.atlassian.net/wiki/spaces/NE/pages/2136506371/RTR+reporting+differences#RDB-Tables-Not-Considered-for-Comparison
        ("dbo", "ETL_DQ_LOG"),
        ("dbo", "ETL_HEALTH_CHECK_PAT_DATA"),
        ("dbo", "ETL_MISSING_PATIENT"),
        ("dbo", "ETL_MISSING_RECORD"),
        ("dbo", "ETL_PROCESS"),
        ("dbo", "EVENT_METRIC"),
        ("dbo", "EVENT_METRIC_INC"),
    }
})

# These table prefixes are excluded from query.sql and expected.json.
# Each entry is (schema_name, table_name_prefix) and is normalized to lowercase.
EXCLUDED_ARTIFACT_TABLE_PREFIXES: frozenset[tuple[str, str]] = frozenset({
    (schema_name.lower(), table_name_prefix.lower())
    for schema_name, table_name_prefix in {
    # ("dbo", "LOOKUP_TABLE_N_"),
    # See https://cdc-nbs.atlassian.net/wiki/spaces/NE/pages/2136506371/RTR+reporting+differences#RDB-Tables-Not-Considered-for-Comparison
        ("dbo", "L_"),
        ("dbo", "LOOKUP_"),
        ("dbo", "S_"),
        ("dbo", "SAS_"),
        ("dbo", "TEMP_"),
    }
})

# These columns are excluded from query.sql and expected.json (no matter the table).
# Names are normalized to lowercase to support case-insensitive matching.
IGNORED_OUTPUT_COLUMNS: frozenset[str] = frozenset({
    column_name.lower()
    for column_name in {
        "INVESTIGATION_KEY",
        "LAB_TEST_KEY",
        "LAB_RPT_LAST_UPDATE_DT",
        "PATIENT_KEY",
        "RDB_LAST_REFRESH_TIME",
        "RESULTED_LAB_TEST_KEY",
        "TEST_RESULT_GRP_KEY",
    }
})

DEFAULT_UID_BLOCK_SIZE_BY_CLASS = {
    "GA": 1000,
    "PERSON": 1000,
}
DEFAULT_POST_PROCESSING_CONTAINER_PREFIX = "nedss-datareporting-reporting-pipeline-service-1"
DEFAULT_POST_PROCESSING_IDLE_MESSAGE = "No ids to process from the topics."
DEFAULT_POST_PROCESSING_WAIT_TIMEOUT_SECONDS = 180
DEFAULT_POST_PROCESSING_INITIAL_WAIT_SECONDS = 5
DEFAULT_KAFKA_CONTAINER_PREFIX = "nedss-datareporting-kafka-1"
DEFAULT_KAFKA_CONSUMER_GROUPS = (
    "pipeline-consumer-app",
    "connect-Kafka-Connect-SqlServer-Sink",
)
LOG_EVENT_TIMESTAMP_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}")
GENERIC_LOCAL_ID_PATTERN = re.compile(r"^(?P<prefix>[^0-9]+)(?P<number>\d+)(?P<suffix>.*)$")
REPLAY_DATETIME_LITERAL_PATTERN = re.compile(
    r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?$"
)

# These column names are always rewritten to CURRENT_TIMESTAMP when auto-datetime mode is 'current',
# regardless of whether the DB metadata reports them as having a function-based DEFAULT.
# Names are normalized to lowercase to support case-insensitive matching.
ALWAYS_REPLACE_COLUMN_NAMES: frozenset[str] = frozenset({
    column_name.lower()
    for column_name in {
        "last_chg_time",
        "record_status_time",
        "status_time",
        "add_time",
        "activity_to_time",
        "rpt_to_state_time",
        "as_of_date",
    }
})

# Column names that should NOT be rewritten to CURRENT_TIMESTAMP, even if they have
# function-based DEFAULT constraints. They represent business data rather than audit timestamps.
# Applies to all tables. Names are normalized to lowercase.
DO_NOT_REPLACE_COLUMNS_ANY_TABLE: frozenset[str] = frozenset({
    column_name.lower()
    for column_name in {
        "LAB_TEST_DT",  # exclude from all tables
        "EARLIEST_RPT_TO_STATE_DT",
        "LAB_RPT_RECEIVED_BY_PH_DT",
    }
})

# Table-specific column exclusions (schema, table, column) that should NOT be rewritten.
# Use when a column name is business data in one table but an audit field in another.
# Keys are normalized to lowercase to support case-insensitive matching.
DO_NOT_REPLACE_COLUMNS_BY_TABLE: frozenset[tuple[str, str, str]] = frozenset({
    (schema_name.lower(), table_name.lower(), column_name.lower())
    for schema_name, table_name, column_name in {
        # ("dbo", "LAB100", "LAB_TEST_DT"),
    }
})

# Used by step-scoped replay lookup subqueries that re-find NBS_act_entity rows when prior-step UID vars are unavailable.
# Timestamp audit fields are ignored because when recreating with CURRENT_TIMESTAMP, these would be invalid.
# Names are normalized to lowercase to support case-insensitive matching.
NBS_ACT_ENTITY_LOOKUP_EXCLUDED_COLUMNS: frozenset[str] = frozenset({
    column_name.lower()
    for column_name in {
        "add_time",
        "last_chg_time",
        "record_status_time",
    }
})
