package gov.cdc.nbs.report.pipeline.organization.service;

import static gov.cdc.nbs.report.pipeline.util.TestUtils.readFileData;
import static gov.cdc.nbs.report.pipeline.util.UtilHelper.deserializePayload;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.nbs.report.pipeline.config.EventProcedureLoggingProperties;
import gov.cdc.nbs.report.pipeline.organization.model.dto.org.OrganizationSp;
import gov.cdc.nbs.report.pipeline.organization.model.dto.place.*;
import gov.cdc.nbs.report.pipeline.organization.repository.OrgRepository;
import gov.cdc.nbs.report.pipeline.organization.repository.PlaceRepository;
import gov.cdc.nbs.report.pipeline.organization.transformer.DataTransformers;
import gov.cdc.nbs.report.pipeline.util.NoDataException;
import gov.cdc.nbs.report.pipeline.util.kafka.RetryTopicResolver;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.TimeUnit;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.KafkaHeaders;

@ExtendWith(MockitoExtension.class)
class OrganizationServiceTest {

  @InjectMocks private OrganizationService organizationService;

  @Mock private OrgRepository orgRepository;

  @Mock private PlaceRepository placeRepository;

  @Mock private KafkaTemplate<String, String> kafkaTemplate;

  @Captor private ArgumentCaptor<String> topicCaptor;

  @Captor private ArgumentCaptor<String> keyCaptor;

  @Captor private ArgumentCaptor<String> valueCaptor;

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
  void setUp() {
    closeable = MockitoAnnotations.openMocks(this);
    organizationService = createOrganizationService(false);

    Logger logger = (Logger) LoggerFactory.getLogger(OrganizationService.class);
    listAppender.start();
    logger.addAppender(listAppender);
  }

  private OrganizationService createOrganizationService(boolean debugLogging) {
    OrganizationService service =
        new OrganizationService(
            orgRepository,
            placeRepository,
            new EventProcedureLoggingProperties(debugLogging),
            new DataTransformers(),
            kafkaTemplate,
            new RetryTopicResolver(),
            new CustomMetrics(new SimpleMeterRegistry()));
    service.setOrgTopic(orgTopic);
    service.setPlaceTopic(placeTopic);
    service.setOrgReportingOutputTopic(orgReportingTopic);
    service.setOrgElasticSearchTopic(orgElasticTopic);
    service.setPlaceReportingOutputTopic(placeReportingTopic);
    service.setTeleOutputTopic(teleReportingTopic);
    service.setElasticSearchEnable(true);
    service.setPhcDatamartEnable(true);
    service.setThreadPoolSize(1);
    service.initMetrics();
    return service;
  }

  @AfterEach
  void tearDown() throws Exception {
    Logger logger = (Logger) LoggerFactory.getLogger(OrganizationService.class);
    logger.detachAppender(listAppender);
    closeable.close();
  }

  @Test
  void passesEnabledLoggingToOrganizationRepository() throws Exception {
    OrganizationSp orgSp =
        objectMapper.readValue(
            readFileData("rawDataFiles/organization/orgSp.json"), OrganizationSp.class);
    when(orgRepository.computeAllOrganizations(anyString(), Mockito.eq(true)))
        .thenReturn(Set.of(orgSp));

    organizationService = createOrganizationService(true);
    organizationService.processMessage(
        record(readFileData("rawDataFiles/organization/OrgChangeData.json"), orgTopic));

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(() -> verify(orgRepository).computeAllOrganizations("10036000", true));
  }

  @Test
  void testProcessOrgMessage() throws Exception {
    OrganizationSp orgSp =
        objectMapper.readValue(
            readFileData("rawDataFiles/organization/orgSp.json"), OrganizationSp.class);
    when(orgRepository.computeAllOrganizations(anyString(), Mockito.eq(false)))
        .thenReturn(Set.of(orgSp));

    validateOrgTransformation();
    verify(orgRepository).updatePhcFact("ORG", "10036000");
  }

