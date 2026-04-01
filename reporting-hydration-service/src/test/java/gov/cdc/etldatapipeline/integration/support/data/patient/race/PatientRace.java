package gov.cdc.etldatapipeline.integration.support.data.patient.race;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Contains the data necessary for creating a new race associated with a
 * patient. A patient may have
 * multiple race entries. Both Patient race and detailed race information is
 * stored in the
 * Person_race table within NBS. The primary race is stored so that race_cd and
 * race_category_cd are
 * both set to the selected race code. Detailed race information is stored where
 * race_cd is the
 * detailed race code and race_category_cd is set to the primary race code.
 *
 * <pre>
 * NBS_ODSE
 * Person.person_uid -> Person_race.person_uid *
 * </pre>
 */
public record PatientRace(LocalDateTime asOf, Race race, List<String> detailedRaceCodes) {

  public enum Race {
    AMERICAN_INDIAN_OR_ALASKA_NATIVE("1002-5"),
    ASIAN("2028-9"),
    BLACK_OR_AFRICAN_AMERICAN("2054-5"),
    MULTI_RACE("M"),
    NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER("2076-8"),
    NOT_ASKED("NASK"),
    OTHER("2131-1"),
    REFUSED_TO_ANSWER("PHC1175"),
    UNKNOWN("U"),
    WHITE("2106-3");

    private final String code;

    Race(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }
}
