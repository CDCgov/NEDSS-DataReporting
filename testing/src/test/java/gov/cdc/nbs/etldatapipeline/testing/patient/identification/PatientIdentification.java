package gov.cdc.nbs.etldatapipeline.testing.patient.identification;

import java.time.LocalDateTime;

public record PatientIdentification(
    LocalDateTime asOf,
    Type type,
    AssigningAuthority assigningAuthority,
    String value) {

  public enum Type {
    ACCOUNT_NUMBER("AN"),
    ALTERNATE_PERSON_NUMBER("APT"),
    CHIP_IDENTIFICATION_NUMBER("CI"),
    DRIVERS_LICENSE_NUMBER("DL"),
    IMMUNIZATION_REGISTRY_ID("IIS"),
    MEDICAID_NUMBER("MA"),
    MEDICAL_RECORD_NUMBER("MR"),
    MEDICARE_NUMBER("MC"),
    MOTHERS_IDENTIFIER("MO"),
    NATIONAL_UNIQUE_INDIVIDUAL_IDENTIFIER("NI"),
    OTHER("OTH"),
    PARTNER_SERVICES_PATIENT_NUMBER("PSID"),
    PATIENT_EXTERNAL_IDENTIFIER("PT"),
    PATIENT_INTERNAL_IDENTIFIER("PI"),
    PERSON_NUMBER("PN"),
    PRISON_IDENTIFICATION_NUMBER("PIN"),
    RYAN_WHITE_IDENTIFIER("RW"),
    SOCIAL_SECURITY("SS"),
    VISA_PASSPORT("VS"),
    WIC_IDENTIFIER("WC");

    private final String code;

    Type(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

  public enum AssigningAuthority {
    AK("AK"),
    AL("AL"),
    AR("AR"),
    AZ("AZ"),
    CA("CA"),
    CO("CO"),
    CT("CT"),
    DE("DE"),
    FL("FL"),
    GA("GA"),
    HI("HI"),
    IA("IA"),
    ID("ID"),
    IL("IL"),
    IN("IN"),
    KS("KS"),
    KY("KY"),
    LA("LA"),
    MA("MA"),
    MD("MD"),
    ME("ME"),
    MI("MI"),
    MN("MN"),
    MO("MO"),
    MS("MS"),
    MT("MT"),
    NC("NC"),
    ND("ND"),
    NE("NE"),
    NH("NH"),
    NJ("NJ"),
    NM("NM"),
    NV("NV"),
    NY("NY"),
    OH("OH"),
    OK("OK"),
    OR("OR"),
    OTHER("OTH"),
    PA("PA"),
    RI("RI"),
    SC("SC"),
    SD("SD"),
    SOCIAL_SECURITY_ADMINISTRATION("SSA"),
    TN("TN"),
    TX("TX"),
    UT("UT"),
    VA("VA"),
    VT("VT"),
    WA("WA"),
    WI("WI"),
    WV("WV"),
    WY("WY");

    private final String code;

    AssigningAuthority(String code) {
      this.code = code;
    }

    public String code() {
      return this.code;
    }
  }

}
