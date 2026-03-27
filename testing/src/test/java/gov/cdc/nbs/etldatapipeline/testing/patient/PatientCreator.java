package gov.cdc.nbs.etldatapipeline.testing.patient;

import gov.cdc.nbs.etldatapipeline.testing.identifier.IdGenerator;
import gov.cdc.nbs.etldatapipeline.testing.identifier.IdGenerator.EntityType;
import gov.cdc.nbs.etldatapipeline.testing.identifier.IdGenerator.GeneratedId;
import gov.cdc.nbs.etldatapipeline.testing.patient.address.PatientAddress;
import gov.cdc.nbs.etldatapipeline.testing.patient.address.PatientAddressManager;
import gov.cdc.nbs.etldatapipeline.testing.patient.name.PatientName;
import gov.cdc.nbs.etldatapipeline.testing.patient.name.PatientNameManager;
import gov.cdc.nbs.etldatapipeline.testing.patient.phone.PatientPhoneAndEmail;
import gov.cdc.nbs.etldatapipeline.testing.patient.phone.PatientPhoneAndEmailManager;
import gov.cdc.nbs.etldatapipeline.testing.patient.race.PatientRace;
import gov.cdc.nbs.etldatapipeline.testing.patient.race.PatientRaceManager;

import java.time.LocalDateTime;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Responsible for creating and inserting patient data into the NBS_ODSE for
 * testing
 */
@Component
public class PatientCreator {

  private IdGenerator idGenerator;
  private JdbcClient client;
  private PatientNameManager nameManager;
  private PatientAddressManager addressManager;
  private PatientPhoneAndEmailManager phoneEmailManager;
  private PatientRaceManager raceManager;

  public PatientCreator(
      final IdGenerator idGenerator,
      @Qualifier("testClient") final JdbcClient client,
      final PatientNameManager nameManager,
      final PatientAddressManager addressManager,
      final PatientPhoneAndEmailManager phoneEmailManager,
      final PatientRaceManager raceManager) {
    this.idGenerator = idGenerator;
    this.client = client;
    this.nameManager = nameManager;
    this.addressManager = addressManager;
    this.phoneEmailManager = phoneEmailManager;
    this.raceManager = raceManager;
  }

  private static final String CREATE_QUERY = """
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

  public void addName(final long patient, final PatientName name) {
    nameManager.add(patient, name);
  }

  public void addAddress(final long patient, final PatientAddress address) {
    addressManager.add(patient, address);
  }

  public void addPhoneAndEmail(final long patient, final PatientPhoneAndEmail phone) {
    phoneEmailManager.add(patient, phone);
  }

  public void addRace(final long patient, final PatientRace race) {
    this.raceManager.add(patient, race);
  }

  // Create a Person with
  // Ethnicity
  // Identifier
}
