package gov.cdc.etldatapipeline.observation;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.*;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.testcontainers.shaded.org.checkerframework.checker.nullness.qual.NonNull;

import java.math.BigDecimal;
import java.util.List;
import java.util.concurrent.CompletableFuture;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class ObservationDataProcessTests {
    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private static final String FILE_PREFIX = "rawDataFiles/";
    private static final String CODED_TOPIC = "codedTopic";
    private static final String DATE_TOPIC = "dateTopic";
    private static final String EDX_TOPIC = "edxTopic";
    private static final String MATERIAL_TOPIC = "materialTopic";
    private static final String NUMERIC_TOPIC = "numericTopic";
    private static final String REASON_TOPIC = "reasonTopic";
    private static final String TXT_TOPIC = "txtTopic";

    ProcessObservationDataUtil transformer;

    private AutoCloseable closeable;
    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        transformer = new ProcessObservationDataUtil(kafkaTemplate);
        Logger logger = (Logger) LoggerFactory.getLogger(ProcessObservationDataUtil.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    void tearDown() throws Exception {
        Logger logger = (Logger) LoggerFactory.getLogger(ProcessObservationDataUtil.class);
        logger.detachAppender(listAppender);
        closeable.close();
    }

    @Test
    void consolidatedDataTransformationTest() {
        Observation observation = new Observation();
        observation.setActUid(100000001L);
        observation.setObsDomainCdSt1("Order");

        observation.setPersonParticipations(readFileData(FILE_PREFIX + "PersonParticipations.json"));
        observation.setOrganizationParticipations(readFileData(FILE_PREFIX + "OrganizationParticipations.json"));
        observation.setMaterialParticipations(readFileData(FILE_PREFIX + "MaterialParticipations.json"));
        observation.setFollowupObservations(readFileData(FILE_PREFIX + "FollowupObservations.json"));

        ObservationTransformed observationTransformed = transformer.transformObservationData(observation);

        Long patId = observationTransformed.getPatientId();
        Long ordererId = observationTransformed.getOrderingPersonId();
        Long authorOrgId = observationTransformed.getAuthorOrganizationId();
        Long ordererOrgId = observationTransformed.getOrderingOrganizationId();
        Long performerOrgId = observationTransformed.getPerformingOrganizationId();
        Long materialId = observationTransformed.getMaterialId();
        String resultObsUid = observationTransformed.getResultObservationUid();

        Assertions.assertEquals(10000055L, ordererId);
        Assertions.assertEquals(10000066L, patId);
        Assertions.assertEquals(34567890L, authorOrgId);
        Assertions.assertEquals(23456789L, ordererOrgId);
        Assertions.assertNull(performerOrgId);
        Assertions.assertEquals(10000005L, materialId);
        Assertions.assertEquals("56789012,56789013", resultObsUid);
    }

    @Test
    void testOrganizationParticipationTransformation() {
        Observation observation = new Observation();
        observation.setActUid(100000001L);
        observation.setObsDomainCdSt1("Result");

        observation.setOrganizationParticipations(readFileData(FILE_PREFIX + "OrganizationParticipations.json"));

        ObservationTransformed observationTransformed = transformer.transformObservationData(observation);
        Long authorOrgId = observationTransformed.getAuthorOrganizationId();
        Long ordererOrgId = observationTransformed.getOrderingOrganizationId();
        Long performerOrgId = observationTransformed.getPerformingOrganizationId();

        Assertions.assertNull(authorOrgId);
        Assertions.assertNull(ordererOrgId);
        Assertions.assertEquals(45678901L, performerOrgId);
    }

    @Test
    void testOrganizationMaterialTransformation() throws JsonProcessingException {
        Observation observation = new Observation();
        observation.setActUid(100000003L);
        observation.setObservationUid(100000003L);
        observation.setObsDomainCdSt1("Order");
        observation.setMaterialParticipations(readFileData(FILE_PREFIX + "MaterialParticipations.json"));
        transformer.setMaterialTopicName(MATERIAL_TOPIC);
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        ObservationMaterial material = constructObservationMaterial(100000003L);
        ObservationTransformed observationTransformed = transformer.transformObservationData(observation);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(MATERIAL_TOPIC, topicCaptor.getValue());
        assertEquals(10000005L, observationTransformed.getMaterialId());

        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(2).getFormattedMessage().contains("Observation Material data (uid=10000005) sent to "+MATERIAL_TOPIC));

        var actualMaterial = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), ObservationMaterial.class);

        assertEquals(material, actualMaterial);
    }

    @Test
    void testOrganizationParentTransformation() {
        Observation observation = new Observation();
        observation.setActUid(100000003L);
        observation.setObservationUid(100000003L);
        observation.setObsDomainCdSt1("Order");
        observation.setParentObservations("[{\"parent_type_cd\": \"COMP\",\"parent_uid\": 234567888}]");

        ObservationTransformed observationTransformed = transformer.transformObservationData(observation);
        assertEquals(234567888L, observationTransformed.getReportObservationUid());
    }

        @Test
    void testOrganizationCodedTransformation() throws JsonProcessingException {
        Observation observation = new Observation();
        observation.setActUid(10001234L);
        observation.setObservationUid(10001234L);
        observation.setObsCode(readFileData(FILE_PREFIX + "ObservationCoded.json"));
        transformer.setCodedTopicName(CODED_TOPIC);

        ObservationCoded coded = new ObservationCoded();
        coded.setObservationUid(observation.getObservationUid());
        coded.setOvcCode("CE[10020004");
        coded.setOvcCodeSystemCd("SNM");
        coded.setOvcCodeSystemDescTxt("SNOMED");
        coded.setOvcDisplayName("Normal]");
        coded.setOvcAltCd("A-124");
        coded.setOvcAltCdDescTxt("NORMAL");

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.transformObservationData(observation);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(CODED_TOPIC, topicCaptor.getValue());
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(5).getFormattedMessage().contains("Observation Coded data (uid=10001234) sent to "+CODED_TOPIC));

        var actualCoded = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), ObservationCoded.class);

        assertEquals(coded, actualCoded);
    }

    @Test
    void testOrganizationDateTransformation() throws JsonProcessingException {
        Observation observation = new Observation();
        observation.setActUid(10001234L);
        observation.setObservationUid(10001234L);
        observation.setObsDate(readFileData(FILE_PREFIX + "ObservationDate.json"));
        transformer.setDateTopicName(DATE_TOPIC);

        ObservationDate obd = new ObservationDate();
        obd.setObservationUid(observation.getObservationUid());
        obd.setOvdFromDate("2024-08-16T00:00:00");

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.transformObservationData(observation);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(DATE_TOPIC, topicCaptor.getValue());
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(6).getFormattedMessage().contains("Observation Date data (uid=10001234) sent to "+DATE_TOPIC));

        var actualObd = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), ObservationDate.class);

        assertEquals(obd, actualObd);
    }

    @Test
    void testOrganizationEdxTransformation() throws JsonProcessingException {
        Observation observation = new Observation();
        observation.setActUid(10001234L);
        observation.setObservationUid(10001234L);
        observation.setEdxIds(readFileData(FILE_PREFIX + "ObservationEdx.json"));
        transformer.setEdxTopicName(EDX_TOPIC);

        ObservationEdx edx = new ObservationEdx();
        edx.setEdxDocumentUid(10101L);
        edx.setEdxActUid(observation.getActUid());
        edx.setEdxAddTime("2024-09-30T21:08:19.017");

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.transformObservationData(observation);
        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(EDX_TOPIC, topicCaptor.getValue());
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(7).getFormattedMessage().contains("Observation Edx data (edx doc uid=10101) sent to "+EDX_TOPIC));

        var actualEdx = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getFirst()).path("payload").toString(), ObservationEdx.class);

        assertEquals(edx, actualEdx);
    }

    @Test
    void testOrganizationNumericTransformation() throws JsonProcessingException {
        Observation observation = new Observation();
        observation.setActUid(10001234L);
        observation.setObservationUid(10001234L);
        observation.setObsNum(readFileData(FILE_PREFIX + "ObservationNumeric.json"));
        transformer.setNumericTopicName(NUMERIC_TOPIC);

        ObservationNumeric numeric = new ObservationNumeric();
        numeric.setObservationUid(observation.getObservationUid());
        numeric.setOvnComparatorCd1("100");
        numeric.setOvnLowRange("10-100");
        numeric.setOvnHighRange("100-1000");
        numeric.setOvnNumericValue1(new BigDecimal("1"));
        numeric.setOvnNumericValue2(new BigDecimal("1"));
        numeric.setOvnNumericUnitCd("mL");
        numeric.setOvnSeparatorCd(":");

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.transformObservationData(observation);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(NUMERIC_TOPIC, topicCaptor.getValue());
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(8).getFormattedMessage().contains("Observation Numeric data (uid=10001234) sent to "+NUMERIC_TOPIC));

        var actualNumeric = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), ObservationNumeric.class);

        assertEquals(numeric, actualNumeric);
    }

    @Test
    void testOrganizationReasonTransformation() throws JsonProcessingException {
        Observation observation = new Observation();
        observation.setActUid(10001234L);
        observation.setObservationUid(10001234L);
        observation.setObsReason(readFileData(FILE_PREFIX + "ObservationReason.json"));
        transformer.setReasonTopicName(REASON_TOPIC);

        ObservationReason reason = new ObservationReason();
        reason.setObservationUid(observation.getObservationUid());
        reason.setReasonCd("80008");
        reason.setReasonDescTxt("PRESENCE OF REASON");

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.transformObservationData(observation);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(REASON_TOPIC, topicCaptor.getValue());
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(9).getFormattedMessage().contains("Observation Reason data (uid=10001234) sent to "+REASON_TOPIC));

        var actualReason = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), ObservationReason.class);

        assertEquals(reason, actualReason);
    }

    @Test
    void testOrganizationTxtTransformation() throws JsonProcessingException {
        Observation observation = new Observation();
        observation.setActUid(10001234L);
        observation.setObservationUid(10001234L);
        observation.setObsTxt(readFileData(FILE_PREFIX + "ObservationTxt.json"));
        transformer.setTxtTopicName(TXT_TOPIC);

        ObservationTxt txt = new ObservationTxt();
        txt.setObservationUid(observation.getObservationUid());
        txt.setOvtSeq(1);
        txt.setOvtTxtTypeCd("N");
        txt.setOvtValueTxt("RECOMMENDED IN SUCH INSTANCES.");

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.transformObservationData(observation);
        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(TXT_TOPIC, topicCaptor.getValue());
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(10).getFormattedMessage().contains("Observation Txt data (uid=10001234) sent to "+TXT_TOPIC));

        var actualTxt = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getFirst()).path("payload").toString(), ObservationTxt.class);

        assertEquals(txt, actualTxt);
    }

    @Test
    void testTransformNoObservationData() {
        Observation observation = new Observation();
        observation.setOrganizationParticipations("{\"act_uid\": 10000003}");
        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list;
        logs.forEach(le -> assertTrue(le.getFormattedMessage().matches("(\\w+) array is null.")));
    }

    @Test
    void testTransformObservationDataError(){
        Observation observation = new Observation();
        String invalidJSON = "invalidJSON";

        observation.setPersonParticipations(invalidJSON);
        observation.setOrganizationParticipations(invalidJSON);
        observation.setMaterialParticipations(invalidJSON);
        observation.setFollowupObservations(invalidJSON);
        observation.setParentObservations(invalidJSON);
        observation.setObsCode(invalidJSON);
        observation.setObsDate(invalidJSON);
        observation.setEdxIds(invalidJSON);
        observation.setObsNum(invalidJSON);
        observation.setObsReason(invalidJSON);
        observation.setObsTxt(invalidJSON);

        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list;
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains(invalidJSON)));
    }

    @Test
    void testTransformObservationInvalidDomainError(){
        Observation observation = new Observation();
        String dummyJSON = "[{\"type_cd\":\"ORD\", \"subject_class_cd\": \"ORD\"}]";
        String invalidDomain = "invalidDomain";
        observation.setObservationUid(10000001L);
        observation.setObsDomainCdSt1(invalidDomain);

        observation.setPersonParticipations(dummyJSON);
        observation.setOrganizationParticipations(dummyJSON);
        observation.setMaterialParticipations(dummyJSON);
        observation.setFollowupObservations(dummyJSON);
        observation.setParentObservations(dummyJSON);

        transformer.setReasonTopicName(REASON_TOPIC);
        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list.subList(0, 4);
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains(invalidDomain)));
    }

    @Test
    void testTransformObservationResultDomainError(){
        Observation observation = new Observation();
        String dummyJSON = "[{\"type_cd\": \"PRF\",\"subject_class_cd\": \"ORG\",\"entity_id\": 45678901}]";

        observation.setObsDomainCdSt1("Result");
        observation.setPersonParticipations(dummyJSON);
        observation.setOrganizationParticipations(dummyJSON);
        observation.setMaterialParticipations(dummyJSON);
        observation.setFollowupObservations(dummyJSON);
        observation.setParentObservations(dummyJSON);

        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list.subList(0, 4);
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains("Result is not valid")));
    }

    @ParameterizedTest
    @CsvSource({
            "'[{\"type_cd\":null, \"subject_class_cd\":null, \"parent_type_cd\":null}]'",
            "'[{\"type_cd\":\"NN\", \"subject_class_cd\":null, \"parent_type_cd\":null}]'",
            "'[{\"type_cd\":null, \"subject_class_cd\":\"NN\", \"parent_type_cd\":null}]'",
    })
    void testTransformObservationNullError(String payload){
        Observation observation = new Observation();

        observation.setObsDomainCdSt1("Order");
        observation.setPersonParticipations(payload);
        observation.setOrganizationParticipations(payload);
        observation.setMaterialParticipations(payload);
        observation.setFollowupObservations(payload);
        observation.setParentObservations(payload);

        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list.subList(0, 4);
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains("_cd is null")));
    }

    private @NonNull ObservationMaterial constructObservationMaterial(Long actUid) {
        ObservationMaterial material = new ObservationMaterial();
        material.setActUid(actUid);
        material.setTypeCd("SPC");
        material.setMaterialId(10000005L);
        material.setSubjectClassCd("MAT");
        material.setRecordStatus("ACTIVE");
        material.setTypeDescTxt("Specimen");
        material.setLastChgTime("2024-01-01T00:00:00.000");
        material.setMaterialCd("UNK");
        material.setMaterialNm(null);
        material.setMaterialDetails("Thought not call ground.");
        material.setMaterialCollectionVol("36");
        material.setMaterialCollectionVolUnit("ML");
        material.setMaterialDesc("Lymphocytes");
        material.setRiskCd(null);
        material.setRiskDescTxt(null);
        return material;
    }
}
