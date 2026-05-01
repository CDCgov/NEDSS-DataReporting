package gov.cdc.nbs.report.pipeline.integration.unit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import gov.cdc.nbs.report.pipeline.integration.support.Await;
import gov.cdc.nbs.report.pipeline.integration.support.QueryRunner;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.json.JSONException;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.skyscreamer.jsonassert.JSONAssert;
import org.skyscreamer.jsonassert.JSONCompareMode;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.simple.JdbcClient;

class DataDrivenUnitTests extends UnitTest {

  private final JdbcClient client;
  private final ObjectMapper mapper =
      new ObjectMapper()
          .enable(SerializationFeature.INDENT_OUTPUT)
          .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
          .setDateFormat(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss"));

  DataDrivenUnitTests(@Qualifier("adminClient") JdbcClient client) {
    this.client = client;
  }

  /**
   * Provides each of the folders present in the /resources/testData/unit/ directory to the
   * testRunner one at a time.
   */
  static Stream<Path> unitTestDirectoryProvider() throws IOException {
    Path root = Paths.get("src/test/resources/testData/unit");
    return Files.list(root).filter(Files::isDirectory); // Filter out files
  }

  /**
   * For each provided test directory, execute the <strong>setup.sql</strong> followed by the
   * <strong>query.sql</strong>. The returned value from the query is then asserted to be equal to
   * the data in the <strong>expected.json</strong> file. </br> The <strong>query.sql</strong> is
   * polled until data is returned using the {@link Await#waitFor} function so queries should be
   * scoped to only return data once a comparison is ready to be made.
   *
   * <p>Required folder structure
   *
   * <pre>
   * resources/testdata/unit/
   *  └── sampleTest/
   *      ├── setup.sql
   *      ├── query.sql
   *      └── expected.json
   * </pre>
   *
   * @param testDirectory
   * @throws IOException If step folder is missing a file, an exception will be thrown.
   * @throws JSONException
   */
  @ParameterizedTest
  @MethodSource("unitTestDirectoryProvider")
  void testRunner(Path testDirectory) throws IOException, JSONException {
    // Parse test data
    String setup = Files.readString(testDirectory.resolve("setup.sql"));
    String query = Files.readString(testDirectory.resolve("query.sql"));
    String expected = Files.readString(testDirectory.resolve("expected.json"));

    // Execute setup.sql
    try {
        client.sql(setup).update();
    } catch (Exception e) {
        System.err.println("================= SETUP ERROR =================");
        System.err.println("Failed to execute setup.sql for " + testDirectory.getFileName());
        e.printStackTrace();
        System.err.println("===============================================");
        throw e;
    }

    // Execute query.sql statements until data is returned
    Map<String, List<Map<String, Object>>> results = QueryRunner.queryForMap(query, client);

    // Validate data returned matches expected.json
    String actual = mapper.writeValueAsString(results);
    JSONAssert.assertEquals(expected, actual, JSONCompareMode.LENIENT);
  }
}
