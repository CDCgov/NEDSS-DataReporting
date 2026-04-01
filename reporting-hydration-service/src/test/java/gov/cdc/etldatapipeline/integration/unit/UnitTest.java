package gov.cdc.etldatapipeline.integration.unit;

import java.io.File;
import java.time.Duration;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

@ActiveProfiles("test")
public abstract class UnitTest {

  @SuppressWarnings("resource")
  private static final ComposeContainer environment =
      new ComposeContainer(
              DockerImageName.parse("docker:25.0.5"), new File("../docker-compose.yaml"))
          .withServices("nbs-mssql", "liquibase")
          .waitingFor("liquibase", Wait.forLogMessage("Migrations complete.*", 1))
          // Set the maximum startup timeout all the waits set are bounded to
          .withStartupTimeout(Duration.ofMinutes(5));

  @BeforeAll
  static void setUp() {
    // Start up necessary containers
    environment.start();
  }

  @AfterAll
  static void tearDown() {
    // Stop all containers
    environment.stop();
  }
}