  @Test
  void testProcessOrgMessageNoElasticSearch() {
    OrganizationSp orgSp = new OrganizationSp();
    orgSp.setOrganizationUid(10036000L);
    when(orgRepository.computeAllOrganizations(anyString(), Mockito.eq(false)))
        .thenReturn(Set.of(orgSp));

    String changeData = readFileData("rawDataFiles/organization/OrgChangeData.json");

    organizationService.setElasticSearchEnable(false);
    organizationService.processMessage(record(changeData, orgTopic));

    // verify that only one message was sent
    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate)
                    .send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture()));

    String actualTopic = topicCaptor.getValue();
    assertEquals(orgReportingTopic, actualTopic);
  }

  @Test
  void testProcessPlaceMessage() throws Exception {
    Place place =
        objectMapper.readValue(readFileData("rawDataFiles/organization/Place.json"), Place.class);
    when(placeRepository.computeAllPlaces(anyString(), Mockito.eq(false)))
        .thenReturn(Optional.of(List.of(place)));

    validatePlaceTransformation();
  }

  @Test
  void testProcessPlaceMessageNoTeleData() throws Exception {
    String payload = "{\"payload\": {\"after\": {\"place_uid\": \"10045001\"}}}";

    Place place =
        objectMapper.readValue(readFileData("rawDataFiles/organization/Place.json"), Place.class);
    place.setPlaceTele(null);
    when(placeRepository.computeAllPlaces(anyString(), Mockito.eq(false)))
        .thenReturn(Optional.of(List.of(place)));

    organizationService.processMessage(record(payload, placeTopic));

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate, times(2))
                    .send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture()));

    ILoggingEvent le = listAppender.list.get(1);
    assertEquals("PlaceTele array is null.", le.getFormattedMessage());
  }

  @ParameterizedTest
  @ValueSource(strings = {"OrgUpdate_retry-0", "OrgUpdate_retry-1"})
  void testProcessOrganizationRetryMessage(String retryTopic) {
    OrganizationSp organization = new OrganizationSp();
    organization.setOrganizationUid(10036000L);
    when(orgRepository.computeAllOrganizations("10036000", false)).thenReturn(Set.of(organization));
    organizationService.setElasticSearchEnable(false);
    organizationService.setPhcDatamartEnable(false);

    CompletableFuture<Void> future =
        organizationService.processMessage(
            retryRecord(
                readFileData("rawDataFiles/organization/OrgChangeData.json"),
                retryTopic,
                orgTopic));
    future.join();

    verify(orgRepository).computeAllOrganizations("10036000", false);
    verifyNoInteractions(placeRepository);
  }

  @ParameterizedTest
  @ValueSource(strings = {"PlaceUpdate_retry-0", "PlaceUpdate_retry-1"})
  void testProcessPlaceRetryMessage(String retryTopic) throws JsonProcessingException {
    String payload = "{\"payload\": {\"after\": {\"place_uid\": \"10045001\"}}}";
    Place place =
        objectMapper.readValue(readFileData("rawDataFiles/organization/Place.json"), Place.class);
    when(placeRepository.computeAllPlaces("10045001", false))
        .thenReturn(Optional.of(List.of(place)));

    CompletableFuture<Void> future =
        organizationService.processMessage(retryRecord(payload, retryTopic, placeTopic));
    future.join();

    verify(placeRepository).computeAllPlaces("10045001", false);
    verifyNoInteractions(orgRepository);
  }

  @Test
  void testProcessMessageRejectsUnknownOriginalTopic() {
    ConsumerRecord<String, String> retryRecord =
        retryRecord(null, "OrgUpdate_retry-0", "unknownTopic");

    CompletableFuture<Void> future = organizationService.processMessage(retryRecord);

    CompletionException exception = assertThrows(CompletionException.class, future::join);
    assertEquals(NoSuchElementException.class, exception.getCause().getCause().getClass());
    verifyNoInteractions(orgRepository, placeRepository);
  }

  @ParameterizedTest
  @CsvSource({
    "{\"payload\": {}},SomeUpdate",
    "{\"payload\": {}},OrgUpdate",
    "{\"payload\": {}},PlaceUpdate",
    "{\"payload\": {\"after\": {}}},OrgUpdate",
    "{\"payload\": {\"after\": {}}},PlaceUpdate",
    "{\"payload\": {\"after\": {\"place_uid\": \"123456789\"}}},PlaceUpdate"
  })
  void testProcessMessageException(String payload, String topic) {
    Class<?> expectedExceptionClass = NoSuchElementException.class;
    if (payload.contains("place_uid")) {
      when(placeRepository.computeAllPlaces(anyString(), Mockito.eq(false)))
          .thenReturn(Optional.of(List.of(new Place())));
      expectedExceptionClass = NullPointerException.class;
    }

    CompletableFuture<Void> future = organizationService.processMessage(record(payload, topic));
    CompletionException ex = assertThrows(CompletionException.class, future::join);
    assertEquals(expectedExceptionClass, ex.getCause().getCause().getClass());
  }

  @ParameterizedTest
  @CsvSource({
    "{\"payload\": {\"after\": {\"organization_uid\": \"123456789\"}}},OrgUpdate",
    "{\"payload\": {\"after\": {\"place_uid\": \"123456789\"}}},PlaceUpdate"
  })
  void testProcessMessageNoDataException(String payload, String inputTopic) {
    if (inputTopic.equals(orgTopic)) {
      Long organizationUid = 123456789L;
      when(orgRepository.computeAllOrganizations(String.valueOf(organizationUid), false))
          .thenReturn(Collections.emptySet());
    } else if (inputTopic.equals(placeTopic)) {
      Long placeUid = 123456789L;
      when(placeRepository.computeAllPlaces(String.valueOf(placeUid), false))
          .thenReturn(Optional.of(Collections.emptyList()));
    }
    CompletableFuture<Void> future =
        organizationService.processMessage(record(payload, inputTopic));

    CompletionException ex = assertThrows(CompletionException.class, future::join);
    assertEquals(NoDataException.class, ex.getCause().getClass());
  }

  @Test
  void testProcessPhcFactDatamartException() {
    final String ERROR_MSG = "Test Error";

    doThrow(new RuntimeException(ERROR_MSG))
        .when(orgRepository)
        .updatePhcFact(anyString(), anyString());
    organizationService.processPhcFactDatamart("123");
    ILoggingEvent log = listAppender.list.getLast();
    assertTrue(log.getFormattedMessage().contains(ERROR_MSG));
  }

  @Test
  void testProcessPhcFactDatamartDisabled() {
    OrganizationSp orgSp = new OrganizationSp();
    orgSp.setOrganizationUid(10036000L);

    String changeData = "{\"payload\": {\"after\": {\"organization_uid\": \"123456789\"}}}";
    organizationService.setPhcDatamartEnable(false);
    organizationService.processMessage(record(changeData, orgTopic));

    verify(orgRepository, never()).updatePhcFact(anyString(), anyString());
  }

  private void validateOrgTransformation() throws JsonProcessingException {
    String changeData = readFileData("rawDataFiles/organization/OrgChangeData.json");
    String expectedKey = readFileData("rawDataFiles/organization/OrgKey.json");

    organizationService.processMessage(record(changeData, orgTopic));

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate, times(2))
                    .send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture()));

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

    PlaceReporting expectedPlace =
        deserializePayload(
            objectMapper
                .readTree(readFileData("rawDataFiles/organization/PlaceReporting.json"))
                .path("payload")
                .toString(),
            PlaceReporting.class);
    PlaceKey expectedKey = PlaceKey.builder().placeUid(10045001L).build();

    PlaceTele expectedTele =
        deserializePayload(
            objectMapper
                .readTree(readFileData("rawDataFiles/organization/PlaceTele.json"))
                .path("payload")
                .toString(),
            PlaceTele.class);
    PlaceTeleKey expectedTeleKey = PlaceTeleKey.builder().placeTeleLocatorUid(10040080L).build();

    organizationService.processMessage(record(payload, placeTopic));

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate, times(3))
                    .send(topicCaptor.capture(), keyCaptor.capture(), valueCaptor.capture()));
    String actualPlaceTopic = topicCaptor.getValue();
    String actualTeleTopic = topicCaptor.getAllValues().getFirst();

    String capTeleKey = keyCaptor.getAllValues().get(1);
    String capTeleValue = valueCaptor.getAllValues().get(1);
    String capKey = keyCaptor.getValue();
    String capValue = valueCaptor.getValue();

    var actualTele =
        objectMapper.readValue(
            objectMapper.readTree(capTeleValue).path("payload").toString(), PlaceTele.class);
    var actualTeleKey =
        objectMapper.readValue(
            objectMapper.readTree(capTeleKey).path("payload").toString(), PlaceTeleKey.class);

    var actualPlace =
        objectMapper.readValue(
            objectMapper.readTree(capValue).path("payload").toString(), PlaceReporting.class);
    var actualPlaceKey =
        objectMapper.readValue(
            objectMapper.readTree(capKey).path("payload").toString(), PlaceKey.class);

    assertEquals(teleReportingTopic, actualTeleTopic);
    assertEquals(placeReportingTopic, actualPlaceTopic);
    assertEquals(expectedKey, actualPlaceKey);
    assertEquals(expectedPlace, actualPlace);
    assertEquals(expectedTeleKey, actualTeleKey);
    assertEquals(expectedTele, actualTele);

    assertNull(valueCaptor.getAllValues().getFirst()); // tombstone message
  }

  private ConsumerRecord<String, String> record(String payload, String topic) {
    return new ConsumerRecord<>(topic, 0, 11L, null, payload);
  }

  private ConsumerRecord<String, String> retryRecord(
      String payload, String retryTopic, String originalTopic) {
    ConsumerRecord<String, String> record = record(payload, retryTopic);
    record
        .headers()
        .add(KafkaHeaders.ORIGINAL_TOPIC, originalTopic.getBytes(StandardCharsets.UTF_8));
    return record;
  }
}
