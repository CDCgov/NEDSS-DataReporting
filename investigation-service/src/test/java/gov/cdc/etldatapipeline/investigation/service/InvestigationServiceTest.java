package gov.cdc.etldatapipeline.investigation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.investigation.repository.InterviewRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Interview;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.NotificationUpdate;
import gov.cdc.etldatapipeline.investigation.repository.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InterviewReporting;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InterviewReportingKey;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationKey;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.etldatapipeline.investigation.repository.NotificationRepository;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import org.apache.kafka.clients.consumer.MockConsumer;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.*;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

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
    private InterviewRepository interviewRepository;

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
    private final String interviewTopic = "Interview";
    private final String investigationTopicOutput = "InvestigationOutput";
    private final String notificationTopicOutput = "investigationNotification";
    private final String interviewTopicOutput = "InterviewOutput";


    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        ProcessInvestigationDataUtil transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationRepository);
        transformer.setInvestigationConfirmationOutputTopicName("investigationConfirmation");
        transformer.setInvestigationObservationOutputTopicName("investigationObservation");
        transformer.setInvestigationNotificationsOutputTopicName(notificationTopicOutput);
        transformer.setInterviewOutputTopicName(interviewTopicOutput);
        investigationService = new InvestigationService(investigationRepository, notificationRepository, interviewRepository, kafkaTemplate, transformer);
        investigationService.setPhcDatamartEnable(true);
        investigationService.setInvestigationTopic(investigationTopic);
        investigationService.setNotificationTopic(notificationTopic);
        investigationService.setInvestigationTopicReporting(investigationTopicOutput);
        investigationService.setInterviewTopic(interviewTopic);
        investigationService.setInterviewOutputTopicReporting(interviewTopicOutput);
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

    @Test
    void testProcessInterviewMessage() throws JsonProcessingException {
        Long interviewUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"interview_uid\": \"" + interviewUid + "\"}}}";

        final gov.cdc.etldatapipeline.investigation.repository.model.dto.Interview interview = constructInterview(interviewUid);
        when(interviewRepository.computeInterviews(String.valueOf(interviewUid))).thenReturn(Optional.of(interview));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        investigationService.processMessage(payload, interviewTopic, consumer);

        final InterviewReportingKey interviewReportingKey = new InterviewReportingKey();
        interviewReportingKey.setInterviewUid(interviewUid);

        final InterviewReporting interviewReportingValue = constructInvestigationInterview(interviewUid);
        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(6)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        String actualTopic = topicCaptor.getAllValues().get(0);
        String actualKey = keyCaptor.getAllValues().get(0);
        String actualValue = messageCaptor.getAllValues().get(0);


        var actualInterviewKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), InterviewReportingKey.class);
        var actualInterviewValue = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), InterviewReporting.class);

        assertEquals(interviewTopicOutput, actualTopic);
        assertEquals(interviewReportingKey, actualInterviewKey);
        assertEquals(interviewReportingValue, actualInterviewValue);

        verify(interviewRepository).computeInterviews(String.valueOf(interviewUid));
    }

    @Test
    void testProcessInterviewException() {
        String invalidPayload = "{\"payload\": {\"after\": {}}}";
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> investigationService.processMessage(invalidPayload, interviewTopic, consumer));
        assertEquals(ex.getCause().getClass(), NoSuchElementException.class);
    }

    @Test
    void testProcessInterviewNoDataException() {
        Long interviewUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"interview_uid\": \"" + interviewUid + "\"}}}";

        when(interviewRepository.computeInterviews(String.valueOf(interviewUid))).thenReturn(Optional.empty());
        assertThrows(NoDataException.class, () -> investigationService.processMessage(payload, interviewTopic, consumer));
    }


    private void validateInvestigationData(String payload, Investigation investigation) throws JsonProcessingException {

        investigationService.processMessage(payload, investigationTopic, consumer);

        InvestigationKey investigationKey = new InvestigationKey();
        investigationKey.setPublicHealthCaseUid(investigation.getPublicHealthCaseUid());
        final InvestigationReporting reportingModel = constructInvestigationReporting(investigation.getPublicHealthCaseUid());

        verify(kafkaTemplate, times(17)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualTopic = topicCaptor.getAllValues().get(14);
        String actualKey = keyCaptor.getAllValues().get(14);
        String actualValue = messageCaptor.getAllValues().get(14);

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
        investigation.setJurisdictionNm("Fulton County");
        investigation.setJurisdictionCd("130001");
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
        investigation.setInvestigationFormCd("INV_FORM_MEA");
        investigation.setOutbreakInd("Yes");
        investigation.setOutbreakName("MDK");
        investigation.setOutbreakNameDesc("Ketchup - McDonalds");
        investigation.setDetectionMethodCd("20");
        investigation.setDetectionMethodDescTxt("Screening procedure (procedure)");

        investigation.setActIds(readFileData(FILE_PATH_PREFIX + "ActIds.json"));
        investigation.setInvestigationConfirmationMethod(readFileData(FILE_PATH_PREFIX + "ConfirmationMethod.json"));
        investigation.setInvestigationObservationIds(readFileData(FILE_PATH_PREFIX + "InvestigationObservationIds.json"));
        investigation.setOrganizationParticipations(readFileData(FILE_PATH_PREFIX + "OrganizationParticipations.json"));
        investigation.setPersonParticipations(readFileData(FILE_PATH_PREFIX + "PersonParticipations.json"));
        investigation.setInvestigationCaseAnswer(readFileData(FILE_PATH_PREFIX + "InvestigationCaseAnswers.json"));
        investigation.setInvestigationNotifications(readFileData(FILE_PATH_PREFIX + "InvestigationNotification.json"));
        investigation.setInvestigationCaseCnt(readFileData(FILE_PATH_PREFIX + "CaseCountInfo.json"));
        investigation.setInvestigationCaseManagement(readFileData(FILE_PATH_PREFIX + "CaseManagement.json"));
        return investigation;
    }

    private InvestigationReporting constructInvestigationReporting(Long investigationUid) {
        final InvestigationReporting reporting = new InvestigationReporting();
        reporting.setPublicHealthCaseUid(investigationUid);
        reporting.setJurisdictionNm("Fulton County");
        reporting.setJurisdictionCd("130001");
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
        reporting.setInvestigationFormCd("INV_FORM_MEA");
        reporting.setOutbreakInd("Yes");
        reporting.setOutbreakName("MDK");
        reporting.setOutbreakNameDesc("Ketchup - McDonalds");
        reporting.setDetectionMethodCd("20");
        reporting.setDetectionMethodDescTxt("Screening procedure (procedure)");

        reporting.setInvestigatorId(32143250L);         // PersonParticipations.json, entity_id for type_cd=InvestgrOfPHC
        reporting.setPhysicianId(14253651L);            // PersonParticipations.json, entity_id for type_cd=PhysicianOfPHC
        reporting.setPatientId(321432537L);             // PersonParticipations.json, entity_id for type_cd=SubjOfPHC
        reporting.setOrganizationId(34865315L);         // OrganizationParticipations.json, entity_id for type_cd=OrgAsReporterOfPHC
        reporting.setInvStateCaseId("12-345-STA");      // ActIds.json, root_extension_txt for type_cd=STATE
        reporting.setCityCountyCaseNbr("12-345-CTY");   // ActIds.json, root_extension_txt for type_cd=CITY
        reporting.setLegacyCaseId("12-345-LGY");        // ActIds.json, root_extension_txt for type_cd=LEGACY
        reporting.setPhcInvFormId(10638298L);          // InvestigationObservationIds.json, source_act_uid for act_type_cd=PHCInvForm
        reporting.setRdbTableNameList("D_INV_CLINICAL,D_INV_ADMINISTRATIVE"); // InvestigationCaseAnswers.json, rdb_table_nm
        reporting.setInvestigationCount(1L);
        reporting.setCaseCount(1L);
        reporting.setInvestigatorAssignedDatetime("2024-01-15T10:20:57.787");
        return reporting;
    }

    private NotificationUpdate constructNotificationUpdate(Long notificationUid) {
        final NotificationUpdate notification = new NotificationUpdate();
        notification.setNotificationUid(notificationUid);
        notification.setInvestigationNotifications(readFileData(FILE_PATH_PREFIX + "InvestigationNotification.json"));
        return notification;
    }


    private Interview constructInterview(Long interviewUid) {
        Interview interview = new Interview();
        interview.setInterviewUid(interviewUid);
        interview.setInterviewDate("2024-11-11 00:00:00.000");
        interview.setInterviewStatusCd("COMPLETE");
        interview.setInterviewLocCd("C");
        interview.setInterviewTypeCd("REINTVW");
        interview.setIntervieweeRoleCd("SUBJECT");
        interview.setIxIntervieweeRole("Subject of Investigation");
        interview.setIxLocation("Clinic");
        interview.setIxStatus("Closed/Completed");
        interview.setIxType("Re-Interview");
        interview.setLastChgTime("2024-11-13 20:27:39.587");
        interview.setAddTime("2024-11-13 20:27:39.587");
        interview.setAddUserId(10055282L);
        interview.setLastChgUserId(10055282L);
        interview.setLocalId("INT10099004GA01");
        interview.setRecordStatusCd("ACTIVE");
        interview.setRecordStatusTime("2024-11-13 20:27:39.587");
        interview.setVersionCtrlNbr(1L);
        interview.setRdbCols(readFileData(FILE_PATH_PREFIX + "RdbColumns.json"));
        interview.setAnswers(readFileData(FILE_PATH_PREFIX + "InterviewAnswers.json"));
        interview.setNotes(readFileData(FILE_PATH_PREFIX + "InterviewNotes.json"));
        return interview;

    }

    private InterviewReporting constructInvestigationInterview(Long interviewUid) {
        InterviewReporting interviewReporting = new InterviewReporting();
        interviewReporting.setInterviewUid(interviewUid);
        interviewReporting.setInterviewDate("2024-11-11 00:00:00.000");
        interviewReporting.setInterviewStatusCd("COMPLETE");
        interviewReporting.setInterviewLocCd("C");
        interviewReporting.setInterviewTypeCd("REINTVW");
        interviewReporting.setIntervieweeRoleCd("SUBJECT");
        interviewReporting.setIxIntervieweeRole("Subject of Investigation");
        interviewReporting.setIxLocation("Clinic");
        interviewReporting.setIxStatus("Closed/Completed");
        interviewReporting.setIxType("Re-Interview");
        interviewReporting.setLastChgTime("2024-11-13 20:27:39.587");
        interviewReporting.setAddTime("2024-11-13 20:27:39.587");
        interviewReporting.setAddUserId(10055282L);
        interviewReporting.setLastChgUserId(10055282L);
        interviewReporting.setLocalId("INT10099004GA01");
        interviewReporting.setRecordStatusCd("ACTIVE");
        interviewReporting.setRecordStatusTime("2024-11-13 20:27:39.587");
        interviewReporting.setVersionCtrlNbr(1L);
        return interviewReporting;
    }
}