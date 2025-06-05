package gov.cdc.etldatapipeline.investigation.utils;


import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.*;
import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;


public class TestUtils {

    public static final String FILE_PATH_PREFIX = "rawDataFiles/";

    public static Investigation constructInvestigation(Long investigationUid) {
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
        investigation.setRptCntyCd("13253");

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

    public static InvestigationReporting constructInvestigationReporting(Long investigationUid) {
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
        reporting.setRptCntyCd("13253");

        reporting.setInvestigatorId(32143250L);         // PersonParticipations.json, entity_id for type_cd=InvestgrOfPHC
        reporting.setPhysicianId(14253651L);            // PersonParticipations.json, entity_id for type_cd=PhysicianOfPHC
        reporting.setPatientId(321432537L);             // PersonParticipations.json, entity_id for type_cd=SubjOfPHC
        reporting.setPersonAsReporterUid(10003004L);    // PersonParticipations.json, entity_id for type_cd=PerAsReporterOfPHC
        reporting.setOrganizationId(34865315L);         // OrganizationParticipations.json, entity_id for type_cd=OrgAsReporterOfPHC
        reporting.setHospitalUid(30303034L);            // OrganizationParticipations.json, entity_id for type_cd=HospOfADT
        reporting.setChronicCareFacUid(31096761L);      // OrganizationParticipations.json, entity_id for type_cd=ChronicCareFac
        reporting.setDaycareFacUid(30303007L);          // OrganizationParticipations.json, entity_id for type_cd=DaycareFac
        reporting.setInvStateCaseId("12-345-STA");      // ActIds.json, root_extension_txt for type_cd=STATE
        reporting.setCityCountyCaseNbr("12-345-CTY");   // ActIds.json, root_extension_txt for type_cd=CITY
        reporting.setLegacyCaseId("12-345-LGY");        // ActIds.json, root_extension_txt for type_cd=LEGACY
        reporting.setPhcInvFormId(10638298L);           // InvestigationObservationIds.json, source_act_uid for act_type_cd=PHCInvForm
        reporting.setRdbTableNameList("D_INV_CLINICAL,D_INV_PLACE_REPEAT,D_INV_ADMINISTRATIVE"); // InvestigationCaseAnswers.json, rdb_table_nm
        reporting.setInvestigationCount(1L);
        reporting.setCaseCount(1L);
        reporting.setInvestigatorAssignedDatetime("2024-01-15T10:20:57.787");
        return reporting;
    }

    public static NotificationUpdate constructNotificationUpdate(Long notificationUid) {
        final NotificationUpdate notification = new NotificationUpdate();
        notification.setNotificationUid(notificationUid);
        notification.setInvestigationNotifications(readFileData(FILE_PATH_PREFIX + "InvestigationNotification.json"));
        return notification;
    }

    public static InvestigationCaseManagement constructCaseManagement(Long investigationUid) {
        InvestigationCaseManagement expected = new InvestigationCaseManagement();
        expected.setCaseManagementUid(1001L);
        expected.setPublicHealthCaseUid(investigationUid);
        expected.setAddUserId(10055001L);
        expected.setCaseOid(1300110031L);
        expected.setInitFupInitialFollUpCd("SF");
        expected.setInitFupInitialFollUp("Surveillance Follow-up");
        expected.setInitFupInternetFollUpCd("N");
        expected.setInternetFollUp("No");
        expected.setInitFupNotifiableCd("06");
        expected.setInitFollUpNotifiable("6-Yes, Notifiable");
        expected.setInitFupClinicCode("80000");
        expected.setSurvInvestigatorAssgnDt("2024-07-15T00:00:00");
        expected.setSurvClosedDt("2024-07-22T00:00:00");
        expected.setSurvProviderContactCd("S");
        expected.setSurvProviderContact("S - Successful");
        expected.setSurvProvExmReason("M");
        expected.setSurvProviderExamReason("Community Screening");
        expected.setSurvProviderDiagnosis("900");
        expected.setSurvPatientFollUp("FF");
        expected.setSurvPatientFollUpCd("Field Follow-up");
        expected.setAdi900StatusCd("02");
        expected.setStatus900("2 - Newly Diagnosed");
        expected.setFlFupFieldRecordNum("1310005124");
        expected.setFlFupInvestigatorAssgnDt("2024-07-23T00:00:00");
        expected.setFlFupInitAssgnDt("2024-07-23T00:00:00");
        expected.setFldFollUpProvExmReason("M");
        expected.setFlFupProvExmReason("Community Screening");
        expected.setFldFollUpProvDiagnosis("900");
        expected.setFlFupProvDiagnosis("900");
        expected.setFldFollUpNotificationPlan("3");
        expected.setFlFupNotificationPlanCd("3 - Dual");
        expected.setFldFollUpExpectedIn("Y");
        expected.setFlFupExpectedInInd("Yes");
        expected.setFlFupExpectedDt("2024-07-21T00:00:00");
        expected.setFlFupExamDt("2024-07-19T00:00:00");
        expected.setFlFupDispositionCd("1");
        expected.setFlFupDispositionDesc("1 - Prev. Pos");
        expected.setFlFupDispoDt("2024-07-23T00:00:00");
        expected.setActRefTypeCd("2");
        expected.setFlFupActualRefType("2 - Provider");
        expected.setFlFupInternetOutcomeCd("I1");
        expected.setFlFupInternetOutcome("I1 - Informed, Urgent Health Matter");
        expected.setCaInterviewerAssignDt("2024-07-22T00:00:00");
        expected.setCaInitIntvwrAssgnDt("2024-07-22T00:00:00");
        expected.setEpiLinkId("1310005124");
        expected.setPatIntvStatusCd("A");
        expected.setCaPatientIntvStatus("A - Awaiting");
        expected.setInitiatingAgncy("Arizona");
        expected.setOojInitgAgncyRecdDate("2024-07-15T00:00:00");
        return expected;
    }


    public static Interview constructInterview(Long interviewUid) {
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
        return interview;

    }

    public static InterviewReporting constructInvestigationInterview(Long interviewUid, Long batchId) {
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
        interviewReporting.setBatchId(batchId);
        return interviewReporting;
    }


    public static InterviewAnswer constructInvestigationInterviewAnswer(Long interviewUid, Long batchId) {
        InterviewAnswer interviewAnswer = new InterviewAnswer();
        interviewAnswer.setInterviewUid(interviewUid);
        interviewAnswer.setAnswerVal("Yes");
        interviewAnswer.setRdbColumnNm("IX_CONTACTS_NAMED_IND");
        interviewAnswer.setBatchId(batchId);
        return interviewAnswer;
    }

    public static InterviewNote constructInvestigationInterviewNote(Long interviewUid, Long batchId) {
        InterviewNote interviewNote = new InterviewNote();
        interviewNote.setInterviewUid(interviewUid);
        interviewNote.setNbsAnswerUid(21L);
        interviewNote.setCommentDate("2024-11-13T15:27:00");
        interviewNote.setUserFirstName("super");
        interviewNote.setUserLastName("user");
        interviewNote.setUserComment("Test123");
        interviewNote.setRecordStatusCd("");
        interviewNote.setBatchId(batchId);
        return interviewNote;
    }

    public static Contact constructContact(Long contactUid) {
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
        contact.setSubjectEntityUid(123L);
        contact.setVersionCtrlNbr(1L);
        contact.setContactExposureSiteUid(123L);
        contact.setProviderContactInvestigatorUid(1234L);
        contact.setDispositionedByUid(123L);
        return contact;
    }

    public static ContactReporting constructContactReporting(Long contactUid) {
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
        contactReporting.setSubjectEntityUid(123L);
        contactReporting.setVersionCtrlNbr(1L);
        contactReporting.setContactExposureSiteUid(123L);
        contactReporting.setProviderContactInvestigatorUid(1234L);
        contactReporting.setDispositionedByUid(123L);
        return contactReporting;
    }


    public static ContactAnswer constructContactAnswers(Long contactUid) {
        ContactAnswer contactAnswer = new ContactAnswer();
        contactAnswer.setContactUid(contactUid);
        contactAnswer.setAnswerVal("Common Space");
        contactAnswer.setRdbColumnNm("CTT_EXPOSURE_TYPE");
        return contactAnswer;
    }

    public static Vaccination constructVaccination(Long vaccinationUid) {
        Vaccination vaccination = new Vaccination();
        vaccination.setVaccinationUid(vaccinationUid);
        vaccination.setAddTime("2024-01-01T10:00:00");
        vaccination.setAddUserId(100L);
        vaccination.setAgeAtVaccination(20);
        vaccination.setAgeAtVaccinationUnit(null);
        vaccination.setLocalId("VAC23");
        vaccination.setElectronicInd("");
        vaccination.setVaccinationAdministeredNm("");
        vaccination.setVaccineExpirationDt("2024-02-06T08:00:00");
        vaccination.setVaccinationAnatomicalSite("");
        vaccination.setVaccineManufacturerNm("test");
        vaccination.setMaterialCd("102");
        return vaccination;
    }

    public static VaccinationAnswer constructVaccinationAnswers(Long vaccinationUid) {
        VaccinationAnswer vaccinationAnswer = new VaccinationAnswer();
        vaccinationAnswer.setVaccinationUid(vaccinationUid);
        vaccinationAnswer.setRdbColumnNm("TEST");
        vaccinationAnswer.setAnswerVal("TEST VAL");
        return vaccinationAnswer;
    }

    public static VaccinationReporting constructVaccinationReporting(Long vaccinationUid) {
        VaccinationReporting vaccinationReporting = new VaccinationReporting();
        vaccinationReporting.setVaccinationUid(vaccinationUid);
        vaccinationReporting.setAddTime("2024-01-01T10:00:00");
        vaccinationReporting.setAddUserId(100L);
        vaccinationReporting.setAgeAtVaccination(20);
        vaccinationReporting.setAgeAtVaccinationUnit(null);
        vaccinationReporting.setLocalId("VAC23");
        vaccinationReporting.setElectronicInd("");
        vaccinationReporting.setVaccinationAdministeredNm("");
        vaccinationReporting.setVaccineExpirationDt("2024-02-06T08:00:00");
        vaccinationReporting.setVaccinationAnatomicalSite("");
        vaccinationReporting.setVaccineManufacturerNm("test");
        vaccinationReporting.setMaterialCd("102");
        return vaccinationReporting;
    }

    public static Treatment constructTreatment(Long treatmentUid) {
        Treatment treatment = new Treatment();
        treatment.setTreatmentUid(treatmentUid);
        treatment.setOrganizationUid(67890L);
        treatment.setProviderUid(11111L);
        treatment.setPatientTreatmentUid(22222L);
        treatment.setTreatmentName("Test Treatment");
        treatment.setTreatmentOid("33333");
        treatment.setTreatmentComments("Test Comments");
        treatment.setTreatmentSharedInd("Y");
        treatment.setCd("TEST_CD");
        treatment.setTreatmentDate("2024-01-01T10:00:00");
        treatment.setTreatmentDrug("Drug123");
        treatment.setTreatmentDrugName("Test Drug");
        treatment.setTreatmentDosageStrength("100");
        treatment.setTreatmentDosageStrengthUnit("mg");
        treatment.setTreatmentFrequency("Daily");
        treatment.setTreatmentDuration("7");
        treatment.setTreatmentDurationUnit("days");
        treatment.setTreatmentRoute("Oral");
        treatment.setLocalId("LOC123");
        treatment.setRecordStatusCd("Active");
        treatment.setAddTime("2024-01-01T10:00:00");
        treatment.setAddUserId(44444L);
        treatment.setLastChangeTime("2024-01-01T10:00:00");
        treatment.setLastChangeUserId(55555L);
        treatment.setVersionControlNumber("1");
        treatment.setAssociatedPhcUids("123456,123457");
        return treatment;
    }
}
