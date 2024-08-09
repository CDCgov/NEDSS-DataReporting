package gov.cdc.etldatapipeline.observation.service;

import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.observation.repository.IObservationRepository;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationKey;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationReporting;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.modelmapper.ModelMapper;
import org.springframework.kafka.core.KafkaTemplate;

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

    final ModelMapper modelMapper = new ModelMapper();
    ProcessObservationDataUtil transformer = new ProcessObservationDataUtil();
    final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    @Test
    void testProcessMessage() {
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
        String invalidPayload = "{\"payload\": {\"after\": }}";

        final var observationService = getObservationService(observationTopic, observationTopicOutput);
        assertThrows(RuntimeException.class, () -> observationService.processMessage(invalidPayload, observationTopic));
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

    private Observation constructObservation(Long observationUid, String obsDomainCdSt1) {
        String filePathPrefix = "rawDataFiles/";
        Observation observation = new Observation();
        observation.setId(observationUid);
        observation.setObsDomainCdSt1(obsDomainCdSt1);
        observation.setPersonParticipations(readFileData(filePathPrefix + "PersonParticipations.json"));
        observation.setOrganizationParticipations(readFileData(filePathPrefix + "OrganizationParticipations.json"));
        observation.setMaterialParticipations(readFileData(filePathPrefix + "MaterialParticipations.json"));
        observation.setFollowupObservations(readFileData(filePathPrefix + "FollowupObservations.json"));
        return observation;
    }

    private void validateData(String inputTopicName, String outputTopicName,
                              String payload, Observation observation) {
        final var observationService = getObservationService(inputTopicName, outputTopicName);
        observationService.processMessage(payload, inputTopicName);

        ObservationKey observationKey = new ObservationKey();
        observationKey.setObservationUid(observation.getId());

        ObservationReporting reportingModel = modelMapper.map(observation, ObservationReporting.class);
        final ObservationTransformed transformed = transformer.transformObservationData(observation);
        observationService.buildReportingModelForTransformedData(reportingModel, transformed);

        String expectedKey = jsonGenerator.generateStringJson(observationKey);
        String expectedValue = jsonGenerator.generateStringJson(reportingModel);

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(outputTopicName, topicCaptor.getValue());
        assertEquals(expectedKey, keyCaptor.getValue());
        assertEquals(expectedValue, messageCaptor.getValue());
    }

    private ObservationService getObservationService(String inputTopicName, String outputTopicName) {
        ObservationService observationService = new ObservationService(observationRepository, kafkaTemplate, transformer);
        observationService.setObservationTopic(inputTopicName);
        observationService.setObservationTopicOutputReporting(outputTopicName);
        return observationService;
    }

}
