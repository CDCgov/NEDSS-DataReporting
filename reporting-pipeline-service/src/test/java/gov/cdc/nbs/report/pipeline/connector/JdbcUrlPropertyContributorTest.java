package gov.cdc.nbs.report.pipeline.connector;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.StandardEnvironment;

class JdbcUrlPropertyContributorTest {

  @Test
  void adds_host_and_port_property_source_when_url_is_present() {
    StandardEnvironment env = new StandardEnvironment();
    env.getPropertySources()
        .addFirst(
            new MapPropertySource(
                "test",
                Map.of(
                    JdbcUrlPropertyContributor.URL_KEY,
                    "jdbc:sqlserver://nbs-mssql:1433;databaseName=RDB_MODERN")));

    new JdbcUrlPropertyContributor(env);

    assertEquals("nbs-mssql", env.getProperty(JdbcUrlPropertyContributor.HOST_KEY));
    assertEquals("1433", env.getProperty(JdbcUrlPropertyContributor.PORT_KEY));
  }

  @Test
  void does_nothing_when_url_is_absent() {
    StandardEnvironment env = new StandardEnvironment();

    new JdbcUrlPropertyContributor(env);

    assertNull(env.getProperty(JdbcUrlPropertyContributor.HOST_KEY));
    assertNull(env.getProperty(JdbcUrlPropertyContributor.PORT_KEY));
  }
}
