package gov.cdc.etldatapipeline.organization.service;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationSp;
import gov.cdc.etldatapipeline.organization.repository.OrgRepository;
import gov.cdc.etldatapipeline.organization.transformer.OrganizationTransformers;
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

import java.util.Collections;
import java.util.List;
import java.util.Set;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrganizationServiceTest {

    @InjectMocks
    private OrganizationService organizationService;

    @Mock
    private OrgRepository orgRepository;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    private AutoCloseable closeable;

    private final String orgTopic = "OrgUpdate";
    private final String orgReportingTopic = "OrgReporting";
    private final String orgElasticTopic = "OrgElastic";

    @BeforeEach
    public void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        OrganizationTransformers transformer = new OrganizationTransformers();
        organizationService = new OrganizationService(orgRepository, transformer, kafkaTemplate);
        organizationService.setOrgReportingOutputTopic(orgReportingTopic);
        organizationService.setOrgElasticSearchTopic(orgElasticTopic);
        Logger logger = (Logger) LoggerFactory.getLogger(OrganizationService.class);
        logger.setLevel(Level.ALL);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    public void tearDown() throws Exception {
        Logger logger = (Logger) LoggerFactory.getLogger(OrganizationService.class);
        logger.detachAppender(listAppender);
        closeable.close();
    }

    @Test
    void testProcessMessage() throws Exception {
        OrganizationSp orgSp = objectMapper.readValue(readFileData("orgcdc/orgSp.json"), OrganizationSp.class);
        when(orgRepository.computeAllOrganizations(anyString())).thenReturn(Set.of(orgSp));

        validateDataTransformation();
    }

    @ParameterizedTest
    @CsvSource({
            "{\"payload\": {}}",
            "{\"payload\": {\"after\": {}}}"
    })
    void testProcessMessageNoData(String payload) {
        organizationService.processMessage(payload, orgTopic);
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(0).getFormattedMessage().contains("Incoming data doesn't contain payload"));
    }

    @Test
    void testProcessMessageException() {
        String invalidPayload = "{\"payload\": {\"after\": }}";
        assertThrows(RuntimeException.class, () -> organizationService.processMessage(invalidPayload, orgTopic));
    }

    @Test
    void testProcessMessageNoDataException() {
        Long organizationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"organization_uid\": \"" + organizationUid + "\"}}}";
        when(orgRepository.computeAllOrganizations(String.valueOf(organizationUid))).thenReturn(Collections.emptySet());
        assertThrows(NoDataException.class, () -> organizationService.processMessage(payload, orgReportingTopic));
    }

    private void validateDataTransformation() throws JsonProcessingException {
        String changeData = readFileData("orgcdc/OrgChangeData.json");
        String expectedKey = readFileData("orgtransformed/OrgKey.json");

        organizationService.processMessage(changeData, orgTopic);

        ArgumentCaptor<String> topicCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> valueCaptor = ArgumentCaptor.forClass(String.class);

        verify(kafkaTemplate, Mockito.times(2)).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());

        JsonNode expectedJsonNode = objectMapper.readTree(expectedKey);
        JsonNode actualJsonNode = objectMapper.readTree(keyCaptor.getValue());

        String actualReportingTopic = topicCaptor.getAllValues().get(0);
        String actualElasticTopic = topicCaptor.getAllValues().get(1);

        assertEquals(expectedJsonNode, actualJsonNode);
        assertEquals(orgReportingTopic, actualReportingTopic);
        assertEquals(orgElasticTopic, actualElasticTopic);
    }
}
