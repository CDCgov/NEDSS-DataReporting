package gov.cdc.nbs.report.pipeline.integration.functional;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import gov.cdc.nbs.report.pipeline.integration.support.Await;
import gov.cdc.nbs.report.pipeline.integration.support.QueryRunner;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Stream;
import org.json.JSONException;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.skyscreamer.jsonassert.JSONAssert;
import org.skyscreamer.jsonassert.JSONCompareMode;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.simple.JdbcClient;

class DataDrivenFunctionalTests extends FunctionalTest {

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
    Path root = Paths.get("src/test/resources/testData/functional");
    return Files.list(root).filter(Files::isDirectory); // Filter out files
  }

  /**
   * Loops through each step in the provided testDirectory. For each step, the
   * <strong>setup.sql</strong> is executed followed by the <strong>query.sql</strong>. The returned
   * value from the query is then asserted to be equal to the data in the
   * <strong>expected.json</strong> file.
   *
   * <p>The <strong>query.sql</strong> is polled until data is returned using the {@link
   * Await#waitFor} function so queries should be scoped to only return data once a comparison is
   * ready to be made.
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
      String[] queryList = queries.trim().split(";");
      for (int i = 0; i < queryList.length; i++) {
        String query = queryList[i];
        String expectedResult = expectedNode.get(String.valueOf(i)).toString();

        Optional<List<Map<String, Object>>> results =
            Await.waitForMatch(() -> QueryRunner.select(query, client), expectedResult);

        assertThat(results).isPresent();
        String actual = mapper.writeValueAsString(results.get());
        JSONAssert.assertEquals(expectedResult, actual, JSONCompareMode.LENIENT);
      }
    }
  }
}
