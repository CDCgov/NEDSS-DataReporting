package gov.cdc.etldatapipeline.person;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientElasticSearch;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientReporting;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.*;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderElasticSearch;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderReporting;
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
import java.util.List;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
public class PersonServiceTest {

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
    public void processPatientReportingData() throws JsonProcessingException {
        PatientSp patientSp = constructPatient();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(List.of(patientSp));

        String processedData = tx.processData(patientSp, PersonType.PATIENT_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");
        PatientReporting expectedPf = objectMapper.treeToValue(payloadNode, PatientReporting.class);

        //Construct transformed patient
        constructPatPrvFull(expectedPf);

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonPatientChangeData.json"),
                personTopic,
                "rawDataFiles/patient/PatientReporting.json",
                "rawDataFiles/patient/PatientKey.json", 0);
    }

    @Test
    public void processPatientElasticSearchData() throws JsonProcessingException {
        PatientSp patientSp = constructPatient();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(List.of(patientSp));

        //Build expected unflattened Provider
        String processedData = tx.processData(patientSp, PersonType.PATIENT_ELASTIC_SEARCH);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");
        PatientElasticSearch expectedPf = objectMapper.treeToValue(payloadNode, PatientElasticSearch.class);

        //Construct transformed patient
        constructPatPrvFull(expectedPf);

        // Validate Patient ElasticSearch Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonPatientChangeData.json"),
                personTopic,
                "rawDataFiles/patient/PatientElastic.json",
                "rawDataFiles/patient/PatientKey.json", 1);
    }

    @Test
    public void processProviderReportingData() throws JsonProcessingException {
        ProviderSp providerSp = constructProvider();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(new ArrayList<>());
        Mockito.when(providerRepository.computeProviders(anyString())).thenReturn(List.of(providerSp));

        //Build expected unflattened Provider
        String processedData = tx.processData(providerSp, PersonType.PROVIDER_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");
        ProviderReporting expectedPf = objectMapper.treeToValue(payloadNode, ProviderReporting.class);

        //Augment Provider with the flattened data
        constructPatPrvFull(expectedPf);

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonProviderChangeData.json"),
                personTopic,
                "rawDataFiles/provider/ProviderReporting.json",
                "rawDataFiles/provider/ProviderKey.json", 0);
    }

    @Test
    public void processProviderElasticSearchData() throws JsonProcessingException {
        ProviderSp providerSp = constructProvider();
        Mockito.when(patientRepository.computePatients(anyString())).thenReturn(new ArrayList<>());
        Mockito.when(providerRepository.computeProviders(anyString())).thenReturn(List.of(providerSp));

        //Build expected unflattened Provider
        String processedData = tx.processData(providerSp, PersonType.PROVIDER_ELASTIC_SEARCH);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");
        ProviderElasticSearch expectedPf = objectMapper.treeToValue(payloadNode, ProviderElasticSearch.class);

        //Augment Provider with the flattened data
        constructPatPrvFull(expectedPf);

        // Validate Patient Reporting Data Transformation
        validateDataTransformation(
                readFileData("rawDataFiles/person/PersonProviderChangeData.json"),
                providerTopic,
                "rawDataFiles/provider/ProviderElasticSearch.json",
                "rawDataFiles/provider/ProviderKey.json", 1);
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

    private <T extends PersonExtendedProps> void constructPatPrvFull(T patProv) {
        // Name
        Name.builder()
                .lastNm("Singgh")
                .middleNm("Js")
                .firstNm("Suurma")
                .nmSuffix("Jr")
                .build().updatePerson(patProv);

        // Address
        Address.builder()
                .streetAddr1("123 Main St.")
                .streetAddr2("")
                .city("Atlanta")
                .zip("30025")
                .cntyCd("13135")
                .county("Gwinnett County")
                .state("13")
                .stateDesc("Georgia")
                .cntryCd("840")
                .homeCountry("United States")
                .birthCountry("Canada")
                .build()
                .updatePerson(patProv);


        // Work Phone
        Phone.builder().telephoneNbr("2323222422").extensionTxt("232").cd("WP").build().updatePerson(patProv);

        // Home Phone
        Phone.builder().telephoneNbr("4562323222").extensionTxt("211").cd("H").build().updatePerson(patProv);

        // Cell Phone
        Phone.builder().telephoneNbr("2823252423").cd("CP").build().updatePerson(patProv);

        // Race
        Race.builder()
                .raceCd("2028-9")
                .raceCategoryCd("2028-9")
                .raceDescTxt("Amer Indian")
                .build()
                .updatePerson(patProv);


        // SSN
        EntityData.builder()
                .rootExtensionTxt("313431144414")
                .assigningAuthorityCd("SSA")
                .build()
                .updatePerson(patProv);


        // Patient Number
        EntityData.builder()
                .typeCd("PN")
                .rootExtensionTxt("56743114514")
                .assigningAuthorityCd("2.16.740.1.113883.3.1147.1.1002")
                .build()
                .updatePerson(patProv);

        //QEC
        EntityData.builder()
                .typeCd("QEC")
                .rootExtensionTxt("12314286")
                .build()
                .updatePerson(patProv);

        //RegNum
        EntityData.builder()
                .typeCd("PRN")
                .rootExtensionTxt("86741517517")
                .assigningAuthorityCd("3.16.740.1.113883.3.1147.1.1002")
                .build()
                .updatePerson(patProv);

        // Email
        Email.builder().emailAddress("someone2@email.com").build().updatePerson(patProv);

    }

}
