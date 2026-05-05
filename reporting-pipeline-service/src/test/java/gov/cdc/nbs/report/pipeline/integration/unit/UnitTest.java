package gov.cdc.nbs.report.pipeline.integration.unit;

import gov.cdc.nbs.report.pipeline.integration.support.config.DataSourceConfig;
import java.io.File;
import java.nio.file.Files;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import javax.sql.DataSource;
import liquibase.Scope;
import liquibase.command.CommandScope;
import liquibase.command.core.UpdateCommandStep;
import liquibase.database.Database;
import liquibase.database.DatabaseFactory;
import liquibase.database.jvm.JdbcConnection;
import liquibase.resource.CompositeResourceAccessor;
import liquibase.resource.DirectoryResourceAccessor;
import liquibase.resource.ResourceAccessor;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@Tag("Unit")
@DataJpaTest()
@Import(DataSourceConfig.class)
@AutoConfigureTestDatabase(replace = Replace.NONE)
@TestInstance(Lifecycle.PER_CLASS)
@Slf4j
public abstract class UnitTest {

  @Autowired
  @Qualifier("adminDataSource")
  private DataSource adminDataSource;

  // The root from which ALL db files (changelogs and sql) can be found
  private static final String RESOURCE_ROOT = "../liquibase-service/src/main/resources";

  // Relative paths from RESOURCE_ROOT
  private static final String MIGRATION_DIR = RESOURCE_ROOT + "/db";
  private static final String ONBOARDING_DIR =
      RESOURCE_ROOT + "/db/001-master/02_onboarding_script_data_load";

  @BeforeAll
  void runMigrations() throws Exception {
    checkDatabaseConnection();
    log.info("Starting Migration Phase...");

    applyMigration("NBS_ODSE", "db.odse.admin.tasks.changelog-16.1.yaml");
    applyMigration("NBS_ODSE", "db.odse.changelog-16.1.yaml");
    applyMigration("NBS_SRTE", "db.srte.admin.tasks.changelog-16.1.yaml");
    applyMigration("rdb_modern", "db.rdb.changelog-16.1.yaml");
    applyMigration("rdb_modern", "db.rdb_modern.changelog-16.1.yaml");

    log.info("Starting Onboarding Phase...");
    applyOnboardingScripts("NBS_ODSE");
  }

  private void checkDatabaseConnection() {
    String url = "unknown";
    try (Connection conn = adminDataSource.getConnection()) {
      // Force a short login timeout for this check (3 seconds)
      url = conn.getMetaData().getURL();
      conn.setNetworkTimeout(null, 3000);
      if (!conn.isValid(3)) {
        throw new SQLException("Connection is not valid.");
      }
    } catch (Exception e) {
      String errorMessage =
          """
          #################################################################################
          DATABASE CONNECTION FAILURE:
          Could not establish a connection to the database.

          Target URL: %s

          REQUIREMENT: You must have an NBS >=6.0.17 version of SQL Server running
          in the background (local service or Docker) before starting this test.

          Please check your 'application-test.yaml' credentials and ensure a connection
          to SQL Server with those credentials is correct.

          Typically, starting an nbs-mssql in the background with docker compose is
          sufficent.

          Example:
          docker compose -f docker-compose.yml up -d nbs-mssql
          #################################################################################
          """;
      log.error(errorMessage, url);
      throw new RuntimeException(errorMessage, e);
    }
  }

  private void applyMigration(String dbName, String changelogFile) throws Exception {
    try (Connection connection = adminDataSource.getConnection()) {
      connection.setCatalog(dbName);

      // 1. Setup the Database wrapper
      Database database =
          DatabaseFactory.getInstance()
              .findCorrectDatabaseImplementation(new JdbcConnection(connection));

      // 2. Build the recursive Search Path (Accessors)
      // This is necessary as all the migrations are organized in nested
      // subdirectories, but the changelog files only reference the migrations
      // by their filename, and not their relative path.
      List<DirectoryResourceAccessor> accessors = new ArrayList<>();
      accessors.add(new DirectoryResourceAccessor(new File(RESOURCE_ROOT)));
      try (var stream = Files.walk(new File(MIGRATION_DIR).toPath())) {
        stream
            .filter(Files::isDirectory)
            .map(
                path -> {
                  try {
                    return new DirectoryResourceAccessor(path.toFile());
                  } catch (Exception e) {
                    return null;
                  }
                })
            .filter(Objects::nonNull)
            .forEach(accessors::add);
      }

      // 3. Execute the Command
      log.debug("Applying: " + changelogFile + " to " + dbName);
      try (var compositeAccessor =
          new CompositeResourceAccessor(accessors.toArray(ResourceAccessor[]::new))) {
        Scope.child(
            Map.of(Scope.Attr.resourceAccessor.name(), compositeAccessor),
            () -> {
              new CommandScope(UpdateCommandStep.COMMAND_NAME)
                  .addArgumentValue(
                      UpdateCommandStep.CHANGELOG_FILE_ARG, "db/changelog/" + changelogFile)
                  .addArgumentValue("database", database)
                  .execute();
            });
      } finally {
        if (database != null) {
          database.close();
        }
      }
    }
  }

  private void applyOnboardingScripts(String dbName) throws Exception {
    File onboardingDir = new File(ONBOARDING_DIR);

    if (!onboardingDir.exists()) {
      throw new RuntimeException(
          "Onboarding directory not found: " + onboardingDir.getAbsolutePath());
    }

    File[] sqlFiles = onboardingDir.listFiles((dir, name) -> name.toLowerCase().endsWith(".sql"));
    if (sqlFiles == null || sqlFiles.length == 0) {
      log.error("No SQL files found in onboarding directory: {}", ONBOARDING_DIR);
      return;
    }
    Arrays.sort(sqlFiles, Comparator.comparing(File::getName));

    // Create a local JdbcTemplate to gain access to the low-level .execute() method
    JdbcTemplate jdbcTemplate = new JdbcTemplate(adminDataSource);

    for (File sqlFile : sqlFiles) {
      log.debug("Executing SQL: " + sqlFile.getName());
      String content = Files.readString(sqlFile.toPath());

      Arrays.stream(content.split("(?i)\\bGO\\b"))
          .map(String::trim)
          .filter(batch -> !batch.isEmpty())
          .forEach(batch -> jdbcTemplate.execute(batch));
    }
  }
}
