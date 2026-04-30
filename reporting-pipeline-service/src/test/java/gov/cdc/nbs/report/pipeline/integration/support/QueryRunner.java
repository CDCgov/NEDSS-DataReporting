package gov.cdc.nbs.report.pipeline.integration.support;


import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.jdbc.core.simple.JdbcClient;

public class QueryRunner {

  private QueryRunner() {}

  /**
   * Splits the provided sql on the ';' character. Each statement is then executed by the provided
   * JdbcClient within an {@link Await#waitFor}. An assertion is made to ensure results are returned
   * within the retry time limit. Results of all queries are compiled into a single {@link HashMap}
   * where the key is the index of the statement (0,1,...) and the value is a {@literal
   * List<Map<String, Object>>}
   *
   * @param sql A single or multiple SQL queries separated by ';'
   * @param client A JdbcClient for executing the provided sql
   * @return
   */
  public static Map<String, List<Map<String, Object>>> queryForMap(String sql, JdbcClient client) {
    Map<String, List<Map<String, Object>>> results = new HashMap<>();
    String[] queries = sql.trim().split(";");
    int queryIndex = 0;

    for (String query : queries) {
      String trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty()) continue;

      try {
        // Log exactly what is being sent to the sandbox
        System.out.println("DEBUG: Executing Batch Query [" + queryIndex + "]: " + trimmedQuery);

        Optional<List<Map<String, Object>>> result =
            Await.waitFor(() -> QueryRunner.select(trimmedQuery, client));

        if (result.isEmpty()) {
          // This is where your failure happens.
          // We throw a detailed exception here to stop the test and show the context.
          throw new AssertionError(
              String.format(
                  "Query [%d] failed to return a result container.\n"
                      + "SQL: %s\n"
                      + "Possible causes: SP has no SELECT statement, connection lost, or timeout"
                      + " in Await.waitFor.",
                  queryIndex, trimmedQuery));
        }

        results.put(String.valueOf(queryIndex), result.get());
        System.out.println(
            "DEBUG: Query [" + queryIndex + "] returned " + result.get().size() + " rows.");

      } catch (Exception e) {
        throw new AssertionError(
            "Exception during execution of query [" + queryIndex + "]: " + trimmedQuery, e);
      }
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
}
