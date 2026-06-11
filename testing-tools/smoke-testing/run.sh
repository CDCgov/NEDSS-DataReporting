#!/bin/bash

# Smoke test for the RTR reporting pipeline.
#
# Starts the full stack, loads a Hepatitis A patient + investigation into NBS_ODSE,
# then polls rdb_modern.dbo.job_flow_log until all 62 expected SP_COMPLETE packages
# are present and no errors are recorded. Exits 0 on success, 1 on timeout or failure.
# The stack is torn down on exit via the trap.

set -euo pipefail

cd "$(dirname "$0")/../.." || exit

UP_TIMEOUT=300
UP_ELAPSED=0
UP_WAIT=10
VAL_TIMEOUT=120
VAL_ELAPSED=0
VAL_WAIT=5
EXPECTED_COMPLETED_PACKAGES=$(
    sort <<'EOF'
CASE_LAB_DATAMART
CASE_LAB_DATAMART
D_INV_ADMINISTRATIVE
D_INV_EPIDEMIOLOGY
D_INV_LAB_FINDING
D_INV_MEDICAL_HISTORY
D_INV_PATIENT_OBS
D_INV_TRAVEL
D_INV_VACCINATION
DynDM_Manage_Case_Management HEPATITIS_A_ACUTE
Hepatitis_Case_DATAMART
L_INV_ADMINISTRATIVE
L_INV_EPIDEMIOLOGY
L_INV_LAB_FINDING
L_INV_MEDICAL_HISTORY
L_INV_PATIENT_OBS
L_INV_TRAVEL
L_INV_VACCINATION
RDB_MODERN.sp_nrt_patient_postprocessing
S_F_PAGE_CASE
S_INV_ADMINISTRATIVE
S_INV_EPIDEMIOLOGY
S_INV_LAB_FINDING
S_INV_MEDICAL_HISTORY
S_INV_PATIENT_OBS
S_INV_TRAVEL
S_INV_VACCINATION
sp_dyn_dm_invest_form_postprocessing HEPATITIS_A_ACUTE
sp_dyn_dm_org_data_postprocessing HEPATITIS_A_ACUTE
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_ADMINISTRATIVE
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_CLINICAL
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_COMPLICATION
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_CONTACT
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_DEATH
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_EPIDEMIOLOGY
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_HIV
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_ISOLATE_TRACKING
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_LAB_FINDING
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_MEDICAL_HISTORY
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_MOTHER
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_OTHER
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_PATIENT_OBS
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_PREGNANCY_BIRTH
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_RESIDENCY
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_RISK_FACTOR
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_SOCIAL_HISTORY
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_STD
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_SYMPTOM
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_TREATMENT
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_TRAVEL
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_UNDER_CONDITION
sp_dyn_dm_page_builder_d_inv_postprocessing: HEPATITIS_A_ACUTE - D_INV_VACCINATION
sp_inv_summary_datamart_postprocessing
sp_nrt_case_count_postprocessing
sp_nrt_investigation_postprocessing
sp_nrt_ldf_dimensional_data_postprocessing
sp_nrt_ldf_postprocessing
sp_nrt_organization_postprocessing
sp_nrt_provider_postprocessing
sp_nrt_srte_condition_code_postprocessing
sp_sld_investigation_repeat_postprocessing
sp_user_profile_postprocessing
EOF
)

# Source .env if present; otherwise fall back to defaults defined in docker-compose.yaml
[ -f .env ] && source .env
DATABASE_PORT=${DATABASE_PORT:-3433}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-$(docker compose config --format json | jq -r '.services."nbs-mssql".environment.DATABASE_PASSWORD')}

run_query() {
    sqlcmd -S "localhost,${DATABASE_PORT}" -U sa -P "$DATABASE_PASSWORD" \
        -d RDB_MODERN -h -1 -W -Q "SET NOCOUNT ON; $1" |
        tr -d '\r' | grep -v '^[[:space:]]*$' || true
}

trap 'docker compose down' EXIT

docker compose up --build reporting-pipeline-service -d

# Wait for the reporting pipeline container to become healthy (5 minute timeout)
echo "Waiting for containers to be healthy..."
while ! docker compose ps --format json | jq -r 'select(.Health == "healthy") | .Name' | grep -q 'reporting-pipeline-service'; do
    if [ "$UP_ELAPSED" -ge "$UP_TIMEOUT" ]; then
        echo "Timed out waiting for reporting-pipeline-service to become healthy after ${UP_TIMEOUT}s"
        exit 1
    fi
    echo "Still waiting for reporting-pipeline-service... (${UP_ELAPSED}s elapsed)"
    sleep 5
    UP_ELAPSED=$((UP_ELAPSED + UP_WAIT))
done
echo "Reporting pipeline is healthy!"

sqlcmd -S "localhost,${DATABASE_PORT}" -U sa -P "$DATABASE_PASSWORD" -i testing-tools/smoke-testing/setup.sql

while true; do
    echo "Validating job_flow_log... (${VAL_ELAPSED}s elapsed)"
    PASS=true

    # Check a: SP_COMPLETE package_Name rows match expected list exactly
    ACTUAL=$(run_query "SELECT package_Name FROM [dbo].[job_flow_log] WHERE [Step_Name] = N'SP_COMPLETE'" | sort)
    if [ "$ACTUAL" != "$EXPECTED_COMPLETED_PACKAGES" ]; then
        ACTUAL_COUNT=$(printf '%s\n' "$ACTUAL" | grep -c . || echo 0)
        echo "  [FAIL] SP_COMPLETE package_Name mismatch (expected 62, got ${ACTUAL_COUNT}):"
        diff <(echo "$EXPECTED_COMPLETED_PACKAGES") <(echo "$ACTUAL") || true
        PASS=false
    fi

    # Check b: no rows with a non-null Error_Description
    ERROR_ROWS=$(run_query "SELECT Error_Description FROM [dbo].[job_flow_log] WHERE Error_Description IS NOT NULL")
    if [ -n "$ERROR_ROWS" ]; then
        echo "  [FAIL] Errors found in job_flow_log:"
        echo "$ERROR_ROWS" | sed 's/^/    /'
        PASS=false
    fi

    if [ "$PASS" = true ]; then
        echo "Validation passed."
        exit 0
    fi

    if [ "$VAL_ELAPSED" -ge "$VAL_TIMEOUT" ]; then
        echo "Validation timed out after ${VAL_TIMEOUT}s."
        exit 1
    fi

    sleep "$VAL_WAIT"
    VAL_ELAPSED=$((VAL_ELAPSED + VAL_WAIT))
done
