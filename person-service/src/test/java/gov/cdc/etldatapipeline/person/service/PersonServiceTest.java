package gov.cdc.etldatapipeline.person.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.model.dto.user.AuthUser;
import gov.cdc.etldatapipeline.person.model.dto.user.AuthUserKey;
import gov.cdc.etldatapipeline.person.repository.PatientRepository;
import gov.cdc.etldatapipeline.person.repository.ProviderRepository;
import gov.cdc.etldatapipeline.person.repository.UserRepository;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.*;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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

    @BeforeEach
    public void setUp() {
        PersonTransformers transformer = new PersonTransformers();
        personService = new PersonService(patientRepository, providerRepository, userRepository, transformer, kafkaTemplate);
        personService.setPersonTopic(inputTopicPerson);
        personService.setUserTopic(inputTopicUser);
        personService.setPatientReportingOutputTopic(patientReportingTopic);
        personService.setPatientElasticSearchOutputTopic(patientElasticTopic);
        personService.setProviderReportingOutputTopic(providerReportingTopic);
        personService.setProviderElasticSearchOutputTopic(providerElasticTopic);
        personService.setUserReportingOutputTopic(userReportingTopic);
    }

    @Test
    void testProcessPatientData() throws JsonProcessingException {
        PatientSp patientSp = constructPatient();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(List.of(patientSp));

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonPatientChangeData.json"),
                patientReportingTopic,
                patientElasticTopic,
                "rawDataFiles/patient/PatientReporting.json",
                "rawDataFiles/patient/PatientElastic.json",
                "rawDataFiles/patient/PatientKey.json");
    }

    @Test
    void testProcessProviderData() throws JsonProcessingException {
        ProviderSp providerSp = constructProvider();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(new ArrayList<>());
        Mockito.when(providerRepository.computeProviders(anyString())).thenReturn(List.of(providerSp));

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonProviderChangeData.json"),
                providerReportingTopic,
                providerElasticTopic,
                "rawDataFiles/provider/ProviderReporting.json",
                "rawDataFiles/provider/ProviderElasticSearch.json",
                "rawDataFiles/provider/ProviderKey.json");
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

    private ProviderSp constructProvider() {
        String filePathPrefix = "rawDataFiles/person/";
        return ProviderSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(filePathPrefix + "PersonName.json"))
                .addressNested(readFileData(filePathPrefix + "PersonAddress.json"))
                .telephoneNested(readFileData(filePathPrefix + "PersonTelephone.json"))
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
