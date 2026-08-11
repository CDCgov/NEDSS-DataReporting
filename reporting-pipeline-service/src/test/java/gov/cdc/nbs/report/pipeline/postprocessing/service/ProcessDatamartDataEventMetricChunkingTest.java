package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static gov.cdc.nbs.report.pipeline.postprocessing.service.Entity.INVESTIGATION;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import gov.cdc.nbs.report.pipeline.config.PostProcessingProperties;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.InvestigationRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentLinkedQueue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

class ProcessDatamartDataEventMetricChunkingTest {

  @Mock private KafkaTemplate<String, String> kafkaTemplate;
  @Mock private PostProcRepository postProcRepository;
  @Mock private InvestigationRepository investigationRepository;

  private ProcessDatamartData datamartProcessor;

  @BeforeEach
  void setUp() {
    MockitoAnnotations.openMocks(this);
    datamartProcessor =
        new ProcessDatamartData(
            kafkaTemplate,
            postProcRepository,
            investigationRepository,
            new PostProcessingProperties(2),
            new CustomMetrics(new SimpleMeterRegistry()));
    datamartProcessor.initMetrics();
  }

  @Test
  void chunksEventMetricInputByEntityCategory() {
    datamartProcessor.processMetricEventDatamart(
        Map.of(
            INVESTIGATION.getEntityName(), new ConcurrentLinkedQueue<>(List.of(1L, 2L, 3L, 4L))));

    ArgumentCaptor<String> investigationIds = ArgumentCaptor.forClass(String.class);
    verify(postProcRepository, times(2))
        .executeStoredProcForEventMetric(
            investigationIds.capture(), eq(""), eq(""), eq(""), eq(""));
    assertEquals(List.of("1,2", "3,4"), investigationIds.getAllValues());
  }

  @Test
  void keepsAllCategoriesInOneCallWhenTotalFitsLimit() {
    datamartProcessor.processMetricEventDatamart(
        Map.of(
            INVESTIGATION.getEntityName(),
            new ConcurrentLinkedQueue<>(List.of(1L)),
            Entity.OBSERVATION.getEntityName(),
            new ConcurrentLinkedQueue<>(List.of(2L))));

    verify(postProcRepository).executeStoredProcForEventMetric("1", "2", "", "", "");
  }
}
