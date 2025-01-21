package gov.cdc.etldatapipeline.organization.model.dto.place;

public interface PlaceExt<T extends PlaceReporting> {
    void update(T place);
}
