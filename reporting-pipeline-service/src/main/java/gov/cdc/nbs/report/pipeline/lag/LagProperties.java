package gov.cdc.nbs.report.pipeline.lag;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Configuration for the consumer-lag report.
 *
 * <p>Reports how much outstanding work the pipeline has: how far the {@code nbs_*} consumer (the
 * pipeline app) and the {@code nrt_*} consumer (the Kafka Connect sink) are behind the end of their
 * topics. A non-empty backlog means records remain to be processed; an empty backlog means both
 * consumers are caught up.
 *
 * @param enabled whether the lag report is active
 * @param pipelineGroupId consumer group that drains the {@code nbs_*} topics (the pipeline app)
 * @param sinkGroupId consumer group that drains the {@code nrt_*} topics (the Kafka Connect sink)
 * @param nbsTopicPrefix prefix identifying source change-event topics
 * @param nrtTopicPrefix prefix identifying entity-detail topics written to the reporting DB
 * @param adminTimeoutMs timeout applied to each Kafka AdminClient call
 * @param peekTimeoutMs budget for peeking the oldest unconsumed record timestamps (time-lag)
 */
@ConfigurationProperties(prefix = "lag")
public record LagProperties(
    @DefaultValue("true") boolean enabled,
    @DefaultValue("pipeline-consumer-app") String pipelineGroupId,
    @DefaultValue("connect-Kafka-Connect-SqlServer-Sink") String sinkGroupId,
    @DefaultValue("nbs_") String nbsTopicPrefix,
    @DefaultValue("nrt_") String nrtTopicPrefix,
    @DefaultValue("10000") long adminTimeoutMs,
    @DefaultValue("2000") long peekTimeoutMs) {

  @ConstructorBinding
  public LagProperties {}
}
