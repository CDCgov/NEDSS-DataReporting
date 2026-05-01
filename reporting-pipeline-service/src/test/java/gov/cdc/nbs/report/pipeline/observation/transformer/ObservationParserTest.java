package gov.cdc.nbs.report.pipeline.observation.transformer;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.Observation;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationCoded;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationDate;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationEdx;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationMaterial;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationNumeric;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationReason;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationTransformed;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationTxt;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ParsedObservation;
import java.util.List;
import org.jetbrains.annotations.NotNull;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.slf4j.LoggerFactory;
import org.testcontainers.shaded.org.checkerframework.checker.nullness.qual.NonNull;

class ObservationParserTest {

  private static final String FILE_PREFIX = "rawDataFiles/observation/";
  private static final Long BATCH_ID = 11L;
  private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();

  @BeforeEach
  void setUp() {
    Logger logger = (Logger) LoggerFactory.getLogger(ObservationParser.class);
    listAppender.start();
    logger.addAppender(listAppender);
  }

  @AfterEach
  void tearDown() {
    Logger logger = (Logger) LoggerFactory.getLogger(ObservationParser.class);
    logger.detachAppender(listAppender);
  }

  @Test
  void consolidatedDataTransformationTest() {
    Observation observation = new Observation();
    observation.setObservationUid(100000001L);
    observation.setObsDomainCdSt1("Order");

    observation.setPersonParticipations(readFileData(FILE_PREFIX + "PersonParticipations.json"));
    observation.setOrganizationParticipations(
        readFileData(FILE_PREFIX + "OrganizationParticipations.json"));
    observation.setMaterialParticipations(
        readFileData(FILE_PREFIX + "MaterialParticipations.json"));
    observation.setFollowupObservations(readFileData(FILE_PREFIX + "FollowupObservations.json"));

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);

    Long patId = parsedObservation.transformed().getPatientId();
    String ordererId = parsedObservation.transformed().getOrderingPersonId();
    Long authorOrgId = parsedObservation.transformed().getAuthorOrganizationId();
    Long ordererOrgId = parsedObservation.transformed().getOrderingOrganizationId();
    Long performerOrgId = parsedObservation.transformed().getPerformingOrganizationId();
    Long materialId = parsedObservation.transformed().getMaterialId();
    String resultObsUid = parsedObservation.transformed().getResultObservationUid();

