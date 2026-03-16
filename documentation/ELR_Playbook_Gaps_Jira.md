# Draft Jira Issues: RTR ELR Bulk Loading Gaps

These issues represent the work necessary to fully support the KY ELR bulk loading playbook.

## 1. RTR-GAP-001: Implement Automated Latency Tracking in RDB_MODERN
**Summary:** Add a processing arrival timestamp to RDB_MODERN tables to support latency metrics.
**Description:** Currently, there is no direct way to measure end-to-end latency from the reporting database alone. We need to add an `RTR_ARRIVAL_TIME` column (or similar) to key tables like `EVENT_METRIC` and `LAB_REPORT` that is populated by the RTR service when the event is processed.
**Priority:** High
**Labels:** metrics, performance, STLT-playbook

## 2. RTR-GAP-002: Orchestrate ELR Bulk Loading for Performance Testing
**Summary:** Create an automated tool or script to orchestrate high-volume ELR loading.
**Description:** The current process for loading ELRs is manual (`ELRImporter.sh`). To support bulk loading tests of millions of records, we need an automated way to:
1. Batch generate and insert ELRs into `NBS_INTERFACE`.
2. Trigger the `ELRImporter` in an optimized way.
3. Monitor for completion.
**Priority:** Medium
**Labels:** performance, automation, testing

## 3. RTR-GAP-003: Resolve Lookup Data Deficiencies in Development Snapshots
**Summary:** Update development database snapshots to include all lookup data required for page builder prepopulation.
**Description:** Performance testing often results in errors in WildFly logs: "prepop caching failed due to question Identifier :null". This is caused by missing data in `NBS_ODSE..LOOKUP_ANSWER` and `NBS_ODSE..LOOKUP_QUESTION` for certain conditions. These deficiencies should be resolved to ensure clean test runs.
**Priority:** Medium
**Labels:** dev-experience, testing, data-quality

## 4. RTR-GAP-004: Automated Performance Reporting Dashboard
**Summary:** Develop a simple dashboard or automated report to visualize ELR processing performance and latency.
**Description:** Capturing metrics manually from SQL queries is error-prone. We need a way to automatically aggregate data from `EVENT_METRIC` and `job_flow_log` into a performance report after a test run.
**Priority:** Low
**Labels:** metrics, visualization, reporting

## 5. RTR-GAP-005: KY-Specific HL7 Schema Validation for convert.py
**Summary:** Ensure `convert.py` correctly handles KY-specific HL7 segments or variations.
**Description:** Since the playbook now specifies using real ELRs, we must verify that the `convert.py` script correctly maps KY's specific HL7 message structures into the `NBS_INTERFACE` table without data loss or errors.
**Priority:** High
**Labels:** data-quality, compatibility, KY-specific

## 6. RTR-GAP-006: De-identification Utility for Real Test ELRs
**Summary:** Provide a utility to de-identify real ELRs before processing in lower environments.
**Description:** To safely use real ELRs in test environments, a tool to automatically scrub or randomize PII (Personally Identifiable Information) while maintaining data relationships (e.g., ensuring the same patient is consistently de-identified) would be beneficial for maintaining security and data integrity.
**Priority:** Medium
**Labels:** security, data-privacy, utility
