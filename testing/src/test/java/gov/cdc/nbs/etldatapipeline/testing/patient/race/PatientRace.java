package gov.cdc.nbs.etldatapipeline.testing.patient.race;

import java.time.LocalDateTime;
import java.util.List;

public record PatientRace(
    LocalDateTime asOf,
    Race race,
    List<String> detailedRaceCodes) {

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
