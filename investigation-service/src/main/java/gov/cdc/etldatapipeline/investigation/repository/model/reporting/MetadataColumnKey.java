package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@NoArgsConstructor
public class MetadataColumnKey {
    @NonNull
    @JsonProperty("table_name")
    private String tableName;

    @NonNull
    @JsonProperty("rdb_column_nm")
    private String rdbColumnName;
}
