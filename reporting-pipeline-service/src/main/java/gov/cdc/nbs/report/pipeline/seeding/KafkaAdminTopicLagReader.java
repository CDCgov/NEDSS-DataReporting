package gov.cdc.nbs.report.pipeline.seeding;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.stream.Collectors;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.ListOffsetsResult.ListOffsetsResultInfo;
import org.apache.kafka.clients.admin.OffsetSpec;
import org.apache.kafka.clients.admin.TopicDescription;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.common.TopicPartition;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;

/**
 * Computes consumer-group lag with the Kafka {@link AdminClient}. The client is built from the
 * Spring-managed {@link KafkaAdmin} configuration so it inherits the same bootstrap servers and
 * security settings (SASL/TLS for MSK) as the application's consumers — no separate credentials.
 */
@Component
public class KafkaAdminTopicLagReader implements TopicLagReader {

  private final KafkaAdmin kafkaAdmin;
  private final long timeoutMs;

  public KafkaAdminTopicLagReader(KafkaAdmin kafkaAdmin, SeedingProperties properties) {
    this.kafkaAdmin = kafkaAdmin;
    this.timeoutMs = properties.adminTimeoutMs();
  }

  @Override
  public Map<String, TopicLag> lagByTopic(String groupId, String topicPrefix) {
    try (AdminClient admin = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
      Set<String> topics = topicsWithPrefix(admin, topicPrefix);
      if (topics.isEmpty()) {
        return Map.of();
      }
      Map<TopicPartition, OffsetSpec> endOffsetRequest = endOffsetRequest(admin, topics);
      Map<TopicPartition, ListOffsetsResultInfo> endOffsets =
          await(admin.listOffsets(endOffsetRequest).all());
      Map<TopicPartition, OffsetAndMetadata> committed =
          await(admin.listConsumerGroupOffsets(groupId).partitionsToOffsetAndMetadata());
      return aggregateByTopic(endOffsets, committed);
    }
  }

  private Set<String> topicsWithPrefix(AdminClient admin, String topicPrefix) {
    return await(admin.listTopics().names()).stream()
        .filter(name -> name.startsWith(topicPrefix))
        .collect(Collectors.toCollection(TreeSet::new));
  }

  private Map<TopicPartition, OffsetSpec> endOffsetRequest(AdminClient admin, Set<String> topics) {
    Map<String, TopicDescription> descriptions =
        await(admin.describeTopics(topics).allTopicNames());
    Map<TopicPartition, OffsetSpec> request = new HashMap<>();
    for (TopicDescription description : descriptions.values()) {
      description
          .partitions()
          .forEach(
              partition ->
                  request.put(
                      new TopicPartition(description.name(), partition.partition()),
                      OffsetSpec.latest()));
    }
    return request;
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
      return future.get(timeoutMs, TimeUnit.MILLISECONDS);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new SeedingInspectionException("Interrupted while inspecting Kafka offsets", e);
    } catch (ExecutionException | TimeoutException e) {
      throw new SeedingInspectionException("Failed to read Kafka offsets", e);
    }
  }
}
