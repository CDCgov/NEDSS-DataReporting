package gov.cdc.etldatapipeline.integration.support.data.patient;

import gov.cdc.etldatapipeline.integration.support.data.patient.address.PatientAddress;
import gov.cdc.etldatapipeline.integration.support.data.patient.address.PatientAddressManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.birth.PatientSexAndBirth;
import gov.cdc.etldatapipeline.integration.support.data.patient.birth.PatientSexAndBirthManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.comment.PatientComment;
import gov.cdc.etldatapipeline.integration.support.data.patient.comment.PatientCommentManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.ethnicity.PatientEthnicity;
import gov.cdc.etldatapipeline.integration.support.data.patient.ethnicity.PatientEthnicityManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.general.PatientGeneralInfo;
import gov.cdc.etldatapipeline.integration.support.data.patient.general.PatientGeneralInfoManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.identification.PatientIdentification;
import gov.cdc.etldatapipeline.integration.support.data.patient.identification.PatientIdentificationManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.mortality.PatientMortality;
import gov.cdc.etldatapipeline.integration.support.data.patient.mortality.PatientMortalityManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.name.PatientName;
import gov.cdc.etldatapipeline.integration.support.data.patient.name.PatientNameManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.phone.PatientPhoneAndEmail;
import gov.cdc.etldatapipeline.integration.support.data.patient.phone.PatientPhoneAndEmailManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.race.PatientRace;
import gov.cdc.etldatapipeline.integration.support.data.patient.race.PatientRaceManager;
import gov.cdc.etldatapipeline.integration.support.identifier.IdGenerator;
import gov.cdc.etldatapipeline.integration.support.identifier.IdGenerator.EntityType;
import gov.cdc.etldatapipeline.integration.support.identifier.IdGenerator.GeneratedId;
import java.time.LocalDateTime;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/** Responsible for creating and inserting patient data into the NBS_ODSE for testing */
@Component
@Profile("test")
public class PatientManager {

  private final IdGenerator idGenerator;
  private final JdbcClient client;
  private final PatientNameManager nameManager;
  private final PatientAddressManager addressManager;
  private final PatientPhoneAndEmailManager phoneEmailManager;
  private final PatientRaceManager raceManager;
  private final PatientEthnicityManager ethnicityManager;
  private final PatientIdentificationManager identificationManager;
  private final PatientCommentManager commentManager;
  private final PatientSexAndBirthManager sexAndBirthManager;
  private final PatientMortalityManager mortalityManager;
  private final PatientGeneralInfoManager generalInfoManager;

  public PatientManager(@Qualifier("adminClient") final JdbcClient client) {
    this.client = client;
    this.idGenerator = new IdGenerator(client);
    this.nameManager = new PatientNameManager(client);
    this.addressManager = new PatientAddressManager(client, idGenerator);
    this.phoneEmailManager = new PatientPhoneAndEmailManager(client, idGenerator);
    this.raceManager = new PatientRaceManager(client);
    this.ethnicityManager = new PatientEthnicityManager(client);
    this.identificationManager = new PatientIdentificationManager(client);
    this.commentManager = new PatientCommentManager(client);
    this.sexAndBirthManager = new PatientSexAndBirthManager(client, idGenerator);
    this.mortalityManager = new PatientMortalityManager(client, idGenerator);
    this.generalInfoManager = new PatientGeneralInfoManager(client);
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

  public GeneratedId create(LocalDateTime addedOn) {

    GeneratedId identifier = idGenerator.next(EntityType.PERSON);

    this.client
        .sql(CREATE_QUERY)
        .param("id", identifier.id())
        .param("local", identifier.toLocalId())
        .param("addedOn", addedOn)
        .param("addedBy", "9999")
        .update();

    return identifier;
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

  public void addEthnicity(final long patient, final PatientEthnicity ethnicity) {
    this.ethnicityManager.add(patient, ethnicity);
  }

  public void addIdentification(final long patient, final PatientIdentification identification) {
    this.identificationManager.add(patient, identification);
  }

  public void setComment(final long patient, final PatientComment comment) {
    commentManager.set(patient, comment);
  }

  public void setSexAndBirthInfo(final long patient, final PatientSexAndBirth patientSexAndBirth) {
    sexAndBirthManager.set(patient, patientSexAndBirth);
  }

  public void setMortalityInfo(final long patient, final PatientMortality patientMortality) {
    mortalityManager.set(patient, patientMortality);
  }

  public void setGeneralInfo(final long patient, final PatientGeneralInfo patientGeneralInfo) {
    generalInfoManager.set(patient, patientGeneralInfo);
  }
}
