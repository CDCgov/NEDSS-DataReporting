package gov.cdc.etldatapipeline.person;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import gov.cdc.etldatapipeline.person.transformer.PersonType;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;

public class ProviderDataPostProcessingTests {
    private static final String FILE_PREFIX = "rawDataFiles/person/";
    PersonTransformers tx = new PersonTransformers();

    ObjectMapper objectMapper = new ObjectMapper();

    @Test
    public void consolidatedProviderTransformationTest() throws JsonProcessingException {

        // Build the PatientProvider object with the json serialized data
        ProviderSp p = ProviderSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(FILE_PREFIX + "ProviderName.json"))
                .addressNested(readFileData(FILE_PREFIX + "PersonAddress.json"))
                .telephoneNested(readFileData(FILE_PREFIX + "PersonTelephone.json"))
                .entityDataNested(readFileData(FILE_PREFIX + "PersonEntityData.json"))
                .emailNested(readFileData(FILE_PREFIX + "PersonEmail.json"))
                .build();

        // Process the respective field json to PatientProvider fields
        String processedData = tx.processData(p, PersonType.PROVIDER_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");

        List<String> actual = Arrays.asList(payloadNode.get("last_name").asText(),
                payloadNode.get("middle_name").asText(),
                payloadNode.get("first_name").asText(),
                payloadNode.get("name_suffix").asText(),
                payloadNode.get("name_degree").asText(),
                payloadNode.get("street_address_1").asText(),
                payloadNode.get("street_address_2").asText(),
                payloadNode.get("city").asText(),
                payloadNode.get("zip").asText(),
                payloadNode.get("county_code").asText(),
                payloadNode.get("county").asText(),
                payloadNode.get("state_code").asText(),
                payloadNode.get("state").asText(),
                payloadNode.get("country").asText(),
                payloadNode.get("phone_work").asText(),
                payloadNode.get("phone_ext_work").asText(),
                payloadNode.get("phone_cell").asText(),
                payloadNode.get("quick_code").asText(),
                payloadNode.get("provider_registration_num").asText(),
                payloadNode.get("provider_registration_num_auth").asText(),
                payloadNode.get("email_work").asText());

        List<Object> expected = Arrays.asList(
                "Singgh",
                "Js",
                "Suurma",
                "Jr",
                "MD",
                "123 Main St.",
                "",
                "Atlanta",
                "30025",
                "13135",
                "Gwinnett County",
                "13",
                "Georgia",
                "United States",
                "2323222422",
                "232",
                "2823252423",
                "12314286",
                "86741517517",
                "3.16.740.1.113883.3.1147.1.1002",
                "someone2@email.com");
        // Validate the PatientProvider field processing
        Assertions.assertEquals(expected, actual);
    }

    @Test
    public void PatientProviderNameTransformationTest() throws JsonProcessingException {

        // Build the PatientProvider object with the json serialized data
        ProviderSp prov = ProviderSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(FILE_PREFIX + "ProviderName.json"))
                .build();

        // Process the respective field json to PatientProviderProvider fields
        String processedData = tx.processData(prov, PersonType.PROVIDER_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");

        List<String> actual = Arrays.asList(payloadNode.get("last_name").asText(),
                payloadNode.get("middle_name").asText(),
                payloadNode.get("first_name").asText(),
                payloadNode.get("name_suffix").asText(),
                payloadNode.get("name_degree").asText());

        List<String> expected = Arrays.asList(
                "Singgh",
                "Js",
                "Suurma",
                "Jr",
                "MD");
        // Validate the PatientProvider field processing
        Assertions.assertEquals(expected, actual);
    }

    @Test
    public void PatientProviderNameTransformationSet2Test() throws JsonProcessingException {

        // Build the PatientProvider object with the json serialized data
        ProviderSp prov = ProviderSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(FILE_PREFIX + "PersonName1.json"))
                .build();

