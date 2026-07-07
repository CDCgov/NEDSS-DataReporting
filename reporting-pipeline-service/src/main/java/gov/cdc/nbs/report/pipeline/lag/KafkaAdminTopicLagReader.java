package gov.cdc.nbs.report.pipeline.lag;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.ListOffsetsResult.ListOffsetsResultInfo;
import org.apache.kafka.clients.admin.OffsetSpec;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.common.TopicPartition;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;

/**
 * Computes consumer-group lag (record-count depth) with the Kafka {@link AdminClient}. The topics
 * inspected for a group are taken from that group's committed offsets, so the report covers exactly
 * the topics the group consumes. The client is built from the Spring-managed {@link KafkaAdmin}
 * configuration so it inherits the same bootstrap servers and security settings (SASL/TLS for MSK)
 * as the application's consumers — no separate credentials.
 */
@Component
public class KafkaAdminTopicLagReader implements TopicLagReader {

  private final KafkaAdmin kafkaAdmin;
  private final long timeoutMs;

  /**
   * Constructs a new reader with the provided dependencies.
   *
   * @param kafkaAdmin Spring-managed admin whose configuration (bootstrap servers, security) is
   *     reused to build the AdminClient
   * @param properties supplies the AdminClient call timeout
   */
  public KafkaAdminTopicLagReader(KafkaAdmin kafkaAdmin, LagProperties properties) {
    this.kafkaAdmin = kafkaAdmin;
    this.timeoutMs = properties.adminTimeoutMs();
  }

  /**
   * Computes per-topic lag for one consumer group by comparing its committed offsets against the
   * log-end offsets of the partitions it consumes. Returns an empty map when the group has no
   * committed offsets (it has not consumed anything yet, or does not exist).
   *
   * @param groupId consumer group whose committed offsets are inspected
   * @return lag per topic keyed by topic name
   * @throws LagInspectionException if Kafka offsets cannot be read
   */
  @Override
  public Map<String, TopicLag> lagByGroup(String groupId) {
    try (AdminClient admin = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
      Map<TopicPartition, OffsetAndMetadata> committed =
          await(admin.listConsumerGroupOffsets(groupId).partitionsToOffsetAndMetadata());
      if (committed.isEmpty()) {
        return Map.of();
      }
      Map<TopicPartition, OffsetSpec> endOffsetRequest =
          committed.keySet().stream()
              .collect(Collectors.toMap(partition -> partition, partition -> OffsetSpec.latest()));
      Map<TopicPartition, ListOffsetsResultInfo> endOffsets =
          await(admin.listOffsets(endOffsetRequest).all());
      return aggregateByTopic(endOffsets, committed);
    }
  }

  private Map<String, TopicLag> aggregateByTopic(
      Map<TopicPartition, ListOffsetsResultInfo> endOffsets,
      Map<TopicPartition, OffsetAndMetadata> committed) {
    // [0] = summed end offset, [1] = summed lag, per topic
    Map<String, long[]> totals = new LinkedHashMap<>();
    endOffsets.forEach(
        (partition, end) -> {
          OffsetAndMetadata commit = committed.get(partition);
          long committedOffset = commit == null ? 0L : commit.offset();
          long lag = Math.max(0L, end.offset() - committedOffset);
          long[] total = totals.computeIfAbsent(partition.topic(), key -> new long[2]);
          total[0] += end.offset();
          total[1] += lag;
        });
    Map<String, TopicLag> result = new LinkedHashMap<>();
    totals.forEach((topic, total) -> result.put(topic, new TopicLag(total[0], total[1])));
    return result;
  }

  private <T> T await(org.apache.kafka.common.KafkaFuture<T> future) {
    try {
      return future
          .toCompletionStage()
          .toCompletableFuture()
          .orTimeout(timeoutMs, TimeUnit.MILLISECONDS)
          .join();
    } catch (java.util.concurrent.CompletionException e) {
      throw new LagInspectionException("Failed to read Kafka offsets", e.getCause());
    }
  }
}
