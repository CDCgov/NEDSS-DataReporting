package gov.cdc.nbs.etldatapipeline.testing.patient.name;

import java.time.LocalDateTime;

/**
 * Contains the data necessary for creating a new name associated with a
 * patient. A patient may have multiple name entries. Patient name information
 * is stored in the Person_name table within NBS.
 * 
 * <pre>
 * NBS_ODSE
 * Person.person_uid -> Person_name.person_uid
 * </pre>
 */
public record PatientName(
    LocalDateTime asOf,
    Type type,
    Prefix prefix,
    String first,
    String middle,
    String secondMiddle,
    String last,
    String secondLast,
    Suffix suffix,
    Degree degree) {

  public PatientName(LocalDateTime asOf, String first, String middle, String last, Suffix suffix) {
    this(
        asOf,
        Type.LEGAL,
        null,
        first,
        middle,
        null,
        last,
        null,
        suffix,
        null);
  }

  public PatientName(String first, String last) {
    this(
        LocalDateTime.now(),
        Type.LEGAL,
        null,
        last,
        null,
        first,
        null,
        null,
        null,
        null);
  }

  public enum Type {
    ADOPTED("AD"),
    ALIAS("AL"),
    ARTIST("A"),
    CODED_PSEUDO("S"),
    INDIGENOUS("I"),
    LEGAL("L"),
    LICENSE("C"),
    MAIDEN("M"),
    MOTHERS_NAME("MO"),
    NAME_AT_BIRTH("BR"),
    PARTNER_OR_SPOUSE("P"),
    RELIGIOUS("R");

    private final String code;

    Type(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum Prefix {
    BISHOP("BSHP"),
    BROTHER("BRO"),
    CARDINAL("CARD"),
    DOCTOR("DR"),
    FATHER("FATH"),
    HONORABLE("HON"),
    MISS("MISS"),
    MONSIGNOR("MON"),
    MOTHER("MOTH"),
    MR("MR"),
    MRS("MRS"),
    MS("MS"),
    PASTOR("PAST"),
    PROFESSOR("PROF"),
    RABBI("RAB"),
    REVEREND("REV"),
    SISTER("SIS"),
    SWAMI("SWM");

    private final String code;

    Prefix(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum Suffix {
    ESQUIRE("ESQ"),
    THE_SECOND("II"),
    THE_THIRD("III"),
    THE_FOURTH("IV"),
    THE_FIFTH("V"),
    JUNIOR("JR"),
    SENIOR("SR");

    private final String code;

    Suffix(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum Degree {
    APN("APN"),
    BA("BA"),
    BS("BS"),
    BSN("BSN"),
    CNM("CNM"),
    CNP("CNP"),
    CPA("CPA"),
    DD("DD"),
    DDS("DDS"),
    DMD("DMD"),
    DO("DO"),
    DRN("DRN"),
    DVM("DVM"),
    JD("JD"),
    LLB("LLB"),
    LLD("LLD"),
    LPN("LPN"),
    MA("MA"),
    MBA("MBA"),
    MD("MD"),
    MED("MED"),
    MPH("MPH"),
    MS("MS"),
    MSN("MSN"),
    NP("NP"),
    PA("PA"),
    PHD("PHD"),
    RN("RN");

    private final String code;

    Degree(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

}