        // Process the respective field json to PatientProviderProvider fields
        String processedData = tx.processData(prov, PersonType.PROVIDER_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");

        List<String> actual = Arrays.asList(payloadNode.get("last_name").asText(),
                payloadNode.get("middle_name").asText(),
                payloadNode.get("first_name").asText(),
                payloadNode.get("name_suffix").asText(),
                payloadNode.get("name_degree").asText());

        List<String> expected = Arrays.asList(
                "jack",
                "amy",
                "beans",
                "Sr",
                "MD");
        // Validate the PatientProvider field processing
        Assertions.assertEquals(expected, actual);
    }

    @Test
    public void PatientProviderAddressTransformationTest() throws JsonProcessingException {

        // Build the PatientProvider object with the json serialized data
        ProviderSp prov = ProviderSp.builder()
                .personUid(10000001L)
                .addressNested(readFileData(FILE_PREFIX + "PersonAddress.json"))
                .build();

        // Process the respective field json to PatientProvider fields
        String processedData = tx.processData(prov, PersonType.PROVIDER_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");

        List<String> actual = Arrays.asList(payloadNode.get("street_address_1").asText(),
                payloadNode.get("street_address_2").asText(),
                payloadNode.get("city").asText(),
                payloadNode.get("zip").asText(),
                payloadNode.get("county_code").asText(),
                payloadNode.get("county").asText(),
                payloadNode.get("state_code").asText(),
                payloadNode.get("state").asText(),
                payloadNode.get("country").asText());

        List<String> expected = Arrays.asList(
                "123 Main St.",
                "",
                "Atlanta",
                "30025",
                "13135",
                "Gwinnett County",
                "13",
                "Georgia",
                "United States");
        // Validate the PatientProvider field processing
        Assertions.assertEquals(expected, actual);
    }

    @Test
    public void PatientProviderTelephoneTransformationTest() throws JsonProcessingException {

        // Build the PatientProvider object with the json serialized data
        ProviderSp prov = ProviderSp.builder()
                .personUid(10000001L)
                .telephoneNested(readFileData(FILE_PREFIX + "PersonTelephone.json"))
                .build();

        // Process the respective field json to PatientProvider fields
        String processedData = tx.processData(prov, PersonType.PROVIDER_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");

        List<String> actual = Arrays.asList(payloadNode.get("phone_work").asText(),
                payloadNode.get("phone_ext_work").asText(),
                payloadNode.get("phone_cell").asText());

        List<String> expected = Arrays.asList(
                "2323222422",
                "232",
                "2823252423"
        );

        // Validate the PatientProvider field processing
        Assertions.assertEquals(expected, actual);
    }

    @Test
    public void PatientProviderEntityDataTransformationTest() throws JsonProcessingException {

        // Build the PatientProvider object with the json serialized data
        ProviderSp prov = ProviderSp.builder()
                .personUid(10000001L)
                .entityDataNested(readFileData(FILE_PREFIX + "PersonEntityData.json"))
                .build();

        // Process the respective field json to PatientProvider fields
        String processedData = tx.processData(prov, PersonType.PROVIDER_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");

        List<String> actual = List.of(payloadNode.get("quick_code").asText(),
                payloadNode.get("provider_registration_num").asText(),
                payloadNode.get("provider_registration_num_auth").asText());

        List<String> expected = List.of(
                "12314286",
                "86741517517",
                "3.16.740.1.113883.3.1147.1.1002");
        // Validate the PatientProvider field processing
        Assertions.assertEquals(expected, actual);
    }

    @Test
    public void PatientProviderEmailTransformationTest() throws JsonProcessingException {

        // Build the PatientProvider object with the json serialized data
        ProviderSp prov = ProviderSp.builder()
                .personUid(10000001L)
                .emailNested(readFileData(FILE_PREFIX + "PersonEmail.json"))
                .build();

        // Process the respective field json to PatientProvider fields
        String processedData = tx.processData(prov, PersonType.PROVIDER_REPORTING);
        JsonNode payloadNode = objectMapper.readTree(processedData).get("payload");

        List<String> actual = List.of(payloadNode.get("email_work").asText());

        List<String> expected = List.of("someone2@email.com");
        // Validate the PatientProvider field processing
        Assertions.assertEquals(expected, actual);
    }
}
