package gov.cdc.nbs.report.pipeline.organization.model.dto.place;

public interface PlaceExt<T extends PlaceReporting> {
  void update(T place);
}
