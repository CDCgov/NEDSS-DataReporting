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
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.ContextConfiguration;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.containers.wait.strategy.Wait;

@Tag("Unit")
@DataJpaTest
@ActiveProfiles("test")
@TestInstance(Lifecycle.PER_CLASS)
@AutoConfigureTestDatabase(replace = Replace.NONE)
@ContextConfiguration(initializers = UnitTest.Initializer.class)
@Import(DataSourceConfig.class)
public abstract class UnitTest {

  private static final Logger log = LoggerFactory.getLogger(UnitTest.class);
  private static final Slf4jLogConsumer consumer = new Slf4jLogConsumer(log);
  private static final File base = new File("../docker-compose.yaml");

  private static boolean started = false;

  @SuppressWarnings("resource")
  private static final ComposeContainer environment =
      new ComposeContainer(base)
          .withServices("nbs-mssql", "liquibase")
          .waitingFor("nbs-mssql", Wait.forHealthcheck())
          .waitingFor(
              "liquibase",
              Wait.forLogMessage(".*Migrations complete.*\\n", 1)
                  .withStartupTimeout(Duration.ofMinutes(10)))
          .withLogConsumer("nbs-mssql", consumer)
          // Set the maximum startup timeout all the waits set are bounded to
          .withStartupTimeout(Duration.ofMinutes(10));

  @AfterAll
  void tearDown() {
    synchronized (UnitTest.class) {
      if (started) {
        environment.stop();
        started = false;
      }
    }
  }

  static class Initializer
      implements ApplicationContextInitializer<ConfigurableApplicationContext> {
    @Override
    public void initialize(ConfigurableApplicationContext context) {
      // Force container startup BEFORE Spring sets up the data source or Liquibase
      if (!started) {
        environment.start();
        started = true;
      }
    }
  }
}
