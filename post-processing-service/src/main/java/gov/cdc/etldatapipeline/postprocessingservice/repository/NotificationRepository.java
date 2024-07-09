package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.NotificationStoredProc;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface NotificationRepository extends JpaRepository<NotificationStoredProc, Long> {
    @Procedure("sp_nrt_notification_postprocessing")
    void executeStoredProcForNotificationIds(@Param("notificationUids") String notificationUids);
}
