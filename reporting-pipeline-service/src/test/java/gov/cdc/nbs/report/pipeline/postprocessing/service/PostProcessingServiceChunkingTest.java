package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

class PostProcessingServiceChunkingTest {

  @Mock private PostProcRepository postProcRepository;
  @Mock private InvestigationRepository investigationRepository;
  @Mock private KafkaTemplate<String, String> kafkaTemplate;

  private PostProcessingService service;

  @BeforeEach
  void setUp() {
    MockitoAnnotations.openMocks(this);
    ProcessDatamartData datamartProcessor =
        new ProcessDatamartData(
            kafkaTemplate,
            postProcRepository,
            investigationRepository,
            new CustomMetrics(new SimpleMeterRegistry()));
    service =
        new PostProcessingService(
            postProcRepository,
            investigationRepository,
            datamartProcessor,
            new RetryTopicResolver(),
            new PostProcessingProperties(2),
            new CustomMetrics(new SimpleMeterRegistry()));
    PostProcessingTestUtils.configureNrtTopics(service);
    service.initMetrics();
    datamartProcessor.initMetrics();
    service.setServiceEnable(true);
  }

  @Test
  void chunksNumericStoredProcedureInput() {
    when(postProcRepository.executeStoredProcForPatientIds(anyString())).thenReturn(List.of());
    service.idCache.put(
        PostProcessingTestUtils.PATIENT_TOPIC,
        new ConcurrentLinkedQueue<>(List.of(1L, 2L, 3L, 4L, 5L)));

    service.processCachedIds();

    ArgumentCaptor<String> ids = ArgumentCaptor.forClass(String.class);
    verify(postProcRepository, times(3)).executeStoredProcForPatientIds(ids.capture());
    assertEquals(List.of("1,2", "3,4", "5"), ids.getAllValues());
  }

  @Test
  void chunksConditionCodeStoredProcedureInput() {
    service.cdCache.put(
        PostProcessingTestUtils.CONDITION_CODE_TOPIC,
        new ConcurrentLinkedQueue<>(List.of("A", "B", "C", "D", "E")));

    service.processCachedIds();

    ArgumentCaptor<String> codes = ArgumentCaptor.forClass(String.class);
    verify(postProcRepository, times(3)).executeStoredProcForConditionCode(codes.capture());
    assertEquals(List.of("A,B", "C,D", "E"), codes.getAllValues());
  }
}
