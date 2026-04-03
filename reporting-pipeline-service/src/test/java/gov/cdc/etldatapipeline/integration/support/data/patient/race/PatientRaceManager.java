package gov.cdc.etldatapipeline.integration.support.data.patient.race;

import org.springframework.jdbc.core.simple.JdbcClient;

public class PatientRaceManager {

  private JdbcClient client;

  public PatientRaceManager(final JdbcClient client) {
    this.client = client;
  }

  private static final String ADD_RACE =
      """
      insert into Person_race (
                    person_uid,
                    as_of_date,
                    race_cd,
                    race_category_cd,
                    add_user_id,
                    add_time,
                    last_chg_user_id,
                    last_chg_time,
                    record_status_cd,
                    record_status_time
                ) values (
                    :patient,
                    :asOf,
                    :race,
                    :race,
                    '9999',
                    getDate(),
                    '9999',
                    getDate(),
                    'ACTIVE',
                    getDate()
                );
      """;

  private static final String ADD_DETAILED_RACE =
      """
      insert into Person_race (
                    person_uid,
                    as_of_date,
                    race_cd,
                    race_category_cd,
                    add_user_id,
                    add_time,
                    last_chg_user_id,
                    last_chg_time,
                    record_status_cd,
                    record_status_time
                ) values (
                    :patient,
                    :asOf,
                    :detailedRace,
                    :race,
                    '9999',
                    getDate(),
                    '9999',
                    getDate(),
                    'ACTIVE',
                    getDate()
                );
      """;

  public void add(final long patient, final PatientRace race) {
    // Add the primary race
    client
        .sql(ADD_RACE)
        .param("patient", patient)
        .param("asOf", race.asOf())
        .param("race", race.race().code())
        .update();

    // If one or more "detailed races" are specified, add entries to the race table
    // where race_cd is the suppplied detailed race and race_category_cd is the
    // primary race code
    if (race.detailedRaceCodes() != null) {
      race.detailedRaceCodes()
          .forEach(
              dr ->
                  client
                      .sql(ADD_DETAILED_RACE)
                      .param("patient", patient)
                      .param("asOf", race.asOf())
                      .param("race", race.race().code())
                      .param("detailedRace", dr)
                      .update());
    }
  }
}
