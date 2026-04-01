package gov.cdc.etldatapipeline.postprocessing.integration.patient;

import gov.cdc.etldatapipeline.postprocessing.integration.id.IdGenerator;
import gov.cdc.etldatapipeline.postprocessing.integration.id.IdGenerator.EntityType;
import gov.cdc.etldatapipeline.postprocessing.integration.id.IdGenerator.GeneratedId;
import java.time.LocalDateTime;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/** Responsible for creating and inserting patient data into the NBS_ODSE for integration testing */
@Component
public class PatientCreator {

  private IdGenerator idGenerator;
  private JdbcClient client;

  public PatientCreator(
      final IdGenerator idGenerator, @Qualifier("testClient") final JdbcClient client) {
    this.idGenerator = idGenerator;
    this.client = client;
  }

  private static final String CREATE_QUERY =
      """
            insert into NBS_ODSE.dbo.Entity(entity_uid, class_cd) values (:id, 'PSN');

            insert into NBS_ODSE.dbo.Person(
                person_uid,
                person_parent_uid,
                local_id,
                version_ctrl_nbr,
                cd,
                electronic_ind,
                edx_ind,
                add_time,
                add_user_id,
                last_chg_time,
                last_chg_user_id,
                record_status_cd,
                record_status_time,
                status_cd,
                status_time
            ) values (
                :id,
                :id,
                :local,
                1,
                'PAT',
                'N',
                'Y',
                :addedOn,
                :addedBy,
                :addedOn,
                :addedBy,
                'ACTIVE',
                :addedOn,
                'A',
                :addedOn
            );
            """;

  public long create() {

    GeneratedId identifier = idGenerator.next(EntityType.PERSON);

    this.client
        .sql(CREATE_QUERY)
        .param("id", identifier.id())
        .param("local", identifier.toLocalId())
        .param("addedOn", LocalDateTime.now())
        .param("addedBy", "9999")
        .update();

    return identifier.id();
  }
}
