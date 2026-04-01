package gov.cdc.etldatapipeline.integration.functional.patient;

import java.util.Optional;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

@Component
@Profile("test")
public class DPatientFinder {

  private final JdbcClient client;

  public DPatientFinder(@Qualifier("rdbClient") JdbcClient client) {
    this.client = client;
  }

  private static final String SELECT_KEY_BY_ID = """
      SELECT TOP 1
          patient_key
      FROM
          D_PATIENT
      WHERE
          patient_mpr_uid = :id
      """;

  public Optional<Long> findDPatientKeyWithRetry(long id) {
    return client.sql(SELECT_KEY_BY_ID).param("id", id).query(Long.class).optional();
  }
}
