package gov.cdc.nbs.report.pipeline.connector;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class JdbcUrlParserTest {

  @Test
  void parses_host_and_port_from_sqlserver_url() {
    String url = "jdbc:sqlserver://nbs-mssql:1433;databaseName=RDB_MODERN;encrypt=true;";
    assertEquals("nbs-mssql", JdbcUrlParser.host(url));
    assertEquals("1433", JdbcUrlParser.port(url));
  }

  @Test
  void parses_host_and_port_from_postgresql_style_url() {
    String url = "jdbc:postgresql://db.internal:5432/app";
    assertEquals("db.internal", JdbcUrlParser.host(url));
    assertEquals("5432", JdbcUrlParser.port(url));
  }

  @Test
  void throws_when_url_is_null() {
    assertThrows(IllegalArgumentException.class, () -> JdbcUrlParser.host(null));
  }

  @Test
  void throws_when_url_has_no_host_port() {
    assertThrows(
        IllegalArgumentException.class, () -> JdbcUrlParser.host("jdbc:sqlserver:no-host-here"));
  }
}
