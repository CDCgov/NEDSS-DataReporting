package gov.cdc.etldatapipeline.investigation;

import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationReporting;
import org.junit.jupiter.api.Test;
import org.modelmapper.ModelMapper;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class InvestigationModelMappingTests {
    private final ModelMapper modelMapper = new ModelMapper();

    @Test
    void testInvestigationReporting() {
        final var investigation = getInvestigation();

        InvestigationReporting reporting = modelMapper.map(investigation, InvestigationReporting.class);

        assertEquals(investigation.getPublicHealthCaseUid(), reporting.getPublicHealthCaseUid());
        assertEquals(investigation.getProgramJurisdictionOid(), reporting.getProgramJurisdictionOid());
        assertEquals(investigation.getJurisdictionCode(), reporting.getJurisdictionCode());
        assertEquals(investigation.getJurisdictionNm(), reporting.getJurisdictionNm());
        assertEquals(investigation.getMoodCd(), reporting.getMoodCd());
        assertEquals(investigation.getClassCd(), reporting.getClassCd());
        assertEquals(investigation.getCaseTypeCd(), reporting.getCaseTypeCd());
        assertEquals(investigation.getCaseClassCd(), reporting.getCaseClassCd());
        assertEquals(investigation.getInvCaseStatus(), reporting.getInvCaseStatus());
        assertNull(reporting.getOutbreakName());
        assertEquals(investigation.getCd(), reporting.getCd());
        assertEquals(investigation.getCdDescTxt(), reporting.getCdDescTxt());
        assertEquals(investigation.getProgAreaCd(), reporting.getProgAreaCd());

        assertNull(reporting.getPregnantInd());
        assertNull(reporting.getPregnantIndCd());

        assertEquals(investigation.getLocalId(), reporting.getLocalId());
        assertEquals(investigation.getRptFormCmpltTime(), reporting.getRptFormCmpltTime());

        assertNull(reporting.getActivityToTime());
        assertNull(reporting.getActivityFromTime());

        assertEquals(investigation.getAddUserId(), reporting.getAddUserId());
        assertEquals(investigation.getAddUserName(), reporting.getAddUserName());
        assertEquals(investigation.getAddTime(), reporting.getAddTime());

        assertNull(reporting.getLastChgTime());
        assertNull(reporting.getLastChgUserId());
        assertNull(reporting.getLastChgUserName());
        assertNull(reporting.getCurrProcessState());
        assertNull(reporting.getCurrProcessStateCd());

        assertEquals(investigation.getInvestigationStatusCd(), reporting.getInvestigationStatusCd());
        assertEquals(investigation.getInvestigationStatus(), reporting.getInvestigationStatus());
        assertEquals(investigation.getRecordStatusCd(), reporting.getRecordStatusCd());
        assertEquals(investigation.getSharedInd(), reporting.getSharedInd());

        assertNull(reporting.getTxt());
        assertNull(reporting.getEffectiveFromTime());
        assertNull(reporting.getEffectiveToTime());
        assertNull(reporting.getEffectiveDurationAmt());
        assertNull(reporting.getEffectiveDurationUnitCd());

        assertEquals(investigation.getRptSourceCd(), reporting.getRptSourceCd());
        assertEquals(investigation.getRptSrcCdDesc(), reporting.getRptSrcCdDesc());
        assertEquals(investigation.getMmwrWeek(), reporting.getMmwrWeek());
        assertEquals(investigation.getMmwrYear(), reporting.getMmwrYear());

        assertNull(reporting.getDiseaseImportedCd());
        assertNull(reporting.getDiseaseImportedInd());
        assertNull(reporting.getImportedCountryCd());
        assertNull(reporting.getImportedStateCd());
        assertNull(reporting.getImportedCountyCd());
        assertNull(reporting.getImportedFromCountry());
        assertNull(reporting.getImportedFromState());
        assertNull(reporting.getImportedFromCounty());
        assertNull(reporting.getImportedCityDescTxt());

        assertEquals(investigation.getDiagnosisTime(), reporting.getDiagnosisTime());

        assertNull(reporting.getHospitalizedAdminTime());
        assertNull(reporting.getHospitalizedDischargeTime());
        assertNull(reporting.getHospitalizedDurationAmt());
        assertNull(reporting.getHospitalizedIndCd());
        assertNull(reporting.getHospitalizedInd());
        assertNull(reporting.getOutbreakInd());
        assertNull(reporting.getOutbreakIndVal());
        assertNull(reporting.getTransmissionModeCd());
        assertNull(reporting.getTransmissionMode());
        assertNull(reporting.getOutcomeCd());
        assertNull(reporting.getDieFrmThisIllnessInd());
        assertNull(reporting.getDayCareInd());
        assertNull(reporting.getFoodHandlerIndCd());
        assertNull(reporting.getFoodHandlerInd());
        assertNull(reporting.getDeceasedTime());

        assertEquals(investigation.getPatAgeAtOnset(), reporting.getPatAgeAtOnset());
        assertEquals(investigation.getPatAgeAtOnsetUnitCd(), reporting.getPatAgeAtOnsetUnitCd());
        assertEquals(investigation.getPatAgeAtOnsetUnit(), reporting.getPatAgeAtOnsetUnit());

        assertEquals(investigation.getDetectionMethodDescTxt(), reporting.getDetectionMethodDescTxt());
        assertEquals(investigation.getProgramAreaDescription(), reporting.getProgramAreaDescription());

        assertNull(reporting.getContactInvPriority());
        assertNull(reporting.getContactInvStatus());
        assertNull(reporting.getReferralBasisCd());
        assertNull(reporting.getReferralBasis());
        assertNull(reporting.getInvPriorityCd());

        assertNull(reporting.getNotificationLocalId());
        assertNull(reporting.getNotificationAddTime());
        assertNull(reporting.getNotificationRecordStatusCd());
        assertNull(reporting.getNotificationLastChgTime());

        assertEquals(investigation.getCaseManagementUid(), reporting.getCaseManagementUid());
        assertEquals(investigation.getNacPageCaseUid(), reporting.getNacPageCaseUid());
        assertEquals(investigation.getNacLastChgTime(), reporting.getNacLastChgTime());
        assertEquals(investigation.getNacAddTime(), reporting.getNacAddTime());
        assertEquals(investigation.getPersonAsReporterUid(), reporting.getPersonAsReporterUid());
        assertEquals(investigation.getHospitalUid(), reporting.getHospitalUid());
        assertEquals(investigation.getOrderingFacilityUid(), reporting.getOrderingFacilityUid());
    }

    private Investigation getInvestigation() {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(234567890L);
        investigation.setPublicHealthCaseUid(1L);
        investigation.setProgramJurisdictionOid(2L);
        investigation.setJurisdictionCode("333");
        investigation.setJurisdictionNm("Nevarro County");

        investigation.setMoodCd("EVN");
        investigation.setClassCd("CASE");
        investigation.setCaseTypeCd("I");
        investigation.setCaseClassCd("C");
        investigation.setInvCaseStatus("Confirmed");
        investigation.setCd("112233");
        investigation.setCdDescTxt("Testaphobia Syndrome");

        investigation.setProgAreaCd("PROG");
        investigation.setLocalId("CAS1000000AA01");
        investigation.setRptFormCmpltTime("2020-02-20T00:00:00.000");

        investigation.setAddUserId(2020L);
        investigation.setAddUserName("ODS NBS");
        investigation.setAddTime("2020-02-20T00:20:00.000");

        investigation.setInvestigationStatusCd("O");
        investigation.setInvestigationStatus("Open");
        investigation.setRecordStatusCd("ACTIVE");
        investigation.setSharedInd("T");

        investigation.setRptSourceCd("LA");
        investigation.setRptSrcCdDesc("Laboratory");
        investigation.setMmwrWeek("20");
        investigation.setMmwrYear("2020");

        investigation.setDiagnosisTime("2020-02-20T00:00:00.000");
        investigation.setPatAgeAtOnset("22");
        investigation.setPatAgeAtOnsetUnitCd("Y");
        investigation.setPatAgeAtOnsetUnit("Years");
        investigation.setDetectionMethodDescTxt("Self-referral");
        investigation.setProgramAreaDescription("General");

        return investigation;
    }
}
