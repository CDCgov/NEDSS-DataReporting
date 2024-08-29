package gov.cdc.etldatapipeline.person.transformer;

import gov.cdc.etldatapipeline.person.model.dto.patient.PatientElasticSearch;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientReporting;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderElasticSearch;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderReporting;

public enum PersonType {
    PATIENT_REPORTING(1, PatientReporting.class),
    PATIENT_ELASTIC_SEARCH(2, PatientElasticSearch.class),
    PROVIDER_REPORTING(3, ProviderReporting.class),
    PROVIDER_ELASTIC_SEARCH(4, ProviderElasticSearch.class);

    public final int val;
    private final Class<?> clazz;

    PersonType (int val, Class<?> clazz) {
        this.val = val;
        this.clazz = clazz;
    }
    @SuppressWarnings("unchecked")
    public <T> Class<T> getClazz() {
        return (Class<T>) clazz;
    }
}
