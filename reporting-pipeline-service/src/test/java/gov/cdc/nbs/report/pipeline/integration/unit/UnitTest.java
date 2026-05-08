package gov.cdc.nbs.report.pipeline.integration.unit;

import gov.cdc.nbs.report.pipeline.integration.support.config.DataSourceConfig;
import java.io.File;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

@DataJpaTest()
@AutoConfigureTestDatabase(replace = Replace.NONE)
@TestInstance(Lifecycle.PER_CLASS)
@ActiveProfiles("test")
@Tag("Unit")
@Import(DataSourceConfig.class)
public abstract class UnitTest {

  private static final Logger log = LoggerFactory.getLogger(UnitTest.class);
  private static final File base = new File("../docker-compose.yaml");

  private static boolean started = false;
  private static ComposeContainer environment;

  @Autowired
  @Qualifier("customComposeFile")
  private File customComposeFile;

  @SuppressWarnings("resource")
  void initializeEnvironment() {
    List<File> composeFiles = new ArrayList<>(Arrays.asList(base));
    if (customComposeFile != null) {
      log.warn(
          "Using custom compose override. Base: {}, Custom: {}",
          base.getPath(),
          customComposeFile.getPath());
      composeFiles.add(customComposeFile);
    }
    environment =
        new ComposeContainer(DockerImageName.parse("docker:25.0.5"), composeFiles)
            .withServices("nbs-mssql")
            .waitingFor("nbs-mssql", Wait.forHealthcheck())
            .withServices("liquibase")
            .waitingFor("liquibase", Wait.forLogMessage(".*Migrations complete.*\\n", 1))
            // Set the maximum startup timeout all the waits set are bounded to
            .withStartupTimeout(Duration.ofMinutes(5));
  }

  @BeforeAll
  void setUp() throws Exception {
    synchronized (UnitTest.class) {
      if (!started) {
        if (environment == null) {
          initializeEnvironment();
        }
        environment.start();
        started = true;
      }
    }
  }

  @AfterAll
  void tearDown() throws Exception {
    synchronized (UnitTest.class) {
      if (started) {
        if (environment == null) {
          initializeEnvironment();
        }
        environment.stop();
        started = false;
      }
    }
  }
}
