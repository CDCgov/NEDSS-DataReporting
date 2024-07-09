package gov.cdc.etldatapipeline.person.model.dto.persondetail;

import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;

public interface ExtendPerson {
    <T extends PersonExtendedProps> T updatePerson(T person);
}
