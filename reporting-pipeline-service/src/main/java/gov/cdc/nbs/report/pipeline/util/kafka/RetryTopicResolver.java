package gov.cdc.nbs.report.pipeline.util.kafka;

import java.nio.charset.StandardCharsets;
import java.util.NoSuchElementException;
import java.util.Set;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.header.Header;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.stereotype.Component;

/** Resolves a Kafka delivery to one of a listener's configured logical main topics. */
@Component
public final class RetryTopicResolver {
  private static final Logger logger = LoggerFactory.getLogger(RetryTopicResolver.class);

  /**
   * Resolves a consumed record to a configured logical main topic.
   *
   * <p>An exact physical-topic match takes precedence. Otherwise, the resolver uses Spring Kafka's
   * {@link KafkaHeaders#ORIGINAL_TOPIC} header, which is added when a record is forwarded to a
   * retry topic. The resolved topic must be present in {@code allowedMainTopics}.
   *
   * @param record the consumed Kafka record containing the physical topic and native headers
   * @param allowedMainTopics the configured main topics accepted by the calling listener
   * @return the physical delivery topic and resolved logical main topic
   * @throws IllegalArgumentException if the record or allowed-topic set is invalid
   * @throws NoSuchElementException if neither the physical nor original topic is allowed
   */
  public TopicResolution resolve(ConsumerRecord<?, ?> record, Set<String> allowedMainTopics) {
    if (record == null) {
      throw new IllegalArgumentException("Consumer record must not be null");
    }
    validateMainTopics(allowedMainTopics);

    String physicalTopic = record.topic();
    String originalTopic = null;
    if (!allowedMainTopics.contains(physicalTopic)) {
      originalTopic = extractOriginalTopic(record);
      if (originalTopic == null || !allowedMainTopics.contains(originalTopic)) {
        throw new NoSuchElementException("Received data from an unknown topic: " + physicalTopic);
      }
    }

    TopicResolution resolution =
        new TopicResolution(physicalTopic, originalTopic != null ? originalTopic : physicalTopic);
    logger.debug(
        "Resolved Kafka topic: physicalTopic={} logicalTopic={}",
        resolution.physicalTopic(),
        resolution.logicalTopic());
    return resolution;
  }

  private static String extractOriginalTopic(ConsumerRecord<?, ?> record) {
    Header originalTopicHeader = record.headers().lastHeader(KafkaHeaders.ORIGINAL_TOPIC);
    if (originalTopicHeader == null || originalTopicHeader.value() == null) {
      return null;
    }

    // convert bytes[] to string using UTF-8 encoding
    String originalTopic = new String(originalTopicHeader.value(), StandardCharsets.UTF_8);
    return originalTopic.isBlank() ? null : originalTopic;
  }

  private static void validateMainTopics(Set<String> allowedMainTopics) {
    if (allowedMainTopics == null || allowedMainTopics.isEmpty()) {
      throw new IllegalArgumentException("Allowed main topics must not be empty");
    }
    if (allowedMainTopics.stream().anyMatch(topic -> topic == null || topic.isBlank())) {
      throw new IllegalArgumentException("Allowed main topic must not be blank");
    }
  }
}
