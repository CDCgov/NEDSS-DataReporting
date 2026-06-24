package gov.cdc.nbs.report.pipeline.seeding;

import java.util.Map;

/**
 * Reads consumer-group lag for every topic matching a prefix. Isolated behind an interface so the
 * seeding decision logic can be unit-tested without a live broker.
 */
public interface TopicLagReader {

  /**
   * @param groupId the consumer group whose committed offsets are compared against topic ends
   * @param topicPrefix only topics whose name starts with this prefix are inspected
   * @return lag per topic, keyed by topic name (empty when no topic matches the prefix)
   */
  Map<String, TopicLag> lagByTopic(String groupId, String topicPrefix);
}
