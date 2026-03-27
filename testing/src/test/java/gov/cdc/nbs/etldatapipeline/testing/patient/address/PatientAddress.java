package gov.cdc.nbs.etldatapipeline.testing.patient.address;

import java.time.LocalDateTime;

/**
 * Contains the data necessary for creating a new address associated with a
 * patient. Valid Type and Use values are provided as enums. The stateCode,
 * countyCode, and countryCodes will need to be supplied as size of the enums
 * would be prohibitive.
 * 
 * <pre>
 * Sample Values
 * stateCode: 13 -> "Georgia"
 * countyCode: 13121 -> "Fulton County, GA"
 * contryCode: 840 -> "United States"
 * </pre>
 */
public record PatientAddress(
    LocalDateTime asOf,
    Type type,
    Use use,
    String address1,
    String address2,
    String city,
    String stateCode,
    String zip,
    String countyCode,
    String censusTract,
    String countryCode,
    String comment) {

  public PatientAddress(
      String address1,
      String address2,
      String city,
      String stateCode,
      String zip,
      String countyCode,
      String censusTract,
      String countryCode) {
    this(
        LocalDateTime.now(),
        Type.HOUSE,
        Use.HOME,
        address1,
        address2,
        city,
        stateCode,
        zip,
        countyCode,
        censusTract,
        countryCode,
        null);
  }

  public enum Type {
    APARTMENT_CONDOMINIUM("A"),
    COUNTRY_OF_ORIGIN("F"),
    DORMITORY("DORM"),
    EMERGENCY_CONTACT("EC"),
    FOSTER_HOME("FH"),
    GROUP_HOME_ORPHANAGE("GHOR"),
    GROUP_HOME_OTHER("GHOTH"),
    GROUP_HOME_SEVERE_MENTAL_IMPAIRMENT("GHMI"),
    GROUP_HOME_DEVELOPMENTALLY_DELAYED("GHDD"),
    HOME_FOR_PREGNANT_TEENS("HPT"),
    HOMELESS_SHELTER("HS"),
    HOTEL("HTL"),
    HOUSE("H"),
    JAIL("PLOC"),
    JUVENILE_DETENTION_CENTER("JD"),
    LIVING_WITH_FRIEND("LWF"),
    MIGRANT_CAMP("MC"),
    MILITARY_BASE("MB"),
    NURSING_HOME_HOSPICE("NH"),
    OFFICE("O"),
    POSTAL_MAILING("M"),
    PRISON_FEDERAL("PF"),
    PRISON_STATE("PS"),
    PRISON_CORRECTIONAL_FACILITY_NOT_SPECIFIED("PNS"),
    REGISTRY_HOME("RH"),
    RESIDENCE_AT_BIRTH("BR"),
    RESIDENTIAL_TREATMENT_FACILITY("RTF"),
    SHELTER_UNSPECIFIED("SHLT"),
    TRANSITIONAL_FACILITY("T"),
    UNKNOWN("U");

    private final String code;

    Type(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum Use {
    BIRTH_DELIVERY_ADDRESS("BDL"),
    HOME("H"),
    PRIMARY_BUSINESS("PB"),
    SECONDARY_BUSINESS("SB"),
    TEMPORARY("TMP");

    private final String code;

    Use(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

}
