package gov.cdc.etldatapipeline.investigation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.investigation.repository.ContactRepository;
import gov.cdc.etldatapipeline.investigation.repository.InterviewRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Contact;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Interview;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.NotificationUpdate;
import gov.cdc.etldatapipeline.investigation.repository.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.*;
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
    private ContactRepository contactRepository;

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
    //input topics
    private final String investigationTopic = "Investigation";
    private final String notificationTopic = "Notification";
    private final String interviewTopic = "Interview";
    private final String contactTopic = "Contact";
    //output topics
    private final String investigationTopicOutput = "InvestigationOutput";
    private final String notificationTopicOutput = "investigationNotification";
    private final String interviewTopicOutput = "InterviewOutput";
    private final String contactTopicOutput = "ContactOutput";


    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        ProcessInvestigationDataUtil transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationRepository);

        investigationService = new InvestigationService(investigationRepository, notificationRepository, interviewRepository, contactRepository, kafkaTemplate, transformer);

        investigationService.setPhcDatamartEnable(true);
        investigationService.setInvestigationTopic(investigationTopic);
        investigationService.setNotificationTopic(notificationTopic);
        investigationService.setInvestigationTopicReporting(investigationTopicOutput);
        investigationService.setInterviewTopic(interviewTopic);
        investigationService.setContactTopic(contactTopic);

        transformer.setInvestigationConfirmationOutputTopicName("investigationConfirmation");
        transformer.setInvestigationObservationOutputTopicName("investigationObservation");
        transformer.setInvestigationNotificationsOutputTopicName(notificationTopicOutput);
        transformer.setInterviewOutputTopicName(interviewTopicOutput);
        transformer.setContactOutputTopicName(contactTopicOutput);
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

    @Test
    void testProcessContactMessage() throws JsonProcessingException {
        Long contactUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"ct_contact_uid\": \"" + contactUid + "\"}}}";

        final Contact contact = constructContact(contactUid);
        when(contactRepository.computeContact(String.valueOf(contactUid))).thenReturn(Optional.of(contact));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        investigationService.processMessage(payload, contactTopic, consumer);

        final  ContactReportingKey contactReportingKey = new ContactReportingKey();
        contactReportingKey.setContactUid(contactUid);

        final ContactReporting  contactReportingValue = constructContactReporting(contactUid);

        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(3)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        String actualTopic = topicCaptor.getAllValues().get(0);
        String actualKey = keyCaptor.getAllValues().get(0);
        String actualValue = messageCaptor.getAllValues().get(0);


        var actualContactKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), ContactReportingKey.class);
        var actualContactValue = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), ContactReporting.class);

        assertEquals(contactTopicOutput, actualTopic);
        assertEquals(contactReportingKey, actualContactKey);
        assertEquals(contactReportingValue, actualContactValue);

        verify(contactRepository).computeContact(String.valueOf(contactUid));
    }

    @Test
    void testProcessContactException() {
        String invalidPayload = "{\"payload\": {\"after\": {}}}";
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> investigationService.processMessage(invalidPayload, contactTopic, consumer));
        assertEquals(ex.getCause().getClass(), NoSuchElementException.class);
    }

    @Test
    void testProcessContactNoDataException() {
        String payload = "{\"payload\": {\"after\": {\"ct_contact_uid\": \"\"}}}";
        assertThrows(NoDataException.class, () -> investigationService.processMessage(payload, contactTopic, consumer));
    }

    private void validateInvestigationData(String payload, Investigation investigation) throws JsonProcessingException {

        investigationService.processMessage(payload, investigationTopic, consumer);

        InvestigationKey investigationKey = new InvestigationKey();
        investigationKey.setPublicHealthCaseUid(investigation.getPublicHealthCaseUid());
        final InvestigationReporting reportingModel = constructInvestigationReporting(investigation.getPublicHealthCaseUid());

        verify(kafkaTemplate, times(18)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualTopic = topicCaptor.getAllValues().get(15);
        String actualKey = keyCaptor.getAllValues().get(15);
        String actualValue = messageCaptor.getAllValues().get(15);

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
        reporting.setRdbTableNameList("D_INV_CLINICAL,D_INV_PLACE_REPEAT,D_INV_ADMINISTRATIVE"); // InvestigationCaseAnswers.json, rdb_table_nm
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

    private Contact constructContact(Long contactUid) {
        Contact contact = new Contact();
        contact.setContactUid(contactUid);
        contact.setAddTime("2024-01-01T10:00:00");
        contact.setAddUserId(100L);
        contact.setContactEntityEpiLinkId("EPI123");
        contact.setCttReferralBasis("Referral");
        contact.setCttStatus("Active");
        contact.setCttDispoDt("2024-01-10");
        contact.setCttDisposition("Completed");
        contact.setCttEvalCompleted("Yes");
        contact.setCttEvalDt("2024-01-05");
        contact.setCttEvalNotes("Evaluation completed successfully.");
        contact.setCttGroupLotId("LOT123");
        contact.setCttHealthStatus("Good");
        contact.setCttInvAssignedDt("2024-01-02");
        contact.setCttJurisdictionNm("JurisdictionA");
        contact.setCttNamedOnDt("2024-01-03");
        contact.setCttNotes("General notes.");
        contact.setCttPriority("High");
        contact.setCttProcessingDecision("Approved");
        contact.setCttProgramArea("ProgramX");
        contact.setCttRelationship("Close Contact");
        contact.setCttRiskInd("Low");
        contact.setCttRiskNotes("Minimal risk identified.");
        contact.setCttSharedInd("Yes");
        contact.setCttSympInd("No");
        contact.setCttSympNotes("No symptoms reported.");
        contact.setCttSympOnsetDt(null);
        contact.setCttTrtCompleteInd("Yes");
        contact.setCttTrtEndDt("2024-02-01");
        contact.setCttTrtInitiatedInd("Yes");
        contact.setCttTrtNotCompleteRsn(null);
        contact.setCttTrtNotStartRsn(null);
        contact.setCttTrtNotes("Treatment completed successfully.");
        contact.setCttTrtStartDt("2024-01-15");
        contact.setLastChgTime("2024-02-05T12:00:00");
        contact.setLastChgUserId(200L);
        contact.setLocalId("LOC456");
        contact.setProgramJurisdictionOid(300L);
        contact.setRecordStatusCd("Active");
        contact.setRecordStatusTime("2024-02-06T08:00:00");
        contact.setSubjectEntityEpiLinkId("EPI456");
        contact.setVersionCtrlNbr(1L);
        contact.setContactExposureSiteUid(123L);
        contact.setProviderContactInvestigatorUid(1234L);
        contact.setDispositionedByUid(123L);
        contact.setRdbCols(readFileData(FILE_PATH_PREFIX + "RdbColumns.json"));
        contact.setAnswers(readFileData(FILE_PATH_PREFIX + "ContactAnswers.json"));
        return contact;
    }

    private ContactReporting constructContactReporting(Long contactUid) {
        ContactReporting contactReporting = new ContactReporting();
        contactReporting.setContactUid(contactUid);
        contactReporting.setAddTime("2024-01-01T10:00:00");
        contactReporting.setAddUserId(100L);
        contactReporting.setContactEntityEpiLinkId("EPI123");
        contactReporting.setCttReferralBasis("Referral");
        contactReporting.setCttStatus("Active");
        contactReporting.setCttDispoDt("2024-01-10");
        contactReporting.setCttDisposition("Completed");
        contactReporting.setCttEvalCompleted("Yes");
        contactReporting.setCttEvalDt("2024-01-05");
        contactReporting.setCttEvalNotes("Evaluation completed successfully.");
        contactReporting.setCttGroupLotId("LOT123");
        contactReporting.setCttHealthStatus("Good");
        contactReporting.setCttInvAssignedDt("2024-01-02");
        contactReporting.setCttJurisdictionNm("JurisdictionA");
        contactReporting.setCttNamedOnDt("2024-01-03");
        contactReporting.setCttNotes("General notes.");
        contactReporting.setCttPriority("High");
        contactReporting.setCttProcessingDecision("Approved");
        contactReporting.setCttProgramArea("ProgramX");
        contactReporting.setCttRelationship("Close Contact");
        contactReporting.setCttRiskInd("Low");
        contactReporting.setCttRiskNotes("Minimal risk identified.");
        contactReporting.setCttSharedInd("Yes");
        contactReporting.setCttSympInd("No");
        contactReporting.setCttSympNotes("No symptoms reported.");
        contactReporting.setCttSympOnsetDt(null);
        contactReporting.setCttTrtCompleteInd("Yes");
        contactReporting.setCttTrtEndDt("2024-02-01");
        contactReporting.setCttTrtInitiatedInd("Yes");
        contactReporting.setCttTrtNotCompleteRsn(null);
        contactReporting.setCttTrtNotStartRsn(null);
        contactReporting.setCttTrtNotes("Treatment completed successfully.");
        contactReporting.setCttTrtStartDt("2024-01-15");
        contactReporting.setLastChgTime("2024-02-05T12:00:00");
        contactReporting.setLastChgUserId(200L);
        contactReporting.setLocalId("LOC456");
        contactReporting.setProgramJurisdictionOid(300L);
        contactReporting.setRecordStatusCd("Active");
        contactReporting.setRecordStatusTime("2024-02-06T08:00:00");
        contactReporting.setSubjectEntityEpiLinkId("EPI456");
        contactReporting.setVersionCtrlNbr(1L);
        contactReporting.setContactExposureSiteUid(123L);
        contactReporting.setProviderContactInvestigatorUid(1234L);
        contactReporting.setDispositionedByUid(123L);
        return contactReporting;
    }

}