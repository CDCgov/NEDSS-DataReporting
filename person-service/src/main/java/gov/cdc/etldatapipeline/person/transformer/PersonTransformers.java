package gov.cdc.etldatapipeline.person.transformer;

import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientElasticSearch;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientKey;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientReporting;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderElasticSearch;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderKey;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderReporting;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import org.springframework.stereotype.Component;

@Component
public class PersonTransformers {
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    public String buildPatientKey(PatientSp p) {
        return jsonGenerator.generateStringJson(PatientKey.builder().patientUid(p.getPersonUid()).build());
    }

    public String buildProviderKey(ProviderSp p) {
        return jsonGenerator.generateStringJson(ProviderKey.builder().providerUid(p.getPersonUid()).build());
    }

    public String processData(PatientSp patientSp, PersonType personType) {
        return jsonGenerator.generateStringJson(processData(patientSp, null, personType));
    }

    public String processData(ProviderSp providerSp, PersonType personType) {
        return jsonGenerator.generateStringJson(processData(null, providerSp, personType));
    }

    public <T extends PersonExtendedProps> T processData(PatientSp patientSp, ProviderSp providerSp,
                                                         PersonType personType) {
        PersonExtendedProps transformedObj =
                switch (personType) {
                    case PATIENT_REPORTING -> buildPatientReporting(patientSp);
                    case PATIENT_ELASTIC_SEARCH -> buildPatientElasticSearch(patientSp);
                    case PROVIDER_REPORTING -> buildProviderReporting(providerSp);
                    case PROVIDER_ELASTIC_SEARCH -> buildProviderElasticSearch(providerSp);
                };
        DataPostProcessor processor = new DataPostProcessor();
        if (personType == PersonType.PATIENT_REPORTING || personType == PersonType.PATIENT_ELASTIC_SEARCH) {
            processor.processPersonName(patientSp.getNameNested(), transformedObj);
            processor.processPersonAddress(patientSp.getAddressNested(), transformedObj);
            processor.processPersonTelephone(patientSp.getTelephoneNested(), transformedObj);
            processor.processPersonEntityData(patientSp.getEntityDataNested(), transformedObj);
            processor.processPersonEmail(patientSp.getEmailNested(), transformedObj);
            processor.processPersonRace(patientSp.getRaceNested(), transformedObj);

        } else if (personType == PersonType.PROVIDER_REPORTING || personType == PersonType.PROVIDER_ELASTIC_SEARCH) {
            processor.processPersonName(providerSp.getNameNested(), transformedObj);
            processor.processPersonAddress(providerSp.getAddressNested(), transformedObj);
            processor.processPersonTelephone(providerSp.getTelephoneNested(), transformedObj);
            processor.processPersonEntityData(providerSp.getEntityDataNested(), transformedObj);
            processor.processPersonEmail(providerSp.getEmailNested(), transformedObj);
        }
        return (T) transformedObj;
    }

    public PatientElasticSearch buildPatientElasticSearch(PatientSp p) {
        return PatientElasticSearch.builder()
                .patientUid(p.getPersonUid())
                .additionalGenderCd(p.getAdditionalGenderCd())
                .addUserId(p.getAddUserId())
                .adultsInHouseNbr(p.getAdultsInHouseNbr())
                .ageReported(p.getAgeReported())
                .ageReportedUnitCd(p.getAgeReportedUnitCd())
                .addTime(p.getAddTime())
                .birthOrderNbr(p.getBirthOrderNbr())
                .birthSex(p.getBirthGenderCd())
                .birthTime(p.getBirthTime())
                .currSexCd(p.getCurrSexCd())
                .childrenInHouseNbr(p.getChildrenInHouseNbr())
                .deceasedTime(p.getDeceasedTime())
                .dedupMatchInd(p.getDedupMatchInd())
                .description(p.getDescription())
                .electronicInd(p.getElectronicInd())
                .ethnicGroupInd(p.getEthnicGroupInd())
                .ethnicUnkReasonCd(p.getEthnicUnkReasonCd())
                .edxInd(p.getEdxInd())
                .educationLevelCd(p.getEducationLevelCd())
                .lastChgUserId(p.getLastChgUserId())
                .lastChgTime(p.getLastChgTime())
                .localId(p.getLocalId())
                .maritalStatusCd(p.getMaritalStatusCd())
                .multipleBirthInd(p.getMultipleBirthInd())
                .occupationCd(p.getOccupationCd())
                .personFirstNm(p.getPersonFirstNm())
                .personMiddleNm(p.getPersonMiddleNm())
                .personLastNm(p.getPersonLastNm())
                .personNmSuffix(p.getPersonNmSuffix())
                .personParentUid(p.getPersonParentUid())
                .preferredGenderCd(p.getPreferredGenderCd())
                .primLangCd(p.getPrimLang())
                .recordStatusTime(p.getRecordStatusTime())
                .recordStatusCd(p.getRecordStatusCd())
                .sexUnkReasonCd(p.getSexUnkReasonCd())
                .statusCd(p.getStatusCd())
                .statusTime(p.getStatusTime())
                .speaksEnglishCd(p.getSpeaksEnglishCd())
                .versionCtrlNbr(p.getVersionCtrlNbr())
                .build();
    }

