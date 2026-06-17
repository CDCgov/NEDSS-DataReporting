package gov.cdc.nbs.report.pipeline.connector;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.source.ConfigurationPropertySource;
import org.springframework.boot.context.properties.source.MapConfigurationPropertySource;

class ConnectorPropertiesTest {

  @Test
  void binds_nested_debezium_and_kafka_connect_groups() {
    ConfigurationPropertySource source =
        new MapConfigurationPropertySource(
            Map.of(
                "connector.debezium.enabled", "true",
                "connector.debezium.url", "http://debezium:8083",
                "connector.debezium.retry-attempts", "10",
                "connector.debezium.retry-delay-ms", "1000",
                "connector.debezium.definitions",
                    "classpath:connectors/debezium/odse_main_connector.json",
                "connector.kafka-connect.enabled", "true",
                "connector.kafka-connect.url", "http://kafka-connect:8083",
                "connector.kafka-connect.definitions",
                    "classpath:connectors/kafka-connect/mssql-connector.json"));

    ConnectorProperties properties =
        new Binder(source).bind("connector", ConnectorProperties.class).get();

    assertTrue(properties.debezium().enabled());
    assertEquals("http://debezium:8083", properties.debezium().url());
    assertEquals(10, properties.debezium().retryAttempts());
    assertEquals(1000L, properties.debezium().retryDelayMs());
    assertEquals(
        List.of("classpath:connectors/debezium/odse_main_connector.json"),
        properties.debezium().definitions());

    assertTrue(properties.kafkaConnect().enabled());
    assertEquals("http://kafka-connect:8083", properties.kafkaConnect().url());
    assertEquals(
        List.of("classpath:connectors/kafka-connect/mssql-connector.json"),
        properties.kafkaConnect().definitions());
  }

  @Test
  void defaults_disable_groups_and_use_default_retry_settings() {
    ConnectorProperties properties = new ConnectorProperties();

    assertFalse(properties.debezium().enabled());
    assertFalse(properties.kafkaConnect().enabled());
    assertEquals(20, properties.debezium().retryAttempts());
    assertEquals(5000L, properties.debezium().retryDelayMs());
    assertTrue(properties.debezium().definitions().isEmpty());
  }
}
