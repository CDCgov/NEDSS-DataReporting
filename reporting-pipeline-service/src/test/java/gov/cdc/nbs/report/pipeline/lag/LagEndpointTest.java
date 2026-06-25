package gov.cdc.nbs.report.pipeline.lag;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;
import java.util.function.LongSupplier;
import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;

class LagEndpointTest {

  private static final long NOW = 1_700_000_000_000L;
  private static final LongSupplier FIXED_CLOCK = () -> NOW;

  private static final LagProperties ENABLED =
      new LagProperties(
          true, "pipeline-consumer-app", "connect-sink", "nbs_", "nrt_", 10000L, 2000L);

  /** Routes the two prefix-scoped lookups to canned results so the decision logic is isolated. */
  private static TopicLagReader reader(Map<String, TopicLag> nbs, Map<String, TopicLag> nrt) {
    return (groupId, topicPrefix) -> topicPrefix.equals("nbs_") ? nbs : nrt;
  }

  private LagEndpoint endpoint(TopicLagReader reader, LagProperties properties) {
    return new LagEndpoint(reader, properties, FIXED_CLOCK);
  }

  @Test
  void ready_when_both_groups_caught_up() {
    TopicLagReader reader =
        reader(
            Map.of("nbs_Person", new TopicLag(1000, 0, null)),
            Map.of("nrt_patient", new TopicLag(1000, 0, null)));

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(LagEndpoint.READY, health.getStatus());
    assertEquals(true, health.getDetails().get("caughtUp"));
    assertEquals(0L, nbs(health).get("recordsBehind"));
    assertEquals(0L, nbs(health).get("timeLagSecs"));
  }

  @Test
  void processing_with_record_breakdown_and_time_lag_when_pipeline_lags() {
    long oldest = NOW - 5_000L; // oldest unconsumed record produced 5s ago
    TopicLagReader reader =
        reader(
            Map.of(
                "nbs_Observation", new TopicLag(1000, 250, oldest),
                "nbs_Person", new TopicLag(500, 0, null)),
            Map.of("nrt_patient", new TopicLag(750, 0, null)));

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(LagEndpoint.PROCESSING, health.getStatus());
    assertEquals(false, health.getDetails().get("caughtUp"));
    assertEquals(250L, nbs(health).get("recordsBehind"));
    assertEquals(5L, nbs(health).get("timeLagSecs"));

    @SuppressWarnings("unchecked")
    Map<String, Long> byTopic = (Map<String, Long>) nbs(health).get("byTopic");
    assertEquals(250L, byTopic.get("nbs_Observation"));
    assertFalse(byTopic.containsKey("nbs_Person")); // drained topics omitted from breakdown
  }

  @Test
  void processing_when_sink_has_not_drained_nrt_topics() {
    TopicLagReader reader =
        reader(
            Map.of("nbs_Person", new TopicLag(1000, 0, null)),
            Map.of("nrt_patient", new TopicLag(1000, 40, NOW - 1_000L)));

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(LagEndpoint.PROCESSING, health.getStatus());
    assertEquals(40L, nrt(health).get("recordsBehind"));
    assertEquals(1L, nrt(health).get("timeLagSecs"));
  }

  @Test
  void caught_up_with_note_when_no_data_observed_yet() {
    // No data produced anywhere: there is no backlog, but flag that the snapshot may not have
    // begun.
    TopicLagReader reader =
        reader(
            Map.of("nbs_Person", new TopicLag(0, 0, null)),
            Map.of("nrt_patient", new TopicLag(0, 0, null)));

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(LagEndpoint.READY, health.getStatus());
    assertEquals(true, health.getDetails().get("caughtUp"));
    assertTrue(health.getDetails().containsKey("note"));
  }

  @Test
  void down_when_offsets_cannot_be_read() {
    TopicLagReader reader =
        (groupId, topicPrefix) -> {
          throw new LagInspectionException("broker unreachable", new RuntimeException());
        };

    Health health = endpoint(reader, ENABLED).lag();

    assertEquals(Status.DOWN, health.getStatus());
  }

  @Test
  void up_and_disabled_when_report_is_turned_off() {
    LagProperties disabled = new LagProperties(false, "g", "s", "nbs_", "nrt_", 10000L, 2000L);
    TopicLagReader reader =
        (groupId, topicPrefix) -> {
          throw new AssertionError("reader must not be called when disabled");
        };

    Health health = endpoint(reader, disabled).lag();

    assertEquals(Status.UP, health.getStatus());
    assertEquals("DISABLED", health.getDetails().get("status"));
    assertFalse(health.getDetails().containsKey("caughtUp"));
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> nbs(Health health) {
    return (Map<String, Object>) health.getDetails().get("nbs");
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> nrt(Health health) {
    return (Map<String, Object>) health.getDetails().get("nrt");
  }
}