    public PatientReporting buildPatientReporting(PatientSp p) {
        return PatientReporting.builder()
                .patientUid(p.getPersonUid())
                .addlGenderInfo(p.getAdditionalGenderCd())
                .addUserId(p.getAddUserId())
                .ageReported(p.getAgeReported())
                .ageReportedUnit(p.getAgeReportedUnit())
                .addTime(p.getAddTime())
                .birth_sex(p.getBirthGenderCd())
                .dob(p.getBirthTime())
                .currentSex(p.getCurrentSex())
                .deceasedIndicator(p.getDeceasedInd())
                .deceasedDate(p.getDeceasedTime())
                .generalComments(p.getDescription())
                .entryMethod(p.getElectronicInd())
                .ethnicity(p.getEthnicity())
                .unkEthnicRsn(p.getEthnicUnkReason())
                .lastChgUserId(p.getLastChgUserId())
                .lastChgTime(p.getLastChgTime())
                .localId(p.getLocalId())
                .maritalStatus(p.getMaritalStatus())
                .primaryOccupation(p.getPrimaryOccupation())
                .patientMprUid(p.getPersonParentUid())
                .preferredGender(p.getPreferredGender())
                .primaryLanguage(p.getPrimLang())
                .recordStatus(p.getRecordStatusCd())
                .currSexUnkRsn(p.getSexUnkReasonCd())
                .speaksEnglish(p.getSpeaksEnglish())
                // Fn() - Auth_User
                .addUserName(p.getAddUserName())
                .lastChgUserName(p.getLastChgUserName())
                .build();
    }

    public ProviderElasticSearch buildProviderElasticSearch(ProviderSp p) {
        return ProviderElasticSearch.builder()
                .personUid(p.getPersonUid())
                .providerUid(p.getPersonUid())
                .addTime(p.getAddTime())
                .dedupMatchInd(p.getDedupMatchInd())
                .description(p.getDescription())
                .electronicInd(p.getElectronicInd())
                .edxInd(p.getEdxInd())
                .lastChgUserId(p.getLastChgUserId())
                .lastChgTime(p.getLastChgTime())
                .localId(p.getLocalId())
                .personFirstNm(p.getFirstNm())
                .personMiddleNm(p.getMiddleNm())
                .personLastNm(p.getLastNm())
                .personNmSuffix(p.getNmSuffix())
                .personParentUid(p.getPersonParentUid())
                .recordStatusTime(p.getRecordStatusTime())
                .recordStatusCd(p.getRecordStatusCd())
                .statusCd(p.getStatusCd())
                .statusTime(p.getStatusTime())
                .versionCtrlNbr(p.getVersionCtrlNbr())
                .build();
    }

    public ProviderReporting buildProviderReporting(ProviderSp p) {
        return ProviderReporting.builder()
                .providerUid(p.getPersonUid())
                .localId(p.getLocalId())
                .recordStatus(p.getRecordStatusCd())
                .entryMethod(p.getElectronicInd())
                .generalComments(p.getDescription())
                .addUserId(p.getAddUserId())
                .lastChgUserId(p.getLastChgUserId())
                .addUserName(p.getAddUserName())
                .lastChgUserName(p.getLastChgUserName())
                .lastChgTime(p.getLastChgTime())
                .addTime(p.getAddTime())
                .build();
    }
}
