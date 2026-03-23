package gov.cdc.etldatapipeline.postprocessingservice.integration;

import java.io.File;
import java.time.Duration;
import java.util.Scanner;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

@ActiveProfiles("test")
abstract class IntegrationTest {

  private static final Logger logger = LoggerFactory.getLogger(IntegrationTest.class);
  private static final Slf4jLogConsumer consumer = new Slf4jLogConsumer(logger);

  @SuppressWarnings("resource")
  protected static final ComposeContainer environment =
      new ComposeContainer(
              DockerImageName.parse("docker:25.0.5"), new File("../docker-compose.yaml"))
          // List specific services to prevent launching wildfly container
          .withServices(
              "nbs-mssql", "liquibase", "kafka", "debezium", "kafka-connect", "person-service")
          .waitingFor("debezium", Wait.forHealthcheck())
          .waitingFor("kafka-connect", Wait.forHealthcheck())
          .waitingFor("person-service", Wait.forHealthcheck())
          // Pull logs from the containers for better debugging
          .withLogConsumer("nbs-mssql", consumer)
          .withLogConsumer("liquibase", consumer)
          .withLogConsumer("kafka", consumer)
          .withLogConsumer("debezium", consumer)
          .withLogConsumer("kafka-connect", consumer)
          .withLogConsumer("person-service", consumer)
          // Set the maximum startup timeout all the waits set are bounded to
          .withStartupTimeout(Duration.ofMinutes(10));

  @BeforeAll
  static void setUp() {
    logContainerStatus("BEFORE starting environment");
    // Start up necessary containers
    environment.start();
    logContainerStatus("AFTER starting environment");
  }

  @AfterAll
  static void tearDown() {
    // Stop all containers
    environment.stop();
  }

  private static void logContainerStatus(String stage) {
    logger.info("Listing all running containers ({}):", stage);
    try {
      Process process = new ProcessBuilder("docker", "ps", "-a").start();
      try (Scanner scanner = new Scanner(process.getInputStream())) {
        while (scanner.hasNextLine()) {
          logger.info("DOCKER ({}): {}", stage, scanner.nextLine());
        }
      }
      process.waitFor();
    } catch (Exception e) {
      logger.error("Failed to list containers ({}): {}", stage, e.getMessage());
    }
  }
}
