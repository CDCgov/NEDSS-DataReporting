package gov.cdc.nbs.report.pipeline.lag;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;

class LagEndpointTest {

  private static final String PIPELINE_GROUP = "pipeline-consumer-app";
  private static final String SINK_GROUP = "connect-sink";

  private static final LagProperties ENABLED =
      new LagProperties(true, PIPELINE_GROUP, SINK_GROUP, 10000L);

  /** Routes the two group lookups to canned results so the decision logic is isolated. */
  private static TopicLagReader reader(Map<String, TopicLag> pipeline, Map<String, TopicLag> sink) {
    return groupId -> groupId.equals(PIPELINE_GROUP) ? pipeline : sink;
  }

  private LagEndpoint endpoint(TopicLagReader reader, LagProperties properties) {
    return new LagEndpoint(reader, properties);
  }

  @Test
  void ready_when_both_groups_caught_up() {
    TopicLagReader reader =
        reader(
            Map.of("nbs_Person", new TopicLag(1000, 0)),
            Map.of("nrt_patient", new TopicLag(1000, 0)));

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(LagEndpoint.READY, health.getStatus());
    assertEquals(true, health.getDetails().get("caughtUp"));
    assertEquals(0L, pipeline(health).get("messagesQueued"));
  }

  @Test
  void processing_with_record_breakdown_when_pipeline_group_lags() {
    TopicLagReader reader =
        reader(
            Map.of(
                "nbs_Observation", new TopicLag(1000, 250),
                "nbs_Datamart", new TopicLag(500, 0)),
            Map.of("nrt_patient", new TopicLag(750, 0)));

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(LagEndpoint.PROCESSING, health.getStatus());
    assertEquals(false, health.getDetails().get("caughtUp"));
    assertEquals(250L, pipeline(health).get("messagesQueued"));

    @SuppressWarnings("unchecked")
    Map<String, Long> byTopic = (Map<String, Long>) pipeline(health).get("byTopic");
    assertEquals(250L, byTopic.get("nbs_Observation"));
    assertFalse(byTopic.containsKey("nbs_Datamart")); // drained topics omitted from breakdown
  }

  @Test
  void processing_when_sink_group_has_not_drained() {
    TopicLagReader reader =
        reader(
            Map.of("nbs_Person", new TopicLag(1000, 0)),
            Map.of("nrt_patient", new TopicLag(1000, 40)));

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(LagEndpoint.PROCESSING, health.getStatus());
    assertEquals(40L, sink(health).get("messagesQueued"));
  }

  @Test
  void caught_up_with_note_when_pipeline_group_has_consumed_nothing() {
    // Pipeline group has no data at all: there is no backlog, but flag that nothing has been read.
    TopicLagReader reader = reader(Map.of(), Map.of("nrt_patient", new TopicLag(0, 0)));

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(LagEndpoint.READY, health.getStatus());
    assertEquals(true, health.getDetails().get("caughtUp"));
    assertTrue(health.getDetails().containsKey("note"));
  }

  @Test
  void down_when_offsets_cannot_be_read() {
    TopicLagReader reader =
        groupId -> {
          throw new LagInspectionException("broker unreachable", new RuntimeException());
        };

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(Status.DOWN, health.getStatus());
  }

  @Test
  void up_and_disabled_when_report_is_turned_off() {
    LagProperties disabled = new LagProperties(false, PIPELINE_GROUP, SINK_GROUP, 10000L);
    TopicLagReader reader =
        groupId -> {
          throw new AssertionError("reader must not be called when disabled");
        };

    Health health = endpoint(reader, disabled).lag();

    assertEquals(Status.UP, health.getStatus());
    assertEquals("DISABLED", health.getDetails().get("status"));
    assertFalse(health.getDetails().containsKey("caughtUp"));
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> pipeline(Health health) {
    return (Map<String, Object>) health.getDetails().get("pipeline");
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> sink(Health health) {
    return (Map<String, Object>) health.getDetails().get("sink");
  }
}
