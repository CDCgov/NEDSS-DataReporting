package gov.cdc.etldatapipeline.postprocessingservice.repository.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

/* THIS CLASS IS NOT BEING USED NOW BUT WE NEED THIS IN THE FUTURE
WHEN WE SEND DATA BACK FROM THE STORED PROC FOR FURTHER PROCESSING.
*/

@Entity
@Data
public class PostProcSp {
    @Id
    private Long id;
}
