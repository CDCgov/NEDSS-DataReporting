package gov.cdc.etldatapipeline.testing.patient.name;

import org.springframework.jdbc.core.simple.JdbcClient;

/** Responsible for managing patient name data into the NBS_ODSE */
public class PatientNameManager {

  private JdbcClient client;

  public PatientNameManager(final JdbcClient client) {
    this.client = client;
  }

  private static final String ADD_NAME =
      """
      insert into Person_name (
                person_uid,
                person_name_seq,
                as_of_date,
                nm_use_cd,
                first_nm,
                first_nm_sndx,
                middle_nm,
                middle_nm2,
                last_nm,
                last_nm_sndx,
                last_nm2,
                last_nm2_sndx,
                nm_suffix,
                nm_degree,
                status_cd,
                status_time,
                add_time,
                last_chg_time,
                record_status_time,
                record_status_cd
            ) values (
                :patient,
                (select count(*) + 1 from Person_name where person_uid = :patient),
                :asOf,
                :type,
                :first,
                soundex(:first),
                :middle,
                :middle2,
                :last,
                soundex(:last),
                :last2,
                soundex(:last2),
                :suffix,
                :degree,
                'A',
                :asOf,
                :asOf,
                :asOf,
                :asOf,
                'ACTIVE'
            );
      """;

  public void add(long patient, PatientName name) {
    this.client
        .sql(ADD_NAME)
        .param("patient", patient)
        .param("asOf", name.asOf())
        .param("type", name.type() != null ? name.type().code() : null)
        .param("first", name.first())
        .param("middle", name.middle())
        .param("middle2", name.secondMiddle())
        .param("last", name.last())
        .param("last2", name.secondLast())
        .param("suffix", name.suffix() != null ? name.suffix().code() : null)
        .param("degree", name.degree() != null ? name.degree().code() : null)
        .update();
  }
}
