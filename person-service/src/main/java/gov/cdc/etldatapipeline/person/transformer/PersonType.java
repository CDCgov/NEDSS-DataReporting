package gov.cdc.etldatapipeline.person.transformer;

public enum PersonType {
    PATIENT_REPORTING(1),
    PATIENT_ELASTIC_SEARCH(2),
    PROVIDER_REPORTING(3),
    PROVIDER_ELASTIC_SEARCH(4);

    public int val;

    private PersonType (int val) {
        this.val = val;
    }
}
