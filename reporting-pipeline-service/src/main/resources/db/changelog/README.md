# Database migrations

The reporting pipeline service uses Liquibase to manage the `RDB/RDB_MODERN` SQL Server database. This directory contains the root changelog and the versioned SQL migrations that Liquibase runs when the service starts.

> **Important: a release changelog is not a complete inventory of database changes in that release.**
>
> A view, function, or stored procedure can be updated in its original changelog and automatically reapplied by Liquibase because its existing changeset uses `runOnChange: true`. For example, a procedure first registered under `v7.13` may be changed and delivered in a later release without a new entry in that later release's changelog. Do **not** use only a release changelog to determine the database changes delivered between releases.
>
> To obtain the complete release-level database change picture, review the Git range: `git diff release_a...release_b`. The diff captures both newly registered changesets and in-place updates to existing `runOnChange` definitions.

## TL;DR

- A release changelog is not a complete database-change inventory; use `git diff release_a...release_b` when comparing releases.
- Put the migration in the directory for the first release that needs it, such as `v7.13.1` or `v7.14`.
- Treat ordinary merged or shared migrations as immutable; safely replaceable view, function, and routine changesets with `runOnChange: true` are intentionally updated in place.
- Make migrations idempotent whenever possible.
- Set `runOnChange` to `true` for views, functions, and routines, and to `false` for all other changesets.
- For a new migration, add the SQL file and register it with a unique changeset in the target release's `rdb.changelog-<version>.yaml`.
- For a stored procedure update, edit the existing definition in place and use a changeset with `runOnChange: true`.
- Check root changelog ordering when adding a release because `includeAll` sorts lexically rather than by semantic version.
- Test both a fresh database and an upgrade from the previous release.

## Changelog structure

```text
db/changelog/
├── db.changelog-master.yaml
└── migrations/
    └── v7.13/
        └── rdb/
            ├── 000-rdbmodern-db-general-001.sql
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
- The root-level `000-rdbmodern-db-general-001.sql` is a legacy file that predates the purpose-based directory layout; new work should follow the purpose directories unless preserving historical context requires otherwise.

> **Ordering:** `includeAll` orders resources lexically, not by semantic version. For example, `v7.13.1` can sort before `v7.13`. At the moment there is only one release changelog under `migrations/`, so the recursive discovery and lexical-order behavior are not yet exercised by multiple release directories. Before adding a release such as `v7.14` whose directory does not sort in migration order, replace the root `includeAll` with explicit `include` entries in release order (or adopt an agreed sortable naming convention). Never rely on lexical ordering without checking it.

- SQL files are grouped by their purpose:
  - `routines/`: stored procedures
  - `functions/`: SQL functions
  - `tables/`: table creation and alteration
  - `views/`: views
  - `onboarding/`: initial data, backfills, and indexes needed when onboarding
  - `remove/`: cleanup and object removal

## Choose where to maintain the migration

| Migration type | Where to maintain it |
|---|---|
| Ordinary migration | Directory for the **first application release that needs it** |
| View, function, or routine with `runOnChange: true` | Existing release file; update the changeset in place |

For ordinary migrations, confirm the target release before opening the PR.

| Target release | Directory | Changelog |
|---|---|---|
| 7.13 | `migrations/v7.13/rdb/` | `rdb.changelog-7.13.yaml` |
| 7.13.1 patch | `migrations/v7.13.1/rdb/` | `rdb.changelog-7.13.1.yaml` |
| 7.14 | `migrations/v7.14/rdb/` | `rdb.changelog-7.14.yaml` |

A fix released in 7.13.1 belongs in `v7.13.1`, not `v7.13`. A feature first released in 7.14 belongs in `v7.14`, even if development started while 7.13 was current. When a release-branch migration is merged forward, preserve the migration rather than recreating it under a different identity. Stored procedure definitions are maintained in the original release file indefinitely; later definition changes update that file's `runOnChange: true` changeset in place.

## Edit an existing migration or create a new one?

Treat ordinary migrations as immutable after they have been merged or applied to a shared database. View, function, and routine changesets that use `runOnChange: true` are the intentional exception: they are designed to be safely replaceable and are intentionally treated as mutable so Liquibase can reapply them when their definitions change.

**Edit an ordinary migration only when all of the following are true:**

- it was introduced by the current, unmerged change;
- it has not been applied outside a disposable development database; and
- changing it will not alter an already-published release.

**Edit a `runOnChange` migration when:**

- it defines a view, function, or routine;
- its changeset has `runOnChange: true`;
- its SQL safely replaces the existing object; and
- the change updates that object's definition in place rather than adding unrelated migration work.

**Create a new migration when:**

- the existing migration has been merged;
- the existing migration may have run in CI, test, staging, or production;
- the change is for a later patch or minor release and is not an update to a `runOnChange: true` object definition; or
- the new work corrects or extends previously released database behavior outside the existing `runOnChange: true` object definition.

Changing an ordinary applied changeset can produce a checksum error. A new changeset preserves an auditable upgrade path and ensures both fresh and existing databases reach the same state.

## Create a migration

This project does not currently provide a migration generator. Create the SQL and YAML changeset manually. A database tool such as SQL Server Management Studio can generate an object's initial DDL, but review and normalize that SQL before committing it.

1. Select the target release and the appropriate purpose directory.
2. If this is the first migration for the release, create its directories and `rdb.changelog-<version>.yaml`.
3. Add a descriptively named SQL file. Follow the `<sequence>-<description>-<revision>.sql` convention and choose a sequence that does not collide within that purpose directory.
   - Use revision `001` for the initial definition.
   - Increment it (`002`, `003`, and so on) only for a later *ordinary* migration against the same object, such as a second `ALTER TABLE` on a table you have already migrated.
   - Do not increment it for a view, function, or stored procedure: those are `runOnChange: true` and are edited in place, keeping `-001` for the life of the object.

> **Note:** If you are about to create `sp_something-002.sql`, you are on the wrong path — see *Updating an existing stored procedure*. Existing files predating this convention may not follow it; apply it to new work.

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
      runOnChange: false
      changes:
        - sqlFile:
            path: db/changelog/migrations/v7.14/rdb/tables/001-add_example_column-001.sql
            splitStatements: false
```

