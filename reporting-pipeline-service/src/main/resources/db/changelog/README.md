# Database migrations

The reporting pipeline service uses Liquibase to manage the `RDB/RDB_MODERN` SQL Server database. This directory contains the root changelog and the versioned SQL migrations that Liquibase runs when the service starts.

## TL;DR

- Put the migration in the directory for the first release that needs it, such as `v7.13.1` or `v7.14`.
- Treat merged or shared migrations as immutable; create a new migration instead of editing one that may have run.
- Make migrations idempotent whenever possible.
- Leave `runOnChange` unset so it retains the default value of `false`.
- Add the SQL file and register it with a unique changeset in the target release's `rdb.changelog-<version>.yaml`.
- For a stored procedure update, `git mv` the old definition into the new release, increment its revision suffix (for example, `001` to `002`), and leave a commented placeholder at the old path.
- Check root changelog ordering when adding a release because `includeAll` sorts lexically rather than by semantic version.
- Test both a fresh database and an upgrade from the previous release.

## Changelog structure

```text
db/changelog/
├── db.changelog-master.yaml
└── migrations/
    └── v7.13/
        └── rdb/
            ├── rdb.changelog-7.13.yaml
            ├── functions/
            ├── onboarding/
            ├── remove/
            ├── routines/
            ├── tables/
            └── views/
```

- `db.changelog-master.yaml` is configured in `application.yaml`. Its recursive `includeAll` discovers changelog files ending in `.yaml` below `migrations/`.
- Each release directory has an RDB changelog named `rdb.changelog-<version>.yaml`.

> **Ordering:** `includeAll` orders resources lexically, not by semantic version. For example, `v7.13.1` can sort before `v7.13`. Before adding a release whose directory does not sort in migration order, replace the root `includeAll` with explicit `include` entries in release order (or adopt an agreed sortable naming convention). Never rely on lexical ordering without checking it.

- SQL files are grouped by their purpose:
  - `routines/`: stored procedures
  - `functions/`: SQL functions
  - `tables/`: table creation and alteration
  - `views/`: views
  - `onboarding/`: initial data, backfills, and indexes needed when onboarding
  - `remove/`: cleanup and object removal

## Choose a release directory

Put a migration in the directory for the **first application release that must apply it**. Confirm the target release before opening the PR.

| Target release | Directory | Changelog |
|---|---|---|
| 7.13 | `migrations/v7.13/rdb/` | `rdb.changelog-7.13.yaml` |
| 7.13.1 patch | `migrations/v7.13.1/rdb/` | `rdb.changelog-7.13.1.yaml` |
| 7.14 | `migrations/v7.14/rdb/` | `rdb.changelog-7.14.yaml` |

A fix released in 7.13.1 belongs in `v7.13.1`, not `v7.13`. A feature first released in 7.14 belongs in `v7.14`, even if development started while 7.13 was current. When a release-branch migration is merged forward, preserve the migration rather than recreating it under a different identity.

## Edit an existing migration or create a new one?

Treat a migration as immutable after it has been merged or applied to a shared database.

**Edit an existing migration only when all of the following are true:**

- it was introduced by the current, unmerged change;
- it has not been applied outside a disposable development database; and
- changing it will not alter an already-published release.

**Create a new migration when:**

- the existing migration has been merged;
- the existing migration may have run in CI, test, staging, or production;
- the change is for a later patch or minor release; or
- the new work corrects or extends previously released database behavior.

Changing an applied changeset can produce a checksum error. A new changeset preserves an auditable upgrade path and ensures both fresh and existing databases reach the same state.

## Create a migration

This project does not currently provide a migration generator. Create the SQL and YAML changeset manually. A database tool such as SQL Server Management Studio can generate an object's initial DDL, but review and normalize that SQL before committing it.

1. Select the target release and the appropriate purpose directory.
2. If this is the first migration for the release, create its directories and `rdb.changelog-<version>.yaml`.
3. Add a descriptively named SQL file. Follow the `<sequence>-<description>-<revision>.sql` convention and choose a sequence that does not collide within that purpose directory. Use revision `001` for the initial definition and increment it (`002`, `003`, and so on) for later migrations of the same object.
4. Whenever possible, make the migration idempotent so running it more than once produces the same database state without failing or duplicating data. Prefer guards such as `IF EXISTS` or `IF NOT EXISTS`, and use conditional data changes where appropriate.
5. Add a uniquely identified changeset to the release changelog.
6. Test both a fresh database and an upgrade from the previous released version.

Example file:

```text
migrations/v7.14/rdb/tables/001-add_example_column-001.sql
```

Example release changelog:

```yaml
databaseChangeLog:
  - changeSet:
      id: 1
      author: liquibase
      changes:
        - sqlFile:
            path: db/changelog/migrations/v7.14/rdb/tables/001-add_example_column-001.sql
            splitStatements: false
```

Changeset IDs must be unique within their changelog. Continue the established ordering in the release changelog; do not reuse an ID already present there. Paths are classpath-relative and start with `db/changelog/`.

Keep `runOnChange` false, which is the Liquibase default. Omit `runOnChange` from new changesets rather than setting it to `true`. A versioned migration should run once; later changes, including stored procedure and view updates, belong in a new changeset. Existing changelogs predate this guidance and contain `runOnChange: true`; do not copy that setting into new changesets.

The repository uses `splitStatements: false` for SQL files containing complete SQL Server definitions. Follow that convention, especially when the file contains procedure bodies or `GO` batch separators.

## Updating an existing stored procedure

A stored procedure update must be a new changeset in the target release. To avoid presenting the entire procedure as deleted and added in a PR, move its definition with Git, leave a documented placeholder at the old path, and modify the moved file.

For example, to update a procedure from 7.13 for 7.14:

```sh
old=reporting-pipeline-service/src/main/resources/db/changelog/migrations/v7.13/rdb/routines/056-sp_investigation_event-001.sql
new=reporting-pipeline-service/src/main/resources/db/changelog/migrations/v7.14/rdb/routines/056-sp_investigation_event-002.sql

mkdir -p "$(dirname "$new")"
git mv "$old" "$new"
cat > "$old" <<'SQL'
-- The procedure definition moved to the v7.14 migration directory.
-- This placeholder preserves the v7.13 changeset path and history.
SQL
```

Then:

1. Edit the procedure at the **new** path.
2. Leave the existing 7.13 changelog entry unchanged; it continues to reference the placeholder at the old path.
3. Add a changeset to `rdb.changelog-7.14.yaml` that references the moved procedure at its new path. Leave `runOnChange` unset so it retains the default value of `false`.
4. Use `git diff --find-renames` to verify that Git presents the procedure as a rename plus the focused edits.

Example new changeset:

```yaml
databaseChangeLog:
  - changeSet:
      id: 1
      author: liquibase
      changes:
        - sqlFile:
            path: db/changelog/migrations/v7.14/rdb/routines/056-sp_investigation_event-002.sql
            splitStatements: false
```

This approach has two important effects:

- A fresh database first runs the old placeholder and later creates the current procedure from the new release.
- An existing database receives the new release changeset and replaces its current procedure definition.

Do not delete the old file or change the old changelog to point at the new path. Either action rewrites the identity or contents of migration history instead of adding an upgrade.
