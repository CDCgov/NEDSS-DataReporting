import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import tracing_post_processing as post_processing


class TracingPostProcessingTest(unittest.TestCase):
    def test_parse_consumer_group_lags_reads_numeric_rows(self) -> None:
        output = """GROUP TOPIC PARTITION CURRENT-OFFSET LOG-END-OFFSET LAG CONSUMER-ID HOST CLIENT-ID
pipeline-consumer-app nrt_place_retry-1 0 0 0 0 consumer-a /172.19.0.7 client-a
pipeline-consumer-app nrt_interview_retry-1 0 4 4 0 consumer-a /172.19.0.7 client-a
connect-Kafka-Connect-SqlServer-Sink nrt_topic 0 8 12 4 consumer-b /172.19.0.8 client-b
"""

        self.assertEqual(post_processing.parse_consumer_group_lags(output), [0, 0, 4])

    def test_parse_consumer_group_lags_treats_dash_as_zero(self) -> None:
        output = """GROUP TOPIC PARTITION CURRENT-OFFSET LOG-END-OFFSET LAG CONSUMER-ID HOST CLIENT-ID
pipeline-consumer-app nrt_topic 0 - 12 - - - -
"""

        self.assertEqual(post_processing.parse_consumer_group_lags(output), [0])

    @patch("tracing_post_processing.fetch_consumer_group_lag")
    def test_all_consumer_groups_at_zero_lag_returns_true_when_totals_are_zero(self, mock_fetch) -> None:
        mock_fetch.side_effect = [
            (True, [0, 0], ""),
            (True, [0], ""),
        ]

        success, is_zero, totals, error = post_processing.all_consumer_groups_at_zero_lag(
            "docker",
            "kafka",
            ("pipeline-consumer-app", "connect-Kafka-Connect-SqlServer-Sink"),
        )

        self.assertTrue(success)
        self.assertTrue(is_zero)
        self.assertIsNone(error)
        self.assertEqual(
            totals,
            {
                "pipeline-consumer-app": 0,
                "connect-Kafka-Connect-SqlServer-Sink": 0,
            },
        )

    def test_idle_boundary_requires_latest_event_idle(self) -> None:
        events = [
            "2026-04-14T13:49:31.248Z ... Stored proc execution completed: sp_event_metric_datamart_postprocessing",
            "2026-04-14T13:49:51.247Z ... No ids to process from the topics.",
            "2026-04-14T13:50:04.865Z ... Executing stored proc: sp_morbidity_report_datamart_postprocessing",
        ]

        self.assertFalse(
            post_processing.has_post_processing_idle_tail(events, "No ids to process from the topics.")
        )

    def test_idle_boundary_requires_three_consecutive_idle_events(self) -> None:
        events = [
            "2026-04-14T13:49:31.248Z ... Stored proc execution completed: sp_event_metric_datamart_postprocessing",
            "2026-04-14T13:49:51.247Z ... No ids to process from the topics.",
            "2026-04-14T13:50:11.246Z ... No ids to process from the topics.",
        ]

        self.assertFalse(
            post_processing.has_post_processing_idle_tail(events, "No ids to process from the topics.")
        )

    def test_idle_boundary_allows_three_idle_after_datamart_event(self) -> None:
        events = [
            "2026-04-14T13:50:04.865Z ... g.c.n.r.p.p.service.ProcessDatamartData  : Executing stored proc: sp_morbidity_report_datamart_postprocessing",
            "2026-04-14T13:50:11.246Z ... No ids to process from the topics.",
            "2026-04-14T13:50:21.246Z ... No ids to process from the topics.",
            "2026-04-14T13:50:31.246Z ... No ids to process from the topics.",
        ]

        self.assertTrue(
            post_processing.has_post_processing_idle_tail(events, "No ids to process from the topics.")
        )

    def test_idle_boundary_rejects_idle_streak_if_new_datamart_event_arrives(self) -> None:
        events = [
            "2026-04-14T13:50:11.246Z ... No ids to process from the topics.",
            "2026-04-14T13:50:21.246Z ... No ids to process from the topics.",
            "2026-04-14T13:50:31.246Z ... No ids to process from the topics.",
            "2026-04-14T13:50:34.111Z ... g.c.n.r.p.p.service.ProcessDatamartData  : Executing stored proc: sp_morbidity_report_datamart_postprocessing",
            "2026-04-14T13:50:41.246Z ... No ids to process from the topics.",
            "2026-04-14T13:50:51.246Z ... No ids to process from the topics.",
        ]

        self.assertFalse(
            post_processing.has_post_processing_idle_tail(events, "No ids to process from the topics.")
        )


if __name__ == "__main__":
    unittest.main()
