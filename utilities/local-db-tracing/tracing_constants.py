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

LOCAL_TRACING_DIR = Path(__file__).resolve().parent
LOCAL_RUNTIME_DIR = LOCAL_TRACING_DIR / ".local"
DEFAULT_STATE_FILE_DIR = LOCAL_RUNTIME_DIR
LEGACY_STATE_FILE = LOCAL_TRACING_DIR / "enabled-cdc-tables.json"
DEFAULT_KNOWN_ASSOCIATIONS_FILE = LOCAL_TRACING_DIR / "known_replay_associations.json"
REPLAY_METADATA_CACHE_PREFIX = "replay-metadata-"
REPLAY_METADATA_CACHE_VERSION = 4
DEFAULT_CORE_REPLAY_IGNORED_TABLES = {
    ("dbo", "EDX_entity_match"),
    ("dbo", "EDX_patient_match"),
}
EXCLUDED_TRACE_TABLES = {
    ("dbo", "job_flow_log"),
}
DEFAULT_UID_BLOCK_SIZE_BY_CLASS = {
    "GA": 1000,
    "PERSON": 1000,
}
DEFAULT_POST_PROCESSING_CONTAINER_PREFIX = "nedss-datareporting-post-processing-service"
DEFAULT_POST_PROCESSING_IDLE_MESSAGE = "No ids to process from the topics."
DEFAULT_POST_PROCESSING_WAIT_TIMEOUT_SECONDS = 180
DEFAULT_POST_PROCESSING_INITIAL_WAIT_SECONDS = 5
LOG_EVENT_TIMESTAMP_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}")
GENERIC_LOCAL_ID_PATTERN = re.compile(r"^(?P<prefix>[^0-9]+)(?P<number>\d+)(?P<suffix>.*)$")
REPLAY_DATETIME_LITERAL_PATTERN = re.compile(
    r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?$"
)
