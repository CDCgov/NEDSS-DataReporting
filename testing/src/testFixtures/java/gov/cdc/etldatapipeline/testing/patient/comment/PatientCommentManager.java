package gov.cdc.etldatapipeline.testing.patient.comment;

import org.springframework.jdbc.core.simple.JdbcClient;

public class PatientCommentManager {

  private final JdbcClient client;

  public PatientCommentManager(final JdbcClient client) {
    this.client = client;
  }

  private static final String SET_COMMENT =
      """
      update person set
        as_of_date_admin = :asOf,
        description = :comment
      where
        person_uid = :patient;
      """;

  public void set(final long patient, final PatientComment patientComment) {
    this.client
        .sql(SET_COMMENT)
        .param("patient", patient)
        .param("asOf", patientComment.asOf())
        .param("comment", patientComment.comment())
        .update();
  }
}
