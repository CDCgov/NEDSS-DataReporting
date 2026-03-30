package gov.cdc.etldatapipeline.testing.patient.general;

import org.springframework.jdbc.core.simple.JdbcClient;

public class PatientGeneralInfoManager {

  private final JdbcClient client;

  public PatientGeneralInfoManager(final JdbcClient client) {
    this.client = client;
  }

  public static final String SET_GENERAL_INFO =
      """
      update person set
        as_of_date_general = :asOf,
        marital_status_cd = :maritalStatusCode,
        mothers_maiden_nm = :mothersMaidenName,
        adults_in_house_nbr = :adultsInHouse,
        children_in_house_nbr = :childrenInHouse,
        occupation_cd = :occupationCode,
        education_level_cd = :educationLevelCode,
        prim_lang_cd = :primaryLanguageCode,
        speaks_english_cd = :speaksEnglishCode,
        ehars_id = :hivCaseId
      where person_uid = :patient
      """;

  public void set(final long patient, final PatientGeneralInfo generalInfo) {
    client
        .sql(SET_GENERAL_INFO)
        .param("asOf", generalInfo.asOf())
        .param("patient", patient)
        .param(
            "maritalStatusCode",
            generalInfo.maritalStatus() != null ? generalInfo.maritalStatus().code() : null)
        .param("mothersMaidenName", generalInfo.mothersMaiden())
        .param("adultsInHouse", generalInfo.numberOfAdults())
        .param("childrenInHouse", generalInfo.numberOfChildren())
        .param(
            "occupationCode",
            generalInfo.occupation() != null ? generalInfo.occupation().code() : null)
        .param(
            "educationLevelCode",
            generalInfo.highestLevelOfEducation() != null
                ? generalInfo.highestLevelOfEducation().code()
                : null)
        .param(
            "primaryLanguageCode",
            generalInfo.primaryLanguage() != null ? generalInfo.primaryLanguage().code() : null)
        .param(
            "speaksEnglishCode",
            generalInfo.speaksEnglish() != null ? generalInfo.speaksEnglish().code() : null)
        .param("hivCaseId", generalInfo.stateHivCaseId())
        .update();
  }
}
