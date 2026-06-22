package gov.cdc.nbs.report.pipeline.connector.health;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.nbs.report.pipeline.connector.ConnectorProperties;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@Component("connectors")
public class ConnectorHealthIndicator implements HealthIndicator {

  private static final String RUNNING = "RUNNING";

  private final ConnectorProperties properties;
  private final ObjectMapper objectMapper;
  private final ResourceLoader resourceLoader;
  private final RestTemplate restTemplate;

  @Autowired
  public ConnectorHealthIndicator(
      ConnectorProperties properties, ObjectMapper objectMapper, ResourceLoader resourceLoader) {
    this(properties, objectMapper, resourceLoader, new RestTemplate());
  }

  ConnectorHealthIndicator(
      ConnectorProperties properties,
      ObjectMapper objectMapper,
      ResourceLoader resourceLoader,
      RestTemplate restTemplate) {
    this.properties = properties;
    this.objectMapper = objectMapper;
    this.resourceLoader = resourceLoader;
    this.restTemplate = restTemplate;
  }

  @Override
  public Health health() {
    Map<String, Object> details = new LinkedHashMap<>();
    List<String> failures = new ArrayList<>();

    checkGroup("debezium", properties.debezium(), details, failures);
    checkGroup("kafkaConnect", properties.kafkaConnect(), details, failures);

    Health.Builder builder = failures.isEmpty() ? Health.up() : Health.down();
    builder.withDetails(details);
    if (!failures.isEmpty()) {
      builder.withDetail("failures", failures);
    }
    return builder.build();
  }

  private void checkGroup(
      String groupName,
      ConnectorProperties.Group group,
      Map<String, Object> details,
      List<String> failures) {
    if (!group.enabled()) {
      details.put(groupName, Map.of("status", "DISABLED"));
      return;
    }

    Map<String, String> connectorStatuses = new LinkedHashMap<>();
    for (String definition : group.definitions()) {
      String name = connectorNameFrom(definition);
      String status = fetchConnectorStatus(group.url(), name);
      connectorStatuses.put(name, status);
      if (!RUNNING.equals(status)) {
        failures.add(groupName + "/" + name + "=" + status);
      }
    }
    details.put(groupName, connectorStatuses);
  }

  private String connectorNameFrom(String resourcePath) {
    try {
      Resource resource = resourceLoader.getResource(resourcePath);
      JsonNode node = objectMapper.readTree(resource.getInputStream());
      return node.path("name").asText();
    } catch (Exception e) {
      return resourcePath;
    }
  }

  private String fetchConnectorStatus(String baseUrl, String connectorName) {
    try {
      String body =
          restTemplate.getForObject(
              baseUrl + "/connectors/" + connectorName + "/status", String.class);
      if (body == null) {
        return "UNKNOWN";
      }
      JsonNode node = objectMapper.readTree(body);
      return node.path("connector").path("state").asText("UNKNOWN");
    } catch (RestClientException | com.fasterxml.jackson.core.JsonProcessingException e) {
      return "UNREACHABLE";
    }
  }
}
