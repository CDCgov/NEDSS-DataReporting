package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.ProviderStoredProc;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ProviderRepository extends JpaRepository<ProviderStoredProc, Long> {
    @Procedure("sp_nrt_provider_postprocessing")
    void executeStoredProcForProviderIds(@Param("providerUids") String providerUids);
}
