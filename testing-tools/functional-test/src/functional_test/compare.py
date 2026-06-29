"""Lenient JSON comparison and value normalization.

Replicates the comparison the Java functional tests perform:

  * Query results are serialized with Jackson using
    ``yyyy-MM-dd'T'HH:mm:ss.SSS`` for dates and ``WRITE_DATES_AS_TIMESTAMPS``
    disabled.
  * The serialized actual is compared to the expected JSON using
    ``JSONAssert`` in ``JSONCompareMode.LENIENT``.

LENIENT means objects are *extensible* (the actual may contain extra keys the
expected does not mention) and arrays are *unordered and extensible* (every
expected element must match some distinct actual element, but the actual may
contain extra elements).
"""

from __future__ import annotations

import datetime
import decimal
import re
from typing import Any

# A datetime string at exactly midnight, e.g. "2026-04-09T00:00:00.000". DATE
# columns come back from the driver as midnight datetimes, but expected.json may
# store them as date-only ("2026-04-09"); both should compare equal.
_DATE_AT_MIDNIGHT = re.compile(r"^(\d{4}-\d{2}-\d{2})T00:00:00(?:\.0+)?$")


def _canonical_temporal(value: str) -> str:
    """Reduce a midnight datetime string to its date so it matches date-only."""
    match = _DATE_AT_MIDNIGHT.match(value)
    return match.group(1) if match else value


def to_comparable(value: Any) -> Any:
    """Normalize a value returned by pymssql into a JSON-comparable form.

    Mirrors how Jackson serializes the Java query results so that the values
    line up with what is stored in the ``expected.json`` files.
    """
    # datetime is a subclass of date, so it must be checked first.
    if isinstance(value, datetime.datetime):
        return f"{value:%Y-%m-%dT%H:%M:%S}.{value.microsecond // 1000:03d}"
    if isinstance(value, datetime.date):
        return f"{value:%Y-%m-%d}T00:00:00.000"
    if isinstance(value, datetime.time):
        return f"{value:%H:%M:%S}.{value.microsecond // 1000:03d}"
    if isinstance(value, (bytes, bytearray)):
        return value.hex()
    return value


def normalize_row(row: dict[str, Any]) -> dict[str, Any]:
    return {key: to_comparable(val) for key, val in row.items()}


def normalize_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [normalize_row(row) for row in rows]


def _is_number(value: Any) -> bool:
    # bool is a subclass of int but JSON treats true/false distinctly.
    return isinstance(value, (int, float, decimal.Decimal)) and not isinstance(value, bool)


def _scalars_match(expected: Any, actual: Any) -> bool:
    if isinstance(expected, bool) or isinstance(actual, bool):
        return expected is actual or expected == actual and type(expected) is type(actual)
    if expected is None or actual is None:
        return expected is None and actual is None
    if _is_number(expected) and _is_number(actual):
        try:
            return decimal.Decimal(str(expected)) == decimal.Decimal(str(actual))
        except (decimal.InvalidOperation, ValueError):
            return False
    if isinstance(expected, str) and isinstance(actual, str):
        # A date-only value matches the same date at midnight (DATE columns come
        # back as "...T00:00:00.000").
        return _canonical_temporal(expected) == _canonical_temporal(actual)
    # Fall back to direct equality; compare numbers-as-strings loosely is not
    # done here because Jackson keeps strings as strings.
    return expected == actual


def lenient_match(expected: Any, actual: Any) -> bool:
    """Return True if ``actual`` matches ``expected`` under LENIENT rules."""
    # Fast path for identical values. Guard against bool/int equivalence
    # (True == 1) so bool strictness is still enforced below.
    if expected == actual and isinstance(expected, bool) == isinstance(actual, bool):
        return True
    if isinstance(expected, dict):
        if not isinstance(actual, dict):
            return False
        for key, exp_val in expected.items():
            if key not in actual:
                return False
            if not lenient_match(exp_val, actual[key]):
                return False
        return True

    if isinstance(expected, list):
        if not isinstance(actual, list):
            return False
        return _match_arrays(expected, actual)

    return _scalars_match(expected, actual)


def _match_arrays(expected: list[Any], actual: list[Any]) -> bool:
    """Every expected element must map to a distinct matching actual element.

    Extra actual elements are allowed (arrays are extensible in LENIENT mode).
    """
    used = [False] * len(actual)

    def match(index: int) -> bool:
        if index == len(expected):
            return True
        for j, candidate in enumerate(actual):
            if not used[j] and lenient_match(expected[index], candidate):
                used[j] = True
                if match(index + 1):
                    return True
                used[j] = False
        return False

    return match(0)
