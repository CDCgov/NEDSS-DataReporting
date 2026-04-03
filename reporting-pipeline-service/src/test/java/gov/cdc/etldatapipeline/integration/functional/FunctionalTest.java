package gov.cdc.etldatapipeline.integration.functional;

import java.io.File;
import java.time.Duration;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest
@ActiveProfiles("test")
@Tag("Functional")
public abstract class FunctionalTest {

  private static final Logger logger = LoggerFactory.getLogger(FunctionalTest.class);
  private static final Slf4jLogConsumer consumer = new Slf4jLogConsumer(logger);
  private static boolean started = false;

  @SuppressWarnings("resource")
  private static final ComposeContainer environment =
      new ComposeContainer(
              DockerImageName.parse("docker:25.0.5"), new File("../docker-compose.yaml"))
          // List specific services to prevent launching wildfly container
          .withServices("nbs-mssql", "liquibase", "kafka", "debezium", "kafka-connect")
          .waitingFor("debezium", Wait.forHealthcheck())
          .waitingFor("kafka-connect", Wait.forHealthcheck())
          // Pull logs from the containers for better debugging
          .withLogConsumer("nbs-mssql", consumer)
          .withLogConsumer("liquibase", consumer)
          .withLogConsumer("kafka", consumer)
          .withLogConsumer("debezium", consumer)
          .withLogConsumer("kafka-connect", consumer)
          // Set the maximum startup timeout all the waits set are bounded to
          .withStartupTimeout(Duration.ofMinutes(10));

  @BeforeAll
  static void setUp() {
    // Start up necessary containers if they are not already running.
    // ComposeContainer does not allow container reuse natively
    if (!started) {
      environment.start();
      started = true;
    }
  }
}
