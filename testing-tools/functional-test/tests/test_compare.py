"""Tests for value normalization and lenient JSON matching."""

import datetime
import decimal

from functional_test.compare import (
    lenient_match,
    normalize_row,
    normalize_rows,
    to_comparable,
)


class TestToComparable:
    def test_datetime_formats_like_jackson(self):
        dt = datetime.datetime(2026, 4, 20, 4, 21, 34, 363000)
        assert to_comparable(dt) == "2026-04-20T04:21:34.363"

    def test_datetime_truncates_microseconds_to_millis(self):
        dt = datetime.datetime(2026, 4, 20, 4, 21, 34, 363999)
        assert to_comparable(dt) == "2026-04-20T04:21:34.363"

    def test_datetime_pads_millis(self):
        dt = datetime.datetime(2026, 1, 2, 3, 4, 5, 7000)
        assert to_comparable(dt) == "2026-01-02T03:04:05.007"

    def test_date_gets_midnight_time(self):
        d = datetime.date(2026, 4, 20)
        assert to_comparable(d) == "2026-04-20T00:00:00.000"

    def test_time_formats_with_millis(self):
        t = datetime.time(4, 21, 34, 363000)
        assert to_comparable(t) == "04:21:34.363"

    def test_bytes_to_hex(self):
        assert to_comparable(b"\x00\xff") == "00ff"

    def test_passthrough_scalars(self):
        assert to_comparable("Jeff") == "Jeff"
        assert to_comparable(13) == 13
        assert to_comparable(None) is None
        assert to_comparable(True) is True
        dec = decimal.Decimal("1.5")
        assert to_comparable(dec) is dec


class TestNormalizeRows:
    def test_normalize_row_converts_values_keeps_keys(self):
        row = {"WHEN": datetime.datetime(2026, 4, 20, 1, 2, 3, 4000), "NAME": "x"}
        assert normalize_row(row) == {"WHEN": "2026-04-20T01:02:03.004", "NAME": "x"}

    def test_normalize_rows_maps_each(self):
        rows = [{"a": 1}, {"b": datetime.date(2026, 1, 1)}]
        assert normalize_rows(rows) == [{"a": 1}, {"b": "2026-01-01T00:00:00.000"}]


class TestLenientMatchObjects:
    def test_extra_actual_keys_allowed(self):
        assert lenient_match({"a": 1}, {"a": 1, "b": 2})

    def test_missing_expected_key_fails(self):
        assert not lenient_match({"a": 1, "b": 2}, {"a": 1})

    def test_value_mismatch_fails(self):
        assert not lenient_match({"a": 1}, {"a": 2})

    def test_non_dict_actual_fails(self):
        assert not lenient_match({"a": 1}, [{"a": 1}])

    def test_nested_objects(self):
        assert lenient_match({"a": {"b": 1}}, {"a": {"b": 1, "c": 2}})


class TestLenientMatchArrays:
    def test_order_independent(self):
        assert lenient_match([{"a": 1}, {"a": 2}], [{"a": 2}, {"a": 1}])

    def test_extra_actual_rows_allowed(self):
        assert lenient_match([{"a": 1}], [{"a": 2}, {"a": 1}])

    def test_missing_expected_row_fails(self):
        assert not lenient_match([{"a": 1}, {"a": 3}], [{"a": 1}, {"a": 2}])

    def test_empty_actual_never_matches_nonempty_expected(self):
        assert not lenient_match([{"a": 1}], [])

    def test_empty_expected_matches_anything(self):
        assert lenient_match([], [{"a": 1}])

    def test_duplicates_need_distinct_actuals(self):
        # Two identical expected rows require two actual rows.
        assert not lenient_match([{"a": 1}, {"a": 1}], [{"a": 1}])
        assert lenient_match([{"a": 1}, {"a": 1}], [{"a": 1}, {"a": 1}])

    def test_non_list_actual_fails(self):
        assert not lenient_match([{"a": 1}], {"a": 1})

    def test_backtracking_required(self):
        # Greedy matching could pair the {"a":1} expected with the {"a":1,"b":9}
        # actual and then fail; correct matching must backtrack.
        expected = [{"a": 1}, {"a": 1, "b": 9}]
        actual = [{"a": 1, "b": 9}, {"a": 1, "b": 0}]
        assert lenient_match(expected, actual)


class TestLenientMatchScalars:
    def test_int_decimal_float_equivalent(self):
        assert lenient_match(13, decimal.Decimal("13"))
        assert lenient_match(13, 13.0)
        assert lenient_match(decimal.Decimal("13.0"), 13)

    def test_numbers_not_equal(self):
        assert not lenient_match(13, 14)

    def test_string_number_not_equal_to_number(self):
        assert not lenient_match("13", 13)
        assert lenient_match("13", "13")

    def test_bool_is_strict(self):
        assert lenient_match(True, True)
        assert not lenient_match(True, 1)
        assert not lenient_match(1, True)
        assert not lenient_match(True, False)

    def test_none_handling(self):
        assert lenient_match(None, None)
        assert not lenient_match(None, 0)
        assert not lenient_match(0, None)

    def test_strings(self):
        assert lenient_match("Jeff", "Jeff")
        assert not lenient_match("Jeff", "jeff")

    def test_date_only_matches_midnight_datetime(self):
        # DATE columns come back as midnight datetimes; expected may be date-only.
        assert lenient_match("2026-04-09", "2026-04-09T00:00:00.000")
        assert lenient_match("2026-04-09T00:00:00.000", "2026-04-09")
        assert lenient_match("2026-04-09", "2026-04-09T00:00:00")

    def test_date_only_does_not_match_nonmidnight(self):
        assert not lenient_match("2026-04-09", "2026-04-09T04:21:34.363")
        assert not lenient_match("2026-04-09", "2026-04-10T00:00:00.000")

    def test_full_datetime_still_compared_exactly(self):
        assert lenient_match("2026-04-20T04:21:34.363", "2026-04-20T04:21:34.363")
        assert not lenient_match("2026-04-20T04:21:34.363", "2026-04-20T04:21:34.000")
