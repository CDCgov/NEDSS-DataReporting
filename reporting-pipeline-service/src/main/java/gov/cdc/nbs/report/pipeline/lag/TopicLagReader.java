package gov.cdc.nbs.report.pipeline.lag;

import java.util.Map;

/**
 * Reads per-topic lag for a consumer group. Isolated behind an interface so the lag-reporting logic
 * can be unit-tested without a live broker.
 */
public interface TopicLagReader {

  /**
   * Computes lag for every topic the group consumes — the topic set is taken from the group's
   * committed offsets, so it covers exactly what the group subscribes to (no topic-name guessing).
   *
   * @param groupId the consumer group to inspect
   * @return lag per topic keyed by topic name (empty when the group has no committed offsets)
   */
  Map<String, TopicLag> lagByGroup(String groupId);
}
