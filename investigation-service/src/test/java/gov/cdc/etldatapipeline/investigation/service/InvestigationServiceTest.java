package gov.cdc.etldatapipeline.investigation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.investigation.repository.odse.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.InvestigationKey;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.etldatapipeline.investigation.repository.rdb.InvestigationCaseAnswerRepository;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.Optional;
import java.util.concurrent.CompletableFuture;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class InvestigationServiceTest {

    @Mock
    private InvestigationRepository investigationRepository;

    @Mock
    private InvestigationCaseAnswerRepository investigationCaseAnswerRepository;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private AutoCloseable closeable;

    private ProcessInvestigationDataUtil transformer;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationCaseAnswerRepository);
        transformer.setInvestigationConfirmationOutputTopicName("investigationConfirmation");
        transformer.setInvestigationObservationOutputTopicName("investigationObservation");
        transformer.setInvestigationNotificationsOutputTopicName("investigationNotification");
    }

    @AfterEach
    void tearDown() throws Exception {
        closeable.close();
    }

    @Test
    void testProcessMessage() throws JsonProcessingException {
        String investigationTopic = "Investigation";
        String investigationTopicOutput = "InvestigationOutput";

        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\"}}}";

        final Investigation investigation = constructInvestigation(investigationUid);
        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.of(investigation));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        validateData(investigationTopic, investigationTopicOutput, payload, investigation);

        verify(investigationRepository).computeInvestigations(String.valueOf(investigationUid));
        verify(investigationRepository).populatePhcFact(String.valueOf(investigationUid));
    }

    @Test
    void testProcessInvestigationException() {
        String investigationTopic = "Investigation";
        String investigationTopicOutput = "InvestigationOutput";
        String invalidPayload = "{\"payload\": {\"after\": }}";

        final var investigationService = getInvestigationService(investigationTopic, investigationTopicOutput);
        assertThrows(RuntimeException.class, () -> investigationService.processMessage(invalidPayload, investigationTopic));
    }

    @Test
    void testProcessInvestigationNoDataException() {
        String investigationTopic = "Investigation";
        String investigationTopicOutput = "InvestigationOutput";
        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\"}}}";

        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.empty());

        final var investigationService = getInvestigationService(investigationTopic, investigationTopicOutput);
        assertThrows(NoDataException.class, () -> investigationService.processMessage(payload, investigationTopic));
    }

    private void validateData(String inputTopicName, String outputTopicName,
                              String payload, Investigation investigation) throws JsonProcessingException {

        final var investigationService = getInvestigationService(inputTopicName, outputTopicName);
        investigationService.processMessage(payload, inputTopicName);

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

        assertEquals(outputTopicName, actualTopic); // investigation topic
        assertEquals(investigationKey, actualInvestigationKey);
        assertEquals(reportingModel, actualReporting);
    }

    private InvestigationService getInvestigationService(String inputTopicName, String outputTopicName) {
        InvestigationService investigationService = new InvestigationService(investigationRepository, kafkaTemplate, transformer);
        investigationService.setInvestigationTopic(inputTopicName);
        investigationService.setInvestigationTopicReporting(outputTopicName);
        investigationService.setPhcDatamartEnable(true);
        return investigationService;
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

        String filePathPrefix = "rawDataFiles/";
        investigation.setActIds(readFileData(filePathPrefix + "ActIds.json"));
        investigation.setInvestigationConfirmationMethod(readFileData(filePathPrefix + "ConfirmationMethod.json"));
        investigation.setObservationNotificationIds(readFileData(filePathPrefix + "ObservationNotificationIds.json"));
        investigation.setOrganizationParticipations(readFileData(filePathPrefix + "OrganizationParticipations.json"));
        investigation.setPersonParticipations(readFileData(filePathPrefix + "PersonParticipations.json"));
        investigation.setInvestigationCaseAnswer(readFileData(filePathPrefix + "InvestigationCaseAnswers.json"));
        investigation.setInvestigationNotifications(readFileData(filePathPrefix + "InvestigationNotifications.json"));
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
}