from rdb_compare.keys import KEY_CONFIG, resolve_keys


# --- (1) KEY_CONFIG hits -------------------------------------------------
def test_config_single_uid_hit_lab_test():
    # LAB_TEST is pinned to LAB_TEST_UID by the single-UID SQL template.
    cols = ["LAB_TEST_KEY", "LAB_TEST_UID", "TEST_METHOD_CD"]
    assert resolve_keys("LAB_TEST", cols) == ("LAB_TEST_UID",)


def test_config_two_id_hit_lab100():
    # LAB100 needs both LAB_RPT_LOCAL_ID and LAB_RPT_UID (2-id template).
    cols = ["LAB_RPT_LOCAL_ID", "LAB_RPT_UID", "RESULTED_LAB_TEST_KEY"]
    assert resolve_keys("LAB100", cols) == ("LAB_RPT_LOCAL_ID", "LAB_RPT_UID")


def test_config_lookup_is_case_insensitive_in_both_directions():
    # Lowercase table name and mixed-case columns still resolve, returning the
    # columns spelled as they actually appear in available_columns.
    cols = ["Lab_Test_Uid", "test_method_cd"]
    assert resolve_keys("lab_test", cols) == ("Lab_Test_Uid",)


def test_config_d_inv_uses_nbs_case_answer_uid():
    # D_INV_* tables key on NBS_CASE_ANSWER_UID per the offset section, never
    # the D_INV_*_KEY surrogate.
    cols = ["D_INV_SYMPTOM_KEY", "NBS_CASE_ANSWER_UID", "SYMPTOM_TXT"]
    assert resolve_keys("D_INV_SYMPTOM", cols) == ("NBS_CASE_ANSWER_UID",)


def test_config_falls_through_when_configured_column_missing():
    # MORBIDITY_REPORT is configured for MORBIDITY_REPORT_LOCAL_ID; if that
    # column is absent the config is skipped and the heuristic takes over.
    cols = ["MORBIDITY_REPORT_KEY", "MORB_RPT_UID"]
    # No *_LOCAL_ID -> falls to *_UID (and never the *_KEY surrogate).
    assert resolve_keys("MORBIDITY_REPORT", cols) == ("MORB_RPT_UID",)


# --- (2) *_LOCAL_ID preference ------------------------------------------
def test_local_id_preferred_over_uid():
    # An unconfigured table with both a LOCAL_ID and a UID picks the LOCAL_ID.
    cols = ["PROVIDER_KEY", "PROVIDER_UID", "PROVIDER_LOCAL_ID"]
    assert resolve_keys("D_PROVIDER", cols) == ("PROVIDER_LOCAL_ID",)


def test_local_id_prefers_entity_matching_prefix():
    # When several *_LOCAL_ID columns exist, prefer the one whose prefix
    # matches the table entity (PATIENT), not the first-listed one.
    cols = ["INVESTIGATION_LOCAL_ID", "PATIENT_LOCAL_ID", "PATIENT_KEY"]
    assert resolve_keys("D_PATIENT", cols) == ("PATIENT_LOCAL_ID",)


def test_local_id_falls_back_to_first_when_no_prefix_match():
    cols = ["FOO_LOCAL_ID", "BAR_LOCAL_ID"]
    assert resolve_keys("UNRELATED_TABLE", cols) == ("FOO_LOCAL_ID",)


# --- (3) *_UID fallback --------------------------------------------------
def test_uid_fallback_when_no_local_id():
    cols = ["SOMETHING_KEY", "EVENT_UID", "DESCRIPTION"]
    assert resolve_keys("SOME_FACT", cols) == ("EVENT_UID",)


# --- (4) *_KEY is never returned ----------------------------------------
def test_key_surrogate_never_returned():
    # Only a surrogate *_KEY is available -> no usable business key.
    cols = ["PATIENT_KEY", "FIRST_NM", "LAST_NM"]
    assert resolve_keys("D_PATIENT", cols) is None


def test_key_with_uid_suffix_is_not_treated_as_uid():
    # A column ending in _KEY must not be picked even though "_UID" matching is
    # the fallback tier; there is no real *_UID here.
    cols = ["RESULTED_LAB_TEST_KEY", "LAB_TEST_KEY"]
    assert resolve_keys("SOME_BRIDGE", cols) is None


# --- (5) None when nothing usable ---------------------------------------
def test_none_when_no_usable_key():
    cols = ["FIRST_NM", "LAST_NM", "BIRTH_DT"]
    assert resolve_keys("D_PATIENT", cols) is None


# --- sanity on the seed --------------------------------------------------
def test_key_config_is_uppercase_and_tuples():
    for table, key in KEY_CONFIG.items():
        assert table == table.upper()
        assert isinstance(key, tuple) and key
        # No surrogate *_KEY columns are ever configured as keys.
        assert not any(c.upper().endswith("_KEY") for c in key)
