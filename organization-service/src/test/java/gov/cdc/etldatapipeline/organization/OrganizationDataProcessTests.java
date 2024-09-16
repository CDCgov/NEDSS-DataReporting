package gov.cdc.etldatapipeline.organization;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationElasticSearch;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationKey;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationReporting;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationSp;
import gov.cdc.etldatapipeline.organization.model.dto.orgdetails.*;
import gov.cdc.etldatapipeline.organization.transformer.OrganizationTransformers;
import gov.cdc.etldatapipeline.organization.transformer.OrganizationType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.deserializePayload;
import static org.junit.jupiter.api.Assertions.*;

class OrganizationDataProcessTests {
    private final ObjectMapper objectMapper = new ObjectMapper();
    OrganizationSp orgSp;

    @BeforeEach
    public void setup() {
        orgSp = deserializePayload(readFileData("orgcdc/orgSp.json"), OrganizationSp.class);
    }

    @Test
    void testOrganizationNameProcess() {
        Name[] name = deserializePayload(orgSp.getOrganizationName(), Name[].class);
        Name expected = Name.builder()
                .onOrgUid(10036000L)
                .organizationName("Autauga County Health Department")
                .build();

        assertNotNull(name);
        assertEquals(expected.toString(), name[0].toString());
    }

    @Test
    void testOrganizationAddressProcess() {
        Address[] addr = deserializePayload(orgSp.getOrganizationAddress(), Address[].class);
        Address expected = Address.builder()
                .addrElpCd("O")
                .addrElpUseCd("WP")
                .addrPlUid(10036001L)
                .streetAddr1("219 North Court Street")
                .streetAddr2("Unit#1")
                .city("Prattville")
                .zip("36067-0000")
                .cntyCd("01001")
                .state("01")
                .cntryCd("840")
                .state_desc("Alabama")
                .county("Autauga County")
                .addressComments("Testing address Comments!")
                .build();

        assertNotNull(addr);
        assertEquals(expected.toString(), addr[0].toString());
    }

    @Test
    void testOrganizationPhoneProcess() {
        Phone[] phn = deserializePayload(orgSp.getOrganizationTelephone(), Phone[].class);
        Phone expected = Phone.builder()
                .phTlUid(10615102L)
                .phElpCd("PH")
                .phElpUseCd("WP")
                .telephoneNbr("3343613743")
                .extensionTxt("1234")
                .emailAddress("john.doe@test.com")
                .phone_comments("Testing phone Comments!")
                .build();

        assertNotNull(phn);
        assertEquals(2, phn.length);
        assertEquals(expected.toString(), phn[1].toString());
    }

    @Test
    void testOrganizationEntityProcess() {
        Entity[] ets = deserializePayload(orgSp.getOrganizationEntityId(), Entity[].class);
        Entity expected = Entity.builder()
                .entityUid(10036000L)
                .typeCd("FI")
                .recordStatusCd("ACTIVE")
                .rootExtensionTxt("A4646")
                .entityIdSeq("1")
                .assigningAuthorityCd("OTH")
                .build();

        assertNotNull(ets);
        assertEquals(2, ets.length);
        assertEquals(expected.toString(), ets[0].toString());
    }

    @Test
    void testOrganizationFaxProcess() {
        Fax[] fax = deserializePayload(orgSp.getOrganizationFax(), Fax[].class);
        Fax expected = Fax.builder()
                .faxTlUid(1002L)
                .faxElpCd("fax-cd-1002")
                .faxElpUseCd("business-use-1002")
                .orgFax("7072834657")
                .build();

        assertNotNull(fax);
        assertEquals(2, fax.length);
        assertEquals(expected.toString(), fax[0].toString());
    }

    @ParameterizedTest
    @EnumSource(OrganizationType.class)
    void testOrganizationReportingProcess(OrganizationType type) throws Exception {
        OrganizationTransformers transformer = new OrganizationTransformers();
        Object actual = transformer.buildTransformedObject(orgSp, type);

        Object expected =
                switch (type) {
                    case ORGANIZATION_REPORTING ->
                            deserializePayload(
                            objectMapper.readTree(
                                    readFileData("orgtransformed/OrgReporting.json")).path("payload").toString(),
                            OrganizationReporting.class);
                    case ORGANIZATION_ELASTIC_SEARCH -> deserializePayload(
                            objectMapper.readTree(
                                    readFileData("orgtransformed/OrgElastic.json")).path("payload").toString(),
                            OrganizationElasticSearch.class);
                };

        assertEquals(expected, actual);
    }

    @Test
    void testOrganizationKeySerialization() throws Exception {
        objectMapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        OrganizationKey organizationKey = OrganizationKey.builder().organizationUid(12345L).build();

        String jsonResult = objectMapper.writeValueAsString(organizationKey);
        String expectedJson = "{\"organization_uid\":12345}";

        assertEquals(expectedJson, jsonResult);
    }

    @Test
    void testOrganizationKeyDeserialization() throws Exception {
        objectMapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        String jsonInput = "{\"organization_uid\":12345}";

        OrganizationKey organizationKey = objectMapper.readValue(jsonInput, OrganizationKey.class);

        assertEquals(12345L, organizationKey.getOrganizationUid());
    }

    @Test
    void testInvalidDataDeserialization() {
        String invalidJson = "{\"invalid_json\"}";
        OrganizationReporting orgReporting = deserializePayload(invalidJson, OrganizationReporting.class);
        assertNull(orgReporting);
    }
}
