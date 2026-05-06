from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TableStatus:
    """Carry the current CDC state for one user table so enable/disable decisions stay explicit."""

    schema_name: str
    table_name: str
    is_tracked_by_cdc: bool


@dataclass(frozen=True)
class CaptureInstance:
    """Keep the source table and CDC capture-instance name paired during change collection."""

    schema_name: str
    table_name: str
    capture_instance: str


@dataclass(frozen=True)
class PrimaryKeyColumn:
    """Preserve PK column order so replay can rebuild keys in the same shape SQL Server expects."""

    schema_name: str
    table_name: str
    column_name: str
    key_ordinal: int


@dataclass(frozen=True)
class UidGeneratorEntry:
    """Mirror Local_UID_generator rows so replay can reuse ODSE-style ID allocation semantics."""

    class_name_cd: str
    type_cd: str
    uid_prefix_cd: str
    uid_suffix_cd: str


@dataclass(frozen=True)
class UidAllocation:
    """Capture one generator reservation so replay can ask ODSE for a fresh value the same way the source did."""

    class_name_cd: str
    count: int
    type_cd: str
    uid_prefix_cd: str
    uid_suffix_cd: str


@dataclass(frozen=True)
class ManagedCdcState:
    """Persist exactly which CDC state the tracer owns so later cleanup does not overreach."""

    tables: list[dict[str, str]]
    database_cdc_enabled_by_tracer: bool


@dataclass(frozen=True)
class KnownAssociation:
    """Describe a row-conditional source-to-target key mapping when the schema does not expose an FK."""

    source_schema: str
    source_table: str
    source_column: str
    target_schema: str
    target_table: str
    target_column: str
    when: dict[str, object]


class SqlCmdError(RuntimeError):
    """Differentiate sqlcmd failures from normal control-flow exits."""

    pass
