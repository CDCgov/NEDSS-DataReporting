package gov.cdc.etldatapipeline.investigation.service;

import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.investigation.repository.odse.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.InvestigationKey;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.etldatapipeline.investigation.repository.rdb.InvestigationCaseAnswerRepository;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
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

    private ProcessInvestigationDataUtil transformer;
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationCaseAnswerRepository);
    }

    @Test
    void testProcessMessage() {
        String investigationTopic = "Investigation";
        String investigationTopicOutput = "InvestigationOutput";

        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\"}}}";

        final Investigation investigation = constructInvestigation(investigationUid);
        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.of(investigation));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        validateData(investigationTopic, investigationTopicOutput, payload, investigation);

        verify(investigationRepository).computeInvestigations(String.valueOf(investigationUid));
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
                              String payload, Investigation investigation) {

        final var investigationService = getInvestigationService(inputTopicName, outputTopicName);
        investigationService.processMessage(payload, inputTopicName);

        InvestigationKey investigationKey = new InvestigationKey();
        investigationKey.setPublicHealthCaseUid(investigation.getPublicHealthCaseUid());
        final InvestigationReporting reportingModel = constructInvestigationReporting(investigation.getPublicHealthCaseUid());

        String expectedKey = jsonGenerator.generateStringJson(investigationKey);
        String expectedValue = jsonGenerator.generateStringJson(reportingModel);

        verify(kafkaTemplate, times(4)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(outputTopicName, topicCaptor.getValue());
        assertEquals(expectedKey, keyCaptor.getValue());
        assertEquals(expectedValue, messageCaptor.getValue());
        assertTrue(keyCaptor.getValue().contains(String.valueOf(investigationKey.getPublicHealthCaseUid())));
    }

    private InvestigationService getInvestigationService(String inputTopicName, String outputTopicName) {
        InvestigationService investigationService = new InvestigationService(investigationRepository, kafkaTemplate, transformer);
        investigationService.setInvestigationTopic(inputTopicName);
        investigationService.setInvestigationTopicReporting(outputTopicName);
        return investigationService;
    }

    private Investigation constructInvestigation(Long investigationUid) {
        String filePathPrefix = "rawDataFiles/";
        Investigation investigation = new Investigation();
        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setActIds(readFileData(filePathPrefix + "ActIds.json"));
        investigation.setInvestigationConfirmationMethod(readFileData(filePathPrefix + "ConfirmationMethod.json"));
        investigation.setObservationNotificationIds(readFileData(filePathPrefix + "ObservationNotificationIds.json"));
        investigation.setOrganizationParticipations(readFileData(filePathPrefix + "OrganizationParticipations.json"));
        investigation.setPersonParticipations(readFileData(filePathPrefix + "PersonParticipations.json"));
        investigation.setInvestigationCaseAnswer(readFileData(filePathPrefix + "InvestigationCaseAnswer.json"));
        return investigation;
    }

    private InvestigationReporting constructInvestigationReporting(Long investigationUid) {
        final InvestigationReporting reporting = new InvestigationReporting();
        reporting.setPublicHealthCaseUid(investigationUid);
        reporting.setInvestigatorId(32143250L);    // PersonParticipations.json, entity_id for type_cd=InvestgrOfPHC
        reporting.setPhysicianId(14253651L);       // PersonParticipations.json, entity_id for type_cd=PhysicianOfPHC
        reporting.setPatientId(321432537L);        // PersonParticipations.json, entity_id for type_cd=SubjOfPHC
        reporting.setOrganizationId(34865315L);    // OrganizationParticipations.json, entity_id for type_cd=OrgAsReporterOfPHC
        reporting.setInvStateCaseId("12-345-678"); // ActIds.json, root_extension_txt for type_cd=STATE
        reporting.setPhcInvFormId(263748598L);     // ObservationNotificationIds.json, source_act_uid for act_type_cd=PHCInvForm
        reporting.setRdbTableNameList("D_INV_CLINICAL,D_INV_ADMINISTRATIVE"); // InvestigationCaseAnswer.json, rdb_table_nm
        return reporting;
    }
}