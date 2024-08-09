package gov.cdc.etldatapipeline.person;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.repository.PatientRepository;
import gov.cdc.etldatapipeline.person.repository.ProviderRepository;
import gov.cdc.etldatapipeline.person.service.PersonService;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import gov.cdc.etldatapipeline.person.transformer.PersonType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
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

    PersonTransformers tx = new PersonTransformers();

    private final String personTopic = "PersonTopic";

    private final String providerTopic = "ProviderTopic";

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    public void setUp() {
        personService = new PersonService(patientRepository, providerRepository, tx, kafkaTemplate);
    }

    @Test
    void processPatientReportingData() throws JsonProcessingException {
        PatientSp patientSp = constructPatient();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(List.of(patientSp));

        //Run the Patient Reporting Data Transformation
        tx.processData(patientSp, PersonType.PATIENT_REPORTING);

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonPatientChangeData.json"),
                personTopic,
                "rawDataFiles/patient/PatientReporting.json",
                "rawDataFiles/patient/PatientKey.json", 0);
    }

    @Test
    void processPatientElasticSearchData() throws JsonProcessingException {
        PatientSp patientSp = constructPatient();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(List.of(patientSp));

        //Run the Patient ElasticSearch Data Transformation
        tx.processData(patientSp, PersonType.PATIENT_ELASTIC_SEARCH);

        // Validate Patient ElasticSearch Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonPatientChangeData.json"),
                personTopic,
                "rawDataFiles/patient/PatientElastic.json",
                "rawDataFiles/patient/PatientKey.json", 1);
    }

    @Test
    void processProviderReportingData() throws JsonProcessingException {
        ProviderSp providerSp = constructProvider();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(new ArrayList<>());
        Mockito.when(providerRepository.computeProviders(anyString())).thenReturn(List.of(providerSp));

        //Run the Provider Reporting Data Transformation
        tx.processData(providerSp, PersonType.PROVIDER_REPORTING);

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonProviderChangeData.json"),
                personTopic,
                "rawDataFiles/provider/ProviderReporting.json",
                "rawDataFiles/provider/ProviderKey.json", 0);
    }

    @Test
    void processProviderElasticSearchData() throws JsonProcessingException {
        ProviderSp providerSp = constructProvider();
        when(patientRepository.computePatients(anyString())).thenReturn(new ArrayList<>());
        when(providerRepository.computeProviders(anyString())).thenReturn(List.of(providerSp));

        //Run the Provider ElasticSearch Data Transformation
        tx.processData(providerSp, PersonType.PROVIDER_ELASTIC_SEARCH);

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonProviderChangeData.json"),
                providerTopic,
                "rawDataFiles/provider/ProviderElasticSearch.json",
                "rawDataFiles/provider/ProviderKey.json", 1);
    }

    @Test
    void testProcessMessageException() {
        String invalidPayload = "{\"payload\": {\"after\": }}";
        assertThrows(RuntimeException.class, () -> personService.processMessage(invalidPayload, personTopic));
    }

    @Test
    void testProcessMessageNoDataException() {
        Long personUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"person_uid\": \"" + personUid + "\", \"cd\": \"PRV\"}}}";
        when(patientRepository.computePatients(String.valueOf(personUid))).thenReturn(Collections.emptyList());
        when(providerRepository.computeProviders(String.valueOf(personUid))).thenReturn(Collections.emptyList());
        assertThrows(NoDataException.class, () -> personService.processMessage(payload, providerTopic));
    }

    private void validateDataTransformation(
            String incomingChangeData,
            String inputTopicName,
            String expectedValueFilePath,
            String expectedKeyFilePath,
            int indexForKafkaValue) throws JsonProcessingException {

        String expectedKey = readFileData(expectedKeyFilePath);
        String expectedValue = readFileData(expectedValueFilePath);

        personService.processMessage(incomingChangeData, inputTopicName);

        ArgumentCaptor<String> topicCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> valueCaptor = ArgumentCaptor.forClass(String.class);

        verify(kafkaTemplate, Mockito.times(2)).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());

        JsonNode expectedKeyJsonNode = objectMapper.readTree(expectedKey);
        JsonNode expectedValueJsonNode = objectMapper.readTree(expectedValue);
        JsonNode actualKeyJsonNode = objectMapper.readTree(keyCaptor.getValue());
        JsonNode actualValueJsonNode = objectMapper.readTree(valueCaptor.getAllValues().get(indexForKafkaValue));

        assertEquals(expectedKeyJsonNode, actualKeyJsonNode);
        assertEquals(expectedValueJsonNode, actualValueJsonNode);

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
