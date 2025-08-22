package gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Entity
@Data
public class BackfillData {
    @Id
    @Column(name = "record_key")
    private Long recordKey;

    @Column(name = "entity")
    private String entity;

    @Column(name = "record_uid_list")
    private String recordUidList;

    @Column(name = "batch_id")
    private Long batchId;

    @Column(name = "err_description")
    private String errDescription;

    @Column(name = "status_cd")
    private String statusCd;

    @Column(name = "retry_count")
    private Integer retryCount;
}
