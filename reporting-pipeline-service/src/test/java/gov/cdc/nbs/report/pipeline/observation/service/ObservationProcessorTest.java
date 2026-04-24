package gov.cdc.nbs.report.pipeline.observation.service;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.Observation;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationKey;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationReporting;
import gov.cdc.nbs.report.pipeline.observation.repository.NrtObservationWriter;
import gov.cdc.nbs.report.pipeline.observation.repository.ObservationRepository;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;

@ExtendWith(MockitoExtension.class)
class ObservationProcessorTest {

  @Spy private CustomMetrics metrics = new CustomMetrics(new SimpleMeterRegistry());
  @Mock private ObservationRepository repository;
  @Mock private NrtObservationWriter writer;
  @Mock private KafkaTemplate<String, String> kafkaTemplate;
  @Captor private ArgumentCaptor<String> keyCaptor;
  @Captor private ArgumentCaptor<String> messageCaptor;
  private final ObjectMapper mapper = new ObjectMapper();
  private final String nrtObservationTopic = "nrt_observation";

  private ObservationProcessor processor;

  @BeforeEach
  void init() {
    processor =
        new ObservationProcessor(metrics, repository, kafkaTemplate, nrtObservationTopic, writer);
  }

  @Test
  void successfullyProcessesObservation() throws JsonProcessingException {
    // Mock database response
    Observation observation = constructObservation(123L, "Order");
    when(repository.computeObservations("123")).thenReturn(Optional.of(observation));

    // Act
    processor.process(1l, "123");

    // Verify
    verify(repository, times(1)).computeObservations("123");
    verify(kafkaTemplate, times(1))
        .send(eq("nrt_observation"), keyCaptor.capture(), messageCaptor.capture());

    ObservationKey expectedKey = new ObservationKey(observation.getObservationUid());
    ObservationKey actualKey =
        mapper.readValue(
            mapper.readTree(keyCaptor.getValue()).path("payload").toString(), ObservationKey.class);
    assertThat(actualKey).isEqualTo(expectedKey);

    var reportingModel =
        constructObservationReporting(
            observation.getObservationUid(), observation.getObsDomainCdSt1());

    var actualReporting =
        mapper.readValue(
            mapper.readTree(messageCaptor.getValue()).path("payload").toString(),
            ObservationReporting.class);

    assertThat(reportingModel).isEqualTo(actualReporting);
  }

  @Test
  void verifyThrowsExceptionWhenNoDataFound() {
    // Mock database response
    when(repository.computeObservations("123")).thenReturn(Optional.empty());

    // Act + Verify
    NoDataException ex = assertThrows(NoDataException.class, () -> processor.process(1l, "123"));
    assertThat(ex.getMessage()).isEqualTo("Unable to find Observation with id: 123");
  }

  private Observation constructObservation(Long observationUid, String obsDomainCdSt1) {
    String filePathPrefix = "rawDataFiles/observation/";
    Observation observation = new Observation();
    observation.setObservationUid(observationUid);
    observation.setActUid(observationUid);
    observation.setClassCd("OBS");
    observation.setMoodCd("ENV");
    observation.setLocalId("OBS10003388MA01");
    observation.setActivityFromTime("2021-01-28 16:06:03.000");
    observation.setObsDomainCdSt1(obsDomainCdSt1);
    observation.setPersonParticipations(readFileData(filePathPrefix + "PersonParticipations.json"));
    observation.setOrganizationParticipations(
        readFileData(filePathPrefix + "OrganizationParticipations.json"));
    observation.setMaterialParticipations(
        readFileData(filePathPrefix + "MaterialParticipations.json"));
    observation.setFollowupObservations(readFileData(filePathPrefix + "FollowupObservations.json"));
    observation.setParentObservations(readFileData(filePathPrefix + "ParentObservations.json"));
    observation.setActIds(readFileData(filePathPrefix + "ActIds.json"));
    return observation;
  }

  private ObservationReporting constructObservationReporting(
      Long observationUid, String obsDomainCdSt1) {
    ObservationReporting observation = new ObservationReporting();
    observation.setBatchId(1l);
    observation.setObservationUid(observationUid);
    observation.setObsDomainCdSt1(obsDomainCdSt1);
    observation.setActUid(observationUid);
    observation.setClassCd("OBS");
    observation.setMoodCd("ENV");
    observation.setLocalId("OBS10003388MA01");
    observation.setOrderingPersonId("10000055");
    observation.setPatientId(10000066L);
    observation.setPerformingOrganizationId(null); // not null when obsDomainCdSt1=Result
    observation.setAuthorOrganizationId(34567890L); // null when obsDomainCdSt1=Result
    observation.setOrderingOrganizationId(23456789L); // null when obsDomainCdSt1=Result
    observation.setHealthCareId(56789012L); // null when obsDomainCdSt1=Result
    observation.setMorbHospReporterId(67890123L); // null when obsDomainCdSt1=Result
    observation.setMorbHospId(78901234L); // null when obsDomainCdSt1=Result
    observation.setMaterialId(10000005L);
    observation.setResultObservationUid("56789012,56789013");
    observation.setFollowupObservationUid("56789014,56789015");
    observation.setReportObservationUid(123456788L);
    observation.setReportRefrUid(123456790L);
    observation.setReportSprtUid(123456788L);

    observation.setAssistantInterpreterId(10000077L);
    observation.setAssistantInterpreterVal("22582");
    observation.setAssistantInterpreterFirstNm("Cara");
    observation.setAssistantInterpreterLastNm("Dune");
    observation.setAssistantInterpreterIdAssignAuth("22D7377772");
    observation.setAssistantInterpreterAuthType("Employee number");

    observation.setTranscriptionistId(10000088L);
    observation.setTranscriptionistVal("34344355455144");
    observation.setTranscriptionistFirstNm("Moff");
    observation.setTranscriptionistLastNm("Gideon");
    observation.setTranscriptionistIdAssignAuth("18D8181818");
    observation.setTranscriptionistAuthType("Employee number");

    observation.setResultInterpreterId(10000022L);
    observation.setLabTestTechnicianId(10000011L);

    observation.setSpecimenCollectorId(10000033L);
    observation.setCopyToProviderId(10000044L);
    observation.setAccessionNumber("20120601114");
    observation.setActivityFromTime("2021-01-28 16:06:03.000");
    observation.setDeviceInstanceId1("No Equipment");
    observation.setDeviceInstanceId2("NEW TOOLS");

    return observation;
  }
}
