package gov.cdc.nbs.report.pipeline.integration.functional;

import java.io.File;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
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

  private static final File base = new File("../docker-compose.yaml");

  private static ComposeContainer environment;

  @Autowired
  @Qualifier("customComposeFile")
  private static File customComposeFile;

  @SuppressWarnings("resource")
  static void initializeEnvironment() {
    DockerImageName dockerImage = DockerImageName.parse("docker:25.0.5");
    List<File> composeFiles = new ArrayList<>(Arrays.asList(base));
    if (customComposeFile != null) {
      logger.info(
          "Using custom compose override. Base: {}, Custom: {}",
          base.getPath(),
          customComposeFile.getPath());
      composeFiles.add(customComposeFile);
    }
    environment =
        new ComposeContainer(dockerImage, composeFiles)
            // List specific services to prevent launching wildfly container
            .withServices("nbs-mssql", "liquibase", "kafka", "debezium", "kafka-connect")
            .waitingFor("liquibase", Wait.forLogMessage(".*Successfully applied.*\\n", 1))
            .waitingFor("debezium", Wait.forHealthcheck())
            .waitingFor("kafka-connect", Wait.forHealthcheck())
            // Pull logs from the containers for better debugging
            .withLogConsumer("nbs-mssql", consumer)
            .withLogConsumer("kafka", consumer)
            .withLogConsumer("debezium", consumer)
            .withLogConsumer("kafka-connect", consumer)
            // Set the maximum startup timeout all the waits set are bounded to
            .withStartupTimeout(Duration.ofMinutes(10));
  }

  @BeforeAll
  static void setUp() {
    // Start up necessary containers if they are not already running.
    // ComposeContainer does not allow container reuse natively
    if (!started) {
      if (environment == null) {
        initializeEnvironment();
      }
      environment.start();
      started = true;
    }
  }

  @AfterAll
  static void tearDown() {
    if (started) {
      if (environment == null) {
        initializeEnvironment();
      }
      environment.stop();
      started = false;
    }
  }
}
