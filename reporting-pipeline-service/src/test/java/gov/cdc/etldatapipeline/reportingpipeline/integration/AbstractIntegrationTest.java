package gov.cdc.etldatapipeline.reportingpipeline.integration;

import java.io.File;
import java.time.Duration;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.containers.wait.strategy.Wait;

@ActiveProfiles("test")
public abstract class AbstractIntegrationTest {

  private static final Logger logger = LoggerFactory.getLogger(AbstractIntegrationTest.class);
  private static final Slf4jLogConsumer consumer = new Slf4jLogConsumer(logger);

  @SuppressWarnings("resource")
  protected static final ComposeContainer environment =
      new ComposeContainer(new File("../docker-compose.yaml"))
          .withRemoveVolumes(true) // ensures volumes are purged at tearDown
          .withServices("nbs-mssql", "liquibase", "kafka", "reporting-pipeline-service")
          .waitingFor("nbs-mssql", Wait.forHealthcheck())
          .waitingFor("kafka", Wait.forHealthcheck())
          .waitingFor("reporting-pipeline-service", Wait.forHealthcheck())
          .withLogConsumer("nbs-mssql", consumer)
          .withLogConsumer("liquibase", consumer)
          .withLogConsumer("kafka", consumer)
          .withLogConsumer("reporting-pipeline-service", consumer)
          .withStartupTimeout(Duration.ofMinutes(5));

  @BeforeAll
  static void setUp() {
    environment.start();
  }

  @AfterAll
  static void tearDown() {
    environment.stop();
  }
}
