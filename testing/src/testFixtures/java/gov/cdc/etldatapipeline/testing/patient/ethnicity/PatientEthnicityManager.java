package gov.cdc.etldatapipeline.testing.patient.ethnicity;

import gov.cdc.etldatapipeline.testing.patient.ethnicity.PatientEthnicity.Ethnicity;
import org.springframework.jdbc.core.simple.JdbcClient;

public class PatientEthnicityManager {

  private final JdbcClient client;

  public PatientEthnicityManager(final JdbcClient client) {
    this.client = client;
  }

  private static final String SET_ETHNICITY =
      """
       update person set
            ethnic_group_ind = :ethnicity,
            as_of_date_ethnicity = :asOf,
            ethnic_unk_reason_cd = :unknownReasonCode
        where person_uid = :patient
      """;

  private static final String ADD_SPANISH_ORIGIN =
      """
        insert into Person_ethnic_group(
            person_uid,
            ethnic_group_cd,
            add_time,
            record_status_cd
        ) values (
            :patient,
            :spanishOriginCode,
            getDate(),
            'ACTIVE'
        )
      """;

  public void add(final long patient, final PatientEthnicity patientEthnicity) {
    String reasonUnknown = null;
    // Reason unknown should only be set when ethnicity is "UNK"
    if (Ethnicity.UNKNOWN.equals(patientEthnicity.ethnicity())
        && patientEthnicity.reasonUnknown() != null) {
      reasonUnknown = patientEthnicity.reasonUnknown().code();
    }

    // Set ethnicity values on Person table
    client
        .sql(SET_ETHNICITY)
        .param("patient", patient)
        .param("asOf", patientEthnicity.asOf())
        .param("ethnicity", patientEthnicity.ethnicity().code())
        .param("unknownReasonCode", reasonUnknown)
        .update();

    // If ethnicity is Hispanic or Latino and Spanish Origins are specified, insert
    // values into person_ethnic_group table
    if (Ethnicity.HISPANIC_OR_LATINO.equals(patientEthnicity.ethnicity())
        && patientEthnicity.spanishOrigins() != null) {
      patientEthnicity
          .spanishOrigins()
          .forEach(
              so -> {
                client
                    .sql(ADD_SPANISH_ORIGIN)
                    .param("patient", patient)
                    .param("spanishOriginCode", so.code())
                    .update();
              });
    }
  }
}
