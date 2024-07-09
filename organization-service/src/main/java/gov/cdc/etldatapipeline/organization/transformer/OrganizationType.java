package gov.cdc.etldatapipeline.organization.transformer;

public enum OrganizationType {
    ORGANIZATION_REPORTING(1),
    ORGANIZATION_ELASTIC_SEARCH(2);

    public final int val;

    OrganizationType(int val) {
        this.val = val;
    }
}
