package gov.cdc.nbs.report.pipeline.integration.unit;

import gov.cdc.nbs.report.pipeline.integration.support.config.DataSourceConfig;
import java.io.File;
import java.time.Duration;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

@ActiveProfiles("test")
@Tag("Unit")
@DataJpaTest
@Import(DataSourceConfig.class)
@AutoConfigureTestDatabase(replace = Replace.NONE)
public abstract class UnitTest {
  private static boolean started = false;

  @SuppressWarnings("resource")
  private static final ComposeContainer environment =
      new ComposeContainer(
              DockerImageName.parse("docker:25.0.5"), new File("../docker-compose.yaml"))
          .withServices("nbs-mssql", "liquibase")
          .waitingFor(
              "liquibase",
              Wait.forLogMessage("Migrations complete.*", 1)
                  .withStartupTimeout(Duration.ofMinutes(5)))
          // Set the maximum startup timeout all the waits set are bounded to
          .withStartupTimeout(Duration.ofMinutes(5));

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
