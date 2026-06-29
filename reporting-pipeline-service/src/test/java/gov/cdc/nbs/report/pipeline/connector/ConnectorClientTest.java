package gov.cdc.nbs.report.pipeline.connector;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.DefaultResourceLoader;
import org.springframework.core.io.ResourceLoader;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.ExpectedCount;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

class ConnectorClientTest {

  private static final String BASE_URL = "http://connect:8083";

  private RestTemplate restTemplate;
  private MockRestServiceServer server;
  private ResourceLoader resourceLoader;
  private ObjectMapper objectMapper;

  @BeforeEach
  void setUp() {
    restTemplate = new RestTemplate();
    server = MockRestServiceServer.createServer(restTemplate);
    resourceLoader = new DefaultResourceLoader();
    objectMapper = new ObjectMapper();
  }

  @Test
  void waitForReady_returns_when_endpoint_responds() {
    server
        .expect(requestTo(BASE_URL + "/connectors"))
        .andExpect(method(HttpMethod.GET))
        .andRespond(withSuccess("[]", MediaType.APPLICATION_JSON));

    newClient(BASE_URL, 3).waitForReady();

    server.verify();
  }

  @Test
  void waitForReady_retries_then_throws_when_endpoint_never_ready() {
    server
        .expect(ExpectedCount.times(2), requestTo(BASE_URL + "/connectors"))
        .andExpect(method(HttpMethod.GET))
        .andRespond(withServerError());

    assertThrows(IllegalStateException.class, newClient(BASE_URL, 2)::waitForReady);
    server.verify();
  }

  @Test
  void register_resolves_placeholders_before_putting() throws Exception {
    String resourcePath = "classpath:connectors/templated-connector.json";

    server
        .expect(requestTo(BASE_URL + "/connectors/templated-connector/config"))
        .andExpect(method(HttpMethod.PUT))
        .andExpect(jsonPath("$['connection.url']").value("jdbc:sqlserver://resolved-host:1433"))
        .andRespond(withSuccess());

    new ConnectorClient(
            BASE_URL,
            1,
            1,
            restTemplate,
            objectMapper,
            resourceLoader,
            raw -> raw.replace("${connector.database.url}", "jdbc:sqlserver://resolved-host:1433"))
        .register(resourcePath);

    server.verify();
  }

  @Test
  void register_puts_config_without_checking_existing() throws Exception {
    String resourcePath = "classpath:connectors/test-connector.json";

    // Connect treats PUT /config as an idempotent upsert, so the client always PUTs and never
    // performs an existence check (GET /connectors) first. MockRestServiceServer is strict, so an
    // unexpected GET here would fail the test.
    server
        .expect(requestTo(BASE_URL + "/connectors/test-connector/config"))
        .andExpect(method(HttpMethod.PUT))
        .andRespond(withSuccess());

    newClient(BASE_URL, 1).register(resourcePath);

    server.verify();
  }

  private ConnectorClient newClient(String url, int retries) {
    return new ConnectorClient(
        url, retries, 1, restTemplate, objectMapper, resourceLoader, raw -> raw);
  }
}
