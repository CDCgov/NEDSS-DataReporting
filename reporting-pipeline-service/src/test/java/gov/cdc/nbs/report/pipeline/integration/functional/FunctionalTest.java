package gov.cdc.nbs.report.pipeline.integration.functional;

import gov.cdc.nbs.report.pipeline.coverage.StoredProcCoverageRecorder;
import gov.cdc.nbs.report.pipeline.integration.support.config.DataSourceConfig;
import java.io.File;
import java.time.Duration;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.ContextConfiguration;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.containers.wait.strategy.Wait;

@SpringBootTest
@Tag("Functional")
@ActiveProfiles("test")
@Import(DataSourceConfig.class)
@TestInstance(Lifecycle.PER_CLASS)
@AutoConfigureTestDatabase(replace = Replace.NONE)
@ContextConfiguration(initializers = FunctionalTest.Initializer.class)
public abstract class FunctionalTest {

  private static final Logger log = LoggerFactory.getLogger(FunctionalTest.class);
  private static final Slf4jLogConsumer consumer = new Slf4jLogConsumer(log);
  private static final File base = new File("../docker-compose.yaml");

  private static boolean started = false;

  @Autowired private JdbcClient jdbcClient;

  @SuppressWarnings("resource")
  private static final ComposeContainer environment =
      new ComposeContainer(base)
          // Don't pull all the containers listed in the compose file
          .withPull(false)
          // List specific services to prevent launching wildfly container
          .withServices("nbs-mssql", "kafka", "debezium", "kafka-connect")
          .waitingFor("nbs-mssql", Wait.forHealthcheck())
          .waitingFor("debezium", Wait.forHealthcheck().withStartupTimeout(Duration.ofMinutes(5)))
          .waitingFor(
              "kafka-connect", Wait.forHealthcheck().withStartupTimeout(Duration.ofMinutes(5)))
          // Pull logs from the containers for better debugging
          .withLogConsumer("nbs-mssql", consumer)
          .withLogConsumer("kafka", consumer)
          .withLogConsumer("debezium", consumer)
          .withLogConsumer("kafka-connect", consumer)
          // Set the maximum startup timeout all the waits set are bounded to
          .withStartupTimeout(Duration.ofMinutes(10));

  @AfterAll
  void tearDown() {
    // Capture stored-proc coverage from job_flow_log while the database is still up.
    StoredProcCoverageRecorder.record(jdbcClient);
    synchronized (FunctionalTest.class) {
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
