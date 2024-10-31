package gov.cdc.etldatapipeline.observation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.observation.repository.IObservationRepository;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationKey;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationReporting;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.*;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class ObservationServiceTest {

    @InjectMocks
    private ObservationService observationService;

    @Mock
    private IObservationRepository observationRepository;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private AutoCloseable closeable;

    private final String inputTopicName = "Observation";
    private final String outputTopicName = "ObservationOutput";

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        ProcessObservationDataUtil transformer = new ProcessObservationDataUtil(kafkaTemplate);
        transformer.setMaterialTopicName("materialTopic");
        observationService = new ObservationService(observationRepository, kafkaTemplate, transformer);
        observationService.setObservationTopic(inputTopicName);
        observationService.setObservationTopicOutputReporting(outputTopicName);
        transformer.setCodedTopicName("ObservationCoded");
        transformer.setReasonTopicName("ObservationReason");
        transformer.setTxtTopicName("ObservationTxt");
    }

    @AfterEach
    void closeService() throws Exception {
        closeable.close();
    }

    @Test
    void testProcessMessage() throws JsonProcessingException {
        // Mocked input data
        Long observationUid = 123456789L;
        String obsDomainCdSt = "Order";
        String payload = "{\"payload\": {\"after\": {\"observation_uid\": \"" + observationUid + "\"}}}";

        Observation observation = constructObservation(observationUid, obsDomainCdSt);
        when(observationRepository.computeObservations(String.valueOf(observationUid))).thenReturn(Optional.of(observation));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));

        validateData(payload, observation);

        verify(observationRepository).computeObservations(String.valueOf(observationUid));
    }

    @Test
    void testProcessMessageException() {
        String invalidPayload = "{\"payload\": {\"after\": {}}}";

        RuntimeException ex = assertThrows(RuntimeException.class, () -> observationService.processMessage(invalidPayload, inputTopicName));
        assertEquals(ex.getCause().getClass(), NoSuchElementException.class);
    }

    @Test
    void testProcessMessageNoDataException() {
        Long observationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"observation_uid\": \"" + observationUid + "\"}}}";

        when(observationRepository.computeObservations(String.valueOf(observationUid))).thenReturn(Optional.empty());
        assertThrows(NoDataException.class, () -> observationService.processMessage(payload, inputTopicName));
    }

    private void validateData(String payload, Observation observation) throws JsonProcessingException {
        observationService.processMessage(payload, inputTopicName);

        ObservationKey observationKey = new ObservationKey();
        observationKey.setObservationUid(observation.getObservationUid());

        var reportingModel = constructObservationReporting(observation.getObservationUid(), observation.getObsDomainCdSt1());

        verify(kafkaTemplate, times(5)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        String actualTopic = topicCaptor.getValue();
        String actualKey = keyCaptor.getValue();
        String actualValue = messageCaptor.getValue();

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), ObservationReporting.class);

        var actualObservationKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), ObservationKey.class);

        assertEquals(outputTopicName, actualTopic);
        assertEquals(observationKey, actualObservationKey);
        assertEquals(reportingModel, actualReporting);
    }

    private Observation constructObservation(Long observationUid, String obsDomainCdSt1) {
        String filePathPrefix = "rawDataFiles/";
        Observation observation = new Observation();
        observation.setObservationUid(observationUid);
        observation.setActUid(observationUid);
        observation.setClassCd("OBS");
        observation.setMoodCd("ENV");
        observation.setLocalId("OBS10003388MA01");
        observation.setObsDomainCdSt1(obsDomainCdSt1);
        observation.setPersonParticipations(readFileData(filePathPrefix + "PersonParticipations.json"));
        observation.setOrganizationParticipations(readFileData(filePathPrefix + "OrganizationParticipations.json"));
        observation.setMaterialParticipations(readFileData(filePathPrefix + "MaterialParticipations.json"));
        observation.setFollowupObservations(readFileData(filePathPrefix + "FollowupObservations.json"));
        observation.setParentObservations(readFileData(filePathPrefix + "ParentObservations.json"));
        observation.setActIds(readFileData(filePathPrefix + "ActIds.json"));
        return observation;
    }

    private ObservationReporting constructObservationReporting(Long observationUid, String obsDomainCdSt1) {
        ObservationReporting observation = new ObservationReporting();
        observation.setObservationUid(observationUid);
        observation.setObsDomainCdSt1(obsDomainCdSt1);
        observation.setActUid(observationUid);
        observation.setClassCd("OBS");
        observation.setMoodCd("ENV");
        observation.setLocalId("OBS10003388MA01");
        observation.setOrderingPersonId(10000055L);
        observation.setPatientId(10000066L);
        observation.setPerformingOrganizationId(null);      // not null when obsDomainCdSt1=Result
        observation.setAuthorOrganizationId(34567890L);     // null when obsDomainCdSt1=Result
        observation.setOrderingOrganizationId(23456789L);   // null when obsDomainCdSt1=Result
        observation.setHealthCareId(56789012L);             // null when obsDomainCdSt1=Result
        observation.setMorbHospReporterId(67890123L);       // null when obsDomainCdSt1=Result
        observation.setMorbHospId(78901234L);               // null when obsDomainCdSt1=Result
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

        return observation;
    }
}
