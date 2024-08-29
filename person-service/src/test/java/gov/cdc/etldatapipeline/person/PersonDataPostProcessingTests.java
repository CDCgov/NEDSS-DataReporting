package gov.cdc.etldatapipeline.person;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientKey;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientReporting;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.Name;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderKey;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderReporting;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import gov.cdc.etldatapipeline.person.transformer.PersonType;
import gov.cdc.etldatapipeline.person.utils.UtilHelper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;

class PersonDataPostProcessingTests {
    private static final String FILE_PREFIX = "rawDataFiles/person/";
    private static final String FILE_PREFIX_PAT = "rawDataFiles/patient/";
    private static final String FILE_PREFIX_PRV = "rawDataFiles/provider/";
    PersonTransformers tx = new PersonTransformers();

    ObjectMapper objectMapper = new ObjectMapper();
    UtilHelper utilHelper = UtilHelper.getInstance();

    @ParameterizedTest
    @EnumSource(PersonTypeExt.class)
    void testPersonDataTransformation(PersonTypeExt personType) throws JsonProcessingException {
        PatientSp pat = constructPatient();
        ProviderSp prv = constructProvider();

        // Transform sp input data into patient/provider output object depending on type
        PersonExtendedProps actual = tx.processData(pat, prv, personType.type);
        PersonExtendedProps expected = getTransformed(personType);

        assertEquals(expected, actual);
    }

    @Test
    void testPatientNameTransformation() {
        // Build the PatientProvider object with the json serialized data
        PatientSp perOp = PatientSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(FILE_PREFIX + "PersonName1.json"))
                .build();

        PersonExtendedProps actual = tx.processData(perOp, null,PersonType.PATIENT_REPORTING);
        PatientReporting expected = PatientReporting.builder()
                .patientUid(10000001L)
                .aliasNickname("XEZD6SLFPRUJQGA52")
                .build();

        Name name = Name.builder()
                .lastNm("jack")
                .middleNm("amy")
                .firstNm("beans")
                .nmSuffix("Sr")
                .build();
        name.updatePerson(expected);

        assertEquals(expected, actual);
    }

    @Test
    void testProviderNameTransformation() {
        // Build the PatientProvider object with the json serialized data
        ProviderSp prov = ProviderSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(FILE_PREFIX + "PersonName1.json"))
                .build();

        PersonExtendedProps actual = tx.processData(null, prov,PersonType.PROVIDER_REPORTING);
        ProviderReporting expected = ProviderReporting.builder()
                .providerUid(10000001L)
                .build();

        Name name = Name.builder()
                .lastNm("jack")
                .middleNm("amy")
                .firstNm("beans")
                .nmSuffix("Sr")
                .nmDegree("MD")
                .build();
        name.updatePerson(expected);

        assertEquals(expected, actual);
    }

    @Test
    void testPatientKeySerialization() throws Exception {
        objectMapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        PatientKey patientnKey = PatientKey.builder().patientUid(12345L).build();

        String jsonResult = objectMapper.writeValueAsString(patientnKey);
        String expectedJson = "{\"patient_uid\":12345}";

        assertEquals(expectedJson, jsonResult);
    }

    @Test
    void testProviderKeySerialization() throws Exception {
        objectMapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        ProviderKey providerKey = ProviderKey.builder().providerUid(12345L).build();

        String jsonResult = objectMapper.writeValueAsString(providerKey);
        String expectedJson = "{\"provider_uid\":12345}";

        assertEquals(expectedJson, jsonResult);
    }

    private <T> T getTransformed(PersonTypeExt type) throws JsonProcessingException {
        return utilHelper.deserializePayload(objectMapper.readTree(
                readFileData(type.getFileName())).path("payload").toString(), type.getType().getClazz());
    }

    private PatientSp constructPatient() {
        return PatientSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(FILE_PREFIX + "PersonName.json"))
                .addressNested(readFileData(FILE_PREFIX + "PersonAddress.json"))
                .raceNested(readFileData(FILE_PREFIX + "PersonRace.json"))
                .telephoneNested(readFileData(FILE_PREFIX + "PersonTelephone.json"))
                .entityDataNested(readFileData(FILE_PREFIX + "PersonEntityData.json"))
                .emailNested(readFileData(FILE_PREFIX + "PersonEmail.json"))
                .build();
    }

    private ProviderSp constructProvider() {
        return ProviderSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(FILE_PREFIX + "ProviderName.json"))
                .addressNested(readFileData(FILE_PREFIX + "PersonAddress.json"))
                .telephoneNested(readFileData(FILE_PREFIX + "PersonTelephone.json"))
                .entityDataNested(readFileData(FILE_PREFIX + "PersonEntityData.json"))
                .emailNested(readFileData(FILE_PREFIX + "PersonEmail.json"))
                .build();
    }

    private enum PersonTypeExt {
        PATIENT_REPORTING(PersonType.PATIENT_REPORTING, FILE_PREFIX_PAT + "PatientReporting.json"),
        PATIENT_ELASTIC_SEARCH(PersonType.PATIENT_ELASTIC_SEARCH, FILE_PREFIX_PAT + "PatientElastic.json"),
        PROVIDER_REPORTING(PersonType.PROVIDER_REPORTING, FILE_PREFIX_PRV + "ProviderReporting.json"),
        PROVIDER_ELASTIC_SEARCH(PersonType.PROVIDER_ELASTIC_SEARCH, FILE_PREFIX_PRV + "ProviderElasticSearch.json");

        private final PersonType type;
        private final String fileName;

        PersonTypeExt(PersonType type, String fileName) {
            this.type = type;
            this.fileName = fileName;
        }

        public PersonType getType() {
            return type;
        }
        public String getFileName() {
            return fileName;
        }
    }
}
