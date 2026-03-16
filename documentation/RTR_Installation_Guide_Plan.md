# High-Level Plan: RTR Database Installation & Upgrade Guide

This document outlines the proposed simplified workflow for STLTs to install or upgrade the RTR database environment. The goal is to provide a single container-based tool that handles both automated and manual deployment paths.

---

## Phase 1: Administrative Onboarding (First-Time Setup)
*Requirement: Executed with `sysadmin` or `db_owner` privileges. Covers User Creation, CDC Activation, and SQL Agent Jobs.*

### Option A: Auto-Apply (Connected)
Run the onboarding tool in `setup` mode with administrative credentials.
```bash
docker run --env-file admin-db.env rtr/liquibase-service setup --onboarding
```
*   **What happens:** The tool creates service users, enables CDC on ODSE/SRTE, and sets up maintenance jobs in MSDB.

### Option B: SQL Bundle (Disconnected)
Generate a consolidated SQL script for a DBA to review and run.
```bash
docker run rtr/liquibase-service generate-sql --onboarding > rtr_onboarding_admin.sql
```
*   **What happens:** The tool produces a single, idempotent SQL file containing all cross-database administrative tasks.

---

## Phase 2: Application Migrations (Onboarding & Updates)
*Requirement: Executed with standard `rtr_admin` privileges. Covers Schema, Metadata, and NRT Hydration.*

### Step 1: Define Target & Mode
Set environment variables in your cluster or deployment manifest:
*   `RTR_DB_TARGET`: (e.g., `RDB_MODERN` or `RDB`)
*   `RTR_AUTO_APPLY`: (`true` or `false`)

### Step 2: Execution

#### Path 1: Auto-Apply Mode (`RTR_AUTO_APPLY=true`)
Simply start the Liquibase container as part of your cluster startup.
*   **What happens:** The tool detects the `RTR_DB_TARGET`, establishes a connection, and applies all pending schema changes and hydration logic automatically.

#### Path 2: Manual Bundle Mode (`RTR_AUTO_APPLY=false`)
If you cannot grant the container direct write access, follow these steps:

1.  **Capture State:** Run the container in `capture-state` mode. It connects to your databases and uses Liquibase's `snapshot` command to produce a **Unified State Asset** (`rtr_state.zip`) containing JSON snapshots of ODSE, SRTE, and RDB.
    ```bash
    docker run --env-file db.env -v ./output:/output rtr/liquibase-service capture-state
    ```
2.  **Generate Delta:** Run the container locally (disconnected) mounting the `rtr_state.zip`. The tool compares the RTR release against these snapshots and produces a tailored ZIP bundle of only the missing changes:
    ```bash
    docker run -v ./output/rtr_state.zip:/input/state.zip -v ./bundle:/output rtr/liquibase-service generate-sql
    ```
3.  **Apply:** Pass the resulting `rtr_migration_bundle.zip` to your DBA. It contains consolidated, context-agnostic SQL files for each database.

---

## Phase 3: Finalization
1.  **Verify:** Run the "Data Parity" queries (provided in the Playbook) to ensure RTR and legacy MasterETL are in sync.
2.  **Start Services:** Bring up the Java microservices; they will automatically begin processing events based on the newly hydrated `nrt_` tables and active CDC.
