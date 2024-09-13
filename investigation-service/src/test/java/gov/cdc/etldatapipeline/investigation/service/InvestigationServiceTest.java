package gov.cdc.etldatapipeline.investigation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.NotificationUpdate;
import gov.cdc.etldatapipeline.investigation.repository.odse.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationKey;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.etldatapipeline.investigation.repository.odse.NotificationRepository;
import gov.cdc.etldatapipeline.investigation.repository.rdb.InvestigationCaseAnswerRepository;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import org.apache.kafka.clients.consumer.MockConsumer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.*;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class InvestigationServiceTest {

    @InjectMocks
    private InvestigationService investigationService;

    @Mock
    private InvestigationRepository investigationRepository;

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private InvestigationCaseAnswerRepository investigationCaseAnswerRepository;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Mock
    MockConsumer<String, String> consumer;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private AutoCloseable closeable;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final String FILE_PATH_PREFIX = "rawDataFiles/";
    private final String investigationTopic = "Investigation";
    private final String notificationTopic = "Notification";
    private final String investigationTopicOutput = "InvestigationOutput";
    private final String notificationTopicOutput = "investigationNotification";

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        ProcessInvestigationDataUtil transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationCaseAnswerRepository, investigationRepository);
        transformer.setInvestigationConfirmationOutputTopicName("investigationConfirmation");
        transformer.setInvestigationObservationOutputTopicName("investigationObservation");
        transformer.setInvestigationNotificationsOutputTopicName(notificationTopicOutput);
        investigationService = new InvestigationService(investigationRepository, notificationRepository, kafkaTemplate, transformer);
        investigationService.setPhcDatamartEnable(true);
        investigationService.setInvestigationTopic(investigationTopic);
        investigationService.setNotificationTopic(notificationTopic);
        investigationService.setInvestigationTopicReporting(investigationTopicOutput);
    }

    @AfterEach
    void tearDown() throws Exception {
        closeable.close();
    }

    @Test
    void testProcessInvestigationMessage() throws JsonProcessingException {
        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\"}}}";

        final Investigation investigation = constructInvestigation(investigationUid);
        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.of(investigation));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        validateInvestigationData(payload, investigation);

        verify(investigationRepository).computeInvestigations(String.valueOf(investigationUid));
        verify(investigationRepository).populatePhcFact(String.valueOf(investigationUid));
    }

    @Test
    void testProcessInvestigationException() {
        String invalidPayload = "{\"payload\": {\"after\": }}";
        assertThrows(RuntimeException.class, () -> investigationService.processMessage(invalidPayload, investigationTopic, consumer));
    }

    @Test
    void testProcessInvestigationNoDataException() {
        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\"}}}";

        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.empty());
        assertThrows(NoDataException.class, () -> investigationService.processMessage(payload, investigationTopic, consumer));
    }

    @Test
    void testProcessNotificationMessage() {
        Long notificationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";

        final NotificationUpdate notification = constructNotificationUpdate(notificationUid);
        when(notificationRepository.computeNotifications(String.valueOf(notificationUid))).thenReturn(Optional.of(notification));
        investigationService.processMessage(payload, notificationTopic, consumer);

        verify(notificationRepository).computeNotifications(String.valueOf(notificationUid));
        verify(kafkaTemplate).send(topicCaptor.capture(), anyString(), anyString());
        assertEquals(notificationTopicOutput, topicCaptor.getValue());
    }

    @Test
    void testProcessNotificationException() {
        String invalidPayload = "{\"payload\": {\"after\": {}}}";
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> investigationService.processMessage(invalidPayload, notificationTopic, consumer));
        assertEquals(ex.getCause().getClass(), NoSuchElementException.class);
    }

    @Test
    void testProcessNotificationNoDataException() {
        Long notificationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";

        when(investigationRepository.computeInvestigations(String.valueOf(notificationUid))).thenReturn(Optional.empty());
        assertThrows(NoDataException.class, () -> investigationService.processMessage(payload, notificationTopic, consumer));
    }

    private void validateInvestigationData(String payload, Investigation investigation) throws JsonProcessingException {

        investigationService.processMessage(payload, investigationTopic, consumer);

        InvestigationKey investigationKey = new InvestigationKey();
        investigationKey.setPublicHealthCaseUid(investigation.getPublicHealthCaseUid());
        final InvestigationReporting reportingModel = constructInvestigationReporting(investigation.getPublicHealthCaseUid());

        verify(kafkaTemplate, times(5)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualTopic = topicCaptor.getAllValues().get(3);
        String actualKey = keyCaptor.getAllValues().get(3);
        String actualValue = messageCaptor.getAllValues().get(3);

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), InvestigationReporting.class);
        var actualInvestigationKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), InvestigationKey.class);

        assertEquals(investigationTopicOutput, actualTopic); // investigation topic
        assertEquals(investigationKey, actualInvestigationKey);
        assertEquals(reportingModel, actualReporting);
    }

    private Investigation constructInvestigation(Long investigationUid) {
        Investigation investigation = new Investigation();
        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setJurisdictionCode("130001");
        investigation.setJurisdictionNm("Fulton County");
        investigation.setInvestigationStatus("Open");
        investigation.setClassCd("CASE");
        investigation.setInvCaseStatus("Confirmed");
        investigation.setCd("10110");
        investigation.setCdDescTxt("Hepatitis A, acute");
        investigation.setProgAreaCd("HEP");
        investigation.setLocalId("CAS10107171GA01");
        investigation.setPatAgeAtOnset("50");
        investigation.setRecordStatusCd("ACTIVE");
        investigation.setMmwrWeek("22");
        investigation.setMmwrYear("2024");

        investigation.setActIds(readFileData(FILE_PATH_PREFIX + "ActIds.json"));
        investigation.setInvestigationConfirmationMethod(readFileData(FILE_PATH_PREFIX + "ConfirmationMethod.json"));
        investigation.setObservationNotificationIds(readFileData(FILE_PATH_PREFIX + "ObservationNotificationIds.json"));
        investigation.setOrganizationParticipations(readFileData(FILE_PATH_PREFIX + "OrganizationParticipations.json"));
        investigation.setPersonParticipations(readFileData(FILE_PATH_PREFIX + "PersonParticipations.json"));
        investigation.setInvestigationCaseAnswer(readFileData(FILE_PATH_PREFIX + "InvestigationCaseAnswers.json"));
        investigation.setInvestigationNotifications(readFileData(FILE_PATH_PREFIX + "InvestigationNotification.json"));
        return investigation;
    }

    private InvestigationReporting constructInvestigationReporting(Long investigationUid) {
        final InvestigationReporting reporting = new InvestigationReporting();
        reporting.setPublicHealthCaseUid(investigationUid);
        reporting.setJurisdictionCode("130001");
        reporting.setJurisdictionNm("Fulton County");
        reporting.setInvestigationStatus("Open");
        reporting.setClassCd("CASE");
        reporting.setInvCaseStatus("Confirmed");
        reporting.setCd("10110");
        reporting.setCdDescTxt("Hepatitis A, acute");
        reporting.setProgAreaCd("HEP");
        reporting.setLocalId("CAS10107171GA01");
        reporting.setPatAgeAtOnset("50");
        reporting.setRecordStatusCd("ACTIVE");
        reporting.setMmwrWeek("22");
        reporting.setMmwrYear("2024");

        reporting.setInvestigatorId(32143250L);         // PersonParticipations.json, entity_id for type_cd=InvestgrOfPHC
        reporting.setPhysicianId(14253651L);            // PersonParticipations.json, entity_id for type_cd=PhysicianOfPHC
        reporting.setPatientId(321432537L);             // PersonParticipations.json, entity_id for type_cd=SubjOfPHC
        reporting.setOrganizationId(34865315L);         // OrganizationParticipations.json, entity_id for type_cd=OrgAsReporterOfPHC
        reporting.setInvStateCaseId("12-345-STA");      // ActIds.json, root_extension_txt for type_cd=STATE
        reporting.setCityCountyCaseNbr("12-345-CTY");   // ActIds.json, root_extension_txt for type_cd=CITY
        reporting.setLegacyCaseId("12-345-LGY");        // ActIds.json, root_extension_txt for type_cd=LEGACY
        reporting.setPhcInvFormId(263748598L);          // ObservationNotificationIds.json, source_act_uid for act_type_cd=PHCInvForm
        reporting.setRdbTableNameList("D_INV_CLINICAL,D_INV_ADMINISTRATIVE"); // InvestigationCaseAnswers.json, rdb_table_nm
        return reporting;
    }

    private NotificationUpdate constructNotificationUpdate(Long notificationUid) {
        final NotificationUpdate notification = new NotificationUpdate();
        notification.setNotificationUid(notificationUid);
        notification.setInvestigationNotifications(readFileData(FILE_PATH_PREFIX + "InvestigationNotification.json"));
        return notification;
    }
}