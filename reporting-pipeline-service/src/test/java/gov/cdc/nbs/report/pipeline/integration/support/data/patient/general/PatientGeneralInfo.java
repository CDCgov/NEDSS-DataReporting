package gov.cdc.nbs.report.pipeline.integration.support.data.patient.general;

import java.time.LocalDateTime;

public record PatientGeneralInfo(
    LocalDateTime asOf,
    MaritalStatus maritalStatus,
    String mothersMaiden,
    Integer numberOfAdults,
    Integer numberOfChildren,
    Occupation occupation,
    Education highestLevelOfEducation,
    Language primaryLanguage,
    SpeaksEnglish speaksEnglish,
    String stateHivCaseId) {

  public enum MaritalStatus {
    ANNULLED("A"),
    COMMON_LAW("C"),
    DIVORCED("D"),
    DOMESTIC_PARTNER("T"),
    INTERLOCUTORY("I"),
    LEGALLY_SEPARATED("L"),
    LIVING_TOGETHER("G"),
    MARRIED("M"),
    OTHER("O"),
    POLYGAMOUS("P"),
    REFUSED_TO_ANSWER("R"),
    SEPARATED("E"),
    SINGLE_NEVER_MARRIED("S"),
    UNKNOWN("U"),
    UNMARRIED("B"),
    UNREPORTED("F"),
    WIDOWED("W");

    private final String code;

    MaritalStatus(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum Occupation {
    AGRICULTURE_FORESTRY_FISHING_AND_HUNTING("11"),
    MINING("21"),
    UTILITIES("22"),
    CONSTRUCTION("23"),
    WHOLESALE_TRADE("42"),
    INFORMATION("51"),
    FINANCE_AND_INSURANCE("52"),
    REAL_ESTATE_AND_RENTAL_AND_LEASING("53"),
    PROFESSIONAL_SCIENTIFIC_AND_TECHNICAL_SERVICES("54"),
    MANAGEMENT_OF_COMPANIES_AND_ENTERPRISES("55"),
    ADMINISTRATIVE_AND_SUPPORT_AND_WASTE_MANAGEMENT("56"),
    EDUCATIONAL_SERVICES("61"),
    HEALTH_CARE_AND_SOCIAL_ASSISTANCE("62"),
    ARTS_ENTERTAINMENT_AND_RECREATION("71"),
    ACCOMMODATION_AND_FOOD_SERVICES("72"),
    OTHER_SERVICES("81"),
    PUBLIC_ADMINISTRATION("92");

    private final String code;

    Occupation(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum Education {
    ONE_OR_MORE_YEARS_OF_COLLEGE_NO_DEGREE("16"),
    TENTH_GRADE("10"),
    ELEVENTH_GRADE("11"),
    TWELFTH_GRADE_NO_DIPLOMA("12"),
    FIRST_2ND_3RD_OR_4TH_GRADE("4"),
    FIFTH_OR_6TH_GRADE("7"),
    SEVENTH_OR_8TH_GRADE("8"),
    NINETH_GRADE("9"),
    ASSOCIATE_DEGREE_ACADEMIC_PROGRAM("AD"),
    BACHELORS_DEGREE("BD"),
    DOCTORAL_DEGREE("DD"),
    GED_GENERAL_EDUCATION_DIPLOMA("GD"),
    HIGH_SCHOOL_GRADUATE("HD"),
    KINDERGARTEN("K"),
    MASTERS_DEGREE("MD"),
    NO_SCHOOLING_COMPLETED("0"),
    NURSERY_SCHOOL("1"),
    OCCUPATIONAL_VOCATIONAL_DEGREE("OV"),
    PRE_KINDERGARTEN("PK"),
    PROFESSIONAL_DEGREE("PD"),
    SOME_COLLEGE_CREDIT_BUT_LESS_THAN_1_YEAR("13"),
    SOME_HIGH_SCHOOL_DEGREE_STATUS_UNKNOWN("HS");

    private final String code;

    Education(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  // A very narrow subset of options available
  public enum Language {
    ABKHAZIAN("ABK"),
    ACHINESE("ACE"),
    APACHE_LANGUAGES("APA"),
    ARABIC("ARA"),
    ARAGONESE("arg"),
    ARAMAIC("ARC"),
    BOSNIAN("BOS"),
    CHEROKEE("CHR"),
    CHINESE("CH"),
    COPTIC("COP"),
    CZECH("CZE_CES"),
    DANISH("DAN"),
    DUTCH("DUT_NLD"),
    EGYPTIAN("EGY"),
    ENGLISH("ENG"),
    ESTONIAN("EST"),
    FIJIAN("FIJ"),
    FILIPINO_PILIPINO("fil"),
    FINNISH("FIN"),
    FRENCH("FR"),
    GEORGIAN("GEO_KAT"),
    GERMAN("GM"),
    IRISH("GLE"),
    ITALIAN("ITA"),
    JAPANESE("JP"),
    PERSIAN("PER_FAS"),
    ROMANY("ROM"),
    SLAVIC("SLA"),
    TURKISH("TUR"),
    OTHER("OTH");

    private final String code;

    Language(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum SpeaksEnglish {
    YES("Y"),
    NO("N"),
    UNKNOWN("UNK");

    private final String code;

    SpeaksEnglish(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }
}
