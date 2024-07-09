package gov.cdc.etldatapipeline.postprocessingservice.repository.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Data
@Entity
public class PageBuilderStoredProc {
    @Id
    private Long id;
}
