package gov.cdc.nbs.report.pipeline.connector.health;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.nbs.report.pipeline.connector.ConnectorProperties;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;
import org.springframework.core.io.DefaultResourceLoader;
import org.springframework.core.io.ResourceLoader;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

class ConnectorHealthIndicatorTest {

  private static final String BASE_URL = "http://debezium:8083";
  private static final String RUNNING_STATUS_BODY = "{\"connector\":{\"state\":\"RUNNING\"}}";
  private static final String FAILED_STATUS_BODY = "{\"connector\":{\"state\":\"FAILED\"}}";

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
  void up_when_all_enabled_connectors_running() {
    ConnectorProperties properties =
        new ConnectorProperties(
            new ConnectorProperties.Group(
                true, BASE_URL, 20, 5000L, List.of("classpath:connectors/test-connector.json")),
            new ConnectorProperties.Group());

    server
        .expect(requestTo(BASE_URL + "/connectors/test-connector/status"))
        .andExpect(method(HttpMethod.GET))
        .andRespond(withSuccess(RUNNING_STATUS_BODY, MediaType.APPLICATION_JSON));

    Health health = newIndicator(properties).health();

    assertEquals(Status.UP, health.getStatus());
    server.verify();
  }

  @Test
  void down_when_a_connector_is_not_running() {
    ConnectorProperties properties =
        new ConnectorProperties(
            new ConnectorProperties.Group(
                true, BASE_URL, 20, 5000L, List.of("classpath:connectors/test-connector.json")),
            new ConnectorProperties.Group());

    server
        .expect(requestTo(BASE_URL + "/connectors/test-connector/status"))
        .andExpect(method(HttpMethod.GET))
        .andRespond(withSuccess(FAILED_STATUS_BODY, MediaType.APPLICATION_JSON));

    Health health = newIndicator(properties).health();

    assertEquals(Status.DOWN, health.getStatus());
    server.verify();
  }

  @Test
  void down_when_connector_endpoint_unreachable() {
    ConnectorProperties properties =
        new ConnectorProperties(
            new ConnectorProperties.Group(),
            new ConnectorProperties.Group(
                true, BASE_URL, 20, 5000L, List.of("classpath:connectors/test-connector.json")));

    server
        .expect(requestTo(BASE_URL + "/connectors/test-connector/status"))
        .andRespond(withServerError());

    Health health = newIndicator(properties).health();

    assertEquals(Status.DOWN, health.getStatus());
    server.verify();
  }

  @Test
  void up_when_both_groups_disabled() {
    Health health = newIndicator(new ConnectorProperties()).health();

    assertEquals(Status.UP, health.getStatus());
  }

  private ConnectorHealthIndicator newIndicator(ConnectorProperties properties) {
    return new ConnectorHealthIndicator(properties, objectMapper, resourceLoader, restTemplate);
  }
}
