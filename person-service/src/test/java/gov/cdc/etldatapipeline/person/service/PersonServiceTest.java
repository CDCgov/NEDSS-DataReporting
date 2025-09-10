package gov.cdc.etldatapipeline.person.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.model.dto.user.AuthUser;
import gov.cdc.etldatapipeline.person.model.dto.user.AuthUserKey;
import gov.cdc.etldatapipeline.person.repository.PatientRepository;
import gov.cdc.etldatapipeline.person.repository.ProviderRepository;
import gov.cdc.etldatapipeline.person.repository.UserRepository;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.*;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PersonServiceTest {

    @Mock
    PatientRepository patientRepository;

    @Mock
    ProviderRepository providerRepository;

    @Mock
    UserRepository userRepository;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> valueCaptor;

    private PersonService personService;

    private final String inputTopicPerson = "Person";
    private final String inputTopicUser = "User";
    private final String patientReportingTopic = "PatientReporting";
    private final String patientElasticTopic = "PatientElastic";
    private final String providerReportingTopic = "ProviderReporting";
    private final String providerElasticTopic = "ProviderElastic";
    private final String userReportingTopic = "UserRepoting";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private AutoCloseable closeable;
    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);

        PersonTransformers transformer = new PersonTransformers();
        personService = new PersonService(
                patientRepository, providerRepository, userRepository, transformer,
                kafkaTemplate, new CustomMetrics(new SimpleMeterRegistry()));
        personService.setPersonTopic(inputTopicPerson);
        personService.setUserTopic(inputTopicUser);
        personService.setPatientReportingOutputTopic(patientReportingTopic);
        personService.setPatientElasticSearchOutputTopic(patientElasticTopic);
        personService.setProviderReportingOutputTopic(providerReportingTopic);
        personService.setProviderElasticSearchOutputTopic(providerElasticTopic);
        personService.setUserReportingOutputTopic(userReportingTopic);
        personService.setElasticSearchEnable(true);
        personService.initMetrics();

        Logger logger = (Logger) LoggerFactory.getLogger(PersonService.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    void tearDown() throws Exception {
        Logger logger = (Logger) LoggerFactory.getLogger(PersonService.class);
        logger.detachAppender(listAppender);
        closeable.close();
    }

    @Test
    void testProcessPatientData() throws JsonProcessingException {
        PatientSp patientSp = constructPatient();
        PatientSp mprPatient = constructPatient();
        mprPatient.setPersonParentUid(mprPatient.getPersonUid());
        Mockito.when(patientRepository.computePatients(anyString()))
                .thenReturn(List.of(patientSp)).thenReturn(List.of(mprPatient));

        String incomingChangeData = readFileData("rawDataFiles/person/PersonPatientChangeData.json");

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                incomingChangeData,
                patientReportingTopic,
                patientElasticTopic,
                "rawDataFiles/patient/PatientReporting.json",
                "rawDataFiles/patient/PatientElastic.json",
                "rawDataFiles/patient/PatientKey.json");
        verify(patientRepository, never()).updatePhcFact(anyString(), anyString());

        personService.processMessage(incomingChangeData, inputTopicPerson);
        verify(patientRepository).updatePhcFact("PAT", String.valueOf(mprPatient.getPersonUid()));
    }

    @ParameterizedTest
    @CsvSource({
            "PersonTelephone.json , rawDataFiles/provider/ProviderReporting.json, rawDataFiles/provider/ProviderElasticSearch.json",
            "PersonTelephone2.json, rawDataFiles/provider/ProviderReporting2.json, rawDataFiles/provider/ProviderElasticSearch2.json",
            "PersonTelephone3.json, rawDataFiles/provider/ProviderReporting3.json, rawDataFiles/provider/ProviderElasticSearch3.json"
    })
    void testProcessProviderData(String personTelephoneFile,
                                 String providerReportingFile,
                                 String providerElasticFile) throws JsonProcessingException {

        ProviderSp providerSp = constructProviderCase(personTelephoneFile);
        ProviderSp mprProvider = constructProviderCase(personTelephoneFile);
        mprProvider.setPersonParentUid(mprProvider.getPersonUid());
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(new ArrayList<>());
        Mockito.when(providerRepository.computeProviders(anyString()))
                .thenReturn(List.of(providerSp)).thenReturn(List.of(mprProvider));

        String incomingChangeData = readFileData("rawDataFiles/person/PersonProviderChangeData.json");

        validateDataTransformation(
                incomingChangeData,
                providerReportingTopic,
                providerElasticTopic,
                providerReportingFile,
                providerElasticFile,
                "rawDataFiles/provider/ProviderKey.json"
        );

        verify(patientRepository, never()).updatePhcFact(anyString(), anyString());

        personService.processMessage(incomingChangeData, inputTopicPerson);
        verify(patientRepository).updatePhcFact("PRV", String.valueOf(mprProvider.getPersonUid()));
    }

    @Test
    void testProcessPatientDataNoElasticSearch() {
        PatientSp patientSp = PatientSp.builder().personUid(10000001L).build();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(List.of(patientSp));

        String patientData = "{\"payload\": {\"after\": {\"person_uid\": 10000001,\"cd\": \"PAT\"}}}";

        personService.setElasticSearchEnable(false);
        personService.processMessage(patientData, inputTopicPerson);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());

        String actualPatientTopic = topicCaptor.getValue();
        assertEquals(patientReportingTopic, actualPatientTopic);
    }

    @Test
    void testProcessProviderDataNoElasticSearch() {
        ProviderSp providerSp = ProviderSp.builder().personUid(10000001L).build();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(new ArrayList<>());
        Mockito.when(providerRepository.computeProviders(anyString())).thenReturn(List.of(providerSp));

        String providerData = "{\"payload\": {\"after\": {\"person_uid\": 10000001,\"cd\": \"PRV\"}}}";

        personService.setElasticSearchEnable(false);
        personService.processMessage(providerData, inputTopicPerson);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());

        String actualProviderTopic = topicCaptor.getValue();
        assertEquals(providerReportingTopic, actualProviderTopic);
    }

    @Test
    void testProcessPatientDataPhcFactDisabled() {
        PatientSp patientSp = PatientSp.builder().personUid(10000001L).build();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(List.of(patientSp));

        String patientData = "{\"payload\": {\"after\": {\"person_uid\": 10000001,\"cd\": \"PAT\"}}}";

        personService.setPhcDatamartDisable(true);
        personService.processMessage(patientData, inputTopicPerson);
        verify(patientRepository, never()).updatePhcFact(anyString(), anyString());
    }

    @Test
    void testProcessProviderDataPhcFactDisabled() {
        ProviderSp providerSp = ProviderSp.builder().personUid(10000001L).build();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(new ArrayList<>());
        Mockito.when(providerRepository.computeProviders(anyString())).thenReturn(List.of(providerSp));

        String providerData = "{\"payload\": {\"after\": {\"person_uid\": 10000001,\"cd\": \"PRV\"}}}";

        personService.setPhcDatamartDisable(true);
        personService.processMessage(providerData, inputTopicPerson);
        verify(patientRepository, never()).updatePhcFact(anyString(), anyString());
    }

    @Test
    void testProcessUserData() throws JsonProcessingException {
        String payload = "{\"payload\": {\"after\": {\"auth_user_uid\": \"11\"}}}";

        AuthUser user = constructAuthUser();
        AuthUserKey userKey = AuthUserKey.builder().authUserUid(11L).build();
        Mockito.when(userRepository.computeAuthUsers(anyString())).thenReturn(Optional.of(List.of(user)));

        personService.processMessage(payload, inputTopicUser);

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());
        String actualTopic = topicCaptor.getValue();
        String actualKey = keyCaptor.getValue();
        String actualValue = valueCaptor.getValue();

        var actualUser = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), AuthUser.class);

        var actualUserKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), AuthUserKey.class);

        assertEquals(userReportingTopic, actualTopic);
        assertEquals(userKey, actualUserKey);
        assertEquals(user, actualUser);
    }

    @ParameterizedTest
    @CsvSource({
            "{\"payload\": {}},Person",
            "{\"payload\": {}},User",
            "{\"payload\": {\"after\": {}}},Person",
            "{\"payload\": {\"after\": {}}},User"
    })
    void testProcessMessageException(String payload, String inputTopic) {
        RuntimeException ex = assertThrows(RuntimeException.class, () -> personService.processMessage(payload, inputTopic));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @ParameterizedTest
    @CsvSource(delimiter = '^', value = {
            "{\"payload\": {\"after\": {\"person_uid\": \"123456789\", \"cd\": \"PRV\"}}}^Person",
            "{\"payload\": {\"after\": {\"auth_user_uid\": \"11\"}}}^User"
    })
    void testProcessMessageNoDataException(String payload, String inputTopic) {
        if (inputTopic.equals(inputTopicPerson)) {
            Long personUid = 123456789L;
            when(patientRepository.computePatients(String.valueOf(personUid))).thenReturn(Collections.emptyList());
            when(providerRepository.computeProviders(String.valueOf(personUid))).thenReturn(Collections.emptyList());
        } else if (inputTopic.equals(inputTopicUser)) {
            Long authUserUid = 11L;
            when(userRepository.computeAuthUsers(String.valueOf(authUserUid))).thenReturn(Optional.of(Collections.emptyList()));
        }
        assertThrows(NoDataException.class, () -> personService.processMessage(payload, inputTopic));
    }

    @Test
    void testProcessPhcFactDatamartException() {
        final String ERROR_MSG = "Test Error";

        doThrow(new RuntimeException(ERROR_MSG)).when(patientRepository).updatePhcFact(anyString(), anyString());
        personService.processPhcFactDatamart("PAT","123");
        ILoggingEvent log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(ERROR_MSG));
    }

    private void validateDataTransformation(
            String incomingChangeData,
            String expectedReportingTopic,
            String expectedElasticTopic,
            String expectedReportingValueFilePath,
            String expectedElasticValueFilePath,
            String expectedKeyFilePath) throws JsonProcessingException {

        String expectedKey = readFileData(expectedKeyFilePath);
        String expectedReportingValue = readFileData(expectedReportingValueFilePath);
        String expectedElasticValue = readFileData(expectedElasticValueFilePath);

        personService.processMessage(incomingChangeData, inputTopicPerson);

        verify(kafkaTemplate, Mockito.times(2)).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());

        String actualReportingTopic = topicCaptor.getAllValues().get(0);
        String actualElasticTopic = topicCaptor.getAllValues().get(1);

        JsonNode expectedKeyJsonNode = objectMapper.readTree(expectedKey);
        JsonNode expectedReportingValueJsonNode = objectMapper.readTree(expectedReportingValue);
        JsonNode expectedElasticValueJsonNode = objectMapper.readTree(expectedElasticValue);

        JsonNode actualKeyJsonNode = objectMapper.readTree(keyCaptor.getValue());
        JsonNode actualReportingValueJsonNode = objectMapper.readTree(valueCaptor.getAllValues().get(0));
        JsonNode actualElasticValueJsonNode = objectMapper.readTree(valueCaptor.getAllValues().get(1));

        assertEquals(expectedReportingTopic, actualReportingTopic);
        assertEquals(expectedElasticTopic, actualElasticTopic);
        assertEquals(expectedKeyJsonNode, actualKeyJsonNode);
        assertEquals(expectedReportingValueJsonNode, actualReportingValueJsonNode);
        assertEquals(expectedElasticValueJsonNode, actualElasticValueJsonNode);
    }

    private PatientSp constructPatient() {
        String filePathPrefix = "rawDataFiles/person/";
        return PatientSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(filePathPrefix + "PersonName.json"))
                .addressNested(readFileData(filePathPrefix + "PersonAddress.json"))
                .raceNested(readFileData(filePathPrefix + "PersonRace.json"))
                .telephoneNested(readFileData(filePathPrefix + "PersonTelephone.json"))
                .entityDataNested(readFileData(filePathPrefix + "PersonEntityData.json"))
                .emailNested(readFileData(filePathPrefix + "PersonEmail.json"))
                .build();
    }

    private ProviderSp constructProviderCase(String overridePhoneData) {
        String filePathPrefix = "rawDataFiles/person/";
        return ProviderSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(filePathPrefix + "PersonName.json"))
                .addressNested(readFileData(filePathPrefix + "PersonAddress.json"))
                .telephoneNested(readFileData(overridePhoneData==null?filePathPrefix + "PersonTelephone.json":filePathPrefix+overridePhoneData))
                .entityDataNested(readFileData(filePathPrefix + "PersonEntityData.json"))
                .emailNested(readFileData(filePathPrefix + "PersonEmail.json"))
                .build();
    }

    private AuthUser constructAuthUser() {
        return AuthUser.builder()
                .authUserUid(11L)
                .userId("local")
                .firstNm("Local")
                .lastNm("User")
                .nedssEntryId(1001L)
                .providerUid(10002007L)
                .addUserId(10020003L)
                .lastChgUserId(10030004L)
                .addTime("2020-10-20 10:20:30")
                .lastChgTime("2020-10-22 10:22:33")
                .recordStatusCd("ACTIVE")
                .recordStatusTime("2020-10-20 10:20:30")
                .build();
    }
}
