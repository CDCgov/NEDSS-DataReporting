package gov.cdc.nbs.report.pipeline.person.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.nbs.report.pipeline.integration.functional.FunctionalTest;
import gov.cdc.nbs.report.pipeline.util.TestUtils;
import java.time.Duration;
import java.util.HashSet;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;
import org.springframework.test.context.TestPropertySource;

@TestPropertySource(
    properties = {
      "spike.cdc-delay.enabled=true",
      "spike.cdc-delay.entity=person",
      "spike.cdc-delay.uid=1000014000",
      "spike.cdc-delay.operation=u",
      "spike.cdc-delay.timeout-ms=30000",
      "featureFlag.thread-pool-size=2",
      "spring.kafka.consumer.maxPollRecs=2"
    })
class PatientCdcDelaySpikeTest extends FunctionalTest {
  private static final long PATIENT_UID = 1000014000L;
  private static final String PERSON_TOPIC = "nbs_Person";
  private static final String PERSON_DLT_TOPIC = "nbs_Person_dlt";
  private static final String PERSON_LISTENER_ID = "person-service-listener";
  private static final Duration OBSERVATION_TIMEOUT = Duration.ofSeconds(30);

  private final ObjectMapper objectMapper = new ObjectMapper();

  @Autowired
  @Qualifier("adminClient")
  private JdbcClient adminClient;

  @Autowired private ConfigurableCdcProcessingDelay cdcProcessingDelay;

  @Autowired private KafkaListenerEndpointRegistry listenerRegistry;

  @Value("${spring.kafka.bootstrap-servers}")
  private String kafkaBootstrapServers;

  @Test
  void patientUpdateDelayedWhileDeleteProcesses() {
    MessageListenerContainer personListener =
        listenerRegistry.getListenerContainer(PERSON_LISTENER_ID);
    assertThat(personListener).as("person listener").isNotNull();

    try (CdcEventObserver observer = new CdcEventObserver(kafkaBootstrapServers)) {
      executeSql("testData/cdcDelaySpike/patient/baseline.sql");
      awaitPatientPresent();
      observer.awaitAssignment();

      personListener.stop();
      Awaitility.await().atMost(Duration.ofSeconds(10)).until(() -> !personListener.isRunning());

      executeSql("testData/cdcDelaySpike/patient/update.sql");
      executeSql("testData/cdcDelaySpike/patient/delete.sql");
      assertThat(observer.awaitOperations(PATIENT_UID, OBSERVATION_TIMEOUT))
          .containsExactlyInAnyOrder("u", "d");

      personListener.start();
      Awaitility.await().atMost(Duration.ofSeconds(10)).until(personListener::isRunning);

      assertThat(cdcProcessingDelay.awaitEntered(Duration.ofSeconds(10))).isTrue();

      PatientSpikeState beforeRelease = awaitDeleteOutcome();
      cdcProcessingDelay.release();
      PatientSpikeState afterRelease =
          awaitAdditionalDeadLetter(beforeRelease.personDeadLetterCount());

      System.out.printf(
          "CDC delay spike patientUid=%d beforeRelease=%s afterRelease=%s%n",
          PATIENT_UID, beforeRelease, afterRelease);

      assertThat(beforeRelease.deleteObserved()).isTrue();
    } finally {
      cdcProcessingDelay.release();
      if (!personListener.isRunning()) {
        personListener.start();
      }
    }
  }

  private void executeSql(String resource) {
    adminClient.sql(TestUtils.readFileData(resource)).update();
  }

  private void awaitPatientPresent() {
    Awaitility.await()
        .atMost(OBSERVATION_TIMEOUT)
        .untilAsserted(() -> assertThat(patientSpikeState().patientPresent()).isTrue());
  }

  private PatientSpikeState awaitDeleteOutcome() {
    AtomicReference<PatientSpikeState> observed = new AtomicReference<>();
    Awaitility.await()
        .atMost(OBSERVATION_TIMEOUT)
        .until(
            () -> {
              PatientSpikeState state = patientSpikeState();
              observed.set(state);
              return state.deleteObserved();
            });
    return observed.get();
  }

  private PatientSpikeState awaitAdditionalDeadLetter(int deadLetterCount) {
    AtomicReference<PatientSpikeState> observed = new AtomicReference<>();
    Awaitility.await()
        .atMost(OBSERVATION_TIMEOUT)
        .until(
            () -> {
              PatientSpikeState state = patientSpikeState();
              observed.set(state);
              return state.personDeadLetterCount() > deadLetterCount;
            });
    return observed.get();
  }

  private PatientSpikeState patientSpikeState() {
    return new PatientSpikeState(patientPresent(), personDeadLetterCount());
  }

  private boolean patientPresent() {
    return !adminClient
        .sql("SELECT 1 FROM [RDB_MODERN].[dbo].[nrt_patient] WHERE [patient_uid] = :patientUid")
        .param("patientUid", PATIENT_UID)
        .query()
        .listOfRows()
        .isEmpty();
  }

  private int personDeadLetterCount() {
    Map<String, Object> row =
        adminClient
            .sql(
                """
                SELECT COUNT(*) AS [dead_letter_count]
                FROM [RDB_MODERN].[dbo].[nrt_dead_letter_log]
                WHERE [origin_topic] = :originTopic
                  AND [payload] LIKE :patientUid
                """)
            .param("originTopic", PERSON_DLT_TOPIC)
            .param("patientUid", "%" + PATIENT_UID + "%")
            .query()
            .singleRow();
    return ((Number) row.get("dead_letter_count")).intValue();
  }

  private record PatientSpikeState(boolean patientPresent, int personDeadLetterCount) {
    boolean deleteObserved() {
      return !patientPresent || personDeadLetterCount > 0;
    }
  }

  private final class CdcEventObserver implements AutoCloseable {
    private final KafkaConsumer<String, String> consumer;
    private final Set<String> operations = new HashSet<>();

    CdcEventObserver(String bootstrapServers) {
      Properties properties = new Properties();
      properties.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
      properties.put(
          ConsumerConfig.GROUP_ID_CONFIG, "patient-cdc-delay-spike-" + UUID.randomUUID());
      properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");
      properties.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);
      properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
      properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
      consumer = new KafkaConsumer<>(properties);
      consumer.subscribe(Set.of(PERSON_TOPIC));
    }

    void awaitAssignment() {
      Awaitility.await()
          .atMost(Duration.ofSeconds(10))
          .until(
              () -> {
                consumer.poll(Duration.ofMillis(100));
                return !consumer.assignment().isEmpty();
              });
    }

    Set<String> awaitOperations(long patientUid, Duration timeout) {
      Awaitility.await()
          .atMost(timeout)
          .until(
              () -> {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
                for (ConsumerRecord<String, String> record : records) {
                  operationFor(record.value(), patientUid).ifPresent(operations::add);
                }
                return operations.containsAll(Set.of("u", "d"));
              });
      return Set.copyOf(operations);
    }

    @Override
    public void close() {
      consumer.close();
    }

    private java.util.Optional<String> operationFor(String value, long patientUid) {
      try {
        JsonNode payload = objectMapper.readTree(value).path("payload");
        JsonNode after = payload.path("after");
        JsonNode record = after.isMissingNode() || after.isNull() ? payload.path("before") : after;
        return record.path("person_uid").asLong() == patientUid
            ? java.util.Optional.of(payload.path("op").asText())
            : java.util.Optional.empty();
      } catch (Exception exception) {
        throw new IllegalStateException("Unable to inspect CDC event", exception);
      }
    }
  }
}
