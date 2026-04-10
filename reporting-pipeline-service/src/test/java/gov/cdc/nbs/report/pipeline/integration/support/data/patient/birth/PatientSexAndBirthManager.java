package gov.cdc.nbs.report.pipeline.integration.support.data.patient.birth;

import gov.cdc.nbs.report.pipeline.integration.support.data.patient.birth.PatientSexAndBirth.Sex;
import gov.cdc.nbs.report.pipeline.integration.support.identifier.IdGenerator;
import gov.cdc.nbs.report.pipeline.integration.support.identifier.IdGenerator.EntityType;
import gov.cdc.nbs.report.pipeline.integration.support.identifier.IdGenerator.GeneratedId;
import org.springframework.jdbc.core.simple.JdbcClient;

public class PatientSexAndBirthManager {

  private final JdbcClient client;
  private final IdGenerator idGenerator;

  public PatientSexAndBirthManager(final JdbcClient client, final IdGenerator idGenerator) {
    this.client = client;
    this.idGenerator = idGenerator;
  }

  private static final String SET_SEX_AND_BIRTH_INFO =
      """
      update Person set
        as_of_date_sex = :asOf,
        birth_time = :birthDate,
        curr_sex_cd = :currentSexCode,
        sex_unk_reason_cd = :sexUnknownReasonCode,
        preferred_gender_cd = :transgenderInfoCode,
        additional_gender_cd = :additionalGender,
        birth_gender_cd = :birthSex,
        multiple_birth_ind = :multipleBirthCode,
        birth_order_nbr = :birthOrder
      where person_uid = :patient
      """;

  private static final String ADD_BIRTH_LOCATOR =
      """
      --- Entity Participation
        insert into Entity_locator_participation (
            version_ctrl_nbr,
            entity_uid,
            locator_uid,
            add_time,
            last_chg_time,
            record_status_cd,
            record_status_time,
            status_cd,
            status_time,
            as_of_date,
            use_cd,
            class_cd
        ) values (
            1,
            :patient,
            :locator,
            getDate(),
            getDate(),
            'ACTIVE',
            getDate(),
            'A',
            getDate(),
            :asOf,
            'BIR',
            'PST'
        );

      --- Postal Locator
        insert into Postal_locator (
            postal_locator_uid,
            city_desc_txt,
            cnty_cd,
            state_cd,
            cntry_cd,
            add_time,
            last_chg_time,
            record_status_cd,
            record_status_time
        ) values (
            :locator,
            :city,
            :countyCode,
            :stateCode,
            :countryCode,
            getDate(),
            getDate(),
            'ACTIVE',
            getDate()
        );
      """;

  public void set(final long patient, final PatientSexAndBirth patientSexAndBirth) {
    String sexUnknownReasonCode = null;
    // Only set reasonUnknown if currentSex is Unknown
    if (Sex.UNKNOWN.equals(patientSexAndBirth.currentSex())
        && patientSexAndBirth.reasonUnknown() != null) {
      sexUnknownReasonCode = patientSexAndBirth.reasonUnknown().code();
    }

    // Set patient's sex and birth info
    this.client
        .sql(SET_SEX_AND_BIRTH_INFO)
        .param("patient", patient)
        .param("asOf", patientSexAndBirth.asOf())
        .param("birthDate", patientSexAndBirth.dob())
        .param(
            "currentSexCode",
            patientSexAndBirth.currentSex() != null ? patientSexAndBirth.currentSex().code() : null)
        .param("sexUnknownReasonCode", sexUnknownReasonCode)
        .param(
            "transgenderInfoCode",
            patientSexAndBirth.transgenderInfo() != null
                ? patientSexAndBirth.transgenderInfo().code()
                : null)
        .param("additionalGender", patientSexAndBirth.additionalGender())
        .param(
            "birthSex",
            patientSexAndBirth.birthSex() != null ? patientSexAndBirth.birthSex().code() : null)
        .param(
            "multipleBirthCode",
            patientSexAndBirth.multipleBirth() != null
                ? patientSexAndBirth.multipleBirth().code()
                : null)
        .param("birthOrder", patientSexAndBirth.birthOrder())
        .update();

    // If birth location data is provided, add a locator entry
    if (patientSexAndBirth.birthCity() != null
        || patientSexAndBirth.birthStateCode() != null
        || patientSexAndBirth.birthCountryCode() != null) {
      GeneratedId addressId = idGenerator.next(EntityType.NBS);

      this.client
          .sql(ADD_BIRTH_LOCATOR)
          .param("patient", patient)
          .param("asOf", patientSexAndBirth.asOf())
          .param("locator", addressId.id())
          .param("city", patientSexAndBirth.birthCity())
          .param("countyCode", patientSexAndBirth.birthCountyCode())
          .param("stateCode", patientSexAndBirth.birthStateCode())
          .param("countryCode", patientSexAndBirth.birthCountryCode())
          .update();
    }
  }
}
