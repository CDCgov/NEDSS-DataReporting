package gov.cdc.nbs.report.pipeline.connector;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.io.DefaultResourceLoader;
import org.springframework.mock.env.MockEnvironment;

class DebeziumConfigTest {

  private static final String DATABASE = "dbo.";

  @Test
  void run_is_noop_when_disabled() throws Exception {
    new DebeziumConfig(
            new ConnectorProperties(),
            new ObjectMapper(),
            new DefaultResourceLoader(),
            new StandardEnvironment())
        .run(null);
  }

  @Test
  void connectorDefinitionsIncludeOnlyColumnsRequiredByConsumers() throws Exception {
    Set<String> mainColumns =
        Set.of(
            DATABASE + "Person.person_uid",
            DATABASE + "Person.cd",
            DATABASE + "Organization.organization_uid",
            DATABASE + "Observation.observation_uid",
            DATABASE + "Public_health_case.public_health_case_uid",
            DATABASE + "Treatment.treatment_uid",
            DATABASE + "state_defined_field_data.ldf_uid",
            DATABASE + "state_defined_field_data.business_object_uid",
            DATABASE + "state_defined_field_data.business_object_nm",
            DATABASE + "Notification.notification_uid",
            DATABASE + "Interview.interview_uid",
            DATABASE + "Place.place_uid",
            DATABASE + "CT_contact.ct_contact_uid",
            DATABASE + "Auth_user.auth_user_uid",
            DATABASE + "Intervention.intervention_uid");
    Set<String> actRelationshipColumns =
        Set.of(
            DATABASE + "Act_relationship.source_act_uid",
            DATABASE + "Act_relationship.target_act_uid",
            DATABASE + "Act_relationship.type_cd",
            DATABASE + "Act_relationship.target_class_cd");

    assertEquals(
        mainColumns,
        includedColumns(
            "connectors/debezium/odse_main_connector.json",
            candidates(mainColumns, DATABASE + "Person.first_nm")));
    assertEquals(
        actRelationshipColumns,
        includedColumns(
            "connectors/debezium/odse_schema_only_connector.json",
            candidates(actRelationshipColumns, DATABASE + "Act_relationship.source_class_cd")));
  }

  @Test
  void mainConnectorSnapshotModeFollowsSeedingFeatureFlag() throws Exception {
    assertEquals("initial", resolvedMainSnapshotMode(connectorEnvironment()));
    assertEquals(
        "schema_only",
        resolvedMainSnapshotMode(
            connectorEnvironment().withProperty("featureFlag.seeding-enable", "false")));
  }

  @Test
  void mainConnectorCompressesProducerBatchesWithZstandard() throws Exception {
    JsonNode config = connectorConfig("connectors/debezium/odse_main_connector.json");

    assertEquals("zstd", config.path("producer.override.compression.type").asText());
    assertEquals("20", config.path("producer.override.linger.ms").asText());
    assertEquals("131072", config.path("producer.override.batch.size").asText());
  }

  @Test
  void connectorDefinitionsOmitValueSchemaAndPreservePayloadEnvelope() throws Exception {
    Set<String> resources =
        Set.of(
            "connectors/debezium/odse_main_connector.json",
            "connectors/debezium/odse_schema_only_connector.json");
    Map<String, String> expected =
        Map.of(
            "transforms", "dropPrefix, convertTimezone, hoistPayload",
            "transforms.hoistPayload.type", "org.apache.kafka.connect.transforms.HoistField$Value",
            "transforms.hoistPayload.field", "payload",
            "value.converter.schemas.enable", "false");

    for (String resource : resources) {
      JsonNode config = connectorConfig(resource);
      Map<String, String> actual =
          expected.keySet().stream()
              .collect(Collectors.toMap(key -> key, key -> config.path(key).asText()));
      assertEquals(expected, actual, resource);
    }
  }

  private Set<String> includedColumns(String resourcePath, Set<String> candidates)
      throws Exception {
    JsonNode config = connectorConfig(resourcePath);
    Pattern[] patterns =
        Arrays.stream(config.path("column.include.list").asText().split(","))
            .map(Pattern::compile)
            .toArray(Pattern[]::new);
    return candidates.stream()
        .filter(
            column ->
                Arrays.stream(patterns).anyMatch(pattern -> pattern.matcher(column).matches()))
        .collect(Collectors.toUnmodifiableSet());
  }

  private Set<String> candidates(Set<String> included, String excluded) {
    return Stream.concat(included.stream(), Stream.of(excluded))
        .collect(Collectors.toUnmodifiableSet());
  }

  private String resolvedMainSnapshotMode(MockEnvironment environment) throws Exception {
    DefaultResourceLoader resourceLoader = new DefaultResourceLoader();
    ObjectMapper objectMapper = new ObjectMapper();
    try (InputStream input =
        resourceLoader
            .getResource("classpath:connectors/debezium/odse_main_connector.json")
            .getInputStream()) {
      String definition = new String(input.readAllBytes(), StandardCharsets.UTF_8);
      String resolved =
          new DebeziumConfig(new ConnectorProperties(), objectMapper, resourceLoader, environment)
              .resolvePlaceholders(definition);
      return objectMapper.readTree(resolved).path("config").path("snapshot.mode").asText();
    }
  }

  private MockEnvironment connectorEnvironment() {
    return new MockEnvironment()
        .withProperty("connector.database.host", "database")
        .withProperty("connector.database.port", "1433")
        .withProperty("connector.database.username", "user")
        .withProperty("connector.database.password", "password")
        .withProperty("connector.kafka.bootstrap-servers", "kafka:9092");
  }

  private JsonNode connectorConfig(String resourcePath) throws Exception {
    DefaultResourceLoader resourceLoader = new DefaultResourceLoader();
    try (InputStream input =
        resourceLoader.getResource("classpath:" + resourcePath).getInputStream()) {
      return new ObjectMapper().readTree(input).path("config");
    }
  }
}
