package gov.cdc.etldatapipeline.organization.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationKey;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationSp;
import gov.cdc.etldatapipeline.organization.repository.OrgRepository;
import gov.cdc.etldatapipeline.organization.transformer.OrganizationTransformers;
import gov.cdc.etldatapipeline.organization.transformer.OrganizationType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.Collections;
import java.util.Set;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class OrganizationServiceTest {

    @Mock
    private OrgRepository orgRepository;

    @Mock
    private OrganizationTransformers transformer;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    private OrganizationService organizationService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private final String orgReportingTopic = "OrgReportingTopic";


    @BeforeEach
    public void setUp() {
        organizationService = new OrganizationService(orgRepository, transformer, kafkaTemplate);
    }

    @Test
    void testProcessMessage() throws Exception {
        OrganizationSp orgSp = objectMapper.readValue(readFileData("orgcdc/orgSp.json"), OrganizationSp.class);
        when(orgRepository.computeAllOrganizations(anyString())).thenReturn(Set.of(orgSp));

        OrganizationKey organizationKey = OrganizationKey.builder().organizationUid(orgSp.getOrganizationUid()).build();
        when(transformer.buildOrganizationKey(orgSp)).thenReturn(new CustomJsonGeneratorImpl().generateStringJson(organizationKey));
        when(transformer.processData(orgSp, OrganizationType.ORGANIZATION_REPORTING)).thenReturn(new ObjectMapper().writeValueAsString(""));

        validateDataTransformation("orgcdc/OrgChangeData.json", orgReportingTopic);
    }

    @Test
    void testProcessMessageException() {
        String invalidPayload = "{\"payload\": {\"after\": }}";
        assertThrows(RuntimeException.class, () -> organizationService.processMessage(invalidPayload, orgReportingTopic));
    }

    @Test
    void testProcessMessageNoDataException() {
        Long organizationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"organization_uid\": \"" + organizationUid + "\"}}}";
        when(orgRepository.computeAllOrganizations(eq(String.valueOf(organizationUid)))).thenReturn(Collections.emptySet());
        assertThrows(NoDataException.class, () -> organizationService.processMessage(payload, orgReportingTopic));
    }

    private void validateDataTransformation(String changeDataFilePath, String expectedTopic) throws JsonProcessingException {
        String changeData = readFileData(changeDataFilePath);
        String expectedKey = readFileData("orgtransformed/OrgKey.json");

        organizationService.processMessage(changeData, expectedTopic);

        ArgumentCaptor<String> topicCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> valueCaptor = ArgumentCaptor.forClass(String.class);

        verify(kafkaTemplate, Mockito.times(2)).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());

        JsonNode expectedJsonNode = objectMapper.readTree(expectedKey);
        JsonNode actualJsonNode = objectMapper.readTree(keyCaptor.getValue());

        assertEquals(expectedJsonNode, actualJsonNode);
    }

}
