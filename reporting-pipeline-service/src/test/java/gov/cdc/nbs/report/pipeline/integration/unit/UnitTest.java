package gov.cdc.nbs.report.pipeline.integration.unit;

import gov.cdc.nbs.report.pipeline.integration.support.config.DataSourceConfig;
import java.io.File;
import java.time.Duration;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.containers.wait.strategy.Wait;

@DataJpaTest
@AutoConfigureTestDatabase(replace = Replace.NONE)
@TestInstance(Lifecycle.PER_CLASS)
@ActiveProfiles("test")
@Tag("Unit")
@Import(DataSourceConfig.class)
public abstract class UnitTest {

  private static final Logger log = LoggerFactory.getLogger(UnitTest.class);
  private static final Slf4jLogConsumer consumer = new Slf4jLogConsumer(log);
  private static final File base = new File("../docker-compose.yaml");

  @SuppressWarnings("resource")
  private static ComposeContainer environment =
      new ComposeContainer(base)
          .withServices("nbs-mssql")
          .waitingFor("nbs-mssql", Wait.forHealthcheck())
          .withLogConsumer("nbs-mssql", consumer)
          // Set the maximum startup timeout all the waits set are bounded to
          .withStartupTimeout(Duration.ofMinutes(10));

  static {
    // Must be statically initialized to allow liquibase configuration
    // to run without manual intervention
    environment.start();
  }

  @AfterAll
  static void tearDown() {
    environment.stop();
  }
}
