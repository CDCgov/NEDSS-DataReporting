package gov.cdc.nbs.report.pipeline.connector;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.web.client.RestTemplate;

public class ConnectorClient {

  private static final Logger log = LoggerFactory.getLogger(ConnectorClient.class);

  private final String baseUrl;
  private final int retryAttempts;
  private final long retryDelayMs;
  private final RestTemplate restTemplate;
  private final ObjectMapper objectMapper;
  private final ResourceLoader resourceLoader;

  public ConnectorClient(
      String baseUrl,
      int retryAttempts,
      long retryDelayMs,
      RestTemplate restTemplate,
      ObjectMapper objectMapper,
      ResourceLoader resourceLoader) {
    this.baseUrl = baseUrl;
    this.retryAttempts = retryAttempts;
    this.retryDelayMs = retryDelayMs;
    this.restTemplate = restTemplate;
    this.objectMapper = objectMapper;
    this.resourceLoader = resourceLoader;
  }

  public void waitForReady() {
    for (int i = 1; i <= retryAttempts; i++) {
      try {
        restTemplate.getForObject(baseUrl + "/connectors", String.class);
        log.info("Connect REST API at {} is ready", baseUrl);
        return;
      } catch (Exception e) {
        log.info(
            "Connect REST API at {} not ready (attempt {}/{}), retrying in {}ms...",
            baseUrl,
            i,
            retryAttempts,
            retryDelayMs);
        try {
          Thread.sleep(retryDelayMs);
        } catch (InterruptedException ex) {
          Thread.currentThread().interrupt();
          throw new IllegalStateException("Interrupted while waiting for Connect REST API", ex);
        }
      }
    }
    throw new IllegalStateException(
        "Connect REST API at "
            + baseUrl
            + " did not become ready after "
            + retryAttempts
            + " attempts");
  }

  @SuppressWarnings("unchecked")
  public void registerIfMissing(String resourcePath) throws java.io.IOException {
    Resource resource = resourceLoader.getResource(resourcePath);
    Map<String, Object> connectorDef = objectMapper.readValue(resource.getInputStream(), Map.class);

    String name = (String) connectorDef.get("name");
    Map<String, Object> config = (Map<String, Object>) connectorDef.get("config");

    String existing = restTemplate.getForObject(baseUrl + "/connectors", String.class);
    if (existing != null && existing.contains("\"" + name + "\"")) {
      log.info("Connector '{}' already registered at {}, skipping", name, baseUrl);
      return;
    }

    restTemplate.put(baseUrl + "/connectors/" + name + "/config", config);
    log.info("Registered connector '{}' at {}", name, baseUrl);
  }
}