    Assertions.assertEquals("10000055", ordererId);
    Assertions.assertEquals(10000066L, patId);
    Assertions.assertEquals(34567890L, authorOrgId);
    Assertions.assertEquals(23456789L, ordererOrgId);
    Assertions.assertNull(performerOrgId);
    Assertions.assertEquals(10000005L, materialId);
    Assertions.assertEquals("56789012,56789013", resultObsUid);
  }

  @Test
  void testPersonParticipationTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(100000001L);
    observation.setObsDomainCdSt1("Order");

    final var expected = getObservationTransformed();

    observation.setPersonParticipations(readFileData(FILE_PREFIX + "PersonParticipations.json"));

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);
    Assertions.assertEquals(expected, parsedObservation.transformed());
  }

  @Test
  void testMorbReportTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(100000001L);
    observation.setObsDomainCdSt1("Order");

    final var expected = new ObservationTransformed();

    expected.setObservationUid(100000001L);
    expected.setReportObservationUid(100000001L);
    expected.setPatientId(10000055L);
    expected.setMorbPhysicianId(10000033L);
    expected.setMorbReporterId(10000044L);
    expected.setBatchId(BATCH_ID);

    observation.setPersonParticipations(
        readFileData(FILE_PREFIX + "PersonParticipationsMorb.json"));
    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);
    Assertions.assertEquals(expected, parsedObservation.transformed());
  }

  @Test
  void testOrganizationParticipationTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(100000001L);
    observation.setObsDomainCdSt1("Result");

    observation.setOrganizationParticipations(
        readFileData(FILE_PREFIX + "OrganizationParticipations.json"));

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);
    Long authorOrgId = parsedObservation.transformed().getAuthorOrganizationId();
    Long ordererOrgId = parsedObservation.transformed().getOrderingOrganizationId();
    Long performerOrgId = parsedObservation.transformed().getPerformingOrganizationId();

    Assertions.assertNull(authorOrgId);
    Assertions.assertNull(ordererOrgId);
    Assertions.assertEquals(45678901L, performerOrgId);
  }

  @Test
  void testObservationMaterialTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(100000003L);
    observation.setObsDomainCdSt1("Order");
    observation.setMaterialParticipations(
        readFileData(FILE_PREFIX + "MaterialParticipations.json"));

    ObservationMaterial material = constructObservationMaterial(100000003L);
    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);

    assertEquals(10000005L, parsedObservation.transformed().getMaterialId());

    assertEquals(material, parsedObservation.materialEntries().get(0));
  }

  @ParameterizedTest
  @CsvSource({"'Order'", "'Result'"})
  void testParentObservationsTransformation(String domainCd) {
    Observation observation = new Observation();
    observation.setObservationUid(100000003L);
    observation.setParentObservations(
        "[{\"parent_type_cd\":\"MorbFrmQ\",\"parent_uid\":234567888,\"parent_domain_cd_st_1\":\"R_Order\"}]");

    observation.setObsDomainCdSt1(domainCd);
    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);
    assertEquals(234567888L, parsedObservation.transformed().getReportObservationUid());
    assertNull(parsedObservation.transformed().getReportRefrUid());
    assertNull(parsedObservation.transformed().getReportSprtUid());
  }

  @Test
  void testObservationCodedTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(10001234L);
    observation.setObsCode(readFileData(FILE_PREFIX + "ObservationCoded.json"));

    ObservationCoded coded = new ObservationCoded();
    coded.setObservationUid(observation.getObservationUid());
    coded.setOvcCode("CE[10020004");
    coded.setOvcCodeSystemCd("SNM");
    coded.setOvcCodeSystemDescTxt("SNOMED");
    coded.setOvcDisplayName("Normal]");
    coded.setOvcAltCd("A-124");
    coded.setOvcAltCdDescTxt("NORMAL");
    coded.setBatchId(BATCH_ID);

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);

    assertEquals(coded, parsedObservation.codedEntries().get(0));
  }

  @Test
  void testObservationDateTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(10001234L);
    observation.setObsDate(readFileData(FILE_PREFIX + "ObservationDate.json"));

    ObservationDate obd = new ObservationDate();
    obd.setObservationUid(observation.getObservationUid());
    obd.setOvdFromDate("2024-08-16T00:00:00");
    obd.setOvdSeq(1);
    obd.setBatchId(BATCH_ID);

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);

    assertEquals(obd, parsedObservation.dateEntries().get(0));
  }

  @Test
  void testObservationEdxTransformation() {
    Observation observation = new Observation();
    observation.setActUid(10001234L);
    observation.setObservationUid(10001234L);
    observation.setEdxIds(readFileData(FILE_PREFIX + "ObservationEdx.json"));

    ObservationEdx edx = new ObservationEdx();
    edx.setEdxDocumentUid(10101L);
    edx.setEdxActUid(observation.getActUid());
    edx.setEdxAddTime("2024-09-30T21:08:19.017");

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);

    assertEquals(edx, parsedObservation.edxEntries().get(0));
  }

  @Test
  void testObservationNumericTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(10001234L);
    observation.setObsNum(readFileData(FILE_PREFIX + "ObservationNumeric.json"));

    ObservationNumeric numeric = new ObservationNumeric();
    numeric.setObservationUid(observation.getObservationUid());
    numeric.setOvnComparatorCd1("100");
    numeric.setOvnLowRange("10-100");
    numeric.setOvnHighRange("100-1000");
    numeric.setOvnNumericValue1("23456000");
    numeric.setOvnNumericValue2("1.0");
    numeric.setOvnNumericUnitCd("mL");
    numeric.setOvnSeparatorCd(":");
    numeric.setOvnSeq(1);
    numeric.setBatchId(BATCH_ID);

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);

    assertEquals(numeric, parsedObservation.numericEntries().get(0));
  }

  @Test
  void testObservationReasonTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(10001234L);
    observation.setObsReason(readFileData(FILE_PREFIX + "ObservationReason.json"));

    ObservationReason reason = new ObservationReason();
    reason.setObservationUid(observation.getObservationUid());
    reason.setReasonCd("80008");
    reason.setReasonDescTxt("PRESENCE OF REASON");
    reason.setBatchId(BATCH_ID);

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);

    assertEquals(reason, parsedObservation.reasonEntries().get(0));
  }

  @Test
  void testObservationTxtTransformation() {
    Observation observation = new Observation();
    observation.setObservationUid(10001234L);
    observation.setObsTxt(readFileData(FILE_PREFIX + "ObservationTxt.json"));

    ObservationTxt txt = new ObservationTxt();
    txt.setObservationUid(observation.getObservationUid());
    txt.setOvtSeq(1);
    txt.setOvtTxtTypeCd("N");
    txt.setOvtValueTxt("RECOMMENDED IN SUCH INSTANCES.");
    txt.setBatchId(BATCH_ID);

    ParsedObservation parsedObservation = ObservationParser.parse(observation, BATCH_ID);

    assertEquals(txt, parsedObservation.textEntries().get(0));
  }

  @Test
  void testTransformNoObservationData() {
    Observation observation = new Observation();
    observation.setObservationUid(10001234L);
    observation.setOrganizationParticipations("{\"act_uid\": 10000003}");
    ObservationParser.parse(observation, BATCH_ID);

    List<ILoggingEvent> logs = listAppender.list;
    logs.forEach(le -> assertTrue(le.getFormattedMessage().matches("^\\w+ array is null.")));
  }

  @Test
  void testTransformObservationDataError() {
    Observation observation = new Observation();
    String invalidJSON = "invalidJSON";

    observation.setObservationUid(10001234L);
    observation.setPersonParticipations(invalidJSON);
    observation.setOrganizationParticipations(invalidJSON);
    observation.setMaterialParticipations(invalidJSON);
    observation.setFollowupObservations(invalidJSON);
    observation.setParentObservations(invalidJSON);
    observation.setActIds(invalidJSON);
    observation.setObsCode(invalidJSON);
    observation.setObsDate(invalidJSON);
    observation.setEdxIds(invalidJSON);
    observation.setObsNum(invalidJSON);
    observation.setObsReason(invalidJSON);
    observation.setObsTxt(invalidJSON);

    ObservationParser.parse(observation, BATCH_ID);

    List<ILoggingEvent> logs = listAppender.list;
    logs.forEach(le -> assertTrue(le.getFormattedMessage().contains(invalidJSON)));
  }

  @Test
  void testTransformObservationInvalidDomainError() {
    Observation observation = new Observation();
    observation.setObservationUid(10001234L);
    String dummyJSON =
        "[{\"type_cd\":\"PRF\",\"subject_class_cd\":\"ORG\",\"entity_id\":45678901,\"domain_cd_st_1\":\"Result\"}]";
    String invalidDomainCode = "Check";

    observation.setObsDomainCdSt1(invalidDomainCode);
    observation.setPersonParticipations(dummyJSON);
    observation.setOrganizationParticipations(dummyJSON);
    observation.setMaterialParticipations(dummyJSON);
    observation.setFollowupObservations(dummyJSON);

    ObservationParser.parse(observation, BATCH_ID);

    List<ILoggingEvent> logs = listAppender.list.subList(0, 4);
    logs.forEach(
        le -> assertTrue(le.getFormattedMessage().contains(invalidDomainCode + " is not valid")));
  }

  @ParameterizedTest
  @CsvSource({
    "'[{\"type_cd\":null, \"subject_class_cd\":null, \"parent_type_cd\":null}]'",
    "'[{\"type_cd\":\"NN\", \"subject_class_cd\":null, \"parent_type_cd\":null}]'",
    "'[{\"type_cd\":null, \"subject_class_cd\":\"NN\", \"parent_type_cd\":null}]'",
  })
  void testTransformObservationNullError(String payload) {
    Observation observation = new Observation();

    observation.setObservationUid(10001234L);
    observation.setObsDomainCdSt1("Order");
    observation.setPersonParticipations(payload);
    observation.setOrganizationParticipations(payload);
    observation.setMaterialParticipations(payload);
    observation.setFollowupObservations(payload);
    observation.setParentObservations(payload);

    ObservationParser.parse(observation, BATCH_ID);

    List<ILoggingEvent> logs = listAppender.list.subList(0, 4);
    logs.forEach(
        le -> assertTrue(le.getFormattedMessage().matches("^Field \\w+ is null or not found.*")));
  }

  private @NotNull ObservationTransformed getObservationTransformed() {
    ObservationTransformed expected = new ObservationTransformed();
    expected.setObservationUid(100000001L);
    expected.setReportObservationUid(100000001L);
    expected.setPatientId(10000066L);
    expected.setOrderingPersonId("10000055");
    expected.setAssistantInterpreterId(10000077L);
    expected.setAssistantInterpreterVal("22582");
    expected.setAssistantInterpreterFirstNm("Cara");
    expected.setAssistantInterpreterLastNm("Dune");
    expected.setAssistantInterpreterIdAssignAuth("22D7377772");
    expected.setAssistantInterpreterAuthType("Employee number");

    expected.setTranscriptionistId(10000088L);
    expected.setTranscriptionistVal("34344355455144");
    expected.setTranscriptionistFirstNm("Moff");
    expected.setTranscriptionistLastNm("Gideon");
    expected.setTranscriptionistIdAssignAuth("18D8181818");
    expected.setTranscriptionistAuthType("Employee number");

    expected.setResultInterpreterId(10000022L);
    expected.setLabTestTechnicianId(10000011L);

    expected.setSpecimenCollectorId(10000033L);
    expected.setCopyToProviderId(10000044L);

    expected.setBatchId(BATCH_ID);

    return expected;
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
