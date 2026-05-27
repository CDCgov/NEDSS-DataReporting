package gov.cdc.nbs.report.pipeline.integration.support;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.springframework.jdbc.core.simple.JdbcClient;

public class QueryRunner {

  private QueryRunner() {}

  /**
   * Splits the provided sql on the ';' character. Each statement is then executed by the provided
   * JdbcClient. Results of all queries are compiled into a single {@link HashMap} where the key is
   * the index of the statement (0,1,...) and the value is a {@literal List<Map<String, Object>>}
   *
   * @param sql A single or multiple SQL queries separated by ';'
   * @param client A JdbcClient for executing the provided sql
   * @return
   */
  public static Map<String, List<Map<String, Object>>> queryForMap(String sql, JdbcClient client) {
    Map<String, List<Map<String, Object>>> results = new HashMap<>();
    List<String> queries = splitStatements(sql);
    int queryIndex = 0;

    for (String query : queries) {
      Optional<List<Map<String, Object>>> result = QueryRunner.select(query, client);
      results.put(String.valueOf(queryIndex), result.get());
      queryIndex++;
    }

    return results;
  }

  public static Optional<List<Map<String, Object>>> select(String query, JdbcClient client) {
    List<Map<String, Object>> result = client.sql(query).query().listOfRows();
    if (result.isEmpty()) {
      return Optional.empty();
    } else {
      return Optional.of(result);
    }
  }

  public static List<String> splitStatements(String sql) {
    if (sql == null || sql.isBlank()) {
      return List.of();
    }

    return Stream.of(sql.split(";"))
        .map(String::trim)
        .filter(statement -> !statement.isBlank() && !statement.trim().startsWith("--"))
        .collect(Collectors.toList());
  }
}
