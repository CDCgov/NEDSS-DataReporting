package gov.cdc.nbs.report.pipeline.integration.unit;

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
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import javax.sql.DataSource;
import org.json.JSONException;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.skyscreamer.jsonassert.JSONAssert;
import org.skyscreamer.jsonassert.JSONCompareMode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

class DataDrivenUnitTests extends UnitTest {

  @Autowired
  @Qualifier("adminDataSource")
  private DataSource adminDataSource;

  @Autowired
  @Qualifier("adminClient")
  private JdbcClient client;

  private final ObjectMapper mapper =
      new ObjectMapper()
          .enable(SerializationFeature.INDENT_OUTPUT)
          .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
          .setDateFormat(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss"));

  /**
   * Specific tests can be executed by manually adding the test name to the list below or by
   * specifying the "tests" parameter.
   *
   * <p>If empty, all unit tests are executed.
   *
   * <p>Command line example:
   *
   * <pre>
   * ./gradlew clean reporting-pipeline-service:test-unit -Dtests=covidCaseDatamart
   * </pre>
   *
   * <p>Direct java class example:
   *
   * <ul>
   *   <li>List.of("covidCaseDatamart")
   * </ul>
   */
  private static List<String> selectedTestNames = List.of();

  /**
   * Provides each of the folders present in the /resources/testData/unit/ directory to the
   * testRunner one at a time.
   */
  static Stream<Path> unitTestDirectoryProvider() throws IOException {
    String testsArg = System.getProperty("tests");

    if (testsArg != null) {
      selectedTestNames = new ArrayList<>(selectedTestNames);
      Collections.addAll(selectedTestNames, testsArg.split(","));
    }

    return DirectoryProvider.stream("src/test/resources/testData/unit", selectedTestNames);
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
  @Transactional(propagation = Propagation.NOT_SUPPORTED)
  void testRunner(Path testDirectory) throws IOException {
    DataSourceTransactionManager transactionManager =
        new DataSourceTransactionManager(adminDataSource);
    TransactionTemplate transactionTemplate = new TransactionTemplate(transactionManager);
    // Parse test data
    String setup = Files.readString(testDirectory.resolve("setup.sql"));
    String query = Files.readString(testDirectory.resolve("query.sql"));
    String expected = Files.readString(testDirectory.resolve("expected.json"));

    transactionTemplate.executeWithoutResult(
        status -> {
          // Always rollback at the end of the test to reset the database state
          status.setRollbackOnly();
          try {
            // Execute setup.sql
            client.sql(setup).update();
            // Execute query.sql statements until data is returned
            Map<String, List<Map<String, Object>>> results = QueryRunner.queryForMap(query, client);
            // Validate data returned matches expected.json
            String actual = mapper.writeValueAsString(results);
            JSONAssert.assertEquals(expected, actual, JSONCompareMode.LENIENT);
          } catch (Exception e) {
            throw (e instanceof RuntimeException re) ? re : new RuntimeException(e);
          }
        });
  }
}
