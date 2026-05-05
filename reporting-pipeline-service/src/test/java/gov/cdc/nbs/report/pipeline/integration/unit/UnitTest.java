package gov.cdc.nbs.report.pipeline.integration.unit;

import gov.cdc.nbs.report.pipeline.integration.support.config.DataSourceConfig;
import java.io.File;
import java.nio.file.Files;
import java.sql.Connection;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import javax.sql.DataSource;
import liquibase.Scope;
import liquibase.command.CommandScope;
import liquibase.command.core.UpdateCommandStep;
import liquibase.database.Database;
import liquibase.database.DatabaseFactory;
import liquibase.database.jvm.JdbcConnection;
import liquibase.resource.CompositeResourceAccessor;
import liquibase.resource.DirectoryResourceAccessor;
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
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@Tag("Unit")
@DataJpaTest()
@Import(DataSourceConfig.class)
@AutoConfigureTestDatabase(replace = Replace.NONE)
@TestInstance(Lifecycle.PER_CLASS)
public abstract class UnitTest {

  @Autowired
  @Qualifier("adminDataSource")
  private DataSource adminDataSource;

  // The root from which ALL db files (changelogs and sql) can be found
  private static final String RESOURCE_ROOT = "../liquibase-service/src/main/resources";

  // Relative paths from RESOURCE_ROOT
  private static final String CHANGELOG_DIR = "db/changelog/";
  private static final String ONBOARDING_DIR = "db/001-master/02_onboarding_script_data_load";

  @BeforeAll
  void runMigrations() throws Exception {
    System.out.println("Starting Migration Phase...");

    applyMigration("NBS_ODSE", "db.odse.admin.tasks.changelog-16.1.yaml");
    applyMigration("NBS_ODSE", "db.odse.changelog-16.1.yaml");
    applyMigration("NBS_SRTE", "db.srte.admin.tasks.changelog-16.1.yaml");
    applyMigration("rdb_modern", "db.rdb.changelog-16.1.yaml");
    applyMigration("rdb_modern", "db.rdb_modern.changelog-16.1.yaml");

    System.out.println("Starting Onboarding Phase...");
    applyOnboardingScripts("NBS_ODSE");
  }

  private void applyMigration(String dbName, String changelogFile) throws Exception {
    try (Connection connection = adminDataSource.getConnection()) {
      connection.setCatalog(dbName);

      Database database =
          DatabaseFactory.getInstance()
              .findCorrectDatabaseImplementation(new JdbcConnection(connection));

      File rootDir = new File(RESOURCE_ROOT);
      File dbDir = new File(rootDir, "db");

      List<DirectoryResourceAccessor> accessors = new ArrayList<>();

      // 1. Add the resources root (to find db/changelog/...)
      accessors.add(new DirectoryResourceAccessor(rootDir));

      // 2. Recursively find and add EVERY subfolder under 'db'
      // This picks up: db/003-odse, db/003-odse/views, db/005-rdb_modern/routines, etc.
      if (dbDir.exists()) {
        try (var stream = java.nio.file.Files.walk(dbDir.toPath())) {
          stream
              .filter(java.nio.file.Files::isDirectory)
              .forEach(
                  path -> {
                    try {
                      accessors.add(new DirectoryResourceAccessor(path.toFile()));
                    } catch (Exception e) {
                      // Ignore folders that can't be accessed
                    }
                  });
        }
      }

      try (CompositeResourceAccessor compositeAccessor =
          new CompositeResourceAccessor(accessors.toArray(new DirectoryResourceAccessor[0]))) {

        Scope.child(
            Map.of(Scope.Attr.resourceAccessor.name(), compositeAccessor),
            () -> {
              CommandScope updateCommand = new CommandScope(UpdateCommandStep.COMMAND_NAME);
              updateCommand.addArgumentValue(
                  UpdateCommandStep.CHANGELOG_FILE_ARG, "db/changelog/" + changelogFile);
              updateCommand.addArgumentValue("database", database);

              System.out.println("Applying: " + changelogFile + " to " + dbName);
              updateCommand.execute();
            });
      } finally {
        if (database != null) {
          database.close();
        }
      }
    }
  }

  private void applyOnboardingScripts(String dbName) throws Exception {
    File onboardingDir = new File(RESOURCE_ROOT, ONBOARDING_DIR);

    if (!onboardingDir.exists()) {
      throw new RuntimeException(
          "Onboarding directory not found: " + onboardingDir.getAbsolutePath());
    }

    File[] sqlFiles = onboardingDir.listFiles((dir, name) -> name.toLowerCase().endsWith(".sql"));
    if (sqlFiles == null || sqlFiles.length == 0) return;

    Arrays.sort(sqlFiles, Comparator.comparing(File::getName));

    try (Connection connection = adminDataSource.getConnection()) {
      connection.setCatalog(dbName);

      for (File sqlFile : sqlFiles) {
        System.out.println("Executing SQL: " + sqlFile.getName());
        String content = Files.readString(sqlFile.toPath());

        // Split by GO for SQL Server batching support
        String[] batches = content.split("(?i)\\bGO\\b");

        try (Statement statement = connection.createStatement()) {
          for (String batch : batches) {
            String trimmedBatch = batch.trim();
            if (!trimmedBatch.isEmpty()) {
              statement.execute(trimmedBatch);
            }
          }
        }
      }
    }
  }
}
