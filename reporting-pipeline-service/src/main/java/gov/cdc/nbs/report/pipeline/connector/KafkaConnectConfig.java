package gov.cdc.nbs.report.pipeline.connector;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class KafkaConnectConfig implements ApplicationRunner {

  private static final Logger log = LoggerFactory.getLogger(KafkaConnectConfig.class);

  private final ConnectorProperties.Group properties;
  private final ObjectMapper objectMapper;
  private final ResourceLoader resourceLoader;
  private final Environment environment;

  public KafkaConnectConfig(
      ConnectorProperties properties,
      ObjectMapper objectMapper,
      ResourceLoader resourceLoader,
      Environment environment) {
    this.properties = properties.getKafkaConnect();
    this.objectMapper = objectMapper;
    this.resourceLoader = resourceLoader;
    this.environment = environment;
  }

  @Override
  public void run(ApplicationArguments args) throws Exception {
    if (!properties.isEnabled()) {
      log.info("Kafka Connect connector auto-configuration is disabled");
      return;
    }

    ConnectorClient client =
        new ConnectorClient(
            properties.getUrl(),
            properties.getRetryAttempts(),
            properties.getRetryDelayMs(),
            new RestTemplate(),
            objectMapper,
            resourceLoader,
            environment::resolveRequiredPlaceholders);

    client.waitForReady();
    for (String definition : properties.getDefinitions()) {
      client.registerIfMissing(definition);
    }
  }
}
