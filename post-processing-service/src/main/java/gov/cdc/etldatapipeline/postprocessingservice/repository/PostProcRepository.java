package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.PostProcSp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface PostProcRepository extends JpaRepository<PostProcSp, Long> {
    @Procedure("sp_nrt_organization_postprocessing")
    void executeStoredProcForOrganizationIds(@Param("organizationUids") String organizationUids);

    @Procedure("sp_nrt_provider_postprocessing")
    void executeStoredProcForProviderIds(@Param("providerUids") String providerUids);

    @Procedure("sp_nrt_patient_postprocessing")
    void executeStoredProcForPatientIds(@Param("patientUids") String patientUids);

    @Procedure("sp_nrt_notification_postprocessing")
    void executeStoredProcForNotificationIds(@Param("notificationUids") String notificationUids);

    @Procedure("sp_nrt_ldf_postprocessing")
    void executeStoredProcForLdfIds(@Param("ldf_uids") String ldfUids);
}
