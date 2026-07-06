package gov.cdc.nbs.report.pipeline.lag;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Configuration for the consumer-lag report.
 *
 * <p>Reports how much outstanding work the pipeline has: how far the pipeline consumer group and
 * the Kafka Connect sink group are behind the topics they consume. A non-empty backlog means
 * records remain to be processed; an empty backlog means both groups are caught up.
 *
 * @param enabled whether the lag report is active
 * @param pipelineGroupId the application's consumer group (consumes the {@code nbs_*} change
 *     events, {@code nbs_Datamart}, and the {@code nrt_*} topics post-processing reads)
 * @param sinkGroupId the Kafka Connect sink's consumer group (drains the {@code nrt_*} topics into
 *     the reporting database)
 * @param adminTimeoutMs timeout applied to each Kafka AdminClient call
 */
@ConfigurationProperties(prefix = "lag")
public record LagProperties(
    @DefaultValue("true") boolean enabled,
    @DefaultValue("pipeline-consumer-app") String pipelineGroupId,
    @DefaultValue("connect-Kafka-Connect-SqlServer-Sink") String sinkGroupId,
    @DefaultValue("10000") long adminTimeoutMs) {

  @ConstructorBinding
  public LagProperties {}
}
