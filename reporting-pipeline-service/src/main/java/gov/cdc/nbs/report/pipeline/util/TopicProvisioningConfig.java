package gov.cdc.nbs.report.pipeline.util;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.bind.Bindable;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.kafka.core.KafkaAdmin;

/**
 * Pre-creates the pipeline's topics with deliberate partition counts before
 * any listener subscribes or producer sends. Without this, whichever client
 * touches a topic first triggers broker auto-creation with the broker-wide
 * default partition count, and the Debezium connectors' topic.creation
 * settings silently never apply (they only cover topics that do not exist).
 *
 * Partitioning intent:
 *  - nbs_* (CDC source topics): partitioned, so listener concurrency can
 *    parallelize consumption. Matches the odse_main connector's
 *    topic.creation.default.partitions.
 *  - nrt_* (reporting output topics): exactly ONE partition each. The JDBC
 *    sink upserts with MERGE ... WITH (HOLDLOCK); concurrent writers on one
 *    table deadlock on key-range locks, so each table must have a single
 *    writer. Parallelism comes from spreading the many tables across sink
 *    tasks, not from partitioning within a table.
 *
 * KafkaAdmin ignores topics that already exist (it never alters partitions),
 * so this is a no-op against an already-provisioned broker.
 */
@Configuration
public class TopicProvisioningConfig {

  @Value("${NBS_TOPIC_PARTITIONS:10}")
  private int nbsTopicPartitions;

  @Bean
  public KafkaAdmin.NewTopics pipelineTopics(Environment environment) {
    Binder binder = Binder.get(environment);
    Map<String, String> nbsTopics = bindTopics(binder, "spring.kafka.topics.nbs");
    Map<String, String> nrtTopics = bindTopics(binder, "spring.kafka.topics.nrt");

    List<NewTopic> topics = new ArrayList<>();
    for (String topic : nbsTopics.values()) {
      topics.add(new NewTopic(topic, nbsTopicPartitions, (short) 1));
    }
    for (String topic : nrtTopics.values()) {
      topics.add(new NewTopic(topic, 1, (short) 1));
    }
    return new KafkaAdmin.NewTopics(topics.toArray(new NewTopic[0]));
  }

  private static Map<String, String> bindTopics(Binder binder, String prefix) {
    return binder
        .bind(prefix, Bindable.mapOf(String.class, String.class))
        .orElseGet(Map::of);
  }
}
