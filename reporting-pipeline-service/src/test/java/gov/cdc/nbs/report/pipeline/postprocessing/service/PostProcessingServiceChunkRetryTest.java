package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import gov.cdc.nbs.report.pipeline.config.PostProcessingProperties;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.InvestigationRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import gov.cdc.nbs.report.pipeline.util.kafka.RetryTopicResolver;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

class PostProcessingServiceChunkRetryTest {

  @Mock private PostProcRepository postProcRepository;
  @Mock private InvestigationRepository investigationRepository;
  @Mock private KafkaTemplate<String, String> kafkaTemplate;

  private PostProcessingService service;
  private SimpleMeterRegistry metricsRegistry;

  @BeforeEach
  void setUp() {
    MockitoAnnotations.openMocks(this);
    metricsRegistry = new SimpleMeterRegistry();
    ProcessDatamartData datamartProcessor =
        new ProcessDatamartData(
            kafkaTemplate,
            postProcRepository,
            investigationRepository,
            new PostProcessingProperties(0),
            new CustomMetrics(new SimpleMeterRegistry()));
    service =
        new PostProcessingService(
            postProcRepository,
            investigationRepository,
            datamartProcessor,
            new RetryTopicResolver(),
            new PostProcessingProperties(2),
            new CustomMetrics(metricsRegistry));
    service.setMaxRetries(2);
    PostProcessingTestUtils.configureNrtTopics(service);
    service.initMetrics();
    datamartProcessor.initMetrics();
    service.setServiceEnable(true);

    when(postProcRepository.executeStoredProcForPatientIds(anyString())).thenReturn(List.of());
  }

  @Test
  void retriesTheWholeEntityAfterALaterChunkFails() {
    when(postProcRepository.executeStoredProcForPatientIds("3,4"))
        .thenThrow(new RuntimeException("chunk failure"))
        .thenReturn(List.of());

    service.idCache.put(
        PostProcessingTestUtils.PATIENT_TOPIC,
        new ConcurrentLinkedQueue<>(List.of(1L, 2L, 3L, 4L, 5L)));

    service.processCachedIds();

    assertTrue(
        service.retryCache.values().stream()
            .anyMatch(batch -> batch.containsKey(PostProcessingTestUtils.PATIENT_TOPIC)));
    verify(postProcRepository, times(2)).executeStoredProcForPatientIds(anyString());
    assertEquals(5.0, metricsRegistry.get("post_msg_failure").counter().count());
    assertEquals(0.0, metricsRegistry.get("post_msg_success").counter().count());

    service.processRetryCache();

    assertTrue(service.retryCache.isEmpty());
    verify(postProcRepository, times(5)).executeStoredProcForPatientIds(anyString());
  }
}
