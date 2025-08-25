package gov.cdc.etldatapipeline.postprocessingservice.repository.model;


import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.GenericGenerator;

import java.sql.Timestamp;

@Entity
@Table(name = "rtr_dead_letter_log")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeadLetterLog {

    @Id
    @GenericGenerator(name = "generator", strategy = "guid", parameters = {})
    @GeneratedValue(generator = "generator")
    @Column(name = "id", columnDefinition="uniqueidentifier")
    private String id;

    @Column(name = "origin_topic", nullable = false)
    private String originTopic;

    @Column(name = "payload", nullable = false)
    private String payload;

    @Column(name = "payload_key", nullable = false)
    private String payloadKey;

    @Column(name = "original_consumer_group")
    private String originalConsumerGroup;

    @Column(name = "exception_stack_trace")
    private String exceptionStackTrace;

    @Column(name = "exception_fqcn")
    private String exceptionFqcn;

    @Column(name = "exception_cause_fqcn")
    private String exceptionCauseFqcn;

    @Column(name = "exception_message")
    private String exceptionMessage;

    @Column(name = "received_at", nullable = false)
    private Timestamp receivedAt;
}