package gov.cdc.etldatapipeline.reportinghydration.investigation.repository;

import gov.cdc.etldatapipeline.reportinghydration.investigation.repository.model.dto.NotificationUpdate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface NotificationRepository extends JpaRepository<NotificationUpdate, String> {

    @Query(nativeQuery = true, value = "execute sp_notification_event :notification_uids")
    Optional<NotificationUpdate> computeNotifications(@Param("notification_uids") String notificationUids);
}
