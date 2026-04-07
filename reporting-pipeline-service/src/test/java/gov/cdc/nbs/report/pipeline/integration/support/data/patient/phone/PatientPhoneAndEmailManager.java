package gov.cdc.nbs.report.pipeline.integration.support.data.patient.phone;

import gov.cdc.nbs.report.pipeline.integration.support.identifier.IdGenerator;
import gov.cdc.nbs.report.pipeline.integration.support.identifier.IdGenerator.EntityType;
import gov.cdc.nbs.report.pipeline.integration.support.identifier.IdGenerator.GeneratedId;
import org.springframework.jdbc.core.simple.JdbcClient;

public class PatientPhoneAndEmailManager {

  private JdbcClient client;
  private IdGenerator idGenerator;

  public PatientPhoneAndEmailManager(final JdbcClient client, final IdGenerator idGenerator) {
    this.client = client;
    this.idGenerator = idGenerator;
  }

  private static final String ADD_PHONE_EMAIL =
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
                    cd,
                    class_cd,
                    locator_desc_txt
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
                    :use,
                    :type,
                    'TELE',
                    :comments
                );

                insert into Tele_locator (
                    tele_locator_uid,
                    cntry_cd,
                    phone_nbr_txt,
                    extension_txt,
                    email_address,
                    add_time,
                    last_chg_time,
                    record_status_cd,
                    record_status_time
                ) values (
                    :locator,
                    :countryCode,
                    :number,
                    :extension,
                    :email,
                    getDate(),
                    getDate(),
                    'ACTIVE',
                    getDate()
                );
      """;

  public void add(final long patient, final PatientPhoneAndEmail phoneEmail) {
    GeneratedId phoneEmailId = idGenerator.next(EntityType.NBS);

    this.client
        .sql(ADD_PHONE_EMAIL)
        .param("patient", patient)
        .param("locator", phoneEmailId.id())
        .param("asOf", phoneEmail.asOf())
        .param("use", phoneEmail.use().code())
        .param("type", phoneEmail.type().code())
        .param("comments", phoneEmail.comments())
        .param("locator", phoneEmailId.id())
        .param("countryCode", phoneEmail.countryCode())
        .param("number", phoneEmail.phoneNumber())
        .param("extension", phoneEmail.extension())
        .param("email", phoneEmail.email())
        .update();
  }
}
