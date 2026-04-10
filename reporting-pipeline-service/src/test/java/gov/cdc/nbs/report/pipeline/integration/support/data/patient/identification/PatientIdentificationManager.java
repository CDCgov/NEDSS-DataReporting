package gov.cdc.nbs.report.pipeline.integration.support.data.patient.identification;

import org.springframework.jdbc.core.simple.JdbcClient;

public class PatientIdentificationManager {

  private final JdbcClient client;

  public PatientIdentificationManager(final JdbcClient client) {
    this.client = client;
  }

  private static final String ADD_IDENTIFICATION =
      """
      insert into Entity_id (
          entity_uid,
          entity_id_seq,
          as_of_date,
          type_cd,
          assigning_authority_cd,
          root_extension_txt,
          add_time,
          record_status_time,
          record_status_cd
      ) values (
          :patient,
          (select count(*) + 1 from Entity_id where entity_uid = :patient),
          :asOf,
          :type,
          :issuer,
          :value,
          getDate(),
          getdate(),
          'ACTIVE'
      );
      """;

  public void add(final long patient, final PatientIdentification identification) {
    String assigningAuthority = null;
    // Assigning Authority is allowed to be null
    if (identification.assigningAuthority() != null) {
      assigningAuthority = identification.assigningAuthority().code();
    }

    this.client
        .sql(ADD_IDENTIFICATION)
        .param("patient", patient)
        .param("asOf", identification.asOf())
        .param("type", identification.type().code())
        .param("issuer", assigningAuthority)
        .param("value", identification.value())
        .update();
  }
}
