package gov.cdc.etldatapipeline.integration.support.data.patient.ethnicity;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Contains the data necessary for setting the ethnicity for a patient. Patients only have 1
 * ethnicity but may have multiple Spanish Origins if the selected Ethnicity is "Hispanic or
 * Latino". An "Unknown Reason" can only be specified if the Ethnicity is "Unknown". The Ethnicity,
 * Unknown Reason, and asOf dates are stored on the person table. Any specified Spanish Origin
 * values are stored in the Person_ethnic_group table.
 *
 * <pre>
 * NBS_ODSE
 * Person.person_uid -> Person_ethnic_group.person_uid
 * </pre>
 */
public record PatientEthnicity(
    LocalDateTime asOf,
    Ethnicity ethnicity,
    List<SpanishOrigin> spanishOrigins,
    ReasonUnknown reasonUnknown) {

  public enum Ethnicity {
    HISPANIC_OR_LATINO("2135-2"),
    NOT_HISPANIC_OR_LATINO("2186-5"),
    UNKNOWN("UNK");

    private final String code;

    Ethnicity(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum ReasonUnknown {
    NOT_ASKED("6"),
    REFUSED_TO_ANSWER("0");

    private final String code;

    ReasonUnknown(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum SpanishOrigin {
    CENTRAL_AMERICAN("2155-0"),
    CUBAN("2182-4"),
    DOMINICAN("2184-0"),
    LATIN_AMERICAN("2178-2"),
    MEXICAN("2148-5"),
    PUERTO_RICAN("2180-8"),
    SOUTH_AMERICAN("2165-9"),
    SPANIARD("2137-8");

    private final String code;

    SpanishOrigin(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }
}
