package gov.cdc.nbs.report.pipeline.integration.functional;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import gov.cdc.nbs.report.pipeline.integration.support.Await;
import gov.cdc.nbs.report.pipeline.integration.support.DirectoryProvider;
import gov.cdc.nbs.report.pipeline.integration.support.QueryRunner;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Stream;
import org.json.JSONException;
import org.junit.jupiter.api.parallel.Execution;
import org.junit.jupiter.api.parallel.ExecutionMode;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.skyscreamer.jsonassert.JSONAssert;
import org.skyscreamer.jsonassert.JSONCompareMode;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.simple.JdbcClient;

class DataDrivenFunctionalTests extends FunctionalTest {

  /**
   * Specific tests can be executed by manually adding the test name to the list below or by
   * specifying the "tests" parameter.
   *
   * <p>If empty, all functional test directories are executed.
   *
   * <p>Command line example:
   *
   * <pre>
   * ./gradlew clean reporting-pipeline-service:test-functional -Dtests=elrEColi,interview
   * </pre>
   *
   * <p>Direct java class example:
   *
   * <ul>
   *   <li>List.of("hivNotificationActualReferral")
   *   <li>List.of("interview", "elrEColi")
   * </ul>
   */
  private static List<String> selectedTestNames = List.of();

  private final JdbcClient client;

  private final ObjectMapper mapper =
      new ObjectMapper()
          .enable(SerializationFeature.INDENT_OUTPUT)
          .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
          .setDateFormat(new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS"));

  DataDrivenFunctionalTests(@Qualifier("adminClient") JdbcClient client) {
    this.client = client;
  }

  /**
   * Provides each of the folders present in the /resources/testData/functional/ directory to the
   * testRunner one at a time.
   */
  static Stream<Path> functionalTestDirectoryProvider() throws IOException {
    String testsArg = System.getProperty("tests");

    if (testsArg != null) {
      selectedTestNames = new ArrayList<>(selectedTestNames);
      Collections.addAll(selectedTestNames, testsArg.split(","));
    }

    return DirectoryProvider.stream("src/test/resources/testData/functional", selectedTestNames);
  }

  /**
   * Loops through each step in the provided testDirectory. For each step, the
   * <strong>setup.sql</strong> is executed. Then each query in the <strong>query.sql</strong> is
   * executed and asserted to match the data in the <strong>expected.json</strong> file.
   *
   * <p>The queries in the <strong>query.sql</strong> are polled until data is returned and matches
   * the expecectation using the {@link Await#waitForMatch} function.
   *
   * <p>Required folder structure
   *
   * <pre>
   * resources/testdata/functional/
   *  └── sampleTest/
   *      ├── 010-step-one/
   *      │       ├── setup.sql
   *      │       ├── query.sql
   *      │       └── expected.json
   *      └── 020-step-two/
   *              ├── setup.sql
   *              ├── query.sql
   *              └── expected.json
   * </pre>
   *
   * @param testDirectory
   * @throws IOException If step folder is missing a file, an exception will be thrown.
   * @throws JSONException
   */
  @ParameterizedTest
  @Execution(ExecutionMode.CONCURRENT)
  @MethodSource("functionalTestDirectoryProvider")
  void testRunner(Path testDirectory) throws IOException, JSONException {
    System.out.println(
        "Executing DataDrivenFunctionalTest for directory: " + testDirectory.getFileName());

    // For each step in testDirectory
    List<Path> stepList =
        new ArrayList<Path>(Files.list(testDirectory).filter(Files::isDirectory).toList());
    stepList.sort(Comparator.comparing(Path::getFileName));
    for (Path stepDirectory : stepList) {
      System.out.println(
          "Executing DataDrivenFunctionalTest step: "
              + testDirectory.getFileName()
              + "/"
              + stepDirectory.getFileName());

      // Parse test data
      String setup = Files.readString(stepDirectory.resolve("setup.sql"));
      String queries = Files.readString(stepDirectory.resolve("query.sql"));
      String expected = Files.readString(stepDirectory.resolve("expected.json"));
      JsonNode expectedNode = mapper.readTree(expected);

      // Execute setup.sql
      client.sql(setup).update();

      // For each query in query.sql, execute and validate it matches expected. Allow
      // retry to wait on processing to complete
      List<String> queryList = QueryRunner.splitStatements(queries);
      for (int i = 0; i < queryList.size(); i++) {
        String query = queryList.get(i);
        String expectedResult = expectedNode.get(String.valueOf(i)).toString();

        Optional<List<Map<String, Object>>> results;
        try {
          results = Await.waitForMatch(() -> QueryRunner.select(query, client), expectedResult);
        } catch (RuntimeException e) {
          throw new AssertionError(
              String.format(
                  "Error executing query %d in %s/%s/query.sql. SQL:%n%s",
                  i, testDirectory.getFileName(), stepDirectory.getFileName(), query.strip()),
              e);
        }

        assertThat(results)
            .withFailMessage(
                "Query %d in %s/%s did not return results within the time limit",
                i, testDirectory.getFileName(), stepDirectory.getFileName())
            .isPresent();
        String actual = mapper.writeValueAsString(results.get());
        JSONAssert.assertEquals(
            String.format(
                "Query %d in %s/%s matched expected JSON",
                i, testDirectory.getFileName(), stepDirectory.getFileName()),
            expectedResult,
            actual,
            JSONCompareMode.LENIENT);
      }
    }
  }
}
