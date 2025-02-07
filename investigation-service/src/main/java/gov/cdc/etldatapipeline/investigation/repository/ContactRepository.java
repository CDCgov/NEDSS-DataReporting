package gov.cdc.etldatapipeline.investigation.repository;

import gov.cdc.etldatapipeline.investigation.repository.model.dto.Contact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface ContactRepository extends JpaRepository<Contact, String> {

    @Query(nativeQuery = true, value = "exec sp_contact_record_event :ct_contact_uid")
    Optional<Contact> computeContact(@Param("ct_contact_uid") String contactUid);
}
