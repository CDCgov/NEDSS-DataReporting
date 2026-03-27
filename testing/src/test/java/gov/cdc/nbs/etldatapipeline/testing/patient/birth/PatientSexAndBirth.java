package gov.cdc.nbs.etldatapipeline.testing.patient.birth;

import java.time.LocalDateTime;

/**
 * Contains the data necessary for setting patient Sex and Birth information.
 * The appropriate codes will need to be supplied for Birth State, Birth County,
 * and Birth Country. Most of the Sex and Birth information is stored within the
 * Person table. However, if birth location info is specified then an entry will
 * be added to the Entity_locator_participation and postal_locator tables
 * similar to an address except the "Entity_locator_participation.use_cd" will
 * be "BIR".
 * 
 * 
 * <pre>
 * Sample Values
 * stateCode: 13 -> "Georgia"
 * countyCode: 13121 -> "Fulton County, GA"
 * contryCode: 840 -> "United States"
 * </pre>
 */
public record PatientSexAndBirth(
    LocalDateTime asOf,
    LocalDateTime dob,
    Sex currentSex,
    ReasonUnknown reasonUnknown,
    TransgenderInfo transgenderInfo,
    String additionalGender,
    Sex birthSex,
    MultipleBirth multipleBirth,
    Integer birthOrder,
    String birthCity,
    String birthStateCode,
    String birthCountyCode,
    String birthCountryCode) {

  public enum Sex {
    MALE("M"),
    FEMALE("F"),
    UNKNOWN("U");

    private final String code;

    Sex(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum ReasonUnknown {
    NOT_ASKED("D"),
    REFUSED_TO_ANSWER("R");

    private final String code;

    ReasonUnknown(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum TransgenderInfo {
    DID_NOT_ASK("NASK"),
    FEMALE("F"),
    FTM("FTM"),
    GENDERQUEER_NEITHER_EXCLUSIVELY_MALE_NOR_FEMALE("446131000124102"),
    MALE("M"),
    MTF("MTF"),
    OTHER("OTH"),
    REFUSED("R"),
    TRANSGENDER_UNSPECIFIED("T"),
    UNKNOWN("U");

    private final String code;

    TransgenderInfo(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum MultipleBirth {
    YES("Y"),
    NO("N"),
    UNKNOWN("UNK");

    private final String code;

    MultipleBirth(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

}
