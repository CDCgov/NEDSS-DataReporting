package gov.cdc.nbs.report.pipeline.connector;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class JdbcUrlParser {

  private static final Pattern HOST_PORT =
      Pattern.compile("jdbc:[^:]+://(?<host>[^:;/]+):(?<port>\\d+)");

  private JdbcUrlParser() {}

  public static String host(String jdbcUrl) {
    return match(jdbcUrl).group("host");
  }

  public static String port(String jdbcUrl) {
    return match(jdbcUrl).group("port");
  }

  private static Matcher match(String jdbcUrl) {
    if (jdbcUrl == null) {
      throw new IllegalArgumentException("JDBC URL must not be null");
    }
    Matcher matcher = HOST_PORT.matcher(jdbcUrl);
    if (!matcher.find()) {
      throw new IllegalArgumentException("Could not parse host/port from JDBC URL: " + jdbcUrl);
    }
    return matcher;
  }
}
