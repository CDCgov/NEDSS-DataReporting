package gov.cdc.etldatapipeline.testing.patient.mortality;

import gov.cdc.etldatapipeline.testing.identifier.IdGenerator;
import gov.cdc.etldatapipeline.testing.identifier.IdGenerator.EntityType;
import gov.cdc.etldatapipeline.testing.identifier.IdGenerator.GeneratedId;
import gov.cdc.etldatapipeline.testing.patient.mortality.PatientMortality.Deceased;
import org.springframework.jdbc.core.simple.JdbcClient;

public class PatientMortalityManager {

  private final JdbcClient client;
  private final IdGenerator idGenerator;

  public PatientMortalityManager(final JdbcClient client, final IdGenerator idGenerator) {
    this.client = client;
    this.idGenerator = idGenerator;
  }

  private static final String SET_MORTALITY =
      """
      update person set
        as_of_date_morbidity = :asOf,
        deceased_ind_cd = :deceasedIndicator,
        deceased_time = :dateOfDeath
      where person_uid = :patient;
      """;

  private static final String ADD_MORTALITY_LOCATOR =
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
          'DTH',
          'PST'
      );

      --- Locator
          insert into postal_locator (
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
            :stateCode,
            :countyCode,
            :countryCode,
            getDate(),
            getDate(),
            'ACTIVE',
            getDate()
        );
      """;

  public void set(final long patient, final PatientMortality patientMortality) {
    // Set values on Person table
    client
        .sql(SET_MORTALITY)
        .param("asOf", patientMortality.asOf())
        .param("patient", patient)
        .param(
            "deceasedIndicator",
            patientMortality.deceased() != null ? patientMortality.deceased().code() : null)
        .param("dateOfDeath", patientMortality.dateOfDeath())
        .update();

    // if deceased is "YES" and a location is specified, add an
    // entity_locator_participation + postal_locator entry
    if (Deceased.YES.equals(patientMortality.deceased())
        && (patientMortality.deathCity() != null
            || patientMortality.deathStateCode() != null
            || patientMortality.deathCountryCode() != null)) {
      GeneratedId mortalityId = idGenerator.next(EntityType.NBS);

      this.client
          .sql(ADD_MORTALITY_LOCATOR)
          .param("patient", patient)
          .param("asOf", patientMortality.asOf())
          .param("locator", mortalityId.id())
          .param("city", patientMortality.deathCity())
          .param("countyCode", patientMortality.deathCountyCode())
          .param("stateCode", patientMortality.deathStateCode())
          .param("countryCode", patientMortality.deathCountryCode())
          .update();
    }
  }
}
