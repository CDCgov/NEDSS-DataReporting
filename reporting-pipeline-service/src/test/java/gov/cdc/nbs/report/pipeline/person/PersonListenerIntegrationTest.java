package gov.cdc.nbs.report.pipeline.person;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;

import gov.cdc.nbs.report.pipeline.person.config.KafkaConsumerConfig;
import gov.cdc.nbs.report.pipeline.person.config.KafkaProducerConfig;
import gov.cdc.nbs.report.pipeline.person.service.PersonService;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.listener.BatchListenerFailedException;
import org.springframework.kafka.test.EmbeddedKafkaBroker;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

/**
 * Verifies that failures from the person batch listeners reach {@code personBatchErrorHandler}:
 * failed records are retried and then published to the dead-letter topic, and records after the
 * failed index are redelivered.
 *
 * <p>These tests fail if the listeners return a {@code CompletableFuture}, because Spring Kafka
 * acknowledges a failed async batch without invoking the container error handler.
 */
@SpringJUnitConfig(classes = PersonListenerIntegrationTest.TestConfiguration.class)
@DirtiesContext
@EmbeddedKafka(
    partitions = 1,
    topics = {
      PersonListenerIntegrationTest.PERSON_TOPIC,
      PersonListenerIntegrationTest.PERSON_DLT,
      PersonListenerIntegrationTest.USER_TOPIC,
      PersonListenerIntegrationTest.USER_DLT
    })
@TestPropertySource(
    properties = {
      "spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
      "spring.kafka.group-id=person-listener-it",
      "spring.kafka.consumer.maxPollIntervalMs=30000",
      "spring.kafka.consumer.maxPollRecs=500",
      "spring.kafka.consumer.auto-offset-reset=earliest",
      "spring.kafka.consumer.max-retry=1",
      "spring.kafka.dlq.dlq-suffix=_dlt",
      "spring.kafka.topics.nbs.person=" + PersonListenerIntegrationTest.PERSON_TOPIC,
      "spring.kafka.topics.nbs.auth-user=" + PersonListenerIntegrationTest.USER_TOPIC,
      "featureFlag.thread-pool-size=1"
    })
class PersonListenerIntegrationTest {

  static final String PERSON_TOPIC = "person-listener-it";
  static final String PERSON_DLT = PERSON_TOPIC + "_dlt";
  static final String USER_TOPIC = "auth-user-listener-it";
  static final String USER_DLT = USER_TOPIC + "_dlt";

  private static final String PERSON_BAD = "person-bad";
  private static final String USER_BAD = "user-bad";
  private static final Duration TIMEOUT = Duration.ofSeconds(30);

  /** Every batch handed to the mocked service, in call order. */
  private static final List<List<String>> PERSON_BATCHES = new CopyOnWriteArrayList<>();

  private static final PersonService PERSON_SERVICE = mock(PersonService.class);

  static {
    // Person batches: fail the record at the index of PERSON_BAD, like PersonService does.
    doAnswer(
            invocation -> {
              List<String> messages = new ArrayList<>(invocation.getArgument(0));
              PERSON_BATCHES.add(messages);
              int failedIndex = messages.indexOf(PERSON_BAD);
              if (failedIndex >= 0) {
                throw new BatchListenerFailedException(
                    "Forced person failure", new IllegalStateException("boom"), failedIndex);
              }
              return null;
            })
        .when(PERSON_SERVICE)
        .processPersonMessages(anyList());

    // Auth-user batches: throw a plain exception, like PersonService.processUser does.
    doAnswer(
            invocation -> {
              List<String> messages = invocation.getArgument(0);
              if (messages.contains(USER_BAD)) {
                throw new IllegalStateException("Forced auth-user failure");
              }
              return null;
            })
        .when(PERSON_SERVICE)
        .processUser(anyList());
  }

  @Autowired private EmbeddedKafkaBroker broker;

  @Autowired
  @Qualifier("personKafkaTemplate")
  private KafkaTemplate<String, String> kafkaTemplate;

  @Test
  void personBatchFailure_isRetriedThenDeadLettered_andLaterRecordsAreRedelivered()
      throws Exception {
    kafkaTemplate.send(PERSON_TOPIC, "1", "person-good-1").get();
    kafkaTemplate.send(PERSON_TOPIC, "2", PERSON_BAD).get();
    kafkaTemplate.send(PERSON_TOPIC, "3", "person-good-2").get();

    try (Consumer<String, String> dltConsumer = dltConsumer(PERSON_DLT)) {
      ConsumerRecord<String, String> dead =
          KafkaTestUtils.getSingleRecord(dltConsumer, PERSON_DLT, TIMEOUT);
      assertThat(dead.value()).isEqualTo(PERSON_BAD);
    }

    // The failed record was delivered more than once (initial attempt + retry).
    assertThat(PERSON_BATCHES.stream().filter(batch -> batch.contains(PERSON_BAD)).count())
        .isGreaterThan(1);

    // The record after the failed index is redelivered without the failed record.
    await()
        .atMost(TIMEOUT)
        .untilAsserted(
            () ->
                assertThat(PERSON_BATCHES)
                    .anySatisfy(
                        batch ->
                            assertThat(batch)
                                .contains("person-good-2")
                                .doesNotContain(PERSON_BAD)));
  }

  @Test
  void authUserBatchFailure_isDeadLettered() throws Exception {
    kafkaTemplate.send(USER_TOPIC, "1", USER_BAD).get();

    try (Consumer<String, String> dltConsumer = dltConsumer(USER_DLT)) {
      ConsumerRecord<String, String> dead =
          KafkaTestUtils.getSingleRecord(dltConsumer, USER_DLT, TIMEOUT);
      assertThat(dead.value()).isEqualTo(USER_BAD);
    }
  }

  private Consumer<String, String> dltConsumer(String topic) {
    Map<String, Object> props = KafkaTestUtils.consumerProps(topic + "-reader", "false", broker);
    props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
    props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    Consumer<String, String> consumer =
        new DefaultKafkaConsumerFactory<String, String>(props).createConsumer();
    broker.consumeFromAnEmbeddedTopic(consumer, topic);
    return consumer;
  }

  @Configuration
  @Import({KafkaConsumerConfig.class, KafkaProducerConfig.class})
  static class TestConfiguration {

    @Bean
    PersonListener personListener() {
      return new PersonListener(PERSON_SERVICE);
    }
  }
}
