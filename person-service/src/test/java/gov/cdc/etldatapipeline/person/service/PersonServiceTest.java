package gov.cdc.etldatapipeline.person.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.repository.PatientRepository;
import gov.cdc.etldatapipeline.person.repository.ProviderRepository;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.NoSuchElementException;

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
    private KafkaTemplate<String, String> kafkaTemplate;

    private PersonService personService;

    private final String inputTopic = "Person";
    private final String patientReportingTopic = "PatientReporting";
    private final String patientElasticTopic = "PatientElastic";
    private final String providerReportingTopic = "ProviderReporting";
    private final String providerElasticTopic = "ProviderElastic";

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    public void setUp() {
        PersonTransformers transformer = new PersonTransformers();
        personService = new PersonService(patientRepository, providerRepository, transformer, kafkaTemplate);
        personService.setPatientReportingOutputTopic(patientReportingTopic);
        personService.setPatientElasticSearchOutputTopic(patientElasticTopic);
        personService.setProviderReportingOutputTopic(providerReportingTopic);
        personService.setProviderElasticSearchOutputTopic(providerElasticTopic);
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

    @ParameterizedTest
    @CsvSource({
            "{\"payload\": {}}",
            "{\"payload\": {\"after\": {}}}"
    })
    void testProcessMessageException(String payload) {
        RuntimeException ex = assertThrows(RuntimeException.class, () -> personService.processMessage(payload, inputTopic));
        assertEquals(ex.getCause().getClass(), NoSuchElementException.class);
    }

    @Test
    void testProcessMessageNoDataException() {
        Long personUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"person_uid\": \"" + personUid + "\", \"cd\": \"PRV\"}}}";
        when(patientRepository.computePatients(String.valueOf(personUid))).thenReturn(Collections.emptyList());
        when(providerRepository.computeProviders(String.valueOf(personUid))).thenReturn(Collections.emptyList());
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

        personService.processMessage(incomingChangeData, inputTopic);

        ArgumentCaptor<String> topicCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> valueCaptor = ArgumentCaptor.forClass(String.class);

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
}