Changeset IDs must be unique within their changelog. Continue the established ordering in the release changelog; do not reuse an ID already present there. Paths are classpath-relative and start with `db/changelog/`.

Set `runOnChange` to `true` for views, functions, and routines, including stored procedures. Set it to `false` for all other changesets. Changesets for views, functions, and routines may rerun when their SQL changes and should be updated in place; create a new changeset for later changes to all other migrations.

The repository commonly uses `splitStatements: false` for SQL files containing one complete SQL Server definition. For files containing `GO` batch separators, set `splitStatements: true` and configure the matching `endDelimiter` (for example, `endDelimiter: GO`). Keep the delimiter on its own line and verify that the resulting batches execute correctly through Liquibase.

## Updating an existing stored procedure

Update an existing stored procedure in its current SQL file and keep its existing changelog entry and file path. The procedure changeset must have `runOnChange: true`, so Liquibase reapplies the changeset when the procedure definition changes. Do not move the file, replace it with a placeholder, or create a duplicate release-specific changeset solely to update the procedure.

For example, to update a procedure already defined in 7.13:

1. Edit the procedure definition at its existing path, such as `migrations/v7.13/rdb/routines/056-sp_investigation_event-001.sql`.
2. Leave the existing changelog entry pointing to that file and ensure the changeset includes `runOnChange: true`.
3. Use `git diff` to verify that the pull request contains only the intended procedure changes.

Example changeset:

```yaml
databaseChangeLog:
  - changeSet:
      id: 1
      author: liquibase
      runOnChange: true
      changes:
        - sqlFile:
            path: db/changelog/migrations/v7.13/rdb/routines/056-sp_investigation_event-001.sql
            splitStatements: true
            endDelimiter: GO
```

On a fresh database, Liquibase applies the procedure definition once. On an existing database, Liquibase detects the changed SQL and reapplies the `runOnChange` changeset so the procedure is updated.

## Rollbacks

Rollback is not supported or validated for these migrations. Do not rely on Liquibase automatic rollback or add rollback logic unless this policy changes. Correct deployed database behavior with a new forward migration; use the approved database backup and restore process for operational recovery when necessary.