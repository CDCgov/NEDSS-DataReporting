package gov.cdc.nbs.report.pipeline.util.kafka;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.NoSuchElementException;
import java.util.Set;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.kafka.support.KafkaHeaders;

class RetryTopicResolverTest {

  private static final String MAIN_TOPIC = "nbs_Person";
  private static final Set<String> ALLOWED_TOPICS = Set.of(MAIN_TOPIC, "nbs_Auth_user");
  private final RetryTopicResolver resolver = new RetryTopicResolver();

  @Test
  void resolvesExactMainTopicWithoutOriginalTopicHeader() {
    ConsumerRecord<String, String> record = record(MAIN_TOPIC);

    TopicResolution resolution = resolver.resolve(record, ALLOWED_TOPICS);

    assertAll(
        () -> assertEquals(MAIN_TOPIC, resolution.physicalTopic()),
        () -> assertEquals(MAIN_TOPIC, resolution.logicalTopic()),
        () -> assertFalse(resolution.retryDelivery()));
  }

  @ParameterizedTest
  @ValueSource(strings = {"nbs_Person_retry-0", "nbs_Person_retry-1"})
  void resolvesRetryTopicFromOriginalTopicHeader(String physicalTopic) {
    ConsumerRecord<String, String> record = record(physicalTopic, MAIN_TOPIC);

    TopicResolution resolution = resolver.resolve(record, ALLOWED_TOPICS);

    assertAll(
        () -> assertEquals(physicalTopic, resolution.physicalTopic()),
        () -> assertEquals(MAIN_TOPIC, resolution.logicalTopic()),
        () -> assertTrue(resolution.retryDelivery()));
  }

  @Test
  void exactMainTopicTakesPrecedenceOverConflictingOriginalTopicHeader() {
    ConsumerRecord<String, String> record = record(MAIN_TOPIC, "nbs_Auth_user");

    TopicResolution resolution = resolver.resolve(record, ALLOWED_TOPICS);

    assertAll(
        () -> assertEquals(MAIN_TOPIC, resolution.logicalTopic()),
        () -> assertFalse(resolution.retryDelivery()));
  }

  @Test
  void rejectsUnknownPhysicalTopicWithoutOriginalTopicHeader() {
    assertUnknownTopic(record("nbs_Person_retry-0"));
  }

  @ParameterizedTest
  @ValueSource(strings = {"", " ", "nbs_Organization"})
  void rejectsInvalidOrUnconfiguredOriginalTopic(String originalTopic) {
    assertUnknownTopic(record("nbs_Person_retry-0", originalTopic));
  }

  @Test
  void rejectsOriginalTopicHeaderWithNullValue() {
    ConsumerRecord<String, String> record = record("nbs_Person_retry-0");
    record.headers().add(KafkaHeaders.ORIGINAL_TOPIC, null);

    assertUnknownTopic(record);
  }

  @Test
  void rejectsMalformedUtf8OriginalTopicHeader() {
    ConsumerRecord<String, String> record = record("nbs_Person_retry-0");
    record.headers().add(KafkaHeaders.ORIGINAL_TOPIC, new byte[] {(byte) 0xC3, (byte) 0x28});

    assertUnknownTopic(record);
  }

  @Test
  void doesNotModifyTheConsumerRecord() {
    ConsumerRecord<String, String> record = record("nbs_Person_retry-1", MAIN_TOPIC);
    int headerCount = record.headers().toArray().length;

    resolver.resolve(record, ALLOWED_TOPICS);

    assertAll(
        () -> assertEquals("record-key", record.key()),
        () -> assertEquals("record-value", record.value()),
        () -> assertEquals(2, record.partition()),
        () -> assertEquals(42L, record.offset()),
        () -> assertEquals(headerCount, record.headers().toArray().length),
        () ->
            assertEquals(
                MAIN_TOPIC,
                new String(
                    record.headers().lastHeader(KafkaHeaders.ORIGINAL_TOPIC).value(),
                    StandardCharsets.UTF_8)));
  }

  @Test
  void rejectsNullRecord() {
    assertThrows(IllegalArgumentException.class, () -> resolver.resolve(null, ALLOWED_TOPICS));
  }

  @Test
  void topicResolutionRejectsNullTopics() {
    assertAll(
        () -> assertThrows(NullPointerException.class, () -> new TopicResolution(null, MAIN_TOPIC)),
        () ->
            assertThrows(NullPointerException.class, () -> new TopicResolution(MAIN_TOPIC, null)));
  }

  @Test
  void rejectsMissingAllowedTopics() {
    ConsumerRecord<String, String> record = record(MAIN_TOPIC);

    assertAll(
        () -> assertThrows(IllegalArgumentException.class, () -> resolver.resolve(record, null)),
        () ->
            assertThrows(IllegalArgumentException.class, () -> resolver.resolve(record, Set.of())));
  }

  @Test
  void rejectsInvalidAllowedTopic() {
    ConsumerRecord<String, String> record = record(MAIN_TOPIC);
    Set<String> topicsWithNull = new HashSet<>();
    topicsWithNull.add(MAIN_TOPIC);
    topicsWithNull.add(null);

    assertAll(
        () ->
            assertThrows(
                IllegalArgumentException.class, () -> resolver.resolve(record, topicsWithNull)),
        () ->
            assertThrows(
                IllegalArgumentException.class,
                () -> resolver.resolve(record, Set.of(MAIN_TOPIC, " "))));
  }

  private void assertUnknownTopic(ConsumerRecord<String, String> record) {
    NoSuchElementException exception =
        assertThrows(NoSuchElementException.class, () -> resolver.resolve(record, ALLOWED_TOPICS));

    assertEquals("Received data from an unknown topic: " + record.topic(), exception.getMessage());
  }

  private ConsumerRecord<String, String> record(String physicalTopic) {
    return new ConsumerRecord<>(physicalTopic, 2, 42L, "record-key", "record-value");
  }

  private ConsumerRecord<String, String> record(String physicalTopic, String originalTopic) {
    ConsumerRecord<String, String> record = record(physicalTopic);
    record
        .headers()
        .add(KafkaHeaders.ORIGINAL_TOPIC, originalTopic.getBytes(StandardCharsets.UTF_8));
    return record;
  }
}
