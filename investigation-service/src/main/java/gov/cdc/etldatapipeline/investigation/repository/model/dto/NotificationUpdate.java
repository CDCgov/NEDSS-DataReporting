package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Entity
@Data
public class NotificationUpdate {

    @Id
    @Column(name = "notification_uid")
    private Long notificationUid;

    @Column(name = "investigation_notifications")
    private String investigationNotifications;

    @Column(name = "notification_history")
    private String notificationHistory;
}
