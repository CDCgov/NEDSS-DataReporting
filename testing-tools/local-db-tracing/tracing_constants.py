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

LOCAL_TRACING_DIR = Path(__file__).resolve().parent
LOCAL_RUNTIME_DIR = LOCAL_TRACING_DIR / ".local"
DEFAULT_STATE_FILE_DIR = LOCAL_RUNTIME_DIR
LEGACY_STATE_FILE = LOCAL_TRACING_DIR / "enabled-cdc-tables.json"
DEFAULT_KNOWN_ASSOCIATIONS_FILE = LOCAL_TRACING_DIR / "known_replay_associations.json"
REPLAY_METADATA_CACHE_PREFIX = "replay-metadata-"
REPLAY_METADATA_CACHE_VERSION = 5

# CDC is not turned on for these tables
EXCLUDED_TRACE_TABLES = {
    ("dbo", "job_flow_log"),
}

# CDC is on for these tables, but they are excluded from setup.sql because
# they are populated as side-effects of replaying other entities
DEFAULT_CORE_REPLAY_IGNORED_TABLES = {
    ("dbo", "EDX_entity_match"),
    ("dbo", "EDX_patient_match"),
}

# These tables are excluded from query.sql and expected.json
EXCLUDED_ARTIFACT_TABLES = {
    ("dbo", "activity_log_detail"),
    ("dbo", "activity_log_master"),
    ("dbo", "job_flow_log"),
    ("dbo", "job_batch_log"),
}

# These table prefixes are excluded from query.sql and expected.json
# Each entry is (schema_name, table_name_prefix); compared case-insensitively in tracing_paths.is_excluded_artifact_table.
EXCLUDED_ARTIFACT_TABLE_PREFIXES = {
    ("dbo", "LOOKUP_TABLE_N_"),
}

# These columns are excluded from query.sql and expected.json (no matter the table)
IGNORED_OUTPUT_COLUMNS = {
    "INVESTIGATION_KEY",
    "LAB_TEST_KEY",
    "LAB_RPT_LAST_UPDATE_DT",
    "PATIENT_KEY",
    "RDB_LAST_REFRESH_TIME",
    "RESULTED_LAB_TEST_KEY",
    "TEST_RESULT_GRP_KEY",
}

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
ALWAYS_REPLACE_COLUMN_NAMES: frozenset[str] = frozenset({
    "last_chg_time",
    "record_status_time",
    "status_time",
    "add_time",
    "activity_to_time",
    "rpt_to_state_time",
    "as_of_date"
})

# Used by step-scoped replay lookup subqueries that re-find NBS_act_entity rows when prior-step UID vars are unavailable.
# Timestamp audit fields are ignored because when recreating with CURRENT_TIMESTAMP, these would be invalid.
NBS_ACT_ENTITY_LOOKUP_EXCLUDED_COLUMNS: frozenset[str] = frozenset({
    "add_time",
    "last_chg_time",
    "record_status_time",
})
