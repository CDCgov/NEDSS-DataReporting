package gov.cdc.etldatapipeline.organization.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationSp;
import gov.cdc.etldatapipeline.organization.model.dto.place.Place;
import gov.cdc.etldatapipeline.organization.model.dto.place.PlaceKey;
import gov.cdc.etldatapipeline.organization.model.dto.place.PlaceReporting;
import gov.cdc.etldatapipeline.organization.repository.OrgRepository;
import gov.cdc.etldatapipeline.organization.repository.PlaceRepository;
import gov.cdc.etldatapipeline.organization.transformer.DataTransformers;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.*;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.deserializePayload;
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
    private PlaceRepository placeRepository;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> valueCaptor;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private AutoCloseable closeable;

    private final String orgTopic = "OrgUpdate";
    private final String orgReportingTopic = "OrgReporting";
    private final String orgElasticTopic = "OrgElastic";

    private final String placeTopic = "PlaceUpdate";
    private final String placeReportingTopic = "PlaceReporting";

    @BeforeEach
    public void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        DataTransformers transformer = new DataTransformers();
        organizationService = new OrganizationService(orgRepository, placeRepository, transformer, kafkaTemplate);
        organizationService.setOrgTopic(orgTopic);
        organizationService.setPlaceTopic(placeTopic);
        organizationService.setOrgReportingOutputTopic(orgReportingTopic);
        organizationService.setOrgElasticSearchTopic(orgElasticTopic);
        organizationService.setPlaceReportingOutputTopic(placeReportingTopic);
    }

    @AfterEach
    public void tearDown() throws Exception {
        closeable.close();
    }

    @Test
    void testProcessOrgMessage() throws Exception {
        OrganizationSp orgSp = objectMapper.readValue(readFileData("orgcdc/orgSp.json"), OrganizationSp.class);
        when(orgRepository.computeAllOrganizations(anyString())).thenReturn(Set.of(orgSp));

        validateDataTransformation();
    }

    @Test
    void testProcessPlaceMessage() throws Exception {
        String payload = "{\"payload\": {\"after\": {\"place_uid\": \"10045001\"}}}";

        Place place = objectMapper.readValue(readFileData("place/Place.json"), Place.class);
        when(placeRepository.computeAllPlaces(anyString())).thenReturn(Optional.of(List.of(place)));

        PlaceReporting expectedPlace = deserializePayload(
                objectMapper.readTree(readFileData("place/PlaceReporting.json")).path("payload").toString(),
                PlaceReporting.class);
        PlaceKey expectedKey = PlaceKey.builder().placeUid(10045001L).build();

        organizationService.processMessage(payload, placeTopic);

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());
        String actualTopic = topicCaptor.getValue();
        String actualKey = keyCaptor.getValue();
        String actualValue = valueCaptor.getValue();

        var actualPlace = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), PlaceReporting.class);
        var actualPlaceKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), PlaceKey.class);

        assertEquals(placeReportingTopic, actualTopic);
        assertEquals(expectedKey, actualPlaceKey);
        assertEquals(expectedPlace, actualPlace);
    }

    @ParameterizedTest
    @CsvSource({
            "{\"payload\": {}},OrgUpdate",
            "{\"payload\": {}},PlaceUpdate",
            "{\"payload\": {\"after\": {}}},OrgUpdate",
            "{\"payload\": {\"after\": {}}},PlaceUpdate"

    })
    void testProcessMessageException(String payload, String topic) {
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> organizationService.processMessage(payload, topic));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @ParameterizedTest
    @CsvSource({
            "{\"payload\": {\"after\": {\"organization_uid\": \"123456789\"}}},OrgUpdate",
            "{\"payload\": {\"after\": {\"place_uid\": \"123456789\"}}},PlaceUpdate"
    })
    void testProcessMessageNoDataException(String payload, String inputTopic) {
        if (inputTopic.equals(orgTopic)) {
            Long organizationUid = 123456789L;
            when(orgRepository.computeAllOrganizations(String.valueOf(organizationUid))).thenReturn(Collections.emptySet());
        } else if (inputTopic.equals(placeTopic)) {
            Long placeUid = 123456789L;
            when(placeRepository.computeAllPlaces(String.valueOf(placeUid))).thenReturn(Optional.of(Collections.emptyList()));
        }
        assertThrows(NoDataException.class, () -> organizationService.processMessage(payload, inputTopic));
    }

    private void validateDataTransformation() throws JsonProcessingException {
        String changeData = readFileData("orgcdc/OrgChangeData.json");
        String expectedKey = readFileData("orgtransformed/OrgKey.json");

        organizationService.processMessage(changeData, orgTopic);

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
