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
import org.testcontainers.utility.DockerImageName;

@ActiveProfiles("test")
@Tag("Unit")
@DataJpaTest
@Import(DataSourceConfig.class)
@AutoConfigureTestDatabase(replace = Replace.NONE)
public abstract class UnitTest {
  private static boolean started = false;
  private static final File base = new File("../docker-compose.yaml");
  private static final File override = new File("../docker-compose.test.yaml");

  @SuppressWarnings("resource")
  private static final ComposeContainer environment =
      new ComposeContainer(DockerImageName.parse("docker:25.0.5"), base, override)
          .withServices("nbs-mssql")
          .withStartupTimeout(Duration.ofMinutes(5))
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
