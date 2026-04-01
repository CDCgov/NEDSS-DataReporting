package gov.cdc.etldatapipeline.integration.support.data.patient.mortality;

import java.time.LocalDateTime;

/**
 * Contains the data necessary for setting patient Mortality information. The
 * appropriate codes will
 * need to be supplied for Death State, Death County, and Death Country. Most of
 * the Mortality
 * information is stored within the Person table. However, if death location
 * info is specified then
 * an entry will be added to the Entity_locator_participation and postal_locator
 * tables similar to
 * an address except the "Entity_locator_participation.use_cd" will be "DTH".
 *
 * <pre>
 * Sample Values
 * stateCode: 13 -> "Georgia"
 * countyCode: 13121 -> "Fulton County, GA"
 * contryCode: 840 -> "United States"
 * </pre>
 */
public record PatientMortality(
    LocalDateTime asOf,
    Deceased deceased,
    LocalDateTime dateOfDeath,
    String deathCity,
    String deathStateCode,
    String deathCountyCode,
    String deathCountryCode) {

  public enum Deceased {
    YES("Y"),
    NO("N"),
    UNKNOWN("UNK");

    private final String code;

    Deceased(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }
}
