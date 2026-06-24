package gov.cdc.nbs.report.pipeline.seeding;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Configuration for the seeding-completion check.
 *
 * <p>Seeding is "complete" when the initial Debezium snapshot has been fully consumed off the
 * {@code nbs_*} topics by the pipeline and fully written from the {@code nrt_*} topics into {@code
 * RDB_MODERN} by the JDBC sink — i.e. both consumer groups have caught up to the end of every
 * partition. See {@code documentation/SnapshotAwarePostProcessing.md} for why this gate matters.
 *
 * @param enabled whether the seeding health check is active
 * @param pipelineGroupId consumer group that drains the {@code nbs_*} topics (the pipeline app)
 * @param sinkGroupId consumer group that drains the {@code nrt_*} topics (the Kafka Connect sink)
 * @param nbsTopicPrefix prefix identifying source change-event topics
 * @param nrtTopicPrefix prefix identifying entity-detail topics written to the reporting DB
 * @param adminTimeoutMs timeout applied to each Kafka AdminClient call
 */
@ConfigurationProperties(prefix = "seeding")
public record SeedingProperties(
    @DefaultValue("true") boolean enabled,
    @DefaultValue("pipeline-consumer-app") String pipelineGroupId,
    @DefaultValue("connect-Kafka-Connect-SqlServer-Sink") String sinkGroupId,
    @DefaultValue("nbs_") String nbsTopicPrefix,
    @DefaultValue("nrt_") String nrtTopicPrefix,
    @DefaultValue("10000") long adminTimeoutMs) {

  @ConstructorBinding
  public SeedingProperties {}
}
