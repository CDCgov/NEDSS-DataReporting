# Plan: RTR Database Installation Simplification

## 1. Goal
Reduce the complexity of the RTR database onboarding and update process by replacing multiple manual SQL execution steps with a unified container-based tool. This tool will support both automated (Liquibase) and manual (Consolidated SQL Bundle) deployment paths.

## 2. Proposed Solution: `rtr-db-tool.sh`
Develop a comprehensive wrapper script within the `liquibase-service` container image. This script will serve as the single entry point for all database-related tasks.

### Mode A: Automated Setup (Liquibase Opt-In)
For users who allow the container to manage their schema directly, the tool will perform a "One-Command Setup":
1.  **Environment Sync:** Automatically update `NBS_ODSE..NBS_Configuration` with the correct `ENV` value (UAT/PROD).
2.  **User Provisioning:** Run the user/login creation scripts against the `master` database.
3.  **Unified Migration:** Execute all Liquibase changelogs, including a new **RTR Onboarding Changelog** that handles:
    *   Schema creation (ODSE, SRTE, RDB_MODERN).
    *   Metadata and Key table hydration (formerly the manual `02` scripts).
    *   CDC Activation on transactional tables.
    *   SQL Agent Job creation.

## 3. Core Strategy: Refactoring for Automation
To make the onboarding scripts (`02`) compatible with Liquibase and the unified tool, we will perform a one-time refactoring of the SQL files.

### 3.1 Removing Routing Logic
The existing `USE [rdb]` / `USE [rdb_modern]` conditional blocks will be removed from all SQL files.
*   **New Flow:** The `rtr-db-tool.sh` script will determine the target database (based on environment variables or a pre-run check of `NBS_Configuration`).
*   **Result:** The SQL files become "context-agnostic," making them easier to test and allowing Liquibase to manage the connection strings cleanly.

### 3.2 Handling Cross-Database Scripts
Scripts that *must* touch databases other than the reporting target will be handled as follows:
*   **Transactional CDC (`1002`-`1005`):** These will be moved into a separate "Transactional" changelog. The tool will run a targeted Liquibase update against `NBS_ODSE` and `NBS_SRTE` for these specific files.
*   **System Jobs (`1006`, `1007`):** Since these target `msdb`, they will remain as `sqlcmd` executions within the tool, as Liquibase is not the ideal tool for managing system-level MSDB objects.

### 3.3 The RTR Onboarding Changelog
All other hydration and metadata scripts will be consolidated into a standard Liquibase changelog.
*   **Benefits:** Atomic deployment, state tracking via `DATABASECHANGELOG`, and automatic inclusion in manual SQL bundles ("Mode B").

### Mode B: Bundle Generation (Liquibase Opt-Out)
For users who cannot let a container touch their DB, the tool will generate a "Manual Migration Pack." 

#### Handling Database "State"
A critical challenge for manual SQL is knowing which migrations have already been applied. The tool will handle this in two ways:
1.  **State-Aware Generation (Recommended):** The user provides database connection details to the container. Liquibase connects in **Read-Only** mode to inspect the `DATABASECHANGELOG` table. It then uses the `update-sql` command to generate *only* the pending SQL changes.
2.  **Disconnected State-Aware Generation (Advanced):** If a direct connection is not allowed in the final environment, the user can perform a "State Capture" from a lower environment or a one-time connection.
    *   The container is run in `capture-state` mode to connect to the database and use Liquibase's `generate-changelog` command to produce a `current_state.xml` file.
    *   This XML file is then mounted into the container for the offline generation run:
        `docker run -v ./current_state.xml:/input/state.xml liquibase-service generate-sql`
    *   The tool uses this XML as a reference to determine exactly which objects are already present and generate only the delta SQL bundle.
3.  **Full Baseline Generation (Fallback):** If no connection or state file is provided, the tool generates a cumulative SQL file containing the *entire* schema definition. Because RTR scripts are designed to be **idempotent** (using `IF NOT EXISTS` logic), this file can be safely run against an existing database; it will simply skip objects that already exist.

#### Pack Contents:
The tool will consolidate dozens of individual scripts into five logical files:
*   `00_USER_CREATION.sql` (Master)
*   `01_NBS_ODSE_SCHEMA.sql` (ODSE)
*   `02_NBS_SRTE_SCHEMA.sql` (SRTE)
*   `03_RDB_MODERN_SCHEMA.sql` (RDB_MODERN)
*   `04_DATA_LOAD_AND_CDC.sql` (Master/Post-Install)

## 3. Implementation Steps

### Step 1: Container Enhancement
*   Add `mssql-tools` and `zip` utilities to the production `Dockerfile` (currently only in `.local`).
*   Embed the `rtr-db-tool.sh` script.

### Step 2: Automation Logic
*   The script should detect environment variables (e.g., `DB_HOST`, `RTR_MODE=GENERATE`) to decide which path to take.
*   Implement "State Inspection" logic: if `DB_HOST` is present during a generation run, check the changelog table; if not, default to "Full Baseline."

### Step 3: Distribution Path
How users will obtain the "Manual Pack":
1.  **On-Demand Generation:** Users pull the image and run:
    `docker run --env-file ./my-db.env -v ./output:/output liquibase-service generate-sql`
2.  **Release Artifacts:** The CI/CD pipeline can pre-generate "Full Baseline" bundles for every release and attach them to the GitHub release page as a ZIP file.

## 4. Expected Impact
*   **Time Savings:** Reduces the onboarding process from hours to ~15 minutes.
*   **Reliability:** Eliminates human error in script execution order.
*   **Security Compliance:** Provides a path for STLTs who require manual DBA review of all SQL before execution.
