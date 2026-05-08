package gov.cdc.nbs.report.pipeline.integration.functional;

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
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest
@AutoConfigureTestDatabase(replace = Replace.NONE)
@TestInstance(Lifecycle.PER_CLASS)
@Import(DataSourceConfig.class)
@ActiveProfiles("test")
@Tag("Functional")
public abstract class FunctionalTest {

  private static final Logger log = LoggerFactory.getLogger(FunctionalTest.class);
  private static final Slf4jLogConsumer consumer = new Slf4jLogConsumer(log);
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
            // List specific services to prevent launching wildfly container
            .withServices("nbs-mssql", "liquibase", "kafka", "debezium", "kafka-connect")
            .waitingFor("nbs-mssql", Wait.forHealthcheck())
            .waitingFor("debezium", Wait.forHealthcheck())
            .waitingFor("liquibase", Wait.forLogMessage(".*Migrations complete.*\\n", 1))
            .waitingFor("kafka-connect", Wait.forHealthcheck())
            // Pull logs from the containers for better debugging
            .withLogConsumer("nbs-mssql", consumer)
            .withLogConsumer("liquibase", consumer)
            .withLogConsumer("kafka", consumer)
            .withLogConsumer("debezium", consumer)
            .withLogConsumer("kafka-connect", consumer)
            // Set the maximum startup timeout all the waits set are bounded to
            .withStartupTimeout(Duration.ofMinutes(10));
  }

  @BeforeAll
  void setUp() {
    synchronized (FunctionalTest.class) {
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
  }

  @AfterAll
  void tearDown() {
    synchronized (FunctionalTest.class) {
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
