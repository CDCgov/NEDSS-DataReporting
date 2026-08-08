package gov.cdc.nbs.report.pipeline.util;

import static org.junit.jupiter.api.Assertions.*;

import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.Contact;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.Interview;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.reporting.ContactReporting;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.reporting.InterviewReporting;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.Observation;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationReporting;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.model.DatamartData;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.model.dto.Datamart;
import org.junit.jupiter.api.Test;

class ReportingPipelineModelMapperTest {

  private final ReportingPipelineModelMapper mapper = new ReportingPipelineModelMapper();

  static class Source {
    private String name;
    private Integer age;

    public String getName() {
      return name;
    }

    public void setName(String name) {
      this.name = name;
    }

    public Integer getAge() {
      return age;
    }

    public void setAge(Integer age) {
      this.age = age;
    }
  }

  static class Destination {
    private String name;
    private Integer age;

    public String getName() {
      return name;
    }

    public void setName(String name) {
      this.name = name;
    }

    public Integer getAge() {
      return age;
    }

    public void setAge(Integer age) {
      this.age = age;
    }
  }

  @Test
  void testMap_basicFieldsMapCorrectly() {
    Source source = new Source();
    source.setName("John Doe");
    source.setAge(42);

    Destination destination = mapper.map(source, Destination.class);

    assertEquals("John Doe", destination.getName());
    assertEquals(42, destination.getAge());
  }

  @Test
  void testMap_emptyStringResolvesToNull() {
    Source source = new Source();
    source.setName("");
    source.setAge(30);

    Destination destination = mapper.map(source, Destination.class);

    assertNull(destination.getName());
    assertEquals(30, destination.getAge());
  }

  @Test
  void testMap_investigationEmptyStringFieldsResolveToNull() {
    Investigation investigation =
        gov.cdc.nbs.report.pipeline.investigation.utils.TestUtils.constructInvestigation(1L);
    investigation.setOutbreakIndVal("");
    investigation.setOutbreakName("");
    investigation.setCdDescTxt("");
    investigation.setLocalId("");
    investigation.setDetectionMethodDescTxt("");

    InvestigationReporting reporting = mapper.map(investigation, InvestigationReporting.class);

    assertNull(reporting.getOutbreakIndVal());
    assertNull(reporting.getOutbreakName());
    assertNull(reporting.getCdDescTxt());
    assertNull(reporting.getLocalId());
    assertNull(reporting.getDetectionMethodDescTxt());

    assertEquals(1L, reporting.getPublicHealthCaseUid());
    assertEquals("130001", reporting.getJurisdictionCd());
    assertEquals("10110", reporting.getCd());
    assertEquals("2024", reporting.getMmwrYear());
  }

  @Test
  void testMap_interviewEmptyStringFieldsResolveToNull() {
    Interview interview =
        gov.cdc.nbs.report.pipeline.investigation.utils.TestUtils.constructInterview(1L);
    interview.setLocalId("");
    interview.setInterviewLocCd("");
    interview.setIxLocation("");

    InterviewReporting reporting = mapper.map(interview, InterviewReporting.class);

    assertNull(reporting.getLocalId());
    assertNull(reporting.getInterviewLocCd());
    assertNull(reporting.getIxLocation());

    assertEquals(1L, reporting.getInterviewUid());
    assertEquals("COMPLETE", reporting.getInterviewStatusCd());
    assertEquals("Closed/Completed", reporting.getIxStatus());
  }

  @Test
  void testMap_contactEmptyStringFieldsResolveToNull() {
    Contact contact =
        gov.cdc.nbs.report.pipeline.investigation.utils.TestUtils.constructContact(1L);
    contact.setCttEvalNotes("");
    contact.setCttNotes("");
    contact.setCttRiskNotes("");
    contact.setCttSympNotes("");
    contact.setCttTrtNotes("");

    ContactReporting reporting = mapper.map(contact, ContactReporting.class);

    assertNull(reporting.getCttEvalNotes());
    assertNull(reporting.getCttNotes());
    assertNull(reporting.getCttRiskNotes());
    assertNull(reporting.getCttSympNotes());
    assertNull(reporting.getCttTrtNotes());

    assertEquals(1L, reporting.getContactUid());
    assertEquals("Referral", reporting.getCttReferralBasis());
    assertEquals("LOC456", reporting.getLocalId());
  }

  @Test
  void testMap_observationEmptyStringFieldsResolveToNull() {
    Observation observation = new Observation();
    observation.setObservationUid(1L);
    observation.setClassCd("OBS");
    observation.setLocalId("");
    observation.setCdDescTxt("");
    observation.setInterpretationDescTxt("");

    ObservationReporting reporting = mapper.map(observation, ObservationReporting.class);

    assertNull(reporting.getLocalId());
    assertNull(reporting.getCdDescTxt());
    assertNull(reporting.getInterpretationDescTxt());

    assertEquals(1L, reporting.getObservationUid());
    assertEquals("OBS", reporting.getClassCd());
  }

  @Test
  void testMap_datamartEmptyStringFieldsResolveToNull() {
    DatamartData datamartData = new DatamartData();
    datamartData.setPublicHealthCaseUid(1L);
    datamartData.setDatamart("HEP");
    datamartData.setConditionCd("");
    datamartData.setStoredProcedure("");

    Datamart datamart = mapper.map(datamartData, Datamart.class);

    assertNull(datamart.getConditionCd());
    assertNull(datamart.getStoredProcedure());

    assertEquals(1L, datamart.getPublicHealthCaseUid());
    assertEquals("HEP", datamart.getDatamart());
  }
}
