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
import gov.cdc.nbs.report.pipeline.postprocessing.repository.model.DatamartData;
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

class ProcessDatamartDataMultiChunkingTest {

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
            new PostProcessingProperties(3),
            new CustomMetrics(new SimpleMeterRegistry()));
    datamartProcessor.initMetrics();
  }

  @Test
  void chunksCovidVaccinationInputsWithoutDroppingEitherList() {
    when(investigationRepository.executeStoredProcForCovidVacDatamart(anyString(), anyString()))
        .thenReturn(List.of());

    boolean processed =
        datamartProcessor.processDmCache(
            Map.of(
                Entity.COVID_VACCINATION_DATAMART.getEntityName(),
                Map.of(
                    Entity.INVESTIGATION.getEntityName(), List.of(1L, 2L, 3L),
                    Entity.PATIENT.getEntityName(), List.of(10L, 11L))),
            null);

    assertTrue(processed);
    ArgumentCaptor<String> vaccinationIds = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<String> patientIds = ArgumentCaptor.forClass(String.class);
    verify(investigationRepository, times(2))
        .executeStoredProcForCovidVacDatamart(vaccinationIds.capture(), patientIds.capture());
    assertEquals(List.of("1,2,3", ""), vaccinationIds.getAllValues());
    assertEquals(List.of("", "10,11"), patientIds.getAllValues());
  }

  @Test
  void chunksMultiIdDatamartsBeforeProcessingDynamicOutputs() {
    when(postProcRepository.executeStoredProcForInvSummaryDatamart(
            anyString(), anyString(), anyString()))
        .thenReturn(List.of());
    datamartProcessor.processDmCache(
        Map.of(
            ProcessDatamartData.MULTI_ID_DATAMART,
            Map.of(
                Entity.INVESTIGATION.getEntityName(), List.of(1L, 2L),
                Entity.OBSERVATION.getEntityName(), List.of(3L),
                Entity.NOTIFICATION.getEntityName(), List.of(4L),
                Entity.PATIENT.getEntityName(), List.of(5L),
                Entity.PROVIDER.getEntityName(), List.of(6L),
                Entity.ORGANIZATION.getEntityName(), List.of(7L))),
        null);

    verify(postProcRepository, times(2))
        .executeStoredProcForInvSummaryDatamart(anyString(), anyString(), anyString());
    verify(postProcRepository, times(2))
        .executeStoredProcForMorbidityReportDatamart(
            anyString(), anyString(), anyString(), anyString(), anyString());
  }

  @Test
  void chunksDynamicDatamartOutputsBeforeSubmittingAsyncCalls() {
    List<DatamartData> dynamicData =
        List.of(
            dynamicData(1L), dynamicData(2L), dynamicData(3L), dynamicData(4L), dynamicData(5L));
    when(postProcRepository.executeStoredProcForInvSummaryDatamart(
            anyString(), anyString(), anyString()))
        .thenReturn(dynamicData);

    datamartProcessor.processDmCache(
        Map.of(
            ProcessDatamartData.MULTI_ID_DATAMART,
            Map.of(Entity.INVESTIGATION.getEntityName(), List.of(100L))),
        null);

    ArgumentCaptor<String> ids = ArgumentCaptor.forClass(String.class);
    verify(postProcRepository, times(2))
        .executeStoredProcForDynDatamart(org.mockito.ArgumentMatchers.eq("DYN_DM"), ids.capture());
    org.junit.jupiter.api.Assertions.assertEquals(
        List.of("1,2,3", "4,5"), ids.getAllValues().stream().sorted().toList());
  }

  private static DatamartData dynamicData(Long uid) {
    DatamartData data = new DatamartData();
    data.setDatamart("DYN_DM");
    data.setPublicHealthCaseUid(uid);
    return data;
  }
}
