package gov.cdc.nbs.report.pipeline.util.kafka;

import java.util.Objects;

/** The physical Kafka delivery topic and its configured logical business topic. */
public record TopicResolution(String physicalTopic, String logicalTopic) {

  /**
   * Creates a validated topic resolution.
   *
   * @param physicalTopic the Kafka topic from which the record was consumed
   * @param logicalTopic the configured main topic used for business routing
   * @throws NullPointerException if either topic is {@code null}
   */
  public TopicResolution {
    Objects.requireNonNull(physicalTopic, "Physical topic must not be null");
    Objects.requireNonNull(logicalTopic, "Logical topic must not be null");
  }

  /**
   * Indicates whether Kafka delivered the record from a retry topic.
   *
   * @return {@code true} when the physical delivery topic differs from the logical main topic
   */
  public boolean retryDelivery() {
    return !physicalTopic.equals(logicalTopic);
  }
}
