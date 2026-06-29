package gov.cdc.nbs.report.pipeline.connector;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.function.UnaryOperator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.util.StreamUtils;
import org.springframework.web.client.RestTemplate;

public class ConnectorClient {

  private static final Logger log = LoggerFactory.getLogger(ConnectorClient.class);

  private final String baseUrl;
  private final int retryAttempts;
  private final long retryDelayMs;
  private final RestTemplate restTemplate;
  private final ObjectMapper objectMapper;
  private final ResourceLoader resourceLoader;
  private final UnaryOperator<String> placeholderResolver;

  public ConnectorClient(
      String baseUrl,
      int retryAttempts,
      long retryDelayMs,
      RestTemplate restTemplate,
      ObjectMapper objectMapper,
      ResourceLoader resourceLoader,
      UnaryOperator<String> placeholderResolver) {
    this.baseUrl = baseUrl;
    this.retryAttempts = retryAttempts;
    this.retryDelayMs = retryDelayMs;
    this.restTemplate = restTemplate;
    this.objectMapper = objectMapper;
    this.resourceLoader = resourceLoader;
    this.placeholderResolver = placeholderResolver;
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
  public void register(String resourcePath) throws java.io.IOException {
    Resource resource = resourceLoader.getResource(resourcePath);
    String raw = StreamUtils.copyToString(resource.getInputStream(), StandardCharsets.UTF_8);
    String resolved = placeholderResolver.apply(raw);
    Map<String, Object> connectorDef = objectMapper.readValue(resolved, Map.class);

    String name = (String) connectorDef.get("name");
    Map<String, Object> config = (Map<String, Object>) connectorDef.get("config");

    // Connect compares the config to the current configuration if already registered and only
    // changes / restarts if something changed. If the config is identical, its a no-op.
    restTemplate.put(baseUrl + "/connectors/" + name + "/config", config);
    log.info("Registered connector '{}' at {}", name, baseUrl);
  }
}
