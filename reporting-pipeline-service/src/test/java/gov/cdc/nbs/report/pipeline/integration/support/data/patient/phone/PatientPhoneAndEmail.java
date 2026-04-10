package gov.cdc.nbs.report.pipeline.integration.support.data.patient.phone;

import java.time.LocalDateTime;

/**
 * Contains the data necessary for creating a new phone/email address associated with a patient.
 * Phone and Email information is stored in the same table. A patient may have multiple phone/email
 * entries.
 *
 * <pre>
 * NBS_ODSE
 * Person.person_uid -> Entity_locator_participation.entity_uid
 * Entity_locator_participation.locator_uid -> tele_locator.tele_locator_uid
 * </pre>
 */
public record PatientPhoneAndEmail(
    LocalDateTime asOf,
    Type type,
    Use use,
    String countryCode,
    String phoneNumber,
    String extension,
    String email,
    String url,
    String comments) {

  public enum Type {
    ANSWERING_SERVICE("AN"),
    BEEPER("BP"),
    CELLULAR_PHONE("CP"),
    EMAIL_ADDRESS("NET"),
    FAX("FAX"),
    PHONE("PH");

    private final String code;

    Type(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum Use {
    ALTERNATE_WORK_PLACE("SB"),
    EMERGENCY_CONTACT("EC"),
    HOME("H"),
    MOBILE_CONTACT("MC"),
    PRIMARY_WORK_PLACE("WP"),
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
