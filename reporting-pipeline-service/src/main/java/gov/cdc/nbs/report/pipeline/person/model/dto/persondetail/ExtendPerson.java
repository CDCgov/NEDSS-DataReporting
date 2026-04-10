package gov.cdc.nbs.report.pipeline.person.model.dto.persondetail;

import gov.cdc.nbs.report.pipeline.person.model.dto.PersonExtendedProps;

public interface ExtendPerson {
  <T extends PersonExtendedProps> T updatePerson(T person);
}
