package gov.cdc.etldatapipeline.organization.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationSp;
import gov.cdc.etldatapipeline.organization.model.dto.place.*;
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
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.*;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.deserializePayload;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

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
    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();

    private final String orgTopic = "OrgUpdate";
    private final String orgReportingTopic = "OrgReporting";
    private final String orgElasticTopic = "OrgElastic";

    private final String placeTopic = "PlaceUpdate";
    private final String placeReportingTopic = "PlaceReporting";
    private final String teleReportingTopic = "TeleReporting";

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
        organizationService.setTeleOutputTopic(teleReportingTopic);

        Logger logger = (Logger) LoggerFactory.getLogger(OrganizationService.class);
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
    void testProcessOrgMessage() throws Exception {
        OrganizationSp orgSp = objectMapper.readValue(readFileData("orgcdc/orgSp.json"), OrganizationSp.class);
        when(orgRepository.computeAllOrganizations(anyString())).thenReturn(Set.of(orgSp));

        validateOrgTransformation();
    }

    @Test
    void testProcessPlaceMessage() throws Exception {
        Place place = objectMapper.readValue(readFileData("place/Place.json"), Place.class);
        when(placeRepository.computeAllPlaces(anyString())).thenReturn(Optional.of(List.of(place)));

        validatePlaceTransformation();
    }

    @Test
    void testProcessPlaceMessageNoTeleData() throws Exception {
        String payload = "{\"payload\": {\"after\": {\"place_uid\": \"10045001\"}}}";

        Place place = objectMapper.readValue(readFileData("place/Place.json"), Place.class);
        place.setPlaceTele(null);
        when(placeRepository.computeAllPlaces(anyString())).thenReturn(Optional.of(List.of(place)));

        organizationService.processMessage(payload, placeTopic);

        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());

        ILoggingEvent le = listAppender.list.get(1);
        assertEquals("PlaceTele array is null.", le.getFormattedMessage());
    }

    @ParameterizedTest
    @CsvSource({
            "{\"payload\": {}},OrgUpdate",
            "{\"payload\": {}},PlaceUpdate",
            "{\"payload\": {\"after\": {}}},OrgUpdate",
            "{\"payload\": {\"after\": {}}},PlaceUpdate",
            "{\"payload\": {\"after\": {\"place_uid\": \"123456789\"}}},PlaceUpdate"

    })
    void testProcessMessageException(String payload, String topic) {
        Class<?> expectedExceptionClass = NoSuchElementException.class;
        if (payload.contains("place_uid")) {
            when(placeRepository.computeAllPlaces(anyString())).thenReturn(Optional.of(List.of(new Place())));
            expectedExceptionClass = NullPointerException.class;
        }

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> organizationService.processMessage(payload, topic));
        assertEquals(expectedExceptionClass, ex.getCause().getClass());
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

    private void validateOrgTransformation() throws JsonProcessingException {
        String changeData = readFileData("orgcdc/OrgChangeData.json");
        String expectedKey = readFileData("orgtransformed/OrgKey.json");

        organizationService.processMessage(changeData, orgTopic);

        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());

        JsonNode expectedJsonNode = objectMapper.readTree(expectedKey);
        JsonNode actualJsonNode = objectMapper.readTree(keyCaptor.getValue());

        String actualReportingTopic = topicCaptor.getAllValues().get(0);
        String actualElasticTopic = topicCaptor.getAllValues().get(1);

        assertEquals(expectedJsonNode, actualJsonNode);
        assertEquals(orgReportingTopic, actualReportingTopic);
        assertEquals(orgElasticTopic, actualElasticTopic);
    }

    private void validatePlaceTransformation() throws JsonProcessingException {
        String payload = "{\"payload\": {\"after\": {\"place_uid\": \"10045001\"}}}";

        PlaceReporting expectedPlace = deserializePayload(
                objectMapper.readTree(readFileData("place/PlaceReporting.json")).path("payload").toString(),
                PlaceReporting.class);
        PlaceKey expectedKey = PlaceKey.builder().placeUid(10045001L).build();

        PlaceTele expectedTele = deserializePayload(
                objectMapper.readTree(readFileData("place/PlaceTele.json")).path("payload").toString(),
                PlaceTele.class);
        PlaceTeleKey expectedTeleKey = PlaceTeleKey.builder().placeTeleLocatorUid(10040080L).build();

        organizationService.processMessage(payload, placeTopic);

        verify(kafkaTemplate, times(3)).send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture());
        String actualPlaceTopic = topicCaptor.getValue();
        String actualTeleTopic = topicCaptor.getAllValues().getFirst();

        String capTeleKey = keyCaptor.getAllValues().get(1);
        String capTeleValue = valueCaptor.getAllValues().get(1);
        String capKey = keyCaptor.getValue();
        String capValue = valueCaptor.getValue();

        var actualTele = objectMapper.readValue(
                objectMapper.readTree(capTeleValue).path("payload").toString(), PlaceTele.class);
        var actualTeleKey = objectMapper.readValue(
                objectMapper.readTree(capTeleKey).path("payload").toString(), PlaceTeleKey.class);

        var actualPlace = objectMapper.readValue(
                objectMapper.readTree(capValue).path("payload").toString(), PlaceReporting.class);
        var actualPlaceKey = objectMapper.readValue(
                objectMapper.readTree(capKey).path("payload").toString(), PlaceKey.class);

        assertEquals(teleReportingTopic, actualTeleTopic);
        assertEquals(placeReportingTopic, actualPlaceTopic);
        assertEquals(expectedKey, actualPlaceKey);
        assertEquals(expectedPlace, actualPlace);
        assertEquals(expectedTeleKey, actualTeleKey);
        assertEquals(expectedTele, actualTele);

        assertNull(valueCaptor.getAllValues().getFirst()); // tombstone message
    }
}
