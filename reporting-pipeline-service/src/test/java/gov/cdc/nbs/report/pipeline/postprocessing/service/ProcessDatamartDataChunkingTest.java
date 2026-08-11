package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import gov.cdc.nbs.report.pipeline.config.PostProcessingProperties;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.InvestigationRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

class ProcessDatamartDataChunkingTest {

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
    when(investigationRepository.executeStoredProcForStdHIVDatamart(anyString()))
        .thenReturn(List.of());
  }

  @Test
  void chunksSingleListDatamartProcedureInput() {
    boolean processed =
        datamartProcessor.processDmCache(
            Map.of(
                Entity.STD_HIV_DATAMART.getEntityName(),
                Map.of(Entity.INVESTIGATION.getEntityName(), List.of(1L, 2L, 3L, 4L, 5L))),
            null);

    assertTrue(processed);
    ArgumentCaptor<String> ids = ArgumentCaptor.forClass(String.class);
    verify(investigationRepository, times(3)).executeStoredProcForStdHIVDatamart(ids.capture());
    org.junit.jupiter.api.Assertions.assertEquals(List.of("1,2", "3,4", "5"), ids.getAllValues());
  }
}
