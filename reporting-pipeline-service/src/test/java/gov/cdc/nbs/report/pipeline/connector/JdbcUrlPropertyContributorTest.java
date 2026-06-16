package gov.cdc.nbs.report.pipeline.connector;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.StandardEnvironment;

class JdbcUrlPropertyContributorTest {

  @Test
  void derives_host_and_port_from_url_when_not_explicitly_set() {
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
  void explicit_host_and_port_override_derived_values() {
    StandardEnvironment env = new StandardEnvironment();
    env.getPropertySources()
        .addFirst(
            new MapPropertySource(
                "test",
                Map.of(
                    JdbcUrlPropertyContributor.URL_KEY,
                    "jdbc:sqlserver://localhost:3433;databaseName=RDB_MODERN",
                    JdbcUrlPropertyContributor.HOST_KEY,
                    "nbs-mssql",
                    JdbcUrlPropertyContributor.PORT_KEY,
                    "1433")));

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

  @Test
  void does_nothing_when_url_value_has_unresolvable_placeholder() {
    StandardEnvironment env = new StandardEnvironment();
    env.getPropertySources()
        .addFirst(
            new MapPropertySource(
                "test", Map.of(JdbcUrlPropertyContributor.URL_KEY, "${MISSING_ENV_VAR}")));

    new JdbcUrlPropertyContributor(env);

    assertNull(env.getProperty(JdbcUrlPropertyContributor.HOST_KEY));
    assertNull(env.getProperty(JdbcUrlPropertyContributor.PORT_KEY));
  }
}
