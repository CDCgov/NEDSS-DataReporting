package gov.cdc.nbs.etldatapipeline.testing.identifier;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Responsible for managing database IDs in the Local_UID_generator table */
@Service
public class IdGenerator {

  private JdbcClient client;

  public IdGenerator(@Qualifier("testClient") final JdbcClient client) {
    this.client = client;
  }

  private static final String SELECT = """
      SELECT TOP 1
          UID_prefix_cd,
          seed_value_nbr,
          UID_suffix_cd
      FROM
          NBS_ODSE.dbo.local_uid_generator
      WHERE
          class_name_cd = :type
          OR type_cd = :type

      """;

  private static final String INCREMENT = """
      UPDATE
          NBS_ODSE.dbo.local_uid_generator
      SET
          seed_value_nbr = seed_value_nbr + 1
      WHERE
          class_name_cd = :type
          OR type_cd = :type
      """;

  /**
   * Gets the next valid Id for the provided Type and increments the value. Will
   * throw an exception
   * if the provided type is not found.
   *
   * @param type {@link EntityType}
   * @return {@link GeneratedId}
   */
  @Transactional
  public GeneratedId next(EntityType type) {
    // Retrieve next valid Id
    GeneratedId identifier = client
        .sql(SELECT)
        .param("type", type.toString())
        .query(
            (rs, rn) -> new GeneratedId(
                rs.getString("UID_prefix_cd"),
                rs.getLong("seed_value_nbr"),
                rs.getString("UID_suffix_cd")))
        .single();

    // Increment table
    client.sql(INCREMENT).param("type", type.toString()).update();

    return identifier;
  }

  public record GeneratedId(String prefix, Long id, String suffix) {
    public String toLocalId() {
      return prefix + id.toString() + suffix;
    }
  }

  /**
   * Matches the class_name_cd column of the Local_UID_generator table, other than
   * the NBS entry.
   * Which references the type_cd column as the class_name_cd for type NBS is
   * dynamic based on the
   * jurisdiction
   */
  public enum EntityType {
    NBS,
    CLINICAL_DOCUMENT,
    COINFECTION_GROUP,
    CS_REPORT,
    CT_CONTACT,
    DEDUPLICATION_LOG,
    EPILINK,
    GEOCODING,
    GEOCODING_LOG,
    GROUP,
    INTERVENTION,
    INTERVIEW,
    MATERIAL,
    NBS_DOCUMENT,
    NBS_QUESTION_ID_LDF,
    NBS_QUESTION_LDF,
    NBS_UIMETEDATA_LDF,
    NND_METADATA,
    NON_LIVING_SUBJECT,
    NOTIFICATION,
    OBSERVATION,
    ORGANIZATION,
    PAGE,
    PATIENT_ENCOUNTER,
    PERSON,
    PERSON_GROUP,
    PLACE,
    PUBLIC_HEALTH_CASE,
    RDB_METADATA,
    REFERRAL,
    REPORT,
    REPORTDATASOURCE,
    REPORTDATASOURCECOLUMN,
    REPORTDISPLAYCOLUMN,
    REPORTFILTER,
    REPORTFILTERCODE,
    REPORTFILTERVALUE,
    SECURITY_LOG,
    TREATMENT,
    WORKUP
  }
}
