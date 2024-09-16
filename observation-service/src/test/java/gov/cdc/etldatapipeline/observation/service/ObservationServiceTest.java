package gov.cdc.etldatapipeline.observation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.observation.repository.IObservationRepository;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationKey;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationReporting;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.NoSuchElementException;
import java.util.Optional;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class ObservationServiceTest {

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

    private AutoCloseable closeable;

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
    }

    @AfterEach
    void closeService() throws Exception {
        closeable.close();
    }

    ProcessObservationDataUtil transformer = new ProcessObservationDataUtil();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void testProcessMessage() throws JsonProcessingException {
        String observationTopic = "Observation";
        String observationTopicOutput = "ObservationOutput";

        // Mocked input data
        Long observationUid = 123456789L;
        String obsDomainCdSt = "Order";
        String payload = "{\"payload\": {\"after\": {\"observation_uid\": \"" + observationUid + "\"}}}";

        Observation observation = constructObservation(observationUid, obsDomainCdSt);
        when(observationRepository.computeObservations(String.valueOf(observationUid))).thenReturn(Optional.of(observation));

        validateData(observationTopic, observationTopicOutput, payload, observation);

        verify(observationRepository).computeObservations(String.valueOf(observationUid));
    }

    @Test
    void testProcessMessageException() {
        String observationTopic = "Observation";
        String observationTopicOutput = "ObservationOutput";
        String invalidPayload = "{\"payload\": {\"after\": {}}}";

        final var observationService = getObservationService(observationTopic, observationTopicOutput);
        RuntimeException ex = assertThrows(RuntimeException.class, () -> observationService.processMessage(invalidPayload, observationTopic));
        assertEquals(ex.getCause().getClass(), NoSuchElementException.class);
    }

    @Test
    void testProcessMessageNoDataException() {
        String observationTopic = "Observation";
        String observationTopicOutput = "ObservationOutput";
        Long observationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"observation_uid\": \"" + observationUid + "\"}}}";

        when(observationRepository.computeObservations(String.valueOf(observationUid))).thenReturn(Optional.empty());

        final var observationService = getObservationService(observationTopic, observationTopicOutput);
        assertThrows(NoDataException.class, () -> observationService.processMessage(payload, observationTopic));
    }

    private void validateData(String inputTopicName, String outputTopicName,
                              String payload, Observation observation) throws JsonProcessingException {
        final var observationService = getObservationService(inputTopicName, outputTopicName);
        observationService.processMessage(payload, inputTopicName);

        ObservationKey observationKey = new ObservationKey();
        observationKey.setObservationUid(observation.getObservationUid());

        ObservationReporting reportingModel = constructObservationReporting(observation.getObservationUid(), observation.getObsDomainCdSt1());

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
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
        observation.setObsDomainCdSt1(obsDomainCdSt1);
        observation.setPersonParticipations(readFileData(filePathPrefix + "PersonParticipations.json"));
        observation.setOrganizationParticipations(readFileData(filePathPrefix + "OrganizationParticipations.json"));
        observation.setMaterialParticipations(readFileData(filePathPrefix + "MaterialParticipations.json"));
        observation.setFollowupObservations(readFileData(filePathPrefix + "FollowupObservations.json"));
        return observation;
    }

    private ObservationReporting constructObservationReporting(Long observationUid, String obsDomainCdSt1) {
        ObservationReporting observation = new ObservationReporting();
        observation.setObservationUid(observationUid);
        observation.setObsDomainCdSt1(obsDomainCdSt1);
        observation.setOrderingPersonId(10000055L);
        observation.setPatientId(10000066L);
        observation.setPerformingOrganizationId(null);      // not null when obsDomainCdSt1=Result
        observation.setAuthorOrganizationId(34567890L);     // null when obsDomainCdSt1=Result
        observation.setOrderingOrganizationId(23456789L);   // null when obsDomainCdSt1=Result
        observation.setMaterialId(10000005L);
        observation.setResultObservationUid(56789012L);
        return observation;
    }

    private ObservationService getObservationService(String inputTopicName, String outputTopicName) {
        ObservationService observationService = new ObservationService(observationRepository, kafkaTemplate, transformer);
        observationService.setObservationTopic(inputTopicName);
        observationService.setObservationTopicOutputReporting(outputTopicName);
        return observationService;
    }
}
