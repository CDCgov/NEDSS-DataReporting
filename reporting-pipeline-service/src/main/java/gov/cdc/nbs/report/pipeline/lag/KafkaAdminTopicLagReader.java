package gov.cdc.nbs.report.pipeline.lag;

import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
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
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.common.KafkaException;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;

/**
 * Computes consumer-group lag with the Kafka {@link AdminClient} (record-count depth) and a
 * short-lived {@link KafkaConsumer} peek (time-lag). Both clients are built from the Spring-managed
 * {@link KafkaAdmin} configuration so they inherit the same bootstrap servers and security settings
 * (SASL/TLS for MSK) as the application's consumers — no separate credentials.
 */
@Component
public class KafkaAdminTopicLagReader implements TopicLagReader {

  private static final String PEEK_GROUP_ID = "rtr-lag-peek";

  private final KafkaAdmin kafkaAdmin;
  private final long timeoutMs;
  private final long peekTimeoutMs;

  public KafkaAdminTopicLagReader(KafkaAdmin kafkaAdmin, LagProperties properties) {
    this.kafkaAdmin = kafkaAdmin;
    this.timeoutMs = properties.adminTimeoutMs();
    this.peekTimeoutMs = properties.peekTimeoutMs();
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
      Map<TopicPartition, Long> oldestTimestamps = peekOldestTimestamps(endOffsets, committed);
      return aggregateByTopic(endOffsets, committed, oldestTimestamps);
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

  /**
   * Reads the producer timestamp of the oldest unconsumed record on each lagging partition by
   * seeking a throwaway consumer to the committed offset and reading the first record there. Only
   * partitions with a backlog are peeked; caught-up partitions are skipped entirely.
   */
  private Map<TopicPartition, Long> peekOldestTimestamps(
      Map<TopicPartition, ListOffsetsResultInfo> endOffsets,
      Map<TopicPartition, OffsetAndMetadata> committed) {
    // value is the committed offset to seek to, or -1 to seek to the beginning (no commit yet)
    Map<TopicPartition, Long> seekTargets = new HashMap<>();
    endOffsets.forEach(
        (partition, end) -> {
          OffsetAndMetadata commit = committed.get(partition);
          long committedOffset = commit == null ? -1L : commit.offset();
          long effective = committedOffset < 0 ? 0L : committedOffset;
          if (end.offset() - effective > 0) {
            seekTargets.put(partition, committedOffset);
          }
        });
    if (seekTargets.isEmpty()) {
      return Map.of();
    }

    Map<String, Object> props = new HashMap<>(kafkaAdmin.getConfigurationProperties());
    props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, ByteArrayDeserializer.class);
    props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, ByteArrayDeserializer.class);
    props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);
    props.put(ConsumerConfig.GROUP_ID_CONFIG, PEEK_GROUP_ID);
    props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

    Map<TopicPartition, Long> oldest = new HashMap<>();
    try (KafkaConsumer<byte[], byte[]> consumer = new KafkaConsumer<>(props)) {
      Set<TopicPartition> partitions = seekTargets.keySet();
      consumer.assign(partitions);

      List<TopicPartition> toBeginning = new ArrayList<>();
      seekTargets.forEach(
          (partition, offset) -> {
            if (offset < 0) {
              toBeginning.add(partition);
            } else {
              consumer.seek(partition, offset);
            }
          });
      if (!toBeginning.isEmpty()) {
        consumer.seekToBeginning(toBeginning);
      }

      long deadline = System.currentTimeMillis() + peekTimeoutMs;
      while (oldest.size() < partitions.size() && System.currentTimeMillis() < deadline) {
        ConsumerRecords<byte[], byte[]> records = consumer.poll(Duration.ofMillis(200));
        if (records.isEmpty()) {
          continue;
        }
        for (TopicPartition partition : partitions) {
          if (oldest.containsKey(partition)) {
            continue;
          }
          List<ConsumerRecord<byte[], byte[]>> partitionRecords = records.records(partition);
          if (!partitionRecords.isEmpty()) {
            oldest.put(partition, partitionRecords.get(0).timestamp());
          }
        }
      }
    } catch (KafkaException e) {
      throw new LagInspectionException("Failed to peek oldest unconsumed records", e);
    }
    return oldest;
  }

  private Map<String, TopicLag> aggregateByTopic(
      Map<TopicPartition, ListOffsetsResultInfo> endOffsets,
      Map<TopicPartition, OffsetAndMetadata> committed,
      Map<TopicPartition, Long> oldestTimestamps) {
    // [0] = summed end offset, [1] = summed lag, per topic
    Map<String, long[]> totals = new LinkedHashMap<>();
    Map<String, Long> oldestByTopic = new HashMap<>();
    endOffsets.forEach(
        (partition, end) -> {
          OffsetAndMetadata commit = committed.get(partition);
          long committedOffset = commit == null ? 0L : commit.offset();
          long lag = Math.max(0L, end.offset() - committedOffset);
          long[] total = totals.computeIfAbsent(partition.topic(), key -> new long[2]);
          total[0] += end.offset();
          total[1] += lag;
          Long timestamp = oldestTimestamps.get(partition);
          if (timestamp != null) {
            oldestByTopic.merge(partition.topic(), timestamp, Math::min);
          }
        });
    Map<String, TopicLag> result = new LinkedHashMap<>();
    totals.forEach(
        (topic, total) ->
            result.put(topic, new TopicLag(total[0], total[1], oldestByTopic.get(topic))));
    return result;
  }

  private <T> T await(org.apache.kafka.common.KafkaFuture<T> future) {
    try {
      return future.get(timeoutMs, TimeUnit.MILLISECONDS);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new LagInspectionException("Interrupted while inspecting Kafka offsets", e);
    } catch (ExecutionException | TimeoutException e) {
      throw new LagInspectionException("Failed to read Kafka offsets", e);
    }
  }
}
